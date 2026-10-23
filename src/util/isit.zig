
const std = @import("std");

const comptimePrint = std.fmt.comptimePrint;

const Signedness = std.builtin.Signedness;

// For compile time checks.

pub fn assertionCall(comptime function: anytype, comptime args: anytype, comptime message: ?[]const u8) void {
    const fninf = @typeInfo(@TypeOf(function));
    if (fninf != .@"fn") @compileError("function must actually be a function.");
    if (fninf.@"fn".return_type != bool) @compileError("function must return bool.");
    if (!@call(.auto, function, args)) @compileError(message orelse "Assertion failed.");
}

pub inline fn sizeEq(comptime T: type, comptime size: usize) bool {
    return @sizeOf(T) == size;
}

pub fn assertSizeEq(comptime T: type, comptime size: usize, comptime message: ?[]const u8) void {
    assertionCall(sizeEq, .{T, size}, message orelse comptimePrint("Assertion Failed: Size of {s} != {d}.", .{@typeName(T), size}));
}

pub inline fn sameSize(comptime A: type, comptime B: type) bool {
    return @sizeOf(A) == @sizeOf(B);
}

pub fn assertSameSize(comptime A: type, comptime B: type, comptime message: ?[]const u8) void {
    assertionCall(sameSize, .{A, B}, message orelse comptimePrint("Assertion Failed: Size of {s} != Size of {s}", .{@typeName(A), @typeName(B)}));
}

pub inline fn sizeNe(comptime T: type, comptime size: usize) bool {
    return @sizeOf(T) != size;
}

pub fn assertSizeNe(comptime T: type, comptime size: usize, comptime message: ?[]const u8) void {
    assertionCall(sizeNe, .{T, size}, message orelse comptimePrint("Assertion Failed: Size of {s} == {d}.", .{@typeName(T), size}));
}

pub inline fn differentSize(comptime A: type, comptime B: type) bool {
    return @sizeOf(A) != @sizeOf(B);
}

pub fn assertDifferentSize(comptime A: type, comptime B: type, comptime message: ?[]const u8) void {
    assertionCall(differentSize, .{A, B}, message orelse comptimePrint("Assertion Failed: Size of {s} == Size of {s}.", .{@typeName(A), @typeName(B)}));
}

pub inline fn alignEq(comptime T: type, comptime alignment: usize) bool {
    return @alignOf(T) == alignment;
}

pub fn assertAlignEq(comptime T: type, comptime alignment: usize, comptime message: ?[]const u8) void {
    assertionCall(alignEq, .{T, alignment}, message orelse comptimePrint("Assertion Failed: Align of {s} != {d}.", .{@typeName(T), alignment}));
}

pub inline fn sameAlign(comptime A: type, comptime B: type) bool {
    return @alignOf(A) == @alignOf(B);
}

pub fn assertSameAlign(comptime A: type, comptime B: type, comptime message: ?[]const u8) void {
    assertionCall(sameAlign, .{A, B}, message orelse comptimePrint("Assertion Failed: Align of {s} != Align of {s}.", .{@typeName(A), @typeName(B)}));
}

pub inline fn alignNe(comptime T: type, comptime alignment: usize) bool {
    return @alignOf(T) != alignment;
}

pub fn assertAlignNe(comptime T: type, comptime alignment: usize, comptime message: ?[]const u8) void {
    assertionCall(alignNe, .{T, alignment}, message orelse comptimePrint("Assertion Failed: Align of {s} == {d}.", .{@typeName(T), alignment}));
}

pub inline fn differentAlign(comptime A: type, comptime B: type) bool {
    return @alignOf(A) != @alignOf(B);
}

pub fn assertDifferentAlign(comptime A: type, comptime B: type, comptime message: ?[]const u8) void {
    assertionCall(differentAlign, .{A, B}, message orelse comptimePrint("Assertion Failed: Align of {s} == Align of {s}.", .{@typeName(A), @typeName(B)}));
}

pub inline fn offsetOfEq(comptime T: type, comptime field: @EnumLiteral(), comptime offset: usize) bool {
    return @offsetOf(T, @tagName(field)) == offset;
}

pub fn assertOffsetOfEq(comptime T: type, comptime field: @EnumLiteral(), comptime offset: usize, comptime message: ?[]const u8) void {
    assertionCall(offsetOfEq, .{T, field, offset}, message orelse comptimePrint("Assertion Failed: Offset of \"{s}\" in {s} != {d}.", .{@tagName(field), @typeName(T), offset}));
}

pub inline fn offsetOfNe(comptime T: type, comptime field: @EnumLiteral(), comptime offset: usize) bool {
    return @offsetOf(T, @tagName(field)) != offset;
}

pub fn assertOffsetOfNe(comptime T: type, comptime field: @EnumLiteral(), comptime offset: usize, comptime message: ?[]const u8) void {
    assertionCall(offsetOfNe, .{T, field, offset}, message orelse comptimePrint("Assertion Failed: Offset of \"{s}\" in {s} == {d}.", .{@tagName(field), @typeName(T), offset}));
}

pub inline fn signednessEq(comptime T: type, comptime signedness: Signedness) bool {
    return @typeInfo(T).int.signedness == signedness;
}

pub fn assertSignednessEq(comptime T: type, comptime signedness: Signedness, comptime message: ?[]const u8) void {
    assertionCall(signednessEq, .{T, signedness}, message orelse comptimePrint("Assertion Failed: {s} is not {s}.", .{@typeName(T), @tagName(signedness)}));
}

pub inline fn signednessNe(comptime T: type, comptime signedness: Signedness) bool {
    return @typeInfo(T).int.signedness != signedness;
}

pub fn assertSignednessNe(comptime T: type, comptime signedness: Signedness, comptime message: ?[]const u8) void {
    assertionCall(signednessNe, .{T, signedness}, message orelse comptimePrint("Assertion Failed: {s} is {s}.", .{@typeName(T), @tagName(signedness)}));
}

pub inline fn typeEq(comptime A: type, comptime B: type) bool {
    return A == B;
}

pub fn assertTypeEq(comptime A: type, comptime B: type, comptime message: ?[]const u8) void {
    assertionCall(typeEq, .{A, B}, message orelse comptimePrint("Assertion Failed: {s} is not {s}.", .{@typeName(A), @typeName(B)}));
}

pub inline fn typeNe(comptime A: type, comptime B: type) bool {
    return A != B;
}

pub fn assertTypeNe(comptime A: type, comptime B: type, comptime message: ?[]const u8) void {
    assertionCall(typeNe, .{A, B}, message orelse comptimePrint("Assertion Failed: {s} is {s}.", .{@typeName(A), @typeName(B)}));
}

pub inline fn unimplemented(_: anytype, comptime message: ?[]const u8) noreturn {
    const msg = message orelse "Not yet implemented.";
    if (@inComptime()) {
        @compileError(msg);
    } else {
        @panic(msg);
    }
}

comptime {
    const TestStruct = extern struct {
        foo: u32,
        bar: u64,
        baz: u8,
    };
    const TestStructAlias = TestStruct;
    assertSizeEq(TestStruct, 24, null);
    assertSizeNe(TestStruct, 16, null);
    assertAlignEq(TestStruct, 8, null);
    assertAlignNe(TestStruct, 4, null);
    assertOffsetOfEq(TestStruct, .bar, 8, null);
    assertOffsetOfNe(TestStruct, .bar, 4, null);
    assertSignednessEq(u32, .unsigned, null);
    assertSignednessNe(u32, .signed, null);
    assertTypeEq(TestStruct, TestStructAlias, null);
    assertTypeNe(TestStruct, u32, null);
}
