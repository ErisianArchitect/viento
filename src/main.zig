const std = @import("std");

// const system = @import("system");
const util = @import("util");
const comp = util.comp;

const joinSlices = util.comp.joinSlices;
const zipWithLeft = util.comp.zipWithLeft;
const zipWithRight = util.comp.zipWithRight;

const StaticTypeMap = util.typemap.StaticTypeMap;
const StaticTypeSet = util.typemap.StaticTypeSet;

const print = std.debug.print;

pub inline fn println(comptime fmt: []const u8, args: anytype) void {
    print(fmt ++ "\n", args);
}

pub inline fn qprint(comptime text: []const u8) void {
    print("{s}", .{text});
}

pub inline fn qprintln(comptime text: []const u8) void {
    println("{s}", .{text});
}

pub fn Ty(comptime tag_value: usize) type {
    return struct {
        pub const tag = tag_value;
    };
}

pub fn manyTys(comptime start: usize, comptime end: usize) []const type {
    comptime if (end < start) @compileError("Invalid range. End is less than start.");
    return struct {
        const result = ret: {
            @setEvalBranchQuota(10000 + (end - start) * 4);
            var types: [end - start]type = undefined;
            for (start..end) |i| {
                types[i] = Ty(i);
            }
            break :ret comp.internArray(.immut, type, types);
        };
    }.result;
    
}

pub fn manyPairs(comptime start: usize, comptime end: usize) []const struct {type, usize} {
    comptime if (end < start) @compileError("Invalid range. End is less than start.");
    return struct {
        const result = ret: {
            @setEvalBranchQuota(10000 + (end - start) * 4);
            var pairs: [end - start]struct {type, usize} = undefined;
            for (start..end) |i| {
                pairs[i] = .{Ty(i), i};
            }
            break :ret comp.internArray(.immut, struct {type, usize}, pairs);
        };
    }.result;
}

pub const SystemContext = struct {

};

pub const Marker = union(enum) {
    with: type,
    without: type,
};

// pub fn SystemExecutor(
//     system: anytype,
//     condition: anytype,
//     markers: []const Marker,
// ) fn (*SystemContext) void {
    
// }

pub const System = struct {
    system_config: type,
    executor: fn(*const System, *SystemContext) void,
    system_rows: *anyopaque,
    condition_rows: *anyopaque,
};

pub const SysConfig = struct {
    system: type,
    dependencies: []const type = &.{},
};

// pub fn Sys(comptime S: type) type {
    
// }

pub const SystemBuilderFnTypes = struct {
    System: type,
    Condition: type = void,
};

pub const MarkerReq = union(enum) {
    with: type,
    without: type,
};

pub fn with(comptime T: type) MarkerReq {
    return .{.with = T};
}

pub fn without(comptime T: type) MarkerReq {
    return .{.without = T};
}

pub fn SystemBuilderType(comptime types: SystemBuilderFnTypes) type {
    return struct {
        const Self = @This();

        system: types.System,
        condition: ?types.Condition = null,
        with_markers: ?[]const type = null,
        without_markers: ?[]const type = null,
        before_dependencies: ?[]const type = null,
        after_dependencies: ?[]const type = null,

        pub fn when(
            comptime self: Self,
            comptime condition_fn: anytype,
        ) SystemBuilderType(.{
            .System = types.System,
            .Condition = @TypeOf(condition_fn)},
        ) {
            if (@TypeOf(condition_fn) == void) {
                @compileError("Cannot be void.");
            }
            return .{
                .system = self.system,
                .condition = condition_fn,
                .with_markers = self.with_markers,
                .without_markers = self.without_markers,
                .before_dependencies = self.before_dependencies,
                .after_dependencies = self.after_dependencies,
            };
        }

        pub fn with(
            comptime self: Self,
            comptime markers: []const type,
        ) Self {
            self.with_markers = markers;
            return self;
        }

        pub fn without(
            comptime self: Self,
            comptime markers: []const type,
        ) Self {
            self.without_markers = markers;
            return self;
        }

        pub fn before(
            comptime self: Self,
            comptime deps: []const type,
        ) Self {
            self.before_dependencies = deps;
            return self;
        }

        pub fn after(
            comptime self: Self,
            comptime deps: []const type,
        ) Self {
            self.after_dependencies = deps;
            return self;
        }
    };
}

pub fn SystemBuilder(comptime system_fn: anytype) SystemBuilderType(.{.System = @TypeOf(system_fn)}) {
    return SystemBuilderType(system_fn){.system = system_fn};
}

// SystemBuilder(system_fn)
//     .when(condition_fn)
//     .with(&.{Foo, Bar})
//     .without(&.{Baz})
//     .before(.{foo_system, bar_system})
//     .after(.{baz_system})
//     .build()

const markerset = @import("util").markerset;

