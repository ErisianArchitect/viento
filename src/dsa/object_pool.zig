
const std = @import("std");

const util = @import("util");

const isit = util.isit;

const Vec = std.ArrayListUnmanaged;

const Allocator = std.mem.Allocator;

pub fn ObjectId(comptime marker: anytype) type {
    return extern struct {
        pub const MARKER = marker;

        const Self = @This();
    
        id: u32,
        generation: u32,

        pub inline fn init(id: u32, generation: u32) Self {
            return .{.id = id, .generation = generation};
        }

        pub inline fn incrGeneration(self: Self) Self {
            self.generation +%= 1;
            return self;
        }
    };
}

pub fn ObjectPoolUnmanaged(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const Id = ObjectId(Self);
        
        pool: Vec(T),
        index: Vec(u32),
        free: Vec(Id),

        pub fn initCapacity(alloc: Allocator, capacity: usize) Self {
            return .{
                .pool = .initCapacity(alloc, capacity),
                .index = .initCapacity(alloc, capacity),
                .free = .initCapacity(alloc, 0),
            };
        }

        pub fn init(alloc: Allocator) Self {
            return .initCapacity(alloc, 0);
        }

        pub fn get(self: *const Self, id: Id) *const T {
            isit.unimplemented(.{self, id}, null);
        }

        pub fn getMut(self: *Self, id: Id) *T {
            isit.unimplemented(.{self, id}, null);
        }

        pub fn insert(self: *Self, alloc: Allocator, value: T) Id {
            isit.unimplemented(.{self, alloc, value}, null);
        }

        pub fn remove(self: *Self, id: Id) T {
            isit.unimplemented(.{self, id}, null);
        }

    };
}
