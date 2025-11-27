// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/move.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/move.carbon

// --- fail_use_of_moved_value.carbon
library "[[@TEST_NAME]]";

fn Run() {
  var a: i32 = 1;
  //@dump-sem-ir-begin
  // Moves a to b. Since i32 is copyable, this copies, but a is now moved-from.
  var unused b: i32 = ~a;
  // Since a is moved-from, we cannot move again.
  // CHECK:STDERR: fail_use_of_moved_value.carbon:[[@LINE+4]]:24: error: use of moved variable `a` [UseOfMovedVariable]
  // CHECK:STDERR:   var unused c: i32 = ~a;
  // CHECK:STDERR:                        ^
  // CHECK:STDERR:
  var unused c: i32 = ~a;
  //@dump-sem-ir-end
  a = 1;
  var unused d: i32 = a;
}

// --- fail_use_of_moved_vector.carbon
class FakeCppVectorCopyable {
  impl as Core.Copy {
    fn Op[self: Self]() -> Self {
      return self;
    }
  }
  impl as Core.Move {
    fn Op[unused ref self: Self]() -> Self {
      return {};
    }
  }
}

class M {
  var v: FakeCppVectorCopyable;
  impl as Core.Copy {
    fn Op[self: Self]() -> Self {
      return {.v = self.v};
    }
  }
  impl as Core.Move {
    fn Op[ref self: Self]() -> Self {
      return {.v = ~self.v};
    }
  }
}
fn Make() -> M {
  return {.v = {}};
}

fn TestMove() {
  var m: M = Make();
  // Moves m to m2.
  var m2: M = ~m;
  // m is moved from, so this should be an error.
  // CHECK:STDERR: fail_use_of_moved_vector.carbon:[[@LINE+4]]:23: error: use of moved variable `m` [UseOfMovedVariable]
  // CHECK:STDERR:   var unused m3: M = ~m;
  // CHECK:STDERR:                       ^
  // CHECK:STDERR:
  var unused m3: M = ~m;
  m = Make();
  var unused m4: M = ~m;
  m = m2;
  var unused m5: M = ~m;
}

// --- fail_control_flow_not_ok.carbon
library "[[@TEST_NAME]]";

fn Run() {
  var a: i32 = 1;
  var b: i32 = ~a;
  if (b > 0) {
    a = 11;
  }
  // CHECK:STDERR: fail_control_flow_not_ok.carbon:[[@LINE+4]]:8: error: use of moved variable `a` [UseOfMovedVariable]
  // CHECK:STDERR:   b = ~a;
  // CHECK:STDERR:        ^
  // CHECK:STDERR:
  b = ~a;
}

// --- control_flow_ok.carbon
library "[[@TEST_NAME]]";

fn Run() {
  var a: i32 = 1;
  var b: i32 = ~a;
  if (b > 0) {
    a = 11;
  } else {
    a = 12;
  }
  b = ~a;
}

