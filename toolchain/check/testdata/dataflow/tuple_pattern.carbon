// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/dataflow/unused.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/dataflow/tuple.carbon

fn TuplePattern() {
  // CHECK:STDERR: tuple_pattern.carbon:[[@LINE+4]]:8: warning: variable `x` is unused [UnusedVariable]
  // CHECK:STDERR:   var (x: i32, y: i32) = (1, 2);
  // CHECK:STDERR:        ^
  // CHECK:STDERR:
  var (x: i32, y: i32) = (1, 2);
  y = 2;
}

fn NestedPattern() {
  // CHECK:STDERR: tuple_pattern.carbon:[[@LINE+3]]:16: warning: variable `b` is unused [UnusedVariable]
  // CHECK:STDERR:   var (a: i32, (b: i32, c: i32)) = (1, (2, 3));
  // CHECK:STDERR:                ^
  var (a: i32, (b: i32, c: i32)) = (1, (2, 3));
  a = 1;
  c = 3;
}
