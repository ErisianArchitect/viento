

pub fn StackVec(comptime T: type, comptime capacity: usize) type {
    return struct {
        const Self = @This();
        
        items: [capacity]T,
        len: usize,

        pub fn init() Self {
            return .{.items = undefined, .len = 0};
        }

        pub fn push(self: *Self, value: T) void {
            if (self.len == capacity) {
                if (@inComptime()) {
                    @compileError("Capacity reached on push.");
                } else {
                    @panic("Capacity reached on push.");
                }
            }
            self.items[self.len] = value;
            self.len += 1;
        }

        pub fn pop(self: *Self) ?T {
            if (self.len == 0) return null;
            self.len -= 1;
            return self.items[self.len];
        }
    };
}
