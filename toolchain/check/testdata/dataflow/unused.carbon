// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE

fn SimpleUnused() {
  // CHECK:STDERR: unused.carbon:[[@LINE+3]]:7: warning: variable `x` is unused [UnusedVariable]
  // CHECK:STDERR:   var x: i32 = 0;
  // CHECK:STDERR:       ^
  var x: i32 = 0;
}

fn SimpleUsed() {
  var x: i32 = 0;
  x = 1;
}

fn Shadowing() {
  var x: i32 = 0;
  if (true) {
    // CHECK:STDERR: unused.carbon:[[@LINE+3]]:9: warning: variable `x` is unused [UnusedVariable]
    // CHECK:STDERR:     var x: i32 = 1;
    // CHECK:STDERR:         ^
    var x: i32 = 1;
  }
  x = 2;
}

fn Parameters(x: i32) {
  // x is an unused parameter, should warn.
  // CHECK:STDERR: unused.carbon:[[@LINE-4]]:15: warning: variable `x` is unused [UnusedVariable]
  // CHECK:STDERR: fn Parameters(x: i32) {
  // CHECK:STDERR:               ^
}

fn ParametersUsed(x: i32) -> i32 {
  return x;
}

fn Underscore(x: i32) {
  var _y: i32 = x;
  // No warning for _y
}
