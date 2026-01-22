// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

package Core library "prelude/types/cpp/int";

import library "prelude/copy";
import library "prelude/operators";
import library "prelude/types/int";
import library "prelude/types/int_literal";
import library "prelude/types/uint";

namespace CppCompat;

class CppCompat.Long32 {
  adapt i32;
}

class CppCompat.ULong32 {
  adapt u32;
}

class CppCompat.LongLong64 {
  adapt i64;
}

class CppCompat.ULongLong64 {
  adapt u64;
}

// Copy

impl CppCompat.Long32 as Copy {
  fn Op[self: Self]() -> Self = "primitive_copy";
}

impl CppCompat.ULong32 as Copy {
  fn Op[self: Self]() -> Self = "primitive_copy";
}

impl CppCompat.LongLong64 as Copy {
  fn Op[self: Self]() -> Self = "primitive_copy";
}

impl CppCompat.ULongLong64 as Copy {
  fn Op[self: Self]() -> Self = "primitive_copy";
}

// Conversions.

impl IntLiteral() as ImplicitAs(CppCompat.Long32) {
  fn Convert[self: Self]() -> CppCompat.Long32 = "int.convert_checked";
}

// TODO: Remove this once `ImplicitAs` extends `As`.
impl IntLiteral() as As(CppCompat.Long32) {
  fn Convert[self: Self]() -> CppCompat.Long32 = "int.convert_checked";
}

final impl CppCompat.Long32 as ImplicitAs(IntLiteral()) {
  fn Convert[self: Self]() -> IntLiteral() = "int.convert_checked";
}

// TODO: ImplicitAs from Int(N) to Long32 if N < 32.
impl i32 as ImplicitAs(CppCompat.Long32) {
  fn Convert[self: Self]() -> CppCompat.Long32 = "int.convert";
}

// TODO: ImplicitAs from Long32 to Int(N) if N > 32.
final impl CppCompat.Long32 as ImplicitAs(i32) {
  fn Convert[self: Self]() -> i32 = "int.convert";
}

impl IntLiteral() as ImplicitAs(CppCompat.ULong32) {
  fn Convert[self: Self]() -> CppCompat.ULong32 = "int.convert_checked";
}

// TODO: Remove this once `ImplicitAs` extends `As`.
impl IntLiteral() as As(CppCompat.ULong32) {
  fn Convert[self: Self]() -> CppCompat.ULong32 = "int.convert_checked";
}

final impl CppCompat.ULong32 as ImplicitAs(IntLiteral()) {
  fn Convert[self: Self]() -> IntLiteral() = "int.convert_checked";
}

// TODO: ImplicitAs from UInt(N) to ULong32 if N < 32.
impl u32 as ImplicitAs(CppCompat.ULong32) {
  fn Convert[self: Self]() -> CppCompat.ULong32 = "int.convert";
}

// TODO: ImplicitAs from ULong32 to UInt(N) if N > 32.
final impl CppCompat.ULong32 as ImplicitAs(u32) {
  fn Convert[self: Self]() -> u32 = "int.convert";
}

impl IntLiteral() as ImplicitAs(CppCompat.LongLong64) {
  fn Convert[self: Self]() -> CppCompat.LongLong64 = "int.convert_checked";
}

// TODO: Remove this once `ImplicitAs` extends `As`.
impl IntLiteral() as As(CppCompat.LongLong64) {
  fn Convert[self: Self]() -> CppCompat.LongLong64 = "int.convert_checked";
}

final impl CppCompat.LongLong64 as ImplicitAs(IntLiteral()) {
  fn Convert[self: Self]() -> IntLiteral() = "int.convert_checked";
}

// TODO: ImplicitAs from Int(N) to LongLong64 if N < 64.
impl i64 as ImplicitAs(CppCompat.LongLong64) {
  fn Convert[self: Self]() -> CppCompat.LongLong64 = "int.convert";
}

// TODO: ImplicitAs from LongLong64 to Int(N) if N > 64.
final impl CppCompat.LongLong64 as ImplicitAs(i64) {
  fn Convert[self: Self]() -> i64 = "int.convert";
}

impl IntLiteral() as ImplicitAs(CppCompat.ULongLong64) {
  fn Convert[self: Self]() -> CppCompat.ULongLong64 = "int.convert_checked";
}

// TODO: Remove this once `ImplicitAs` extends `As`.
impl IntLiteral() as As(CppCompat.ULongLong64) {
  fn Convert[self: Self]() -> CppCompat.ULongLong64 = "int.convert_checked";
}

final impl CppCompat.ULongLong64 as ImplicitAs(IntLiteral()) {
  fn Convert[self: Self]() -> IntLiteral() = "int.convert_checked";
}

// TODO: ImplicitAs from UInt(N) to ULongLong64 if N < 64.
impl u64 as ImplicitAs(CppCompat.ULongLong64) {
  fn Convert[self: Self]() -> CppCompat.ULongLong64 = "int.convert";
}

// TODO: ImplicitAs from ULongLong64 to UInt(N) if N > 64.
final impl CppCompat.ULongLong64 as ImplicitAs(u64) {
  fn Convert[self: Self]() -> u64 = "int.convert";
}

// TODO: As from Long32 to Int(N) if N < 32.
// TODO: As from ULong32 to UInt(N) if N < 32.
// TODO: As from LongLong64 to Int(N) if N < 64.
// TODO: As from ULongLong64 to UInt(N) if N < 64.
// TODO: As from Int(N) to Long32 if N > 32.
// TODO: As from UInt(N) to ULong32 if N > 32.
// TODO: As from Int(N) to LongLong64 if N > 64.
// TODO: As from UInt(N) to ULongLong64 if N > 64.


// Comparisons.

impl forall [U:! ImplicitAs(CppCompat.Long32)]
    CppCompat.Long32 as EqWith(U) {
  fn Equal[self: Self](other: Self) -> bool = "int.eq";
  fn NotEqual[self: Self](other: Self) -> bool = "int.neq";
}

