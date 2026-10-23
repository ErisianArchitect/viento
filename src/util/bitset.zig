
const std = @import("std");
const comp = @import("comp.zig");

pub fn Bitset(comptime bit_count: u32) type {
    const bitlen: usize = @bitSizeOf(usize);
    const mask_count: usize = blk: {
        if (bitlen == 0) break :blk 0
        else break :blk (bit_count + (bitlen - 1)) / bitlen;
    };
    const bitlen_shift = @ctz(bitlen);
    const subbit_mask = bitlen - 1;
    return struct {
        const Self = @This();
        
        masks: [mask_count]usize,

        pub fn init() Self {
            return .{.masks = @splat(0)};
        }

        pub inline fn maskIndex(bit: usize) usize {
            return bit >> bitlen_shift;
        }

        pub inline fn maskSubbit(bit: usize) u6 {
            if (comptime bitlen <= 64) @setRuntimeSafety(false);
            return @intCast(bit & subbit_mask);
        }

        pub fn add(self: *Self, bit: usize) void {
            if (comptime mask_count == 0) return;
            const mask_index = maskIndex(bit);
            const subbit_index = maskSubbit(bit);
            self.masks[mask_index] |= @as(usize, 1) << subbit_index;
        }

        pub fn remove(self: *Self, bit: usize) void {
            if (comptime mask_count == 0) return;
            const mask_index = maskIndex(bit);
            const subbit_index = maskSubbit(bit);
            self.masks[mask_index] &= ~(@as(usize, 1) << subbit_index);
        }

        pub fn set(self: *Self, bit: usize, value: bool) void {
            if (comptime mask_count == 0) return;
            if (value) {
                self.add(bit);
            } else {
                self.remove(bit);
            }
        }

        pub fn toggle(self: *Self, bit: usize) void {
            if (comptime mask_count == 0) return;
            const mask_index = maskIndex(bit);
            const subbit_index = maskSubbit(bit);
            self.masks[mask_index] ^= @as(usize, 1) << subbit_index;
        }

        pub fn get(self: *const Self, bit: usize) bool {
            if (comptime mask_count == 0) return false;
            const mask_index = maskIndex(bit);
            const subbit_index = maskSubbit(bit);
            return (self.masks[mask_index] & (@as(usize, 1) << subbit_index)) != 0;
        }
    };
}
