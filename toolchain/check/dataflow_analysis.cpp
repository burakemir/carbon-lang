// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/check/dataflow_analysis.h"

#include "common/set.h"
#include "llvm/ADT/BitVector.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "toolchain/check/diagnostic_helpers.h"
#include "toolchain/diagnostics/diagnostic.h"
#include "toolchain/sem_ir/file.h"
#include "toolchain/sem_ir/function.h"
#include "toolchain/sem_ir/inst.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Check {

CARBON_DIAGNOSTIC(UnusedVariable, Warning, "variable `{0}` is unused",
                  std::string);
CARBON_DIAGNOSTIC(UseOfMovedVariable, Error, "use of moved variable `{0}`",
                  std::string);

// Retrieves the name of a variable given its storage ID.
static auto GetName(const SemIR::File& sem_ir, SemIR::EntityNameId entity_id)
    -> SemIR::NameId {
  return sem_ir.entity_names().Get(entity_id).name_id;
}

// Returns true if the function is `Core.Move.Op`.
static auto IsMoveOp(const SemIR::File& sem_ir, SemIR::FunctionId function_id)
    -> bool {
  const auto& function = sem_ir.functions().Get(function_id);
  auto name_str = sem_ir.names().GetFormatted(function.name_id);
  if (name_str != "Op") {
    return false;
  }
  if (!function.parent_scope_id.has_value()) {
    return false;
  }
  auto parent_scope_id = function.parent_scope_id;
  const auto& parent_scope = sem_ir.name_scopes().Get(parent_scope_id);
  auto parent_name_str = sem_ir.names().GetFormatted(parent_scope.name_id());
  if (parent_name_str != "Move") {
    return false;
  }
  if (!sem_ir.name_scopes().IsCorePackage(parent_scope.parent_scope_id())) {
    return false;
  }
  return true;
}

// Recursive helper to find EntityNameIds from a pattern.
static auto CollectEntityNamesFromPattern(
    const SemIR::File& sem_ir, SemIR::InstId pattern_id,
    llvm::SmallVectorImpl<std::pair<SemIR::EntityNameId, SemIR::InstId>>& names)
    -> void {
  auto inst = sem_ir.insts().Get(pattern_id);
  if (auto var_pattern = inst.TryAs<SemIR::VarPattern>()) {
    CollectEntityNamesFromPattern(sem_ir, var_pattern->subpattern_id, names);
  } else if (auto var_param = inst.TryAs<SemIR::VarParamPattern>()) {
    CollectEntityNamesFromPattern(sem_ir, var_param->subpattern_id, names);
  } else if (auto ref_param = inst.TryAs<SemIR::RefParamPattern>()) {
    CollectEntityNamesFromPattern(sem_ir, ref_param->subpattern_id, names);
  } else if (auto val_param = inst.TryAs<SemIR::ValueParamPattern>()) {
    CollectEntityNamesFromPattern(sem_ir, val_param->subpattern_id, names);
  } else if (auto ref_bind = inst.TryAs<SemIR::RefBindingPattern>()) {
    names.push_back({ref_bind->entity_name_id, pattern_id});
  } else if (auto val_bind = inst.TryAs<SemIR::ValueBindingPattern>()) {
    names.push_back({val_bind->entity_name_id, pattern_id});
  } else if (auto tuple_pattern = inst.TryAs<SemIR::TuplePattern>()) {
    auto elements = sem_ir.inst_blocks().Get(tuple_pattern->elements_id);
    for (auto element_id : elements) {
      CollectEntityNamesFromPattern(sem_ir, element_id, names);
    }
  }
}

struct VarInfo {
  SemIR::NameId name_id;
  SemIR::EntityNameId entity_id;
  SemIR::InstId def_inst_id;
};

