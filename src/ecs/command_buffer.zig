

pub fn CommandBuffer() type {
    return struct {
        const Self = @This();
        
        pub fn buildEntity(self: *Self) void {}
        pub fn createEntity(self: *Self, name: ?[]const u8) u64 {}
        pub fn removeEntity(self: *Self, id: u64) void {}
        pub fn sendEvent(self: *Self, event: anytype) void {}

        pub fn entity(self: *Self, id: u64) void {}
        
    };
}