impl forall [U:! ImplicitAs(CppCompat.Long32)]
    CppCompat.Long32 as OrderedWith(U) {
  fn Less[self: Self](other: Self) -> bool = "int.less";
  fn LessOrEquivalent[self: Self](other: Self) -> bool = "int.less_eq";
  fn Greater[self: Self](other: Self) -> bool = "int.greater";
  fn GreaterOrEquivalent[self: Self](other: Self) -> bool = "int.greater_eq";
}

impl forall [U:! ImplicitAs(CppCompat.ULong32)]
    CppCompat.ULong32 as EqWith(U) {
  fn Equal[self: Self](other: Self) -> bool = "int.eq";
  fn NotEqual[self: Self](other: Self) -> bool = "int.neq";
}

impl forall [U:! ImplicitAs(CppCompat.ULong32)]
    CppCompat.ULong32 as OrderedWith(U) {
  fn Less[self: Self](other: Self) -> bool = "int.less";
  fn LessOrEquivalent[self: Self](other: Self) -> bool = "int.less_eq";
  fn Greater[self: Self](other: Self) -> bool = "int.greater";
  fn GreaterOrEquivalent[self: Self](other: Self) -> bool = "int.greater_eq";
}

impl forall [U:! ImplicitAs(CppCompat.LongLong64)]
    CppCompat.LongLong64 as EqWith(U) {
  fn Equal[self: Self](other: Self) -> bool = "int.eq";
  fn NotEqual[self: Self](other: Self) -> bool = "int.neq";
}

impl forall [U:! ImplicitAs(CppCompat.LongLong64)]
    CppCompat.LongLong64 as OrderedWith(U) {
  fn Less[self: Self](other: Self) -> bool = "int.less";
  fn LessOrEquivalent[self: Self](other: Self) -> bool = "int.less_eq";
  fn Greater[self: Self](other: Self) -> bool = "int.greater";
  fn GreaterOrEquivalent[self: Self](other: Self) -> bool = "int.greater_eq";
}

impl forall [U:! ImplicitAs(CppCompat.ULongLong64)]
    CppCompat.ULongLong64 as EqWith(U) {
  fn Equal[self: Self](other: Self) -> bool = "int.eq";
  fn NotEqual[self: Self](other: Self) -> bool = "int.neq";
}

impl forall [U:! ImplicitAs(CppCompat.ULongLong64)]
    CppCompat.ULongLong64 as OrderedWith(U) {
  fn Less[self: Self](other: Self) -> bool = "int.less";
  fn LessOrEquivalent[self: Self](other: Self) -> bool = "int.less_eq";
  fn Greater[self: Self](other: Self) -> bool = "int.greater";
  fn GreaterOrEquivalent[self: Self](other: Self) -> bool = "int.greater_eq";
}


// Arithmetic.

// Arithmetic for Long32.

final impl CppCompat.Long32 as Negate where .Result = Self {
  fn Op[self: Self]() -> Self = "int.snegate";
}

final impl CppCompat.Long32 as AddWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.sadd";
}

final impl CppCompat.Long32 as SubWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.ssub";
}

final impl CppCompat.Long32 as MulWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.smul";
}

final impl CppCompat.Long32 as DivWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.sdiv";
}

final impl CppCompat.Long32 as ModWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.smod";
}

impl forall [U:! ImplicitAs(CppCompat.Long32)]
    CppCompat.Long32 as AddWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.sadd";
}

impl forall [U:! ImplicitAs(CppCompat.Long32)]
    CppCompat.Long32 as SubWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.ssub";
}

impl forall [U:! ImplicitAs(CppCompat.Long32)]
    CppCompat.Long32 as MulWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.smul";
}

impl forall [U:! ImplicitAs(CppCompat.Long32)]
    CppCompat.Long32 as DivWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.sdiv";
}

impl forall [U:! ImplicitAs(CppCompat.Long32)]
    CppCompat.Long32 as ModWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.smod";
}

impl forall [T:! ImplicitAs(CppCompat.Long32)]
    T as AddWith(CppCompat.Long32) where .Result = CppCompat.Long32 {
  fn Op[self: CppCompat.Long32](other: CppCompat.Long32) -> CppCompat.Long32 = "int.sadd";
}

impl forall [T:! ImplicitAs(CppCompat.Long32)]
    T as SubWith(CppCompat.Long32) where .Result = CppCompat.Long32 {
  fn Op[self: CppCompat.Long32](other: CppCompat.Long32) -> CppCompat.Long32 = "int.ssub";
}

impl forall [T:! ImplicitAs(CppCompat.Long32)]
    T as MulWith(CppCompat.Long32) where .Result = CppCompat.Long32 {
  fn Op[self: CppCompat.Long32](other: CppCompat.Long32) -> CppCompat.Long32 = "int.smul";
}

impl forall [T:! ImplicitAs(CppCompat.Long32)]
    T as DivWith(CppCompat.Long32) where .Result = CppCompat.Long32 {
  fn Op[self: CppCompat.Long32](other: CppCompat.Long32) -> CppCompat.Long32 = "int.sdiv";
}

impl forall [T:! ImplicitAs(CppCompat.Long32)]
    T as ModWith(CppCompat.Long32) where .Result = CppCompat.Long32 {
  fn Op[self: CppCompat.Long32](other: CppCompat.Long32) -> CppCompat.Long32 = "int.smod";
}

// Arithmetic for ULong32.

final impl CppCompat.ULong32 as Negate where .Result = Self {
  fn Op[self: Self]() -> Self = "int.unegate";
}

final impl CppCompat.ULong32 as AddWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.uadd";
}

final impl CppCompat.ULong32 as SubWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.usub";
}

final impl CppCompat.ULong32 as MulWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.umul";
}

final impl CppCompat.ULong32 as DivWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.udiv";
}

final impl CppCompat.ULong32 as ModWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.umod";
}

