// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE

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
  // CHECK:STDERR: liveness.carbon:[[@LINE+3]]:3: warning: variable `x` is unused [UnusedVariable]
  // CHECK:STDERR:   var x: i32 = 0;
  // CHECK:STDERR:   ^~~~~~~~~~
  var x: i32 = 0;
  if (b) {
     return;
  }
  x = 1;
}

fn DeadUse() {
  // CHECK:STDERR: liveness.carbon:[[@LINE+3]]:3: warning: variable `x` is unused [UnusedVariable]
  // CHECK:STDERR:   var x: i32 = 0;
  // CHECK:STDERR:   ^~~~~~~~~~
  var x: i32 = 0;
  if (false) {
     // This code is syntactically present, but unreachable.
     x = 1;
     var y: i32 = x;
  }
}
