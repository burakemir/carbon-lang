// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

package Core library "prelude/types/box";

import library "prelude/copy";
import library "prelude/destroy";
import library "prelude/move";

class Box(T :! type) {

  // Creates a Box that takes ownership of the object at *x.
  // This is only sound if nothing else attempts to destroy *x and
  // release the associated memory. We can verify simple cases
  // of *x being a "unique reference", for instance if x is a local
  // variable dynamic allocation.
  // Taking ownership is very similar (but not the same) as "Move": the
  // original location can only be used in restricted ways (no destroy
  // capability; for "Move" it cannot be used at all).
  // TODO: if we know that x is the address of a local, then *x will
  // be destroyed at the end of a scope, which violates the precondition
  // above. In other words, locals cannot lose the "destroy" capability.
  fn Take(x: T*) -> Self {
    return {.ptr = x};
  }

  fn Get[self: Self]() -> T* { return self.ptr; }

  private var ptr: T*;
}

impl forall [T:! type] Box(T) as Move {
  fn Op[ref self: Self]() -> Self {
    let old_ptr: T* = self.ptr;
    // TODO: This should be: self.ptr = null;
    return {.ptr = old_ptr};
  }
}