impl forall [U:! ImplicitAs(CppCompat.ULong32)]
    CppCompat.ULong32 as AddWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.uadd";
}

impl forall [U:! ImplicitAs(CppCompat.ULong32)]
    CppCompat.ULong32 as SubWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.usub";
}

impl forall [U:! ImplicitAs(CppCompat.ULong32)]
    CppCompat.ULong32 as MulWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.umul";
}

impl forall [U:! ImplicitAs(CppCompat.ULong32)]
    CppCompat.ULong32 as DivWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.udiv";
}

impl forall [U:! ImplicitAs(CppCompat.ULong32)]
    CppCompat.ULong32 as ModWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.umod";
}

impl forall [T:! ImplicitAs(CppCompat.ULong32)]
    T as AddWith(CppCompat.ULong32) where .Result = CppCompat.ULong32 {
  fn Op[self: CppCompat.ULong32](other: CppCompat.ULong32) -> CppCompat.ULong32 = "int.uadd";
}

impl forall [T:! ImplicitAs(CppCompat.ULong32)]
    T as SubWith(CppCompat.ULong32) where .Result = CppCompat.ULong32 {
  fn Op[self: CppCompat.ULong32](other: CppCompat.ULong32) -> CppCompat.ULong32 = "int.usub";
}

impl forall [T:! ImplicitAs(CppCompat.ULong32)]
    T as MulWith(CppCompat.ULong32) where .Result = CppCompat.ULong32 {
  fn Op[self: CppCompat.ULong32](other: CppCompat.ULong32) -> CppCompat.ULong32 = "int.umul";
}

impl forall [T:! ImplicitAs(CppCompat.ULong32)]
    T as DivWith(CppCompat.ULong32) where .Result = CppCompat.ULong32 {
  fn Op[self: CppCompat.ULong32](other: CppCompat.ULong32) -> CppCompat.ULong32 = "int.udiv";
}

impl forall [T:! ImplicitAs(CppCompat.ULong32)]
    T as ModWith(CppCompat.ULong32) where .Result = CppCompat.ULong32 {
  fn Op[self: CppCompat.ULong32](other: CppCompat.ULong32) -> CppCompat.ULong32 = "int.umod";
}

// Arithmetic for LongLong64.

final impl CppCompat.LongLong64 as Negate where .Result = Self {
  fn Op[self: Self]() -> Self = "int.snegate";
}

final impl CppCompat.LongLong64 as AddWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.sadd";
}

final impl CppCompat.LongLong64 as SubWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.ssub";
}

final impl CppCompat.LongLong64 as MulWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.smul";
}

final impl CppCompat.LongLong64 as DivWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.sdiv";
}

final impl CppCompat.LongLong64 as ModWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.smod";
}

impl forall [U:! ImplicitAs(CppCompat.LongLong64)]
    CppCompat.LongLong64 as AddWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.sadd";
}

impl forall [U:! ImplicitAs(CppCompat.LongLong64)]
    CppCompat.LongLong64 as SubWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.ssub";
}

impl forall [U:! ImplicitAs(CppCompat.LongLong64)]
    CppCompat.LongLong64 as MulWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.smul";
}

impl forall [U:! ImplicitAs(CppCompat.LongLong64)]
    CppCompat.LongLong64 as DivWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.sdiv";
}

impl forall [U:! ImplicitAs(CppCompat.LongLong64)]
    CppCompat.LongLong64 as ModWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.smod";
}

impl forall [T:! ImplicitAs(CppCompat.LongLong64)]
    T as AddWith(CppCompat.LongLong64) where .Result = CppCompat.LongLong64 {
  fn Op[self: CppCompat.LongLong64](other: CppCompat.LongLong64) -> CppCompat.LongLong64 = "int.sadd";
}

impl forall [T:! ImplicitAs(CppCompat.LongLong64)]
    T as SubWith(CppCompat.LongLong64) where .Result = CppCompat.LongLong64 {
  fn Op[self: CppCompat.LongLong64](other: CppCompat.LongLong64) -> CppCompat.LongLong64 = "int.ssub";
}

impl forall [T:! ImplicitAs(CppCompat.LongLong64)]
    T as MulWith(CppCompat.LongLong64) where .Result = CppCompat.LongLong64 {
  fn Op[self: CppCompat.LongLong64](other: CppCompat.LongLong64) -> CppCompat.LongLong64 = "int.smul";
}

impl forall [T:! ImplicitAs(CppCompat.LongLong64)]
    T as DivWith(CppCompat.LongLong64) where .Result = CppCompat.LongLong64 {
  fn Op[self: CppCompat.LongLong64](other: CppCompat.LongLong64) -> CppCompat.LongLong64 = "int.sdiv";
}

impl forall [T:! ImplicitAs(CppCompat.LongLong64)]
    T as ModWith(CppCompat.LongLong64) where .Result = CppCompat.LongLong64 {
  fn Op[self: CppCompat.LongLong64](other: CppCompat.LongLong64) -> CppCompat.LongLong64 = "int.smod";
}

// Arithmetic for ULongLong64.

final impl CppCompat.ULongLong64 as Negate where .Result = Self {
  fn Op[self: Self]() -> Self = "int.unegate";
}

final impl CppCompat.ULongLong64 as AddWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.uadd";
}

final impl CppCompat.ULongLong64 as SubWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.usub";
}

final impl CppCompat.ULongLong64 as MulWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.umul";
}

final impl CppCompat.ULongLong64 as DivWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.udiv";
}

final impl CppCompat.ULongLong64 as ModWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.umod";
}

impl forall [U:! ImplicitAs(CppCompat.ULongLong64)]
    CppCompat.ULongLong64 as AddWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.uadd";
}

impl forall [U:! ImplicitAs(CppCompat.ULongLong64)]
    CppCompat.ULongLong64 as SubWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.usub";
}

impl forall [U:! ImplicitAs(CppCompat.ULongLong64)]
    CppCompat.ULongLong64 as MulWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.umul";
}

