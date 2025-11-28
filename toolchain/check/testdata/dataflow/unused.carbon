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
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/dataflow/unused.carbon

fn SimpleUnused() {
  // CHECK:STDERR: unused.carbon:[[@LINE+4]]:3: warning: variable `x` is unused [UnusedVariable]
  // CHECK:STDERR:   var x: i32 = 0;
  // CHECK:STDERR:   ^~~~~~~~~~
  // CHECK:STDERR:
  var x: i32 = 0;
}

fn SimpleUsed() {
  var x: i32 = 0;
  x = 1;
  // CHECK:STDERR: unused.carbon:[[@LINE+4]]:3: warning: variable `y` is unused [UnusedVariable]
  // CHECK:STDERR:   var y: i32 = x;
  // CHECK:STDERR:   ^~~~~~~~~~
  // CHECK:STDERR:
  var y: i32 = x;
}

fn Shadowing() {
  // CHECK:STDERR: unused.carbon:[[@LINE+4]]:3: warning: variable `x` is unused [UnusedVariable]
  // CHECK:STDERR:   var x: i32 = 0;
  // CHECK:STDERR:   ^~~~~~~~~~
  // CHECK:STDERR:
  var x: i32 = 0;
  if (true) {
    // CHECK:STDERR: unused.carbon:[[@LINE+4]]:5: warning: variable `x` is unused [UnusedVariable]
    // CHECK:STDERR:     var x: i32 = 1;
    // CHECK:STDERR:     ^~~~~~~~~~
    // CHECK:STDERR:
    var x: i32 = 1;
  }
  x = 2;
}

// CHECK:STDERR: unused.carbon:[[@LINE+4]]:15: warning: variable `x` is unused [UnusedVariable]
// CHECK:STDERR: fn Parameters(x: i32) {
// CHECK:STDERR:               ^~~~~~
// CHECK:STDERR:
fn Parameters(x: i32) {
}

fn ParametersUsed(x: i32) -> i32 {
  return x;
}

fn Underscore(x: i32) {
  var _y: i32 = x;
}

fn RefParam(ref x: i32) {
  x = 1;
}

// CHECK:STDERR: unused.carbon:[[@LINE+4]]:19: warning: variable `y` is unused [UnusedVariable]
// CHECK:STDERR: fn RefParamUnused(ref y: i32) {
// CHECK:STDERR:                   ^~~~~~~~~~
// CHECK:STDERR:
fn RefParamUnused(ref y: i32) {
}

fn ReturnedVar() -> i32 {
  returned var x: i32 = 0;
  return var;
}

fn ReturnVarExplicit() -> i32 {
  var x: i32 = 0;
  return x;
}