const MarkerSet = markerset.MarkerSet(manyTys(0, 1024));

pub fn main(_: std.process.Init) !void {
    var mset = MarkerSet.init();
    mset.addAll(&.{Ty(1), Ty(2), Ty(64), Ty(68)});
    try std.testing.expectEqual(mset.bits.masks.len, 16);
    try std.testing.expect(mset.has(Ty(1)));
    try std.testing.expect(mset.has(Ty(2)));
    try std.testing.expect(mset.has(Ty(64)));
    try std.testing.expect(mset.has(Ty(68)));
    try std.testing.expect(!mset.has(Ty(0)));
    try std.testing.expect(!mset.has(Ty(3)));
    try std.testing.expect(mset.hasAll(&.{Ty(1), Ty(2), Ty(64), Ty(68)}));
    try std.testing.expect(mset.hasAny(&.{Ty(0), Ty(1), Ty(66)}));
    try std.testing.expect(mset.hasNone(&.{Ty(0), Ty(3), Ty(66)}));
    mset.removeAll(&.{Ty(1), Ty(2), Ty(64), Ty(68)});
    try std.testing.expect(!mset.has(Ty(0)));
    try std.testing.expect(!mset.has(Ty(1)));
    try std.testing.expect(!mset.has(Ty(2)));
    try std.testing.expect(!mset.has(Ty(3)));
    try std.testing.expect(!mset.has(Ty(64)));
    try std.testing.expect(!mset.has(Ty(68)));
    try std.testing.expect(mset.isEmpty());
    const multi = comptime MarkerSet.MultiMask.init(.add, &.{Ty(1), Ty(2), Ty(64), Ty(68)});
    try std.testing.expectEqual(multi.len, 2);
    qprintln("Pass");
    // println("Hash: {d}", .{comp.hashAny("Test")});
    // println("Hash: {d}", .{comp.hashAny("Test")});
    // println("Hash: {d}", .{comp.hashAny(u64)});
    // println("Hash: {d}", .{comp.hashAny(u64)});
    // println("Hash: {d}", .{comp.hashAny(u32)});
    // println("Hash: {d}", .{comp.hashAny(u32)});
}

// pub fn main(_: std.process.Init) !void {
//     const map1 = StaticTypeMap(usize).init(manyPairs(0, 1000));
//     const set = StaticTypeSet.init(map1.keys());
//     println("Max Bucket Size: {d}", .{map1.maxBucketSize()});
//     try std.testing.expect(set.has(Ty(43)));
//     try std.testing.expect(set.has(Ty(999)));
//     try std.testing.expectEqual(map1.val(Ty(65)), 65);
//     inline for (5..100) |i| {
//         try std.testing.expect(set.has(Ty(i)));
//     }
//     inline for (1000..1100) |i| {
//         try std.testing.expect(!set.has(Ty(i)));
//     }
//     // const joined = StaticTypeMap(usize).init(joinSlices(.immut, struct {type, usize}, null, &.{
//     //     zipWithRight(.immut, type, @as(usize, 0), map1.keys()),
//     //     zipWithRight(.immut, type, @as(usize, 1), map2.keys()),
//     // }));
//     // const set = StaticTypeSet.init(joined.keys());
    
//     // inline for (map1.buckets) |bucket| {
//     //     println("Bucket size: {d}", .{comptime bucket.len});
//     // }
//     // println("hash u32: {d}\nhash u64: {d}", .{
//     //     comp.typeHash(u32),
//     //     comp.typeHash(u64),
//     // });
//     // println("Max bucket size: {d}", .{map1.maxBucketSize()});
//     // println("Len: {d}", .{map1.len});
//     // inline for (map1.bucketFor(Ty(420))) |slot| {
//     //     println("Type: {s}", .{@typeName(slot.key)});
//     // }
//     // println("Value of Ty(16): {d}", .{map1.val(Ty(16))});
//     // println("u32 ID: {d}\nu64 ID: {d}", .{
//     //     map1.id(u32),
//     //     map1.id(u64),
//     // });
//     // comptime var builder = EcsBuilder(.{}){};
//     // const MyEcs = comptime builder
//     //     .withResources(&.{})
//     //     .withComponents(&.{})
//     //     .withEvents(&.{})
//     //     .withMarkers(&.{})
//     //     .withQueries(&.{})
//     //     .withInjectables(&.{})
//     //     .build();
//     // MyEcs.foo();
//     // const text = comptime joinSlices(.immut, u8, ", ", &.{"one", "two", "three"});
//     // const items = zipWithRight(.immut, []const u8, "test", &.{"Foo", "Bar", "Baz"});
//     // for (items) |item| {
//     //     println("Left: {s}, Right: {s}", .{item[0], item[1]});
//     // }
//     // qprintln(text);
// }