impl forall [U:! ImplicitAs(CppCompat.ULongLong64)]
    CppCompat.ULongLong64 as DivWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.udiv";
}

impl forall [U:! ImplicitAs(CppCompat.ULongLong64)]
    CppCompat.ULongLong64 as ModWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.umod";
}

impl forall [T:! ImplicitAs(CppCompat.ULongLong64)]
    T as AddWith(CppCompat.ULongLong64) where .Result = CppCompat.ULongLong64 {
  fn Op[self: CppCompat.ULongLong64](other: CppCompat.ULongLong64) -> CppCompat.ULongLong64 = "int.uadd";
}

impl forall [T:! ImplicitAs(CppCompat.ULongLong64)]
    T as SubWith(CppCompat.ULongLong64) where .Result = CppCompat.ULongLong64 {
  fn Op[self: CppCompat.ULongLong64](other: CppCompat.ULongLong64) -> CppCompat.ULongLong64 = "int.usub";
}

impl forall [T:! ImplicitAs(CppCompat.ULongLong64)]
    T as MulWith(CppCompat.ULongLong64) where .Result = CppCompat.ULongLong64 {
  fn Op[self: CppCompat.ULongLong64](other: CppCompat.ULongLong64) -> CppCompat.ULongLong64 = "int.umul";
}

impl forall [T:! ImplicitAs(CppCompat.ULongLong64)]
    T as DivWith(CppCompat.ULongLong64) where .Result = CppCompat.ULongLong64 {
  fn Op[self: CppCompat.ULongLong64](other: CppCompat.ULongLong64) -> CppCompat.ULongLong64 = "int.udiv";
}

impl forall [T:! ImplicitAs(CppCompat.ULongLong64)]
    T as ModWith(CppCompat.ULongLong64) where .Result = CppCompat.ULongLong64 {
  fn Op[self: CppCompat.ULongLong64](other: CppCompat.ULongLong64) -> CppCompat.ULongLong64 = "int.umod";
}

// Bitwise operators.

// Bitwise operators for Long32.

final impl CppCompat.Long32 as BitComplement where .Result = Self {
  fn Op[self: Self]() -> Self = "int.complement";
}

final impl CppCompat.Long32 as BitAndWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.and";
}

final impl CppCompat.Long32 as BitOrWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.or";
}

final impl CppCompat.Long32 as BitXorWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.xor";
}

final impl CppCompat.Long32 as LeftShiftWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.left_shift";
}

final impl CppCompat.Long32 as RightShiftWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.right_shift";
}

impl forall [U:! ImplicitAs(CppCompat.Long32)]
    CppCompat.Long32 as BitAndWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.and";
}

impl forall [U:! ImplicitAs(CppCompat.Long32)]
    CppCompat.Long32 as BitOrWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.or";
}

impl forall [U:! ImplicitAs(CppCompat.Long32)]
    CppCompat.Long32 as BitXorWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.xor";
}

impl forall [U:! ImplicitAs(CppCompat.Long32)]
    CppCompat.Long32 as LeftShiftWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.left_shift";
}

impl forall [U:! ImplicitAs(CppCompat.Long32)]
    CppCompat.Long32 as RightShiftWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.right_shift";
}

impl forall [T:! ImplicitAs(CppCompat.Long32)]
    T as BitAndWith(CppCompat.Long32) where .Result = CppCompat.Long32 {
  fn Op[self: CppCompat.Long32](other: CppCompat.Long32) -> CppCompat.Long32 = "int.and";
}

impl forall [T:! ImplicitAs(CppCompat.Long32)]
    T as BitOrWith(CppCompat.Long32) where .Result = CppCompat.Long32 {
  fn Op[self: CppCompat.Long32](other: CppCompat.Long32) -> CppCompat.Long32 = "int.or";
}

impl forall [T:! ImplicitAs(CppCompat.Long32)]
    T as BitXorWith(CppCompat.Long32) where .Result = CppCompat.Long32 {
  fn Op[self: CppCompat.Long32](other: CppCompat.Long32) -> CppCompat.Long32 = "int.xor";
}

impl forall [T:! ImplicitAs(CppCompat.Long32)]
    T as LeftShiftWith(CppCompat.Long32) where .Result = CppCompat.Long32 {
  fn Op[self: CppCompat.Long32](other: CppCompat.Long32) -> CppCompat.Long32 = "int.left_shift";
}

impl forall [T:! ImplicitAs(CppCompat.Long32)]
    T as RightShiftWith(CppCompat.Long32) where .Result = CppCompat.Long32 {
  fn Op[self: CppCompat.Long32](other: CppCompat.Long32) -> CppCompat.Long32 = "int.right_shift";
}

// Bitwise operators for ULong32.

final impl CppCompat.ULong32 as BitComplement where .Result = Self {
  fn Op[self: Self]() -> Self = "int.complement";
}

final impl CppCompat.ULong32 as BitAndWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.and";
}

final impl CppCompat.ULong32 as BitOrWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.or";
}

final impl CppCompat.ULong32 as BitXorWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.xor";
}

final impl CppCompat.ULong32 as LeftShiftWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.left_shift";
}

final impl CppCompat.ULong32 as RightShiftWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.right_shift";
}

impl forall [U:! ImplicitAs(CppCompat.ULong32)]
    CppCompat.ULong32 as BitAndWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.and";
}

impl forall [U:! ImplicitAs(CppCompat.ULong32)]
    CppCompat.ULong32 as BitOrWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.or";
}

impl forall [U:! ImplicitAs(CppCompat.ULong32)]
    CppCompat.ULong32 as BitXorWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.xor";
}

impl forall [U:! ImplicitAs(CppCompat.ULong32)]
    CppCompat.ULong32 as LeftShiftWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.left_shift";
}

impl forall [U:! ImplicitAs(CppCompat.ULong32)]
    CppCompat.ULong32 as RightShiftWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.right_shift";
}

