// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/check/dataflow_analysis.h"

#include "common/set.h"
#include "llvm/ADT/StringRef.h"
#include "toolchain/sem_ir/file.h"
#include "toolchain/sem_ir/function.h"
#include "toolchain/sem_ir/inst.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Check {

// Recursive helper to find EntityNameId from a pattern.
static auto GetEntityNameFromPattern(const SemIR::File& sem_ir,
                                     SemIR::InstId pattern_id)
    -> SemIR::EntityNameId {
  auto inst = sem_ir.insts().Get(pattern_id);
  if (auto var_pattern = inst.TryAs<SemIR::VarPattern>()) {
    return GetEntityNameFromPattern(sem_ir, var_pattern->subpattern_id);
  }
  if (auto var_param = inst.TryAs<SemIR::VarParamPattern>()) {
    return GetEntityNameFromPattern(sem_ir, var_param->subpattern_id);
  }
  if (auto ref_param = inst.TryAs<SemIR::RefParamPattern>()) {
    return GetEntityNameFromPattern(sem_ir, ref_param->subpattern_id);
  }
  if (auto val_param = inst.TryAs<SemIR::ValueParamPattern>()) {
    return GetEntityNameFromPattern(sem_ir, val_param->subpattern_id);
  }
  if (auto ref_bind = inst.TryAs<SemIR::RefBindingPattern>()) {
    return ref_bind->entity_name_id;
  }
  if (auto val_bind = inst.TryAs<SemIR::ValueBindingPattern>()) {
    return val_bind->entity_name_id;
  }
  // TODO: Handle TuplePattern, etc. if necessary.
  return SemIR::EntityNameId::None;
}

// Helper to get variable info from various instructions.
// Returns {NameId, EntityNameId}
static auto GetVarInfo(const SemIR::File& sem_ir, SemIR::InstId inst_id)
    -> std::pair<SemIR::NameId, SemIR::EntityNameId> {
  auto inst = sem_ir.insts().Get(inst_id);

  if (auto var_storage = inst.TryAs<SemIR::VarStorage>()) {
    if (var_storage->pattern_id.has_value()) {
      auto entity_name_id =
          GetEntityNameFromPattern(sem_ir, var_storage->pattern_id);
      if (entity_name_id.has_value()) {
        return {sem_ir.entity_names().Get(entity_name_id).name_id,
                entity_name_id};
      }
    }
  } else if (auto ref_bind = inst.TryAs<SemIR::RefBinding>()) {
    return {sem_ir.entity_names().Get(ref_bind->entity_name_id).name_id,
            ref_bind->entity_name_id};
  } else if (auto val_bind = inst.TryAs<SemIR::ValueBinding>()) {
    return {sem_ir.entity_names().Get(val_bind->entity_name_id).name_id,
            val_bind->entity_name_id};
  } else if (auto name_ref = inst.TryAs<SemIR::NameRef>()) {
    // NameRef.value_id points to the binding (RefBinding/ValueBinding).
    auto binding_id = name_ref->value_id;
    auto binding_inst = sem_ir.insts().Get(binding_id);
    if (auto ref_bind = binding_inst.TryAs<SemIR::RefBinding>()) {
      return {sem_ir.entity_names().Get(ref_bind->entity_name_id).name_id,
              ref_bind->entity_name_id};
    } else if (auto val_bind = binding_inst.TryAs<SemIR::ValueBinding>()) {
      return {sem_ir.entity_names().Get(val_bind->entity_name_id).name_id,
              val_bind->entity_name_id};
    }
  }
  return {SemIR::NameId::None, SemIR::EntityNameId::None};
}

// Retrieves the name of a variable given its EntityNameId.
static auto GetName(const SemIR::File& sem_ir, SemIR::EntityNameId entity_id)
    -> SemIR::NameId {
  return sem_ir.entity_names().Get(entity_id).name_id;
}

auto BuildDataflowFacts(const SemIR::File& sem_ir,
                        SemIR::FunctionId function_id, llvm::raw_ostream* out)
    -> DataflowFacts {
  DataflowFacts facts;
  const auto& function = sem_ir.functions().Get(function_id);

  if (out) {
    llvm::StringRef func_name = sem_ir.names().GetFormatted(function.name_id);
    *out << "Function: " << func_name << "\n";
  }

  // Collect definitions from parameters.
  if (function.param_patterns_id.has_value()) {
    auto param_patterns = sem_ir.inst_blocks().Get(function.param_patterns_id);
    for (auto pattern_id : param_patterns) {
      auto entity_name_id = GetEntityNameFromPattern(sem_ir, pattern_id);
      if (entity_name_id.has_value()) {
        auto name_id = GetName(sem_ir, entity_name_id);
        // Use the pattern_id as the instruction ID for the definition.
        facts.defs.Insert(Fact{pattern_id.index, entity_name_id.index});
        if (out) {
          *out << "def: " << sem_ir.names().GetFormatted(name_id) << " ("
               << entity_name_id.index << ") at " << pattern_id << "\n";
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

      // 1. Definition (VarStorage)
      if (inst.Is<SemIR::VarStorage>()) {
        auto [name_id, var_id] = GetVarInfo(sem_ir, inst_id);
        if (name_id.has_value()) {
          facts.defs.Insert(Fact{inst_id.index, var_id.index});
          if (out) {
            *out << "def: " << sem_ir.names().GetFormatted(name_id) << " ("
                 << var_id.index << ") at " << inst_id << "\n";
          }
        }
      }

      // 2. Assignment
      else if (auto assign = inst.TryAs<SemIR::Assign>()) {
        auto [name_id, var_id] = GetVarInfo(sem_ir, assign->lhs_id);
        if (name_id.has_value()) {
          facts.assigns.Insert(Fact{inst_id.index, var_id.index});
          if (out) {
            *out << "assign: " << sem_ir.names().GetFormatted(name_id) << " ("
                 << var_id.index << ") at " << inst_id << "\n";
          }
        }
      }

      // 3. Use (NameRef not in LHS)
      else if (inst.Is<SemIR::NameRef>()) {
        if (!assigned_lhs.Contains(inst_id)) {
          auto [name_id, var_id] = GetVarInfo(sem_ir, inst_id);
          if (name_id.has_value()) {
            facts.uses.Insert(Fact{inst_id.index, var_id.index});
            if (out) {
              *out << "use: " << sem_ir.names().GetFormatted(name_id) << " ("
                   << var_id.index << ") at " << inst_id << "\n";
            }
          }
        }
      }

      // 4. Edges (Terminators)
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

auto CheckUnusedVariables(const SemIR::File& sem_ir, const DataflowFacts& facts,
                          llvm::raw_ostream& out) -> void {
  // Collect all used variable IDs (EntityNameId indices).
  Set<int32_t> used_vars;
  facts.uses.ForEach([&](const Fact& use) { used_vars.Insert(use.id2); });

  // Check definitions.
  facts.defs.ForEach([&](const Fact& def) {
    auto var_id = def.id2;
    if (!used_vars.Contains(var_id)) {
      auto name_id = GetName(sem_ir, SemIR::EntityNameId(var_id));
      llvm::StringRef name = sem_ir.names().GetFormatted(name_id);
      if (!name.starts_with("_")) {
        out << "Warning: variable '" << name << "' is unused.\n";
      }
    }
  });
}

auto RunDataflowAnalysis(const SemIR::File& sem_ir,
                         SemIR::FunctionId function_id, llvm::raw_ostream& out)
    -> void {
  auto facts = BuildDataflowFacts(sem_ir, function_id, &out);
  CheckUnusedVariables(sem_ir, facts, out);
}

}  // namespace Carbon::Check