// Helper to get variable info from various instructions.
static auto GetVarInfos(const SemIR::File& sem_ir, SemIR::InstId inst_id)
    -> llvm::SmallVector<VarInfo> {
  llvm::SmallVector<VarInfo> infos;
  auto inst = sem_ir.insts().Get(inst_id);

  if (auto var_storage = inst.TryAs<SemIR::VarStorage>()) {
    if (var_storage->pattern_id.has_value()) {
      llvm::SmallVector<std::pair<SemIR::EntityNameId, SemIR::InstId>> names;
      CollectEntityNamesFromPattern(sem_ir, var_storage->pattern_id, names);
      for (auto [entity_id, def_id] : names) {
        infos.push_back({GetName(sem_ir, entity_id), entity_id, def_id});
      }
    }
  } else if (auto ref_bind = inst.TryAs<SemIR::RefBinding>()) {
    infos.push_back({GetName(sem_ir, ref_bind->entity_name_id),
                     ref_bind->entity_name_id, inst_id});
  } else if (auto val_bind = inst.TryAs<SemIR::ValueBinding>()) {
    infos.push_back({GetName(sem_ir, val_bind->entity_name_id),
                     val_bind->entity_name_id, inst_id});
  } else if (auto name_ref = inst.TryAs<SemIR::NameRef>()) {
    auto binding_id = name_ref->value_id;
    auto binding_inst = sem_ir.insts().Get(binding_id);
    if (auto ref_bind = binding_inst.TryAs<SemIR::RefBinding>()) {
      infos.push_back({GetName(sem_ir, ref_bind->entity_name_id),
                       ref_bind->entity_name_id, binding_id});
    } else if (auto val_bind = binding_inst.TryAs<SemIR::ValueBinding>()) {
      infos.push_back({GetName(sem_ir, val_bind->entity_name_id),
                       val_bind->entity_name_id, binding_id});
    }
  }
  return infos;
}

// Helper to get variable info from a value expression (e.g. NameRef, etc.)
static auto GetVarFromValue(const SemIR::File& sem_ir, SemIR::InstId value_id)
    -> std::optional<VarInfo> {
  auto inst = sem_ir.insts().Get(value_id);
  if (auto name_ref = inst.TryAs<SemIR::NameRef>()) {
    auto binding_id = name_ref->value_id;
    auto binding_inst = sem_ir.insts().Get(binding_id);
    if (auto ref_bind = binding_inst.TryAs<SemIR::RefBinding>()) {
      return VarInfo{GetName(sem_ir, ref_bind->entity_name_id),
                     ref_bind->entity_name_id, binding_id};
    } else if (auto val_bind = binding_inst.TryAs<SemIR::ValueBinding>()) {
      return VarInfo{GetName(sem_ir, val_bind->entity_name_id),
                     val_bind->entity_name_id, binding_id};
    }
  } else if (auto addr_of = inst.TryAs<SemIR::AddrOf>()) {
    return GetVarFromValue(sem_ir, addr_of->lvalue_id);
  } else if (auto bound_method = inst.TryAs<SemIR::BoundMethod>()) {
    return GetVarFromValue(sem_ir, bound_method->object_id);
  }
  return std::nullopt;
}

