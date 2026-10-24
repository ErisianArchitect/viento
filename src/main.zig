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

const ecs = @import("ecs");

const MarkerSet = ecs.marker.MarkerSet(manyTys(0, 1024));
const marker = ecs.marker;
const q = marker.MarkerQuery;

fn MarkerQueryParam(comptime query: marker.MarkerQuery) type {
    return struct {
        pub const PROTOTYPE = MarkerQueryParam;
        pub const QUERY = query;
    };
}

fn bar_system(
    _: MarkerQueryParam(.with(Ty(1))),
) void {
}

const test_query = q.all(&.{
    q.with(Ty(1)),
    q.with(Ty(2)),
    q.with(Ty(64)),
    q.with(Ty(68)),
    q.withAny(&.{
        Ty(1),
        Ty(35),
    }),
    q.withAll(&.{
        Ty(1),
        Ty(2),
        Ty(64),
        Ty(68),
    }),
    q.withoutAny(&.{
        Ty(1),
        Ty(2),
        Ty(35),
    }),
    q.withoutAll(&.{
        Ty(8),
        Ty(9),
        Ty(10),
    }),
    q.not(q.with(Ty(0))),
    q.all(&.{
        q.with(Ty(1)),
        q.with(Ty(2)),
    }),
    q.any(&.{
        q.with(Ty(1)),
        q.without(Ty(1)),
    }),
    q.none(&.{
        q.with(Ty(55)),
        q.without(Ty(2)),
    }),
});

const test_query_parts = test_query.participants();


pub const ObjectId = packed struct {
    id: u40,
    generation: u24,
};
comptime {
    if (@sizeOf(ObjectId) != 8) {
        @compileError("Not 64-bits");
    }
}

const Vec = @import("dsa").Vec;

pub fn main() !void {
    const T = comp.UniqueType(u32);
    println("Type Name: {s}", .{@typeName(T)});
    // return testVec();
    const map1 = StaticTypeMap(usize).init(manyPairs(0, 1000));
    const set = StaticTypeSet.init(map1.keys());
    println("Max Bucket Size: {d}", .{map1.maxBucketSize()});
    try std.testing.expect(set.has(Ty(43)));
    try std.testing.expect(set.has(Ty(999)));
    try std.testing.expectEqual(map1.val(Ty(65)), 65);
    inline for (5..100) |i| {
        try std.testing.expect(set.has(Ty(i)));
        try std.testing.expect(map1.has(Ty(i)));
    }
}

