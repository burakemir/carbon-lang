// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/dataflow/liveness.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/dataflow/liveness.carbon

fn ControlFlow(b: bool) -> i32 {
  var x: i32 = 0;
  if (b) {
    x = 1;
  } else {
    x = 2;
  }
  return x;
}

fn Unreachable(b: bool) {
  // CHECK:STDERR: liveness.carbon:[[@LINE+4]]:3: warning: variable `x` is unused [UnusedVariable]
  // CHECK:STDERR:   var x: i32 = 0;
  // CHECK:STDERR:   ^~~~~~~~~~
  // CHECK:STDERR:
  var x: i32 = 0;
  if (b) {
     return;
  }
  x = 1;
}

fn DeadUse() {
  var x: i32 = 0;
  if (false) {
     // This code is syntactically present.
     // Analysis sees this, and determines that x is used when dataflow analysis runs.
     // Compile-time evaluation will remove the block later, making x unused.
     // CHECK:STDERR: liveness.carbon:[[@LINE+4]]:6: warning: variable `y` is unused [UnusedVariable]
     // CHECK:STDERR:      var y: i32 = x;
     // CHECK:STDERR:      ^~~~~~~~~~
     // CHECK:STDERR:
     var y: i32 = x;
  }
}
