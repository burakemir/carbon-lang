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
  // Leader,      // (block_id, inst_id)
  Set<Fact> leaders;
  // Edge,        // (inst_id_from, inst_id_to)
  Set<Fact> edges;
  // BranchEdge,  // (inst_id_from, block_id_to)
  Set<Fact> branch_edges;
  // Def,         // (inst_id, var_id) - Definitions (VarStorage)
  Set<Fact> defs;
  // Assign,      // (inst_id, var_id) - Assignments
  Set<Fact> assigns;
  // Use,         // (inst_id, var_id) - Uses
  Set<Fact> uses;
  // Live         // (inst_id, var_id) - Variable is live at instruction
  // (LiveIn)
  Set<Fact> live;
  // Move         // (inst_id, var_id) - Instruction moves this variable
  Set<Fact> moves;
  // IsMoved      // (inst_id, var_id) - Variable is in moved-from state at
  // instruction
  Set<Fact> is_moved;
};

// Runs a simple dataflow analysis on the SemIR.
auto RunDataflowAnalysis(Context& context, SemIR::FunctionId function_id,
                         llvm::raw_ostream* out) -> void;

}  // namespace Carbon::Check

#endif  // CARBON_TOOLCHAIN_CHECK_DATAFLOW_ANALYSIS_H_
