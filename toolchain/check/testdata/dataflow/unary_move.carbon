// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/dataflow/unary_move.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/dataflow/unary_move.carbon

fn Run() {
  var a: i32 = 1;
  // Moves a to b. Since i32 is copyable, this copies.
  // CHECK:STDERR: unary_move.carbon:[[@LINE+4]]:7: warning: variable `b` is unused [UnusedVariable]
  // CHECK:STDERR:   var b: i32 = ~a;
  // CHECK:STDERR:       ^
  // CHECK:STDERR:
  var b: i32 = ~a;
  // a is moved from, so this should be an error.
  // CHECK:STDERR: unary_move.carbon:[[@LINE+12]]:7: warning: variable `c` is unused [UnusedVariable]
  // CHECK:STDERR:   var c: i32 = a;
  // CHECK:STDERR:       ^
  // CHECK:STDERR:
  // CHECK:STDERR: unary_move.carbon:[[@LINE+8]]:16: error: use of moved variable `a` [UseOfMovedVariable]
  // CHECK:STDERR:   var c: i32 = a;
  // CHECK:STDERR:                ^
  // CHECK:STDERR:
  // CHECK:STDERR: unary_move.carbon:[[@LINE+4]]:16: error: use of moved variable `a` [UseOfMovedVariable]
  // CHECK:STDERR:   var c: i32 = a;
  // CHECK:STDERR:                ^
  // CHECK:STDERR:
  var c: i32 = a;
  a = 1;
  var _d: i32 = a;
}

class M {
  var v: i32;
  impl as Core.Move {
    fn Op[ref self: Self]() -> Self {
      let old: i32 = self.v;
      self.v = 0;
      return {.v = old};
    }
  }
}

fn TestMove() {
  var m: M = {.v = 42};
  var m2: M = ~m;
  // m is moved from, so this should be an error.
  // CHECK:STDERR: unary_move.carbon:[[@LINE+23]]:15: error: cannot copy value of type `M` [CopyOfUncopyableType]
  // CHECK:STDERR:   var m3: M = m;
  // CHECK:STDERR:               ^
  // CHECK:STDERR: unary_move.carbon:[[@LINE+20]]:15: note: type `M` does not implement interface `Core.Copy` [MissingImplInMemberAccessNote]
  // CHECK:STDERR:   var m3: M = m;
  // CHECK:STDERR:               ^
  // CHECK:STDERR:
  // CHECK:STDERR: unary_move.carbon:[[@LINE-9]]:7: warning: variable `m2` is unused [UnusedVariable]
  // CHECK:STDERR:   var m2: M = ~m;
  // CHECK:STDERR:       ^~
  // CHECK:STDERR:
  // CHECK:STDERR: unary_move.carbon:[[@LINE+12]]:7: warning: variable `m3` is unused [UnusedVariable]
  // CHECK:STDERR:   var m3: M = m;
  // CHECK:STDERR:       ^~
  // CHECK:STDERR:
  // CHECK:STDERR: unary_move.carbon:[[@LINE+8]]:15: error: use of moved variable `m` [UseOfMovedVariable]
  // CHECK:STDERR:   var m3: M = m;
  // CHECK:STDERR:               ^
  // CHECK:STDERR:
  // CHECK:STDERR: unary_move.carbon:[[@LINE+4]]:15: error: use of moved variable `m` [UseOfMovedVariable]
  // CHECK:STDERR:   var m3: M = m;
  // CHECK:STDERR:               ^
  // CHECK:STDERR:
  var m3: M = m;
  m = {.v = 43};
  var m4: M = ~m;
}

fn TestMoveBox() {
}
