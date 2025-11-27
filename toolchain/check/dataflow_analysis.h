// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#ifndef CARBON_TOOLCHAIN_CHECK_DATAFLOW_ANALYSIS_H_
#define CARBON_TOOLCHAIN_CHECK_DATAFLOW_ANALYSIS_H_

#include "llvm/Support/raw_ostream.h"
#include "toolchain/sem_ir/file.h"

namespace Carbon::Check {

// Runs a simple dataflow analysis on the SemIR.
auto RunDataflowAnalysis(const SemIR::File& sem_ir,
                         SemIR::FunctionId function_id, llvm::raw_ostream& out)
    -> void;

}  // namespace Carbon::Check

#endif  // CARBON_TOOLCHAIN_CHECK_DATAFLOW_ANALYSIS_H_