static auto BuildDataflowFacts(const SemIR::File& sem_ir,
                               SemIR::FunctionId function_id,
                               llvm::raw_ostream* out) -> DataflowFacts {
  DataflowFacts facts;
  const auto& function = sem_ir.functions().Get(function_id);

  if (out) {
    llvm::StringRef func_name = sem_ir.names().GetFormatted(function.name_id);
    *out << "Function: " << func_name << "\n";
  }

  // Track ref bindings to treat assignments as uses.
  Set<int32_t> ref_params;

  // Collect definitions from parameters.
  if (function.param_patterns_id.has_value()) {
    auto param_patterns = sem_ir.inst_blocks().Get(function.param_patterns_id);
    for (auto pattern_id : param_patterns) {
      llvm::SmallVector<std::pair<SemIR::EntityNameId, SemIR::InstId>>
          entity_names;
      CollectEntityNamesFromPattern(sem_ir, pattern_id, entity_names);
      for (auto [entity_name_id, def_inst_id] : entity_names) {
        auto name_id = GetName(sem_ir, entity_name_id);
        facts.defs.Insert(Fact{def_inst_id.index, entity_name_id.index});
        if (out) {
          *out << "def: " << sem_ir.names().GetFormatted(name_id) << " ("
               << entity_name_id.index << ") at " << def_inst_id << "\n";
        }

        // Identify ref bindings.
        auto inst = sem_ir.insts().Get(pattern_id);
        if (inst.Is<SemIR::RefParamPattern>()) {
          ref_params.Insert(entity_name_id.index);
        }
      }
    }
  }

  if (function.body_block_ids.empty()) {
    return facts;
  }

  for (const auto& block_id : function.body_block_ids) {
    const auto& block = sem_ir.inst_blocks().Get(block_id);

    // Emit leader fact for non-empty blocks.
    if (!block.empty()) {
      facts.leaders.Insert(Fact{block_id.index, block.front().index});
      if (out) {
        *out << "leader: " << block_id << " -> " << block.front() << "\n";
      }
    }

    // First pass: identify LHS of assignments to avoid counting them as uses.
    Set<SemIR::InstId> assigned_lhs;
    for (const auto& inst_id : block) {
      auto inst = sem_ir.insts().Get(inst_id);
      if (auto assign = inst.TryAs<SemIR::Assign>()) {
        assigned_lhs.Insert(assign->lhs_id);
      }
    }

    for (size_t i = 0; i < block.size(); ++i) {
      auto inst_id = block[i];
      auto inst = sem_ir.insts().Get(inst_id);

      // Intra-block edge
      if (i + 1 < block.size()) {
        auto next_inst_id = block[i + 1];
        facts.edges.Insert(Fact{inst_id.index, next_inst_id.index});
        if (out) {
          *out << "edge: " << inst_id << " -> " << next_inst_id << "\n";
        }
      }

      if (inst.Is<SemIR::VarStorage>()) {
        // Emit `Defs` facts for VarStorage.
        auto var_infos = GetVarInfos(sem_ir, inst_id);
        for (auto [name_id, var_id, def_inst_id] : var_infos) {
          facts.defs.Insert(Fact{def_inst_id.index, var_id.index});
          if (out) {
            *out << "def: " << sem_ir.names().GetFormatted(name_id) << " ("
                 << var_id.index << ") at " << def_inst_id << "\n";
          }
        }
      } else if (auto assign = inst.TryAs<SemIR::Assign>()) {
        // Emit `Assigns` facts for Assignment.
        auto var_infos = GetVarInfos(sem_ir, assign->lhs_id);
        for (auto [name_id, var_id, _] : var_infos) {
          facts.assigns.Insert(Fact{inst_id.index, var_id.index});
          if (out) {
            *out << "assign: " << sem_ir.names().GetFormatted(name_id) << " ("
                 << var_id.index << ") at " << inst_id << "\n";
          }
        }
      } else if (inst.Is<SemIR::NameRef>()) {
        // Emit `Use` facts for case NameRef.
        auto var_infos = GetVarInfos(sem_ir, inst_id);
        for (auto [name_id, var_id, _] : var_infos) {
          bool is_lhs = assigned_lhs.Contains(inst_id);
          // If it's a ref binding, assignment counts as a use because it
          // involves dereferencing the pointer/ref to write to it.
          if (!is_lhs || ref_params.Contains(var_id.index)) {
            facts.uses.Insert(Fact{inst_id.index, var_id.index});
            if (out) {
              *out << "use: " << sem_ir.names().GetFormatted(name_id) << " ("
                   << var_id.index << ") at " << inst_id << "\n";
            }
          }
        }
      } else if (auto val_init = inst.TryAs<SemIR::ValueOfInitializer>()) {
        // Emit `Use` facts for  ValueOfInitializer. This case applies
        // when returning a var by value.
        auto var_infos = GetVarInfos(sem_ir, val_init->init_id);
        for (auto [name_id, var_id, _] : var_infos) {
          facts.uses.Insert(Fact{inst_id.index, var_id.index});
          if (out) {
            *out << "use: " << sem_ir.names().GetFormatted(name_id) << " ("
                 << var_id.index << ") at " << inst_id << "\n";
          }
        }
      } else if (auto acquire = inst.TryAs<SemIR::AcquireValue>()) {
        // Emit `Use` facts for AcquireValue. This case applies when
        // converting a reference to a value (e.g. return var).
        auto var_infos = GetVarInfos(sem_ir, acquire->value_id);
        for (auto [name_id, var_id, _] : var_infos) {
          facts.uses.Insert(Fact{inst_id.index, var_id.index});
          if (out) {
            *out << "use: " << sem_ir.names().GetFormatted(name_id) << " ("
                 << var_id.index << ") at " << inst_id << "\n";
          }
        }
      } else if (auto ret = inst.TryAs<SemIR::ReturnExpr>()) {
        // Handle `Use` facts for ReturnExpr. This case applies
        // when returning a var directly (e.g. with return slot).
        auto var_infos = GetVarInfos(sem_ir, ret->expr_id);
        for (auto [name_id, var_id, _] : var_infos) {
          facts.uses.Insert(Fact{inst_id.index, var_id.index});
          if (out) {
            *out << "use: " << sem_ir.names().GetFormatted(name_id) << " ("
                 << var_id.index << ") at " << inst_id << "\n";
          }
        }
      } else if (auto call = inst.TryAs<SemIR::Call>()) {
        // Handle `Use` facts for Move. This case applies when
        // the move operator ~ is called.
        SemIR::InstId callee_id = call->callee_id;
        auto callee = sem_ir.insts().Get(callee_id);
        if (auto bound = callee.TryAs<SemIR::BoundMethod>()) {
          // Use SemIR::GetCallee to resolve the function ID from the bound
          // method's function declaration, which might be a FunctionDecl,
          // SpecificFunction, or SpecificImplFunction.
          SemIR::FunctionId func_id = SemIR::FunctionId::None;
          auto callee_variant =
              SemIR::GetCallee(sem_ir, bound->function_decl_id);
          if (auto* fn = std::get_if<SemIR::CalleeFunction>(&callee_variant)) {
            func_id = fn->function_id;
          }

          if (func_id != SemIR::FunctionId::None && IsMoveOp(sem_ir, func_id)) {
            if (auto info = GetVarFromValue(sem_ir, bound->object_id)) {
              facts.moves.Insert(Fact{inst_id.index, info->entity_id.index});
              if (out) {
                *out << "move: " << sem_ir.names().GetFormatted(info->name_id)
                     << " (" << info->entity_id.index << ") at " << inst_id
                     << "\n";
              }
            }
          }
        }
      }

      // Handle `Edge` facts (Terminators)
      if (auto branch = inst.TryAs<SemIR::Branch>()) {
        facts.branch_edges.Insert(Fact{inst_id.index, branch->target_id.index});
        if (out) {
          *out << "branch-edge: " << inst_id << " -> " << branch->target_id
               << "\n";
        }
      } else if (auto branch_if = inst.TryAs<SemIR::BranchIf>()) {
        facts.branch_edges.Insert(
            Fact{inst_id.index, branch_if->target_id.index});
        if (out) {
          *out << "branch-edge: " << inst_id << " -> " << branch_if->target_id
               << "\n";
        }
      } else if (auto branch_arg = inst.TryAs<SemIR::BranchWithArg>()) {
        facts.branch_edges.Insert(
            Fact{inst_id.index, branch_arg->target_id.index});
        if (out) {
          *out << "branch-edge: " << inst_id << " -> " << branch_arg->target_id
               << "\n";
        }
      }
    }
  }
  return facts;
}

