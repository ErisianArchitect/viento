
const std = @import("std");

const util = @import("util");

const comp = util.comp;
const typemap = util.typemap;
const bitset = util.bitset;

pub fn MarkerSet(comptime marker_types: []const type) type {
    return struct {
        const Self = @This();
        
        const indices = typemap.StaticTypeSet.init(marker_types);
        const Bitset = bitset.Bitset(marker_types.len);
        
        bits: Bitset,

        pub fn init() Self {
            return .{.bits = .init()};
        }

        pub const MultiMask = struct {
            index: usize,
            mask: usize,

            fn maskAll(comptime Markers: []const type) *const Bitset {
                @setEvalBranchQuota(std.math.maxInt(u32));
                var maskset = Bitset.init();
                for (Markers) |m| {
                    maskset.add(indices.id(m));
                }
                return comp.internObject(.immut, maskset);
            }

            fn countMasks(comptime Markers: []const type) usize {
                return struct {
                    pub const result = ret: {
                        @setEvalBranchQuota(std.math.maxInt(u32));
                        const maskset = maskAll(Markers);
                        var mask_count = 0;
                        for (maskset.masks) |m| {
                            if (m != 0) mask_count += 1;
                        }
                        break :ret mask_count;
                    };
                }.result;
            }

            pub const MultiMaskAction = enum {
                add,
                remove,
            };

            pub fn init(
                comptime action: MultiMaskAction,
                comptime Markers: []const type,
            ) [countMasks(Markers)]@This() {
                @setEvalBranchQuota(std.math.maxInt(u32));
                const marks = maskAll(Markers);
                var mask_count = 0;
                for (marks.masks) |m| {
                    if (m != 0) mask_count += 1;
                }
                var builder: [mask_count]@This() = undefined;
                for (marks.masks, 0..) |m, i| {
                    if (m != 0) {
                        switch (action) {
                            .add => builder[i] = MultiMask{.index = i, .mask = m},
                            .remove => builder[i] = MultiMask{.index = i, .mask = ~m},
                        }
                    }
                }
                return builder;
            }
        };

        fn ensureHasType(comptime T: type) void { comptime {
            if (!indices.has(T)) @compileError("Type not present in set: " ++ @typeName(T));
        }}

        pub fn add(self: *Self, comptime Marker: type) void {
            comptime ensureHasType(Marker);
            const index: usize = comptime indices.id(Marker);
            self.bits.add(index);
        }

        pub fn remove(self: *Self, comptime Marker: type) void {
            comptime ensureHasType(Marker);
            const index: usize = comptime indices.id(Marker);
            self.bits.remove(index);
        }

        pub fn addAll(self: *Self, comptime Markers: []const type) void {
            const multi = struct {
                pub const value = MultiMask.init(.add, Markers);
            };
            @setEvalBranchQuota(std.math.maxInt(u32));
            inline for (multi.value) |m| {
                self.bits.masks[m.index] |= m.mask;
            }
        }

        pub fn removeAll(self: *Self, comptime Markers: []const type) void {
            const multi = struct {
                pub const value = MultiMask.init(.remove, Markers);
            };
            @setEvalBranchQuota(std.math.maxInt(u32));
            inline for (multi.value) |m| {
                self.bits.masks[m.index] &= m.mask;
            }
        }

        pub fn set(self: *Self, comptime Marker: type, value: bool) void {
            comptime ensureHasType(Marker);
            const index: usize = comptime indices.id(Marker);
            self.bits.set(index, value);
        }

        pub fn setAll(self: *Self, comptime Markers: []const type, value: bool) void {
            const add_masks = comptime MultiMask.init(.add, Markers);
            const remove_masks = comptime MultiMask.init(.remove, Markers);
            @setEvalBranchQuota(std.math.maxInt(u32));
            if (value) {
                inline for(add_masks) |m| {
                    self.bits.masks[m.index] |= m.mask;
                }
            } else {
                inline for(remove_masks) |m| {
                    self.bits.masks[m.index] &= m.mask;
                }
            }
        }

        pub fn toggle(self: *Self, comptime Marker: type) void {
            comptime ensureHasType(Marker);
            const index: usize = comptime indices.id(Marker);
            self.bits.toggle(index);
        }

        pub fn toggleAll(self: *Self, comptime Markers: []const type) void {
            const multi = comptime MultiMask.init(.add, Markers);
            @setEvalBranchQuota(std.math.maxInt(u32));
            inline for (multi) |m| {
                self.bits.masks[m.index] ^= m.mask;
            }
        }

        pub fn has(self: *const Self, comptime Marker: type) bool {
            comptime ensureHasType(Marker);
            const index: usize = comptime indices.id(Marker);
            return self.bits.get(index);
        }

        pub fn hasAny(self: *const Self, comptime Markers: []const type) bool {
            const multi = struct {
                pub const value = MultiMask.init(.add, Markers);
            };
            @setEvalBranchQuota(std.math.maxInt(u32));
            inline for (multi.value) |m| {
                if (self.bits.masks[m.index] & m.mask != 0) return true;
            }
            return false;
        }

        pub fn missingAny(self: *const Self, comptime Markers: []const type) bool {
            const multi = struct {
                pub const value = MultiMask.init(.add, Markers);
            };
            @setEvalBranchQuota(std.math.maxInt(u32));
            inline for (multi.value) |m| {
                if (self.bits.masks[m.index] & m.mask != m.mask) return true;
            }
            return false;
        }

        pub fn hasAll(self: *const Self, comptime Markers: []const type) bool {
            const multi = struct {
                pub const value = MultiMask.init(.add, Markers);
            };
            @setEvalBranchQuota(std.math.maxInt(u32));
            inline for (multi.value) |m| {
                if (self.bits.masks[m.index] & m.mask != m.mask) return false;
            }
            return true;
        }

        pub fn missingAll(self: *const Self, comptime Markers: []const type) bool {
            const multi = struct {
                pub const value = MultiMask.init(.add, Markers);
            };
            @setEvalBranchQuota(std.math.maxInt(u32));
            inline for (multi.value) |m| {
                if (self.bits.masks[m.index] & m.mask != 0) return false;
            }
            return true;
        }

        pub fn hasNone(self: *const Self, comptime Markers: []const type) bool {
            const multi = struct {
                pub const value = MultiMask.init(.add, Markers);
            };
            @setEvalBranchQuota(std.math.maxInt(u32));
            inline for (multi.value) |m| {
                if (self.bits.masks[m.index] & m.mask != 0) return false;
            }
            return true;
        }

        pub fn isEmpty(self: *const Self) bool {
            @setEvalBranchQuota(std.math.maxInt(u32));
            for (self.bits.masks) |m| {
                if (m != 0) return false;
            }
            return true;
        }
    };
}
