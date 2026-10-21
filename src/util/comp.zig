
const std = @import("std");

const XxHash64 = std.hash.XxHash64;

pub inline fn UniqueType(comptime T: type) type {
    return struct {
        tag: T,
    };
}

const PrivateToken = struct{};

const HASH_SEED = 3253931770482926364;

pub fn TaggedType(comptime any: anytype) type {
    return struct {
        pub const tag = any;
    };
}

pub inline fn hashAny(comptime any: anytype) u64 {
    return struct {
        pub const result: u64 = ret: {
         // const Unique = UniqueType(struct {TaggedType(any), TaggedType(hashAny), PrivateToken});
         const Unique = TaggedType(.{any, hashAny, PrivateToken});
         const unique_name = @typeName(Unique);
         var hasher = XxHash64.init(HASH_SEED);
         hasher.update(unique_name);
         break :ret hasher.final();
        };
    }.result;
}

// pub inline fn typeHashWith(comptime T: type, comptime with: anytype) u64 {
//     return hashAny(.{.{T, with}, typeHashWith, PrivateToken});
// }

pub inline fn typeHash(comptime T: type) u64 {
    return struct {
        pub const result: u64 = ret: {
            const Unique = UniqueType(struct {T, PrivateToken});
            const type_name = @typeName(Unique);
            var hasher = XxHash64.init(HASH_SEED);
            hasher.update(type_name);
            break :ret hasher.final();
        };
    }.result;
}

pub inline fn ArrayType(comptime T: type) type {
    return @typeInfo(T).array.child;
}

pub const Mutability = enum {
    const Self = @This();
    
    immut,
    mut,

    pub fn Slice(comptime self: Self, comptime T: type) type {
        switch (self) {
            .immut => return []const T,
            .mut => return []T,
        }
    }

    pub fn TerminatedSlice(comptime self: Self, comptime T: type, comptime terminator: T) type {
        switch (self) {
            .immut => return [:terminator]const T,
            .mut => return [:terminator]T,
        }
    }

    pub fn Pointer(comptime self: Self, comptime T: type) type {
        switch (self) {
            .immut => return *const T,
            .mut => return *T,
        }
    }
};

pub inline fn internArray(
    comptime mutability: Mutability,
    comptime T: type,
    comptime arr: anytype,
) switch (mutability) {
    .immut => []const T,
    .mut => []T,
} {
    switch (comptime mutability) {
        .immut => return struct {
            const storage = arr;
            pub const result: mutability.Slice(T) = &storage;
        }.result,
        .mut => return struct {
            var storage = arr;
            pub const result: mutability.Slice(T) = &storage;
        }.result,
    }
}

pub inline fn internObject(
    comptime mutability: Mutability,
    comptime obj: anytype,
) switch (mutability) {
    .immut => *const @TypeOf(obj),
    .mut => *@TypeOf(obj),
} {
    switch (comptime mutability) {
        .immut => return struct {
            const storage = obj;
            pub const result = &storage;
        }.result,
        .mut => return struct {
            var storage = obj;
            pub const result = &storage;
        }.result,
    }
}

pub inline fn joinSlices(
    comptime mutability: Mutability,
    comptime T: type,
    comptime separator: ?[]const T,
    comptime slices: []const []const T,
) switch (mutability) {
    .immut => []const T,
    .mut => []T,
} {
    return struct {
        pub const result = ret: {
            @setEvalBranchQuota(std.math.maxInt(u32));
            if (slices.len == 0) break :ret &.{};
            const sep = blk:{ if (separator) |s| {
                break :blk s;
            } else {
                break :blk &.{};
            }};
            var size: usize = sep.len * (slices.len - 1);
            for (slices) |s| {
                size += s.len;
            }
            var buf: [size]T = undefined;
            var offset = 0;
            for (slices) |s| {
                if (sep.len != 0 and offset != 0) {
                    @memcpy(buf[offset..][0..sep.len], sep);
                    offset += sep.len;
                }
                @memcpy(buf[offset..][0..s.len], s);
                offset += s.len;
            }
            break :ret internArray(mutability, T, buf);
        };
    }.result;
}

pub fn zipWithRight(
    comptime mutability: Mutability,
    comptime T: type,
    comptime rhs: anytype,
    comptime items: []const T,
) switch (mutability) {
    .immut => []const struct {T, @TypeOf(rhs)},
    .mut => []struct {T, @TypeOf(rhs)},
} {
    return struct {
        pub const result = ret: {
            @setEvalBranchQuota(std.math.maxInt(u32));
            if (items.len == 0) break :ret &.{};
            const Tup = struct {T, @TypeOf(rhs)};
            var new_items: [items.len]Tup = undefined;
            for (items, 0..) |lhs, i| {
                new_items[i].@"0" = lhs;
                new_items[i].@"1" = rhs;
            }
            break :ret internArray(mutability, Tup, new_items);
        };
    }.result;
}

pub fn zipWithLeft(
    comptime mutability: Mutability,
    comptime T: type,
    comptime lhs: anytype,
    comptime items: []const T,
) switch (mutability) {
    .immut => []const struct {@TypeOf(lhs), T},
    .mut => []struct {@TypeOf(lhs), T},
} {
    return struct {
        pub const result = ret: {
            @setEvalBranchQuota(std.math.maxInt(u32));
            if (items.len == 0) break :ret &.{};
            const Tup = struct {@TypeOf(lhs), T};
            var new_items: [items.len]Tup = undefined;
            for (items, 0..) |rhs, i| {
                new_items[i].@"0" = lhs;
                new_items[i].@"1" = rhs;
            }
            break :ret internArray(mutability, Tup, new_items);
        };
    }.result;
}