pub fn testVec() !void {
    // const alloc = init.gpa;
    var debug_alloc = std.heap.DebugAllocator(.{.thread_safe = false}).init;
    const alloc = debug_alloc.allocator();
    defer {
        switch (debug_alloc.deinit()) {
            .leak => @panic("Memory leak."),
            .ok => {},
        }
    }
    var items = Vec([]const u8).init(alloc);
    defer items.deinit(alloc);
    items.push(alloc, "Hello, world!");
    items.push(alloc, "This is a test.");
    items.push(alloc, "The quick brown fox jumps over the lazy dog.");
    for (items.slice()) |item| {
        println("Item: {s}", .{item});
    }
    qprintln("Popping:");
    while (items.pop()) |item| {
        println("Popped: {s}", .{item});
    }
    items.push(alloc, "Foo");
    items.push(alloc, "Bar");
    items.push(alloc, "Foo");
    items.push(alloc, "Baz");
    items.push(alloc, "Fred");
    items.push(alloc, "Foo");
    items.drain({}, 0, items.len, struct {
        fn takeItem(_: void, _: usize, item: []const u8) bool {
            println("Drain: {s}", .{item});
            return std.mem.eql(u8, item, "Foo");
        }
    }.takeItem);
    for (items.slice()) |item| {
        println("Post Drain: {s}", .{item});
    }
    const removed = items.remove(1);
    println("Removed: {s}", .{removed});
    for (items.slice()) |item| {
        println("Post Remove: {s}", .{item});
    }
    items.pushMany(alloc, &.{
        "Item2",
        "Item3",
        "Item4",
        "Item5",
        "Item6",
        "Item7"
    });
    var out: [4][]const u8 = @splat("");
    items.removeMany(2, &out);
    for (out) |item| {
        println("Out: {s}", .{item});
    }
    for (items.slice()) |item| {
        println("After removeMany: {s}", .{item});
    }
    if (items.contains("Item7")) {
        qprintln("Contains Item7");
    } else {
        @panic("Failure on contains.");
    }
    items.insert(alloc, 0, "Inserted into first.");
    
    for (items.slice()) |it| {
        println("After insert: {s}", .{it});
    }

    items.clear();
    items.pushMany(alloc, &.{"0", "1", "2"});
    items.insertMany(alloc, 0, &.{"Ins0", "Ins1", "Ins2"});
    for (items.slice()) |it| {
        println("After insertMany: {s}", .{it});
    }
    var dump = Vec([]const u8).initCapacity(alloc, 0);
    defer dump.deinit(alloc);
    dump.transferFrom(alloc, 0, &items, 0, 3);
    for (dump.slice()) |it| {
        println("Dump: {s}", .{it});
    }
    for (items.slice()) |it| {
        println("After Dump: {s}", .{it});
    }
    items.pushMany(alloc, &.{"3", "4", "5", "6", "7"});
    items.clearRange(3, 6);
    for (items.slice()) |it| {
        println("After clearRange: {s}", .{it});
    }
    items.clear();
    items.insertManyWith(alloc, 0, 3, {}, struct {
        pub fn map(_: void, index: usize) []const u8 {
            return switch (index) {
                0 => "Zero",
                1 => "One",
                2 => "Two",
                else => @panic("Out of range."),
            };
        }
    }.map);
    for (items.slice()) |it| {
        println("After insertManyWith: {s}", .{it});
    }
    items.insertManyWith(alloc, 1, 5, {}, struct {
        pub fn map(_: void, index: usize) []const u8 {
            return switch (index) {
                0 => "0",
                1 => "1",
                2 => "2",
                else => "Out of range.",
            };
        }
    }.map);
    qprintln("-----");
    for (items.slice()) |it| {
        println("After insertManyWith: {s}", .{it});
    }
    const swap_removed = items.swapRemove(0);
    qprintln("-----");
    println("Swap Removed: {s}", .{swap_removed});
    for (items.slice()) |it| {
        println("After swapRemove: {s}", .{it});
    }
    var swap_remove_many: [2][]const u8 = undefined;
    items.swapRemoveMany(1, &swap_remove_many);
    qprintln("-----");
    for (swap_remove_many) |it| {
        println("Swap Many Removed: {s}", .{it});
    }
    for (items.slice()) |it| {
        println("After swapRemoveMany: {s}", .{it});
    }
    items.swap(0, 1);
    items.swap(1, 2);
    for (items.slice()) |it| {
        println("After swap: {s}", .{it});
    }

    var strbuf = Vec(u8).init(alloc);
    defer strbuf.deinit(alloc);
    strbuf.pushMany(alloc, "Hello, world!");
    strbuf.pushMany(alloc, "\n");
    strbuf.pushMany(alloc, "This is a test.");
    println("Strbuf:\n{s}", .{strbuf.slice()});
    // inline for (test_query_parts) |t| {
    //     println("Type: {s}", .{@typeName(t)});
    // }
    // var mset = MarkerSet.init();
    // mset.addAll(&.{Ty(1), Ty(2), Ty(64), Ty(68)});
    // try std.testing.expect(test_query.eval(&mset));
    // try std.testing.expectEqual(mset.bits.masks.len, 16);
    // try std.testing.expect(mset.has(Ty(1)));
    // try std.testing.expect(mset.has(Ty(2)));
    // try std.testing.expect(mset.has(Ty(64)));
    // try std.testing.expect(mset.has(Ty(68)));
    // try std.testing.expect(!mset.has(Ty(0)));
    // try std.testing.expect(!mset.has(Ty(3)));
    // try std.testing.expect(mset.hasAll(&.{Ty(1), Ty(2), Ty(64), Ty(68)}));
    // try std.testing.expect(mset.hasAny(&.{Ty(0), Ty(1), Ty(66)}));
    // try std.testing.expect(mset.hasNone(&.{Ty(0), Ty(3), Ty(66)}));
    // mset.removeAll(&.{Ty(1), Ty(2), Ty(64), Ty(68)});
    // try std.testing.expect(!mset.has(Ty(0)));
    // try std.testing.expect(!mset.has(Ty(1)));
    // try std.testing.expect(!mset.has(Ty(2)));
    // try std.testing.expect(!mset.has(Ty(3)));
    // try std.testing.expect(!mset.has(Ty(64)));
    // try std.testing.expect(!mset.has(Ty(68)));
    // try std.testing.expect(mset.isEmpty());
    // const multi = comptime MarkerSet.MultiMask.init(.add, &.{Ty(1), Ty(2), Ty(64), Ty(68)});
    // try std.testing.expectEqual(multi.len, 2);
    qprintln("Pass");
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
