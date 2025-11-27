// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

package Core library "prelude/move";

import library "prelude/copy";

// Moving (relocating) an object with storage. Has the effect of invalidating
// the source location, it can no longer be used until it is initialized,
// for example through assignment.
interface Move {

  // TODO: has the effect of invalidating self.
  fn Op[ref self: Self]() -> Self;
}

private fn Bool() -> type = "bool.make_type";
private fn CharLiteral() -> type = "char_literal.make_type";
private fn FloatLiteral() -> type = "float_literal.make_type";
private fn IntLiteral() -> type = "int_literal.make_type";

impl Bool() as Move {
  fn Op[ref self: Self]() -> Self { return self; }
}

impl CharLiteral() as Move {
  fn Op[ref self: Self]() -> Self { return self; }
}

impl FloatLiteral() as Move {
  fn Op[ref self: Self]() -> Self { return self; }
}

impl IntLiteral() as Move {
  fn Op[ref self: Self]() -> Self { return self; }
}

impl type as Move {
  fn Op[ref self: Self]() -> Self { return self; }
}

impl forall [T:! type] T* as Move {
  fn Op[ref self: Self]() -> Self { return self; }
}