impl forall [T:! ImplicitAs(CppCompat.ULong32)]
    T as BitAndWith(CppCompat.ULong32) where .Result = CppCompat.ULong32 {
  fn Op[self: CppCompat.ULong32](other: CppCompat.ULong32) -> CppCompat.ULong32 = "int.and";
}

impl forall [T:! ImplicitAs(CppCompat.ULong32)]
    T as BitOrWith(CppCompat.ULong32) where .Result = CppCompat.ULong32 {
  fn Op[self: CppCompat.ULong32](other: CppCompat.ULong32) -> CppCompat.ULong32 = "int.or";
}

impl forall [T:! ImplicitAs(CppCompat.ULong32)]
    T as BitXorWith(CppCompat.ULong32) where .Result = CppCompat.ULong32 {
  fn Op[self: CppCompat.ULong32](other: CppCompat.ULong32) -> CppCompat.ULong32 = "int.xor";
}

impl forall [T:! ImplicitAs(CppCompat.ULong32)]
    T as LeftShiftWith(CppCompat.ULong32) where .Result = CppCompat.ULong32 {
  fn Op[self: CppCompat.ULong32](other: CppCompat.ULong32) -> CppCompat.ULong32 = "int.left_shift";
}

impl forall [T:! ImplicitAs(CppCompat.ULong32)]
    T as RightShiftWith(CppCompat.ULong32) where .Result = CppCompat.ULong32 {
  fn Op[self: CppCompat.ULong32](other: CppCompat.ULong32) -> CppCompat.ULong32 = "int.right_shift";
}

// Bitwise operators for LongLong64.

final impl CppCompat.LongLong64 as BitComplement where .Result = Self {
  fn Op[self: Self]() -> Self = "int.complement";
}

final impl CppCompat.LongLong64 as BitAndWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.and";
}

final impl CppCompat.LongLong64 as BitOrWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.or";
}

final impl CppCompat.LongLong64 as BitXorWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.xor";
}

final impl CppCompat.LongLong64 as LeftShiftWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.left_shift";
}

final impl CppCompat.LongLong64 as RightShiftWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.right_shift";
}

impl forall [U:! ImplicitAs(CppCompat.LongLong64)]
    CppCompat.LongLong64 as BitAndWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.and";
}

impl forall [U:! ImplicitAs(CppCompat.LongLong64)]
    CppCompat.LongLong64 as BitOrWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.or";
}

impl forall [U:! ImplicitAs(CppCompat.LongLong64)]
    CppCompat.LongLong64 as BitXorWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.xor";
}

impl forall [U:! ImplicitAs(CppCompat.LongLong64)]
    CppCompat.LongLong64 as LeftShiftWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.left_shift";
}

impl forall [U:! ImplicitAs(CppCompat.LongLong64)]
    CppCompat.LongLong64 as RightShiftWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.right_shift";
}

impl forall [T:! ImplicitAs(CppCompat.LongLong64)]
    T as BitAndWith(CppCompat.LongLong64) where .Result = CppCompat.LongLong64 {
  fn Op[self: CppCompat.LongLong64](other: CppCompat.LongLong64) -> CppCompat.LongLong64 = "int.and";
}

impl forall [T:! ImplicitAs(CppCompat.LongLong64)]
    T as BitOrWith(CppCompat.LongLong64) where .Result = CppCompat.LongLong64 {
  fn Op[self: CppCompat.LongLong64](other: CppCompat.LongLong64) -> CppCompat.LongLong64 = "int.or";
}

impl forall [T:! ImplicitAs(CppCompat.LongLong64)]
    T as BitXorWith(CppCompat.LongLong64) where .Result = CppCompat.LongLong64 {
  fn Op[self: CppCompat.LongLong64](other: CppCompat.LongLong64) -> CppCompat.LongLong64 = "int.xor";
}

impl forall [T:! ImplicitAs(CppCompat.LongLong64)]
    T as LeftShiftWith(CppCompat.LongLong64) where .Result = CppCompat.LongLong64 {
  fn Op[self: CppCompat.LongLong64](other: CppCompat.LongLong64) -> CppCompat.LongLong64 = "int.left_shift";
}

impl forall [T:! ImplicitAs(CppCompat.LongLong64)]
    T as RightShiftWith(CppCompat.LongLong64) where .Result = CppCompat.LongLong64 {
  fn Op[self: CppCompat.LongLong64](other: CppCompat.LongLong64) -> CppCompat.LongLong64 = "int.right_shift";
}

// Bitwise operators for ULongLong64.

final impl CppCompat.ULongLong64 as BitComplement where .Result = Self {
  fn Op[self: Self]() -> Self = "int.complement";
}

final impl CppCompat.ULongLong64 as BitAndWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.and";
}

final impl CppCompat.ULongLong64 as BitOrWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.or";
}

final impl CppCompat.ULongLong64 as BitXorWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.xor";
}

final impl CppCompat.ULongLong64 as LeftShiftWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.left_shift";
}

final impl CppCompat.ULongLong64 as RightShiftWith(Self) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.right_shift";
}

impl forall [U:! ImplicitAs(CppCompat.ULongLong64)]
    CppCompat.ULongLong64 as BitAndWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.and";
}

impl forall [U:! ImplicitAs(CppCompat.ULongLong64)]
    CppCompat.ULongLong64 as BitOrWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.or";
}

impl forall [U:! ImplicitAs(CppCompat.ULongLong64)]
    CppCompat.ULongLong64 as BitXorWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.xor";
}

impl forall [U:! ImplicitAs(CppCompat.ULongLong64)]
    CppCompat.ULongLong64 as LeftShiftWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.left_shift";
}

impl forall [U:! ImplicitAs(CppCompat.ULongLong64)]
    CppCompat.ULongLong64 as RightShiftWith(U) where .Result = Self {
  fn Op[self: Self](other: Self) -> Self = "int.right_shift";
}

