
const viento = @import("../root.zig");

const nombre = viento.name(.foo);

pub const ParamKind = union(enum) {
    injectable: type,
    resource: type,
    component: type,
};

pub fn Ref(comptime T: type) type {
    return extern struct {
        const Self = @This();
        
        ref: *const T,

        pub inline fn init(pointer: *const T) Self {
            return .{.ref = pointer};
        }
    };
}

pub fn Mut(comptime T: type) type {
    return extern struct {
        const Self = @This();
        
        ref: *T,

        pub inline fn init(pointer: *T) Self {
            return .{.ref = pointer};
        }
    };
}

pub fn Res(comptime T: type) type {
    return extern struct {
        const Self = @This();
        
        ref: *const T,

        pub inline fn init(pointer: *const T) Self {
            return .{.ref = pointer};
        }
    };
}

pub fn ResMut(comptime T: type) type {
    return extern struct {
        const Self = @This();
        
        ref: *T,

        pub inline fn init(pointer: *T) Self {
            return .{.ref = pointer};
        }
    };
}

pub const EntityId = extern struct {
    id: u64,
};

pub const World = struct {
    foo: u32,
    bar: u32,
    baz: u32,
};

pub const Vec3 = extern struct {
    x: f32,
    y: f32,
    z: f32,
};

pub const Quat = extern struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,
};

pub const Transform = extern struct {
    rot: Quat,
    pos: Vec3,
};

pub fn Captures(comptime captures: anytype) type {
    const type_info = @typeInfo(@TypeOf(captures));
    if (type_info != .@"struct" or !type_info.@"struct".is_tuple) {
        @compileError("Type must be a tuple.");
    }
    return struct {
        comptime { if (@sizeOf(@This()) != 0) @compileError("Not zst."); }
        
    };
}

pub fn Condition(comptime condition: anytype) type {
    const type_info = @typeInfo(@TypeOf(condition));
    if (type_info != .@"struct" or !type_info.@"struct".is_tuple) {
        @compileError("Type must be a tuple.");
    }
    return struct {
        const cond = condition;
        pub fn check() bool { return true; }
    };
}

const Physics = opaque {};

pub const expr = struct {
    pub fn eq(comptime a: anytype) fn(b: @TypeOf(a)) bool {
        return struct {
            pub fn equal(b: @TypeOf(a)) bool {
                return a == b;
            }
        }.equal;
    }

    pub fn fieldEq(comptime a: anytype, comptime field: @EnumLiteral()) fn(b: anytype) bool {
        return struct {
            pub fn equal(b: anytype) bool {
                return @field(b, @tagName(field)) == a;
            }
        }.equal;
    }
};

pub fn When(comptime expression: anytype) type {
    return struct {
        const expr = expression;
        pub fn eval() bool {
            return true;
        }
    };
}
