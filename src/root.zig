//! By convention, root.zig is the root source file when making a package.
const std = @import("std");

pub const VIENTO_NAME_PREFIX = "$__VIENTO:";

pub inline fn name(comptime suffix: anytype) []const u8 {
    switch (@TypeOf(suffix)) {
        []const u8 => {
            return VIENTO_NAME_PREFIX ++ suffix ++ ";";
        },
        @EnumLiteral() => {
            return VIENTO_NAME_PREFIX ++ @tagName(suffix) ++ ";";
        },
        else => @compileError("Must be []const u8 or @EnumLiteral()"),
    }
}

pub const VIENTO_INFO_NAME = name(.INFO);
pub const VIENTO_PARAMS_NAME = name(.PARAMS);