impl forall [T:! ImplicitAs(CppCompat.ULongLong64)]
    T as BitAndWith(CppCompat.ULongLong64) where .Result = CppCompat.ULongLong64 {
  fn Op[self: CppCompat.ULongLong64](other: CppCompat.ULongLong64) -> CppCompat.ULongLong64 = "int.and";
}

impl forall [T:! ImplicitAs(CppCompat.ULongLong64)]
    T as BitOrWith(CppCompat.ULongLong64) where .Result = CppCompat.ULongLong64 {
  fn Op[self: CppCompat.ULongLong64](other: CppCompat.ULongLong64) -> CppCompat.ULongLong64 = "int.or";
}

impl forall [T:! ImplicitAs(CppCompat.ULongLong64)]
    T as BitXorWith(CppCompat.ULongLong64) where .Result = CppCompat.ULongLong64 {
  fn Op[self: CppCompat.ULongLong64](other: CppCompat.ULongLong64) -> CppCompat.ULongLong64 = "int.xor";
}

impl forall [T:! ImplicitAs(CppCompat.ULongLong64)]
    T as LeftShiftWith(CppCompat.ULongLong64) where .Result = CppCompat.ULongLong64 {
  fn Op[self: CppCompat.ULongLong64](other: CppCompat.ULongLong64) -> CppCompat.ULongLong64 = "int.left_shift";
}

impl forall [T:! ImplicitAs(CppCompat.ULongLong64)]
    T as RightShiftWith(CppCompat.ULongLong64) where .Result = CppCompat.ULongLong64 {
  fn Op[self: CppCompat.ULongLong64](other: CppCompat.ULongLong64) -> CppCompat.ULongLong64 = "int.right_shift";
}

// Arithmetic with primitive types (LHS is primitive, RHS is Cpp type).
// We want the result to be the Cpp type (simulating promotion to long/etc).

impl i32 as AddWith(CppCompat.Long32) where .Result = CppCompat.Long32 {
  fn Op[self: i32](other: CppCompat.Long32) -> CppCompat.Long32 {
    return (self as CppCompat.Long32) + other;
  }
}
impl i32 as SubWith(CppCompat.Long32) where .Result = CppCompat.Long32 {
  fn Op[self: i32](other: CppCompat.Long32) -> CppCompat.Long32 {
    return (self as CppCompat.Long32) - other;
  }
}
impl i32 as MulWith(CppCompat.Long32) where .Result = CppCompat.Long32 {
  fn Op[self: i32](other: CppCompat.Long32) -> CppCompat.Long32 {
    return (self as CppCompat.Long32) * other;
  }
}
impl i32 as DivWith(CppCompat.Long32) where .Result = CppCompat.Long32 {
  fn Op[self: i32](other: CppCompat.Long32) -> CppCompat.Long32 {
    return (self as CppCompat.Long32) / other;
  }
}
impl i32 as ModWith(CppCompat.Long32) where .Result = CppCompat.Long32 {
  fn Op[self: i32](other: CppCompat.Long32) -> CppCompat.Long32 {
    return (self as CppCompat.Long32) % other;
  }
}

impl i32 as BitAndWith(CppCompat.Long32) where .Result = CppCompat.Long32 {
  fn Op[self: i32](other: CppCompat.Long32) -> CppCompat.Long32 {
    return (self as CppCompat.Long32) & other;
  }
}
impl i32 as BitOrWith(CppCompat.Long32) where .Result = CppCompat.Long32 {
  fn Op[self: i32](other: CppCompat.Long32) -> CppCompat.Long32 {
    return (self as CppCompat.Long32) | other;
  }
}
impl i32 as BitXorWith(CppCompat.Long32) where .Result = CppCompat.Long32 {
  fn Op[self: i32](other: CppCompat.Long32) -> CppCompat.Long32 {
    return (self as CppCompat.Long32) ^ other;
  }
}

// ULong32 vs u32
impl u32 as AddWith(CppCompat.ULong32) where .Result = CppCompat.ULong32 {
  fn Op[self: u32](other: CppCompat.ULong32) -> CppCompat.ULong32 {
    return (self as CppCompat.ULong32) + other;
  }
}
impl u32 as SubWith(CppCompat.ULong32) where .Result = CppCompat.ULong32 {
  fn Op[self: u32](other: CppCompat.ULong32) -> CppCompat.ULong32 {
    return (self as CppCompat.ULong32) - other;
  }
}
impl u32 as MulWith(CppCompat.ULong32) where .Result = CppCompat.ULong32 {
  fn Op[self: u32](other: CppCompat.ULong32) -> CppCompat.ULong32 {
    return (self as CppCompat.ULong32) * other;
  }
}
impl u32 as DivWith(CppCompat.ULong32) where .Result = CppCompat.ULong32 {
  fn Op[self: u32](other: CppCompat.ULong32) -> CppCompat.ULong32 {
    return (self as CppCompat.ULong32) / other;
  }
}
impl u32 as ModWith(CppCompat.ULong32) where .Result = CppCompat.ULong32 {
  fn Op[self: u32](other: CppCompat.ULong32) -> CppCompat.ULong32 {
    return (self as CppCompat.ULong32) % other;
  }
}

impl u32 as BitAndWith(CppCompat.ULong32) where .Result = CppCompat.ULong32 {
  fn Op[self: u32](other: CppCompat.ULong32) -> CppCompat.ULong32 {
    return (self as CppCompat.ULong32) & other;
  }
}
impl u32 as BitOrWith(CppCompat.ULong32) where .Result = CppCompat.ULong32 {
  fn Op[self: u32](other: CppCompat.ULong32) -> CppCompat.ULong32 {
    return (self as CppCompat.ULong32) | other;
  }
}
impl u32 as BitXorWith(CppCompat.ULong32) where .Result = CppCompat.ULong32 {
  fn Op[self: u32](other: CppCompat.ULong32) -> CppCompat.ULong32 {
    return (self as CppCompat.ULong32) ^ other;
  }
}

