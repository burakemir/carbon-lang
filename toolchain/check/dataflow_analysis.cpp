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

auto RunDataflowAnalysis(const SemIR::File& sem_ir,
                         SemIR::FunctionId function_id, llvm::raw_ostream& out)
    -> void {
  const auto& function = sem_ir.functions().Get(function_id);
  llvm::StringRef func_name = sem_ir.names().GetFormatted(function.name_id);
  out << "Function: " << func_name << "\n";

  if (function.body_block_ids.empty()) {
    return;
  }

  DataflowFacts facts;

  // Helper to get variable info from various instructions.
  // Returns {NameId, VarStorageId}
  auto get_var_info =
      [&](SemIR::InstId inst_id) -> std::pair<SemIR::NameId, SemIR::InstId> {
    auto inst = sem_ir.insts().Get(inst_id);

    if (auto var_storage = inst.TryAs<SemIR::VarStorage>()) {
      auto pattern_id = var_storage->pattern_id;
      if (pattern_id.has_value()) {
        auto pattern_inst = sem_ir.insts().Get(pattern_id);
        if (auto var_pattern = pattern_inst.TryAs<SemIR::VarPattern>()) {
          auto subpattern_id = var_pattern->subpattern_id;
          auto subpattern_inst = sem_ir.insts().Get(subpattern_id);
          if (auto ref_bind = subpattern_inst.TryAs<SemIR::RefBinding>()) {
            return {sem_ir.entity_names().Get(ref_bind->entity_name_id).name_id,
                    inst_id};
          } else if (auto val_bind =
                         subpattern_inst.TryAs<SemIR::ValueBinding>()) {
            return {sem_ir.entity_names().Get(val_bind->entity_name_id).name_id,
                    inst_id};
          }
        }
      }
    } else if (auto ref_bind = inst.TryAs<SemIR::RefBinding>()) {
      // RefBinding.value_id should point to VarStorage
      return {sem_ir.entity_names().Get(ref_bind->entity_name_id).name_id,
              ref_bind->value_id};
    } else if (auto val_bind = inst.TryAs<SemIR::ValueBinding>()) {
      return {sem_ir.entity_names().Get(val_bind->entity_name_id).name_id,
              val_bind->value_id};
    } else if (auto name_ref = inst.TryAs<SemIR::NameRef>()) {
      // NameRef.value_id points to the binding (RefBinding/ValueBinding)
      // Recurse once to get from Binding to Storage
      auto binding_id = name_ref->value_id;
      auto binding_inst = sem_ir.insts().Get(binding_id);
      if (auto ref_bind = binding_inst.TryAs<SemIR::RefBinding>()) {
        return {sem_ir.entity_names().Get(ref_bind->entity_name_id).name_id,
                ref_bind->value_id};
      } else if (auto val_bind = binding_inst.TryAs<SemIR::ValueBinding>()) {
        return {sem_ir.entity_names().Get(val_bind->entity_name_id).name_id,
                val_bind->value_id};
      }
    }
    return {SemIR::NameId::None, SemIR::InstId::None};
  };

  for (const auto& block_id : function.body_block_ids) {
    const auto& block = sem_ir.inst_blocks().Get(block_id);

    // Emit leader fact for non-empty blocks.
    if (!block.empty()) {
      facts.leaders.Insert(Fact{block_id.index, block.front().index});
      out << "leader: " << block_id << " -> " << block.front() << "\n";
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
        out << "edge: " << inst_id << " -> " << next_inst_id << "\n";
      }

      // 1. Definition (VarStorage)
      if (inst.Is<SemIR::VarStorage>()) {
        auto [name_id, var_id] = get_var_info(inst_id);
        if (name_id.has_value()) {
          facts.defs.Insert(Fact{inst_id.index, var_id.index});
          out << "def: " << sem_ir.names().GetFormatted(name_id) << " ("
              << var_id << ") at " << inst_id << "\n";
        }
      }

      // 2. Assignment
      else if (auto assign = inst.TryAs<SemIR::Assign>()) {
        auto [name_id, var_id] = get_var_info(assign->lhs_id);
        if (name_id.has_value()) {
          facts.assigns.Insert(Fact{inst_id.index, var_id.index});
          out << "assign: " << sem_ir.names().GetFormatted(name_id) << " ("
              << var_id << ") at " << inst_id << "\n";
        }
      }

      // 3. Use (NameRef not in LHS)
      else if (inst.Is<SemIR::NameRef>()) {
        if (!assigned_lhs.Contains(inst_id)) {
          auto [name_id, var_id] = get_var_info(inst_id);
          if (name_id.has_value()) {
            facts.uses.Insert(Fact{inst_id.index, var_id.index});
            out << "use: " << sem_ir.names().GetFormatted(name_id) << " ("
                << var_id << ") at " << inst_id << "\n";
          }
        }
      }

      // 4. Edges (Terminators)
      if (auto branch = inst.TryAs<SemIR::Branch>()) {
        facts.branch_edges.Insert(Fact{inst_id.index, branch->target_id.index});
        out << "branch-edge: " << inst_id << " -> " << branch->target_id
            << "\n";
      } else if (auto branch_if = inst.TryAs<SemIR::BranchIf>()) {
        facts.branch_edges.Insert(
            Fact{inst_id.index, branch_if->target_id.index});
        out << "branch-edge: " << inst_id << " -> " << branch_if->target_id
            << "\n";
      } else if (auto branch_arg = inst.TryAs<SemIR::BranchWithArg>()) {
        facts.branch_edges.Insert(
            Fact{inst_id.index, branch_arg->target_id.index});
        out << "branch-edge: " << inst_id << " -> " << branch_arg->target_id
            << "\n";
      }
    }
  }
}

}  // namespace Carbon::Check
