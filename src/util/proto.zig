// =============================================================
// Prototypes determine what types can safely convert between
// each other. If two types have intersecting prototypes, that
// means that they can safely be converted to each other.
// =============================================================

const std = @import("std");

const SourceLocation = std.builtin.SourceLocation;

pub const PrototypeError = error {
    MissingPrototypeField,
    PrototypeFieldNotAPrototype,
    PrototypeMismatch,
};

pub inline fn prototypeErrorMsg(err: PrototypeError) []const u8 {
    return switch (err) {
        PrototypeError.MissingPrototypeField => "Missing PROTOTYPE field.",
        PrototypeError.PrototypeFieldNotAPrototype => "PROTOTYPE field is not a prototype.",
        PrototypeError.PrototypeMismatch => "Prototype did not match.",
    };
}

pub inline fn prototypeCompileError(comptime err: PrototypeError) void {
    comptime @compileError(prototypeErrorMsg(err));
}

const FILE = struct { fn source() SourceLocation { return @src(); } }.source().file;

pub const PrototypeTag = struct {
    const Self = @This();
    
    markers: []const type,

    pub inline fn init(comptime markers: []const type) Self {
        comptime return .{.markers=markers};
    }

    pub fn intersects(self: Self, other: Self) bool {
        comptime {
            for (self.markers) |marker_a| {
                for (other.markers) |marker_b| {
                    if (marker_a == marker_b) {
                        return true;
                    }
                }
            }
            return false;
        }
    }
};

pub const Prototype = struct {
    const Self = @This();

    pub const PROTOTYPE = Prototype.create(.PROTOTYPE, .{Self});

    const_name: []const u8,
    tag: PrototypeTag,

    pub fn create(comptime const_name: @EnumLiteral(), comptime tag: []const type) Prototype {
        comptime return .{
            .const_name = @tagName(const_name),
            .tag = PrototypeTag.init(tag),
        };
    }

    pub fn checkPrototype(self: Self, comptime T: type) PrototypeError!void {
        comptime {
            if (!@hasDecl(T, self.const_name)) return PrototypeError.MissingPrototypeField;
            if (@TypeOf(@field(T, self.const_name)) != Self) return PrototypeError.PrototypeFieldNotAPrototype;
            if (!self.tag.intersects(@field(T, self.const_name).tag)) return PrototypeError.PrototypeMismatch;
        }
    }

    pub fn isPrototypeOfType(self: Self, comptime T: type) bool {
        comptime {
            self.checkPrototype(T) catch return false;
            return true;
        }
    }

    pub fn assertPrototype(self: Self, comptime T: type) void {
        comptime {
            self.checkPrototype(T) catch |err| prototypeCompileError(err);
        }
    }

    pub fn assertPrototypeOf(self: Self, value: anytype) void {
        comptime self.assertPrototype(@TypeOf(value));
    }
};
