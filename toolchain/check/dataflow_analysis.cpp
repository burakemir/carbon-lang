// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/check/dataflow_analysis.h"

#include "common/map.h"
#include "common/set.h"
#include "toolchain/base/kind_switch.h"
#include "toolchain/check/context.h"
#include "toolchain/sem_ir/file.h"
#include "toolchain/sem_ir/ids.h"
#include "toolchain/sem_ir/inst.h"
#include "toolchain/sem_ir/inst_kind.h"

// Dataflow analysis is a technique for gathering information about the
// possible set of values calculated at various points in a computer program.
// It involves setting up a system of dataflow equations (or constraints) that
// relate information at different points in the program, based on the semantics
// of instructions and the control flow graph. These equations are then solved,
// typically using an iterative algorithm that propagates information through
// the graph until a fixpoint is reached.
//
// Good resources on dataflow analysis are:
// * Anders Møller and Michael I. Schwartzbach "Static Program Analysis" or
// also "Lecture Notes on Static Analysis"
// * the Dragon book (Compilers: Principles, Techniques, and Tools, 2nd
// Edition), specifically Chapter 9.2 "Introduction to Dataflow Analysis" and
// Chapter 12.3 "A Logical Representation of Data Flow" for datalog.

namespace Carbon::Check {

// Represents a single fact with two IDs.
template <typename Id1, typename Id2>
using Fact = std::pair<Id1, Id2>;

// Facts about the control flow graph.
using LeaderFact = Fact<SemIR::InstBlockId, SemIR::InstId>;
using EdgeFact = Fact<SemIR::InstId, SemIR::InstId>;
using BranchEdgeFact = Fact<SemIR::InstId, SemIR::InstBlockId>;

// Facts about variables.
// The first ID is the instruction where the fact holds or is generated.
// The second ID is the variable (EntityNameId).
using VarFact = Fact<SemIR::InstId, SemIR::EntityNameId>;

struct DataflowFacts {
  Set<LeaderFact> leaders;
  Set<EdgeFact> edges;
  Set<BranchEdgeFact> branch_edges;

  Set<VarFact> assigns;
  Set<VarFact> uses;

  // Var is moved at this instruction.
  Set<VarFact> moves;
  // Var is in moved-from state at this instruction.
  Set<VarFact> is_moved;
};

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

  auto check_interface = [&](SemIR::InterfaceId interface_id) {
    const auto& interface = sem_ir.interfaces().Get(interface_id);
    auto interface_name = sem_ir.names().GetFormatted(interface.name_id);
    return interface_name == "Move" &&
           sem_ir.name_scopes().IsCorePackage(interface.parent_scope_id);
  };

  // Case 1: The function is directly in the Move interface.
  auto parent_name_str = sem_ir.names().GetFormatted(parent_scope.name_id());
  if (parent_name_str == "Move") {
    return sem_ir.name_scopes().IsCorePackage(parent_scope.parent_scope_id());
  }

  // Case 2: The function is in an impl of the Move interface.
  auto parent_inst_info = sem_ir.name_scopes().GetInstIfValid(parent_scope_id);
  if (parent_inst_info.second) {
    if (auto impl_decl = parent_inst_info.second->TryAs<SemIR::ImplDecl>()) {
      const auto& impl = sem_ir.impls().Get(impl_decl->impl_id);
      if (impl.interface.interface_id.has_value() &&
          check_interface(impl.interface.interface_id)) {
        return true;
      }
    }
  }

  return false;
}

// Recursive helper to find EntityNameIds from a pattern.
static auto CollectEntityNamesFromPattern(
    const SemIR::File& sem_ir, SemIR::InstId root_pattern_id,
    llvm::SmallVectorImpl<std::pair<SemIR::EntityNameId, SemIR::InstId>>& names)
    -> void {
  llvm::SmallVector<SemIR::InstId> work_list;
  work_list.push_back(root_pattern_id);

  while (!work_list.empty()) {
    auto pattern_id = work_list.pop_back_val();
    auto inst = sem_ir.insts().Get(pattern_id);
    CARBON_KIND_SWITCH(inst) {
      case CARBON_KIND(SemIR::VarPattern var_pattern): {
        work_list.push_back(var_pattern.subpattern_id);
        break;
      }
      case CARBON_KIND(SemIR::VarParamPattern var_param): {
        work_list.push_back(var_param.subpattern_id);
        break;
      }
      case CARBON_KIND(SemIR::RefParamPattern ref_param): {
        work_list.push_back(ref_param.subpattern_id);
        break;
      }
      case CARBON_KIND(SemIR::ValueParamPattern val_param): {
        work_list.push_back(val_param.subpattern_id);
        break;
      }
      case CARBON_KIND(SemIR::RefBindingPattern ref_bind): {
        names.push_back({ref_bind.entity_name_id, pattern_id});
        break;
      }
      case CARBON_KIND(SemIR::ValueBindingPattern val_bind): {
        names.push_back({val_bind.entity_name_id, pattern_id});
        break;
      }
      case CARBON_KIND(SemIR::TuplePattern tuple): {
        auto elements = sem_ir.inst_blocks().Get(tuple.elements_id);
        for (auto element_id : llvm::reverse(elements)) {
          work_list.push_back(element_id);
        }
        break;
      }
      default:
        break;
    }
  }
}

// A variable together with the ID of the instruction defining the variable
// (e.g., VarStorage or binding).
//
// For diagnostics, we want to point to the specific place where a variable
// is defined, in order to distinguish different variables that may have
// the same name.
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

  CARBON_KIND_SWITCH(inst) {
    case CARBON_KIND(SemIR::VarPattern var_pattern): {
      llvm::SmallVector<std::pair<SemIR::EntityNameId, SemIR::InstId>> names;
      CollectEntityNamesFromPattern(sem_ir, var_pattern.subpattern_id, names);
      for (auto [entity_id, def_id] : names) {
        infos.push_back({GetName(sem_ir, entity_id), entity_id, def_id});
      }
      break;
    }

    case CARBON_KIND(SemIR::RefBinding ref_bind): {
      infos.push_back({GetName(sem_ir, ref_bind.entity_name_id),
                       ref_bind.entity_name_id, inst_id});
      break;
    }
    case CARBON_KIND(SemIR::ValueBinding val_bind): {
      infos.push_back({GetName(sem_ir, val_bind.entity_name_id),
                       val_bind.entity_name_id, inst_id});
      break;
    }
    case CARBON_KIND(SemIR::NameRef name_ref): {
      // NameRef.value_id points to the binding (RefBinding/ValueBinding).
      auto binding_id = name_ref.value_id;
      auto binding_inst = sem_ir.insts().Get(binding_id);
      CARBON_KIND_SWITCH(binding_inst) {
        case CARBON_KIND(SemIR::RefBinding inner_ref_bind): {
          infos.push_back({GetName(sem_ir, inner_ref_bind.entity_name_id),
                           inner_ref_bind.entity_name_id, binding_id});
          break;
        }
        case CARBON_KIND(SemIR::ValueBinding inner_val_bind): {
          infos.push_back({GetName(sem_ir, inner_val_bind.entity_name_id),
                           inner_val_bind.entity_name_id, binding_id});
          break;
        }
        default:
          break;
      }
      break;
    }
    default:
      break;
  }
  return infos;
}

// Helper to get variable info from a value expression (e.g. NameRef, etc.)
static auto GetVarFromValue(const SemIR::File& sem_ir, SemIR::InstId value_id)
    -> std::optional<VarInfo> {
  auto inst = sem_ir.insts().Get(value_id);
  CARBON_KIND_SWITCH(inst) {
    case CARBON_KIND(SemIR::NameRef name_ref): {
      auto binding_id = name_ref.value_id;
      auto binding_inst = sem_ir.insts().Get(binding_id);
      CARBON_KIND_SWITCH(binding_inst) {
        case CARBON_KIND(SemIR::RefBinding ref_bind): {
          return VarInfo{GetName(sem_ir, ref_bind.entity_name_id),
                         ref_bind.entity_name_id, binding_id};
        }
        case CARBON_KIND(SemIR::ValueBinding val_bind): {
          return VarInfo{GetName(sem_ir, val_bind.entity_name_id),
                         val_bind.entity_name_id, binding_id};
        }
        default:
          break;
      }
      break;
    }
    case CARBON_KIND(SemIR::AddrOf addr_of): {
      return GetVarFromValue(sem_ir, addr_of.lvalue_id);
    }
    case CARBON_KIND(SemIR::BoundMethod bound_method): {
      return GetVarFromValue(sem_ir, bound_method.object_id);
    }
    default:
      break;
  }
  return std::nullopt;
}