// CHECK:STDOUT: --- fail_use_of_moved_value.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.7ce: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %Move.type: type = facet_type <@Move> [concrete]
// CHECK:STDOUT:   %Int.as.Move.impl.Op.type.79c: type = fn_type @Int.as.Move.impl.Op, @Int.as.Move.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Move.impl.Op.8da: %Int.as.Move.impl.Op.type.79c = struct_value () [symbolic]
// CHECK:STDOUT:   %Move.impl_witness.dab: <witness> = impl_witness imports.%Move.impl_witness_table.0a0, @Int.as.Move.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Move.impl.Op.type.60e: type = fn_type @Int.as.Move.impl.Op, @Int.as.Move.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Move.impl.Op.038: %Int.as.Move.impl.Op.type.60e = struct_value () [concrete]
// CHECK:STDOUT:   %Move.facet: %Move.type = facet_value %i32, (%Move.impl_witness.dab) [concrete]
// CHECK:STDOUT:   %Move.WithSelf.Op.type.877: type = fn_type @Move.WithSelf.Op, @Move.WithSelf(%Move.facet) [concrete]
// CHECK:STDOUT:   %.a89: type = fn_type_with_self_type %Move.WithSelf.Op.type.877, %Move.facet [concrete]
// CHECK:STDOUT:   %Int.as.Move.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Move.impl.Op.038, @Int.as.Move.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %Destroy.Op.type: type = fn_type @Destroy.Op [concrete]
// CHECK:STDOUT:   %Destroy.Op: %Destroy.Op.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.ead: @Int.as.Move.impl.%Int.as.Move.impl.Op.type (%Int.as.Move.impl.Op.type.79c) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Move.impl.%Int.as.Move.impl.Op (constants.%Int.as.Move.impl.Op.8da)]
// CHECK:STDOUT:   %Move.impl_witness_table.0a0 = impl_witness_table (%Core.import_ref.ead), @Int.as.Move.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Run() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %b.patt: %pattern_type.7ce = ref_binding_pattern b [concrete]
// CHECK:STDOUT:     %b.var_patt: %pattern_type.7ce = var_pattern %b.patt [concrete]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %b.var: ref %i32 = var %b.var_patt
// CHECK:STDOUT:   %a.ref.loc7: ref %i32 = name_ref a, %a
// CHECK:STDOUT:   %impl.elem0.loc7: %.a89 = impl_witness_access constants.%Move.impl_witness.dab, element0 [concrete = constants.%Int.as.Move.impl.Op.038]
// CHECK:STDOUT:   %bound_method.loc7_23.1: <bound method> = bound_method %a.ref.loc7, %impl.elem0.loc7
// CHECK:STDOUT:   %specific_fn.loc7: <specific function> = specific_function %impl.elem0.loc7, @Int.as.Move.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Move.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc7_23.2: <bound method> = bound_method %a.ref.loc7, %specific_fn.loc7
// CHECK:STDOUT:   %Int.as.Move.impl.Op.call.loc7: init %i32 = call %bound_method.loc7_23.2(%a.ref.loc7)
// CHECK:STDOUT:   assign %b.var, %Int.as.Move.impl.Op.call.loc7
// CHECK:STDOUT:   %i32.loc7: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %b: ref %i32 = ref_binding b, %b.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %c.patt: %pattern_type.7ce = ref_binding_pattern c [concrete]
// CHECK:STDOUT:     %c.var_patt: %pattern_type.7ce = var_pattern %c.patt [concrete]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %c.var: ref %i32 = var %c.var_patt
// CHECK:STDOUT:   %a.ref.loc13: ref %i32 = name_ref a, %a
// CHECK:STDOUT:   %impl.elem0.loc13: %.a89 = impl_witness_access constants.%Move.impl_witness.dab, element0 [concrete = constants.%Int.as.Move.impl.Op.038]
// CHECK:STDOUT:   %bound_method.loc13_23.1: <bound method> = bound_method %a.ref.loc13, %impl.elem0.loc13
// CHECK:STDOUT:   %specific_fn.loc13: <specific function> = specific_function %impl.elem0.loc13, @Int.as.Move.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Move.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc13_23.2: <bound method> = bound_method %a.ref.loc13, %specific_fn.loc13
// CHECK:STDOUT:   %Int.as.Move.impl.Op.call.loc13: init %i32 = call %bound_method.loc13_23.2(%a.ref.loc13)
// CHECK:STDOUT:   assign %c.var, %Int.as.Move.impl.Op.call.loc13
// CHECK:STDOUT:   %i32.loc13: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %c: ref %i32 = ref_binding c, %c.var
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %Destroy.Op.bound.loc13: <bound method> = bound_method %c.var, constants.%Destroy.Op
// CHECK:STDOUT:   %Destroy.Op.call.loc13: init %empty_tuple.type = call %Destroy.Op.bound.loc13(%c.var)
// CHECK:STDOUT:   %Destroy.Op.bound.loc7: <bound method> = bound_method %b.var, constants.%Destroy.Op
// CHECK:STDOUT:   %Destroy.Op.call.loc7: init %empty_tuple.type = call %Destroy.Op.bound.loc7(%b.var)
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT: }
// CHECK:STDOUT:
