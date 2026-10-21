
pub const VIENTO_PREFIX: []const u8 = "$__VIENTO:";

pub inline fn vientoName(comptime name: anytype) []const u8 {
    switch (@TypeOf(name)) {
        []const u8 => return VIENTO_PREFIX ++ name ++ ";",
        @EnumLiteral() => return vientoName(@tagName(name)),
    }
}