static auto BuildDataflowFacts(const SemIR::File& sem_ir,
                               SemIR::FunctionId function_id) -> DataflowFacts {
  DataflowFacts facts;
  const auto& function = sem_ir.functions().Get(function_id);

  // Track ref bindings to treat assignments as uses.
  Set<SemIR::EntityNameId> ref_params;

  // Collect definitions from parameters.
  if (function.param_patterns_id.has_value()) {
    auto param_patterns = sem_ir.inst_blocks().Get(function.param_patterns_id);
    for (auto pattern_id : param_patterns) {
      llvm::SmallVector<std::pair<SemIR::EntityNameId, SemIR::InstId>>
          entity_names;
      CollectEntityNamesFromPattern(sem_ir, pattern_id, entity_names);
      for (auto [entity_name_id, def_inst_id] : entity_names) {
        // Identify ref bindings.
        auto inst = sem_ir.insts().Get(pattern_id);
        if (inst.Is<SemIR::RefParamPattern>()) {
          ref_params.Insert(entity_name_id);
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
      facts.leaders.Insert(Fact{block_id, block.front()});
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
        facts.edges.Insert(Fact{inst_id, next_inst_id});
      }

      CARBON_KIND_SWITCH(inst) {
        case CARBON_KIND(SemIR::Assign assign): {
          // Emit `Assigns` facts for Assignment.
          auto var_infos = GetVarInfos(sem_ir, assign.lhs_id);
          for (auto [name_id, var_id, _] : var_infos) {
            facts.assigns.Insert(Fact{inst_id, var_id});
          }
          break;
        }
        case SemIR::NameRef::Kind: {
          // Emit `Use` facts for case NameRef.
          auto var_infos = GetVarInfos(sem_ir, inst_id);
          for (auto [name_id, var_id, _] : var_infos) {
            bool is_lhs = assigned_lhs.Contains(inst_id);
            // If it's a ref binding, assignment counts as a use because it
            // involves dereferencing the pointer/ref to write to it.
            if (!is_lhs || ref_params.Contains(var_id)) {
              facts.uses.Insert(Fact{inst_id, var_id});
            }
          }
          break;
        }
        case CARBON_KIND(SemIR::ValueOfInitializer val_init): {
          // Emit `Use` facts for  ValueOfInitializer. This case applies
          // when returning a var by value.
          auto var_infos = GetVarInfos(sem_ir, val_init.init_id);
          for (auto [name_id, var_id, _] : var_infos) {
            facts.uses.Insert(Fact{inst_id, var_id});
          }
          break;
        }
        case CARBON_KIND(SemIR::AcquireValue acquire): {
          // Emit `Use` facts for AcquireValue. This case applies when
          // converting a reference to a value (e.g. return var).
          auto var_infos = GetVarInfos(sem_ir, acquire.value_id);
          for (auto [name_id, var_id, _] : var_infos) {
            facts.uses.Insert(Fact{inst_id, var_id});
          }
          break;
        }
        case CARBON_KIND(SemIR::ReturnExpr ret): {
          // Handle `Use` facts for ReturnExpr. This case applies
          // when returning a var directly (e.g. with return slot).
          auto var_infos = GetVarInfos(sem_ir, ret.expr_id);
          for (auto [name_id, var_id, _] : var_infos) {
            facts.uses.Insert(Fact{inst_id, var_id});
          }
          break;
        }
        case CARBON_KIND(SemIR::Call call): {
          // Handle `Use` facts for Move. This case applies when
          // the move operator ~ is called.
          SemIR::InstId callee_id = call.callee_id;
          // Use SemIR::GetCallee to resolve the function ID from the call
          // instruction, which might be a FunctionDecl, SpecificFunction, or
          // SpecificImplFunction.
          SemIR::FunctionId func_id = SemIR::FunctionId::None;
          auto callee_variant = SemIR::GetCallee(sem_ir, callee_id);
          if (auto* fn = std::get_if<SemIR::CalleeFunction>(&callee_variant)) {
            func_id = fn->function_id;
          }

          if (func_id != SemIR::FunctionId::None && IsMoveOp(sem_ir, func_id)) {
            auto callee_inst = sem_ir.insts().Get(callee_id);
            if (auto bound = callee_inst.TryAs<SemIR::BoundMethod>()) {
              if (auto info = GetVarFromValue(sem_ir, bound->object_id)) {
                facts.moves.Insert(Fact{inst_id, info->entity_id});
              }
            }
          }
          break;
        }
        // Handle `Edge` facts (Terminators)
        case CARBON_KIND(SemIR::Branch branch): {
          facts.branch_edges.Insert(Fact{inst_id, branch.target_id});
          break;
        }
        case CARBON_KIND(SemIR::BranchIf branch_if): {
          facts.branch_edges.Insert(Fact{inst_id, branch_if.target_id});
          break;
        }
        case CARBON_KIND(SemIR::BranchWithArg branch_arg): {
          facts.branch_edges.Insert(Fact{inst_id, branch_arg.target_id});
          break;
        }
        default:
          break;
      }
    }
  }
  return facts;
}

static auto RunLivenessAnalysis(Context& context, DataflowFacts& facts)
    -> void {
  const auto& sem_ir = context.sem_ir();
  llvm::SmallVector<VarFact> worklist;

  // Pre-calculate predecessors from edges and branch_edges.
  Map<SemIR::InstId, llvm::SmallVector<SemIR::InstId>> predecessors;
  Map<SemIR::InstId, llvm::SmallVector<SemIR::InstId>> successors;

  auto add_edge = [&](SemIR::InstId from, SemIR::InstId to) {
    successors.Insert(from, [] { return llvm::SmallVector<SemIR::InstId>(); })
        .value()
        .push_back(to);
    predecessors.Insert(to, [] { return llvm::SmallVector<SemIR::InstId>(); })
        .value()
        .push_back(from);
  };

  facts.edges.ForEach([&](const EdgeFact& f) { add_edge(f.first, f.second); });
  facts.branch_edges.ForEach([&](const BranchEdgeFact& f) {
    // Connect terminator to leader of target block.
    SemIR::InstBlockId target_block_id = f.second;
    std::optional<SemIR::InstId> leader_inst_id = std::nullopt;
    facts.leaders.ForEach([&](const LeaderFact& leader) {
      if (leader.first == target_block_id) {
        leader_inst_id = leader.second;
      }
    });
    if (leader_inst_id.has_value()) {
      add_edge(f.first, *leader_inst_id);
    }
  });

  // Forward pass for is_moved.
  llvm::SmallVector<VarFact> moved_worklist;
  facts.moves.ForEach([&](const VarFact& f) {
    // Successors of a move are moved.
    if (auto it = successors.Lookup(f.first)) {
      for (SemIR::InstId succ_id : it.value()) {
        Fact succ_moved_fact = {succ_id, f.second};
        if (facts.is_moved.Insert(succ_moved_fact).is_inserted()) {
          moved_worklist.push_back(succ_moved_fact);
        }
      }
    }
  });

  while (!moved_worklist.empty()) {
    VarFact current = moved_worklist.back();
    moved_worklist.pop_back();
    SemIR::InstId inst_id = current.first;
    SemIR::EntityNameId var_id = current.second;

    if (auto it = successors.Lookup(inst_id)) {
      for (SemIR::InstId succ_id : it.value()) {
        bool killed = facts.assigns.Contains(VarFact{succ_id, var_id});

        if (!killed) {
          VarFact succ_moved_fact = {succ_id, var_id};
          if (facts.is_moved.Insert(succ_moved_fact).is_inserted()) {
            moved_worklist.push_back(succ_moved_fact);
          }
        }
      }
    }
  }

  // Check instruction where a var is both "used" and "is_moved"
  facts.uses.ForEach([&](const VarFact& f) {
    if (facts.is_moved.Contains(f)) {
      auto [inst_id, var_id] = f;
      auto name_id = GetName(sem_ir, SemIR::EntityNameId(var_id));
      llvm::StringRef name = sem_ir.names().GetFormatted(name_id);
      auto loc_id = sem_ir.insts().GetCanonicalLocId(SemIR::InstId(inst_id));
      CARBON_DIAGNOSTIC(UseOfMovedVariable, Error,
                        "use of moved variable `{0}`", std::string);
      context.emitter().Emit(LocIdForDiagnostics(loc_id), UseOfMovedVariable,
                             name.str());
    }
  });
}

auto RunDataflowAnalysis(Context& context, SemIR::FunctionId function_id)
    -> void {
  auto facts = BuildDataflowFacts(context.sem_ir(), function_id);
  RunLivenessAnalysis(context, facts);
}

}  // namespace Carbon::Check
