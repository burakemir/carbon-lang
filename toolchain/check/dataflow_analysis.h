// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#ifndef CARBON_TOOLCHAIN_CHECK_DATAFLOW_ANALYSIS_H_
#define CARBON_TOOLCHAIN_CHECK_DATAFLOW_ANALYSIS_H_

#include "common/set.h"
#include "llvm/Support/raw_ostream.h"
#include "toolchain/check/context.h"
#include "toolchain/sem_ir/file.h"

namespace Carbon::Check {

// Types of facts collected during dataflow analysis.
enum class FactType {
  Leader,      // (block_id, inst_id)
  Edge,        // (inst_id_from, inst_id_to)
  BranchEdge,  // (inst_id_from, block_id_to)
  Def,         // (inst_id, var_id) - Definitions (VarStorage)
  Assign,      // (inst_id, var_id) - Assignments
  Use,         // (inst_id, var_id) - Uses
  Live         // (inst_id, var_id) - Variable is live at instruction (LiveIn)
};

// Represents a single fact with two IDs.
// The meaning of id1 and id2 depends on the FactType.
// Using int32_t to store the raw index values of the various Id types.
struct Fact {
  int32_t id1;
  int32_t id2;

  friend auto operator==(const Fact& lhs, const Fact& rhs) -> bool {
    return lhs.id1 == rhs.id1 && lhs.id2 == rhs.id2;
  }
};

// Hasher for Fact to use with Carbon::Set.
inline auto CarbonHashValue(const Fact& fact, uint64_t seed) -> HashCode {
  Hasher hasher(seed);
  hasher.HashRaw(fact.id1);
  hasher.HashRaw(fact.id2);
  return static_cast<HashCode>(hasher);
}

struct DataflowFacts {
  Set<Fact> leaders;
  Set<Fact> edges;
  Set<Fact> branch_edges;
  Set<Fact> defs;
  Set<Fact> assigns;
  Set<Fact> uses;
  Set<Fact> live;
};

// Builds dataflow facts for a function. Optionally prints them to `out`.
auto BuildDataflowFacts(const SemIR::File& sem_ir,
                        SemIR::FunctionId function_id, llvm::raw_ostream* out)
    -> DataflowFacts;

// Checks for unused variables based on the dataflow facts.
auto CheckUnusedVariables(Context& context, const DataflowFacts& facts) -> void;

// Runs liveness analysis and prints the results.
auto RunLivenessAnalysis(const SemIR::File& sem_ir, DataflowFacts& facts,
                         llvm::raw_ostream& out) -> void;

// Runs a simple dataflow analysis on the SemIR.
auto RunDataflowAnalysis(Context& context, SemIR::FunctionId function_id,
                         llvm::raw_ostream* out) -> void;

}  // namespace Carbon::Check

#endif  // CARBON_TOOLCHAIN_CHECK_DATAFLOW_ANALYSIS_H_