// LongLong64 vs i64
impl i64 as AddWith(CppCompat.LongLong64) where .Result = CppCompat.LongLong64 {
  fn Op[self: i64](other: CppCompat.LongLong64) -> CppCompat.LongLong64 {
    return (self as CppCompat.LongLong64) + other;
  }
}
impl i64 as SubWith(CppCompat.LongLong64) where .Result = CppCompat.LongLong64 {
  fn Op[self: i64](other: CppCompat.LongLong64) -> CppCompat.LongLong64 {
    return (self as CppCompat.LongLong64) - other;
  }
}
impl i64 as MulWith(CppCompat.LongLong64) where .Result = CppCompat.LongLong64 {
  fn Op[self: i64](other: CppCompat.LongLong64) -> CppCompat.LongLong64 {
    return (self as CppCompat.LongLong64) * other;
  }
}
impl i64 as DivWith(CppCompat.LongLong64) where .Result = CppCompat.LongLong64 {
  fn Op[self: i64](other: CppCompat.LongLong64) -> CppCompat.LongLong64 {
    return (self as CppCompat.LongLong64) / other;
  }
}
impl i64 as ModWith(CppCompat.LongLong64) where .Result = CppCompat.LongLong64 {
  fn Op[self: i64](other: CppCompat.LongLong64) -> CppCompat.LongLong64 {
    return (self as CppCompat.LongLong64) % other;
  }
}

impl i64 as BitAndWith(CppCompat.LongLong64) where .Result = CppCompat.LongLong64 {
  fn Op[self: i64](other: CppCompat.LongLong64) -> CppCompat.LongLong64 {
    return (self as CppCompat.LongLong64) & other;
  }
}
impl i64 as BitOrWith(CppCompat.LongLong64) where .Result = CppCompat.LongLong64 {
  fn Op[self: i64](other: CppCompat.LongLong64) -> CppCompat.LongLong64 {
    return (self as CppCompat.LongLong64) | other;
  }
}
impl i64 as BitXorWith(CppCompat.LongLong64) where .Result = CppCompat.LongLong64 {
  fn Op[self: i64](other: CppCompat.LongLong64) -> CppCompat.LongLong64 {
    return (self as CppCompat.LongLong64) ^ other;
  }
}

// ULongLong64 vs u64
impl u64 as AddWith(CppCompat.ULongLong64) where .Result = CppCompat.ULongLong64 {
  fn Op[self: u64](other: CppCompat.ULongLong64) -> CppCompat.ULongLong64 {
    return (self as CppCompat.ULongLong64) + other;
  }
}
impl u64 as SubWith(CppCompat.ULongLong64) where .Result = CppCompat.ULongLong64 {
  fn Op[self: u64](other: CppCompat.ULongLong64) -> CppCompat.ULongLong64 {
    return (self as CppCompat.ULongLong64) - other;
  }
}
impl u64 as MulWith(CppCompat.ULongLong64) where .Result = CppCompat.ULongLong64 {
  fn Op[self: u64](other: CppCompat.ULongLong64) -> CppCompat.ULongLong64 {
    return (self as CppCompat.ULongLong64) * other;
  }
}
impl u64 as DivWith(CppCompat.ULongLong64) where .Result = CppCompat.ULongLong64 {
  fn Op[self: u64](other: CppCompat.ULongLong64) -> CppCompat.ULongLong64 {
    return (self as CppCompat.ULongLong64) / other;
  }
}
impl u64 as ModWith(CppCompat.ULongLong64) where .Result = CppCompat.ULongLong64 {
  fn Op[self: u64](other: CppCompat.ULongLong64) -> CppCompat.ULongLong64 {
    return (self as CppCompat.ULongLong64) % other;
  }
}

impl u64 as BitAndWith(CppCompat.ULongLong64) where .Result = CppCompat.ULongLong64 {
  fn Op[self: u64](other: CppCompat.ULongLong64) -> CppCompat.ULongLong64 {
    return (self as CppCompat.ULongLong64) & other;
  }
}
impl u64 as BitOrWith(CppCompat.ULongLong64) where .Result = CppCompat.ULongLong64 {
  fn Op[self: u64](other: CppCompat.ULongLong64) -> CppCompat.ULongLong64 {
    return (self as CppCompat.ULongLong64) | other;
  }
}
impl u64 as BitXorWith(CppCompat.ULongLong64) where .Result = CppCompat.ULongLong64 {
  fn Op[self: u64](other: CppCompat.ULongLong64) -> CppCompat.ULongLong64 {
    return (self as CppCompat.ULongLong64) ^ other;
  }
}

// Compound assignments.

// Compound assignments for Long32.

impl forall [U:! ImplicitAs(CppCompat.Long32)]
	  CppCompat.Long32 as AddAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.sadd_assign";
}

impl forall [U:! ImplicitAs(CppCompat.Long32)]
	  CppCompat.Long32 as SubAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.ssub_assign";
}

impl forall [U:! ImplicitAs(CppCompat.Long32)]
	  CppCompat.Long32 as MulAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.smul_assign";
}

impl forall [U:! ImplicitAs(CppCompat.Long32)]
	  CppCompat.Long32 as DivAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.sdiv_assign";
}

impl forall [U:! ImplicitAs(CppCompat.Long32)]
	  CppCompat.Long32 as ModAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.smod_assign";
}

impl forall [U:! ImplicitAs(CppCompat.Long32)]
	  CppCompat.Long32 as BitAndAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.and_assign";
}

impl forall [U:! ImplicitAs(CppCompat.Long32)]
	  CppCompat.Long32 as BitOrAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.or_assign";
}

impl forall [U:! ImplicitAs(CppCompat.Long32)]
	  CppCompat.Long32 as BitXorAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.xor_assign";
}

impl forall [U:! ImplicitAs(CppCompat.Long32)]
	  CppCompat.Long32 as LeftShiftAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.left_shift_assign";
}

impl forall [U:! ImplicitAs(CppCompat.Long32)]
	  CppCompat.Long32 as RightShiftAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.right_shift_assign";
}

// Compound assignments for ULong32.

