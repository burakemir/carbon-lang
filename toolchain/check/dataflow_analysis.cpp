// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/check/dataflow_analysis.h"

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

  auto get_name_from_var_storage =
      [&](const SemIR::VarStorage& var_storage) -> SemIR::NameId {
    auto pattern_id = var_storage.pattern_id;
    if (!pattern_id.has_value()) {
      return SemIR::NameId::None;
    }

    auto pattern_inst = sem_ir.insts().Get(pattern_id);
    if (auto var_pattern = pattern_inst.TryAs<SemIR::VarPattern>()) {
      auto subpattern_id = var_pattern->subpattern_id;
      auto subpattern_inst = sem_ir.insts().Get(subpattern_id);

      if (auto ref_bind_patt =
              subpattern_inst.TryAs<SemIR::RefBindingPattern>()) {
        return sem_ir.entity_names().Get(ref_bind_patt->entity_name_id).name_id;
      } else if (auto val_bind_patt =
                     subpattern_inst.TryAs<SemIR::ValueBindingPattern>()) {
        return sem_ir.entity_names().Get(val_bind_patt->entity_name_id).name_id;
      }
    }
    return SemIR::NameId::None;
  };

  for (const auto& block_id : function.body_block_ids) {
    const auto& block = sem_ir.inst_blocks().Get(block_id);
    for (const auto& inst_id : block) {
      auto inst = sem_ir.insts().Get(inst_id);

      // Check for variable definition (storage allocation)
      if (auto var_storage = inst.TryAs<SemIR::VarStorage>()) {
        SemIR::NameId name_id = get_name_from_var_storage(*var_storage);

        if (name_id.has_value()) {
          llvm::StringRef name = sem_ir.names().GetFormatted(name_id);
          out << "var defined: " << name << "\n";
        }
      }
      // Check for assignment
      else if (auto assign = inst.TryAs<SemIR::Assign>()) {
        auto lhs_inst = sem_ir.insts().Get(assign->lhs_id);

        // Case 1: Assignment to VarStorage (Initialization)
        if (auto var_storage = lhs_inst.TryAs<SemIR::VarStorage>()) {
          SemIR::NameId name_id = get_name_from_var_storage(*var_storage);
          if (name_id.has_value()) {
            llvm::StringRef name = sem_ir.names().GetFormatted(name_id);
            out << "var assigned: " << name << "\n";
          }
        }
        // Case 2: Assignment to NameRef (Re-assignment)
        else if (auto name_ref = lhs_inst.TryAs<SemIR::NameRef>()) {
          auto value_inst = sem_ir.insts().Get(name_ref->value_id);
          // Check if the name refers to a RefBinding (variable).
          if (auto ref_bind = value_inst.TryAs<SemIR::RefBinding>()) {
            auto name_id =
                sem_ir.entity_names().Get(ref_bind->entity_name_id).name_id;
            llvm::StringRef name = sem_ir.names().GetFormatted(name_id);
            out << "var assigned: " << name << "\n";
          }
        }
      }
    }
  }
}

}  // namespace Carbon::Check