static auto CheckUnusedVariables(Context& context, const DataflowFacts& facts)
    -> void {
  auto& sem_ir = context.sem_ir();
  Set<int32_t> used_vars;
  facts.uses.ForEach([&](const Fact& use) { used_vars.Insert(use.id2); });

  facts.defs.ForEach([&](const Fact& def) {
    auto var_id = def.id2;
    if (!used_vars.Contains(var_id)) {
      auto name_id = GetName(sem_ir, SemIR::EntityNameId(var_id));
      llvm::StringRef name = sem_ir.names().GetFormatted(name_id);
      if (!name.starts_with("_")) {
        auto inst_id = SemIR::InstId(def.id1);
        auto loc_id = sem_ir.insts().GetCanonicalLocId(inst_id);
        context.emitter().Emit(LocIdForDiagnostics(loc_id), UnusedVariable,
                               name.str());
      }
    }
  });
}

static auto RunLivenessAnalysis(Context& context, DataflowFacts& facts,
                                llvm::raw_ostream* out) -> void {
  const auto& sem_ir = context.sem_ir();
  llvm::DenseMap<int32_t, llvm::SmallVector<int32_t, 2>> predecessors;
  llvm::DenseMap<int32_t, int32_t> leaders_map;

  facts.leaders.ForEach([&](const Fact& f) { leaders_map[f.id1] = f.id2; });

  facts.edges.ForEach(
      [&](const Fact& f) { predecessors[f.id2].push_back(f.id1); });
  facts.branch_edges.ForEach([&](const Fact& f) {
    auto leader_it = leaders_map.find(f.id2);
    if (leader_it != leaders_map.end()) {
      predecessors[leader_it->second].push_back(f.id1);
    }
  });

  std::vector<Fact> worklist;
  facts.uses.ForEach([&](const Fact& f) {
    if (facts.live.Insert(f).is_inserted()) {
      worklist.push_back(f);
    }
  });

  while (!worklist.empty()) {
    Fact current = worklist.back();
    worklist.pop_back();
    int32_t inst_id = current.id1;
    int32_t var_id = current.id2;

    if (auto it = predecessors.find(inst_id); it != predecessors.end()) {
      for (int32_t pred_id : it->second) {
        bool killed = false;
        if (facts.defs.Contains(Fact{pred_id, var_id}) ||
            facts.assigns.Contains(Fact{pred_id, var_id})) {
          killed = true;
        }

        if (!killed) {
          Fact pred_live_fact = {pred_id, var_id};
          if (facts.live.Insert(pred_live_fact).is_inserted()) {
            worklist.push_back(pred_live_fact);
          }

          // Propagate is_moved state. For a live variable, we already
          // know that there is an error, but for useful diagnostics, we
          // need to find the place where the variable is used.
          if (facts.moves.Contains(Fact{pred_id, var_id}) ||
              facts.is_moved.Contains(Fact{pred_id, var_id})) {
            if (out) {
              if (facts.moves.Contains(Fact{pred_id, var_id})) {
                *out << "moves contains " << SemIR::InstId(pred_id) << " ";
                auto name_id = GetName(sem_ir, SemIR::EntityNameId(var_id));
                *out << sem_ir.names().GetFormatted(name_id);
              }
              if (facts.is_moved.Contains(Fact{pred_id, var_id})) {
                *out << "moves contains " << SemIR::InstId(pred_id) << " ";
                auto name_id = GetName(sem_ir, SemIR::EntityNameId(var_id));
                *out << sem_ir.names().GetFormatted(name_id);
              }
            }
            Fact is_moved_fact = {inst_id, var_id};
            if (facts.is_moved.Insert(is_moved_fact).is_inserted()) {
              worklist.push_back(is_moved_fact);
            }
          }
        }
      }
    }
  }

  // Check instruction where a var is both "used" and "is_moved"
  facts.uses.ForEach([&](const Fact& f) {
    if (facts.is_moved.Contains(f)) {
      if (out) {
        *out << "is_moved contains " << f.id1 << " " << f.id2;
      }
      auto [inst_id, var_id] = f;
      auto name_id = GetName(sem_ir, SemIR::EntityNameId(var_id));
      llvm::StringRef name = sem_ir.names().GetFormatted(name_id);
      auto loc_id = sem_ir.insts().GetCanonicalLocId(SemIR::InstId(inst_id));
      context.emitter().Emit(LocIdForDiagnostics(loc_id), UseOfMovedVariable,
                             name.str());
      // TODO: Find the place that moved and emit diagnostic moved here.
    }
  });

  if (out) {
    std::vector<int32_t> sorted_insts;
    llvm::DenseMap<int32_t, std::vector<int32_t>> live_map;
    facts.live.ForEach([&](const Fact& f) {
      if (live_map.find(f.id1) == live_map.end()) {
        sorted_insts.push_back(f.id1);
      }
      live_map[f.id1].push_back(f.id2);
    });

    std::sort(sorted_insts.begin(), sorted_insts.end());

    for (auto inst_id : sorted_insts) {
      *out << "Liveness: " << SemIR::InstId(inst_id) << " -> {";
      auto& vars = live_map[inst_id];
      std::sort(vars.begin(), vars.end());
      bool first = true;
      for (auto var_id : vars) {
        if (!first) {
          *out << ", ";
        }
        auto name_id = GetName(sem_ir, SemIR::EntityNameId(var_id));
        *out << sem_ir.names().GetFormatted(name_id);
        first = false;
      }
      *out << "}\n";
    }
  }
}

auto RunDataflowAnalysis(Context& context, SemIR::FunctionId function_id,
                         llvm::raw_ostream* out) -> void {
  auto facts = BuildDataflowFacts(context.sem_ir(), function_id, out);
  CheckUnusedVariables(context, facts);
  RunLivenessAnalysis(context, facts, out);
}

}  // namespace Carbon::Check