impl forall [U:! ImplicitAs(CppCompat.ULong32)]
	  CppCompat.ULong32 as AddAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.uadd_assign";
}

impl forall [U:! ImplicitAs(CppCompat.ULong32)]
	  CppCompat.ULong32 as SubAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.usub_assign";
}

impl forall [U:! ImplicitAs(CppCompat.ULong32)]
	  CppCompat.ULong32 as MulAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.umul_assign";
}

impl forall [U:! ImplicitAs(CppCompat.ULong32)]
	  CppCompat.ULong32 as DivAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.udiv_assign";
}

impl forall [U:! ImplicitAs(CppCompat.ULong32)]
	  CppCompat.ULong32 as ModAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.umod_assign";
}

impl forall [U:! ImplicitAs(CppCompat.ULong32)]
	  CppCompat.ULong32 as BitAndAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.and_assign";
}

impl forall [U:! ImplicitAs(CppCompat.ULong32)]
	  CppCompat.ULong32 as BitOrAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.or_assign";
}

impl forall [U:! ImplicitAs(CppCompat.ULong32)]
	  CppCompat.ULong32 as BitXorAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.xor_assign";
}

impl forall [U:! ImplicitAs(CppCompat.ULong32)]
	  CppCompat.ULong32 as LeftShiftAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.left_shift_assign";
}

impl forall [U:! ImplicitAs(CppCompat.ULong32)]
	  CppCompat.ULong32 as RightShiftAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.right_shift_assign";
}

// Compound assignments for LongLong64.

impl forall [U:! ImplicitAs(CppCompat.LongLong64)]
	  CppCompat.LongLong64 as AddAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.sadd_assign";
}

impl forall [U:! ImplicitAs(CppCompat.LongLong64)]
	  CppCompat.LongLong64 as SubAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.ssub_assign";
}

impl forall [U:! ImplicitAs(CppCompat.LongLong64)]
	  CppCompat.LongLong64 as MulAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.smul_assign";
}

impl forall [U:! ImplicitAs(CppCompat.LongLong64)]
	  CppCompat.LongLong64 as DivAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.sdiv_assign";
}

impl forall [U:! ImplicitAs(CppCompat.LongLong64)]
	  CppCompat.LongLong64 as ModAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.smod_assign";
}

impl forall [U:! ImplicitAs(CppCompat.LongLong64)]
	  CppCompat.LongLong64 as BitAndAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.and_assign";
}

impl forall [U:! ImplicitAs(CppCompat.LongLong64)]
	  CppCompat.LongLong64 as BitOrAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.or_assign";
}

impl forall [U:! ImplicitAs(CppCompat.LongLong64)]
	  CppCompat.LongLong64 as BitXorAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.xor_assign";
}

impl forall [U:! ImplicitAs(CppCompat.LongLong64)]
	  CppCompat.LongLong64 as LeftShiftAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.left_shift_assign";
}

impl forall [U:! ImplicitAs(CppCompat.LongLong64)]
	  CppCompat.LongLong64 as RightShiftAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.right_shift_assign";
}

// Compound assignments for ULongLong64.

impl forall [U:! ImplicitAs(CppCompat.ULongLong64)]
	  CppCompat.ULongLong64 as AddAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.uadd_assign";
}

impl forall [U:! ImplicitAs(CppCompat.ULongLong64)]
	  CppCompat.ULongLong64 as SubAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.usub_assign";
}

impl forall [U:! ImplicitAs(CppCompat.ULongLong64)]
	  CppCompat.ULongLong64 as MulAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.umul_assign";
}

impl forall [U:! ImplicitAs(CppCompat.ULongLong64)]
	  CppCompat.ULongLong64 as DivAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.udiv_assign";
}

impl forall [U:! ImplicitAs(CppCompat.ULongLong64)]
	  CppCompat.ULongLong64 as ModAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.umod_assign";
}

impl forall [U:! ImplicitAs(CppCompat.ULongLong64)]
	  CppCompat.ULongLong64 as BitAndAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.and_assign";
}

impl forall [U:! ImplicitAs(CppCompat.ULongLong64)]
	  CppCompat.ULongLong64 as BitOrAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.or_assign";
}

impl forall [U:! ImplicitAs(CppCompat.ULongLong64)]
	  CppCompat.ULongLong64 as BitXorAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.xor_assign";
}

impl forall [U:! ImplicitAs(CppCompat.ULongLong64)]
	  CppCompat.ULongLong64 as LeftShiftAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.left_shift_assign";
}

impl forall [U:! ImplicitAs(CppCompat.ULongLong64)]
	  CppCompat.ULongLong64 as RightShiftAssignWith(U) {
  fn Op[ref self: Self](other: Self) = "int.right_shift_assign";
}

// Increment and decrement.

impl CppCompat.Long32 as Dec {
  fn Op[ref self: Self]() {
    self -= (1 as CppCompat.Long32);
  }
}

impl CppCompat.Long32 as Inc {
  fn Op[ref self: Self]() {
    self += (1 as CppCompat.Long32);
  }
}

impl CppCompat.ULong32 as Dec {
  fn Op[ref self: Self]() {
    self -= (1 as CppCompat.ULong32);
  }
}

impl CppCompat.ULong32 as Inc {
  fn Op[ref self: Self]() {
    self += (1 as CppCompat.ULong32);
  }
}

impl CppCompat.LongLong64 as Dec {
  fn Op[ref self: Self]() {
    self -= (1 as CppCompat.LongLong64);
  }
}

impl CppCompat.LongLong64 as Inc {
  fn Op[ref self: Self]() {
    self += (1 as CppCompat.LongLong64);
  }
}

impl CppCompat.ULongLong64 as Dec {
  fn Op[ref self: Self]() {
    self -= (1 as CppCompat.ULongLong64);
  }
}

impl CppCompat.ULongLong64 as Inc {
  fn Op[ref self: Self]() {
    self += (1 as CppCompat.ULongLong64);
  }
}
