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

  for (const auto& block_id : function.body_block_ids) {
    const auto& block = sem_ir.inst_blocks().Get(block_id);
    for (const auto& inst_id : block) {
      auto inst = sem_ir.insts().Get(inst_id);

      if (auto name_ref = inst.TryAs<SemIR::NameBindingDecl>()) {
        out << "NAME BINDING: ";
        inst.Print(out);
        out << "\n";
      }

      if (auto assign = inst.TryAs<SemIR::Assign>()) {
        out << "ASSIGN: ";
        inst.Print(out);
        out << " lhs: ";
        auto lhs = sem_ir.insts().Get(assign->lhs_id);
        lhs.Print(out);
        out << "\n";
      }

      if (auto name_ref = inst.TryAs<SemIR::NameRef>()) {
        out << "USE: " << name_ref->name_id;
        inst.Print(out);
        out << "\n";
      }
      if (auto var_storage = inst.TryAs<SemIR::VarStorage>()) {
        out << "DECL: ";
        inst.Print(out);
        out << "\n";
        auto pattern_id = var_storage->pattern_id;
        if (!pattern_id.has_value()) {
          out << "does not have value ";
          continue;
        }

        auto pattern_inst = sem_ir.insts().Get(pattern_id);

        out << "  pat: ";
        inst.Print(out);
        SemIR::NameId name_id = SemIR::NameId::None;

        if (auto var_pattern = pattern_inst.TryAs<SemIR::VarPattern>()) {
          auto subpattern_id = var_pattern->subpattern_id;
          auto subpattern_inst = sem_ir.insts().Get(subpattern_id);

          if (auto ref_bind = subpattern_inst.TryAs<SemIR::RefBinding>()) {
            name_id =
                sem_ir.entity_names().Get(ref_bind->entity_name_id).name_id;
          } else if (auto val_bind =
                         subpattern_inst.TryAs<SemIR::ValueBinding>()) {
            name_id =
                sem_ir.entity_names().Get(val_bind->entity_name_id).name_id;
          }
        }

        if (name_id.has_value()) {
          llvm::StringRef name = sem_ir.names().GetFormatted(name_id);
          out << "var defined: " << name << "\n";
        }
      }
    }
  }
}

}  // namespace Carbon::Check
