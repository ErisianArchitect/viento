
const std = @import("std");

const util = @import("util");

const markerset = @import("markerset.zig");

const stackvec = util.stackvec;
const comp = util.comp;

pub const MarkerSet = markerset.MarkerSet;

const StackVec = stackvec.StackVec;

const CallMod = std.lang.CallModifier;

pub const MarkerQuery = union(enum) {
    const Self = @This();

    With: type,
    Without: type,
    WithAny: []const type,
    WithAll: []const type,
    WithoutAny: []const type,
    WithoutAll: []const type,
    Any: []const MarkerQuery,
    All: []const MarkerQuery,
    None: []const MarkerQuery,

    fn participantCount(comptime self: Self) usize {
        return struct {
            pub const result = ret: {
                @setEvalBranchQuota(std.math.maxInt(u32));
                switch (self) {
                    .With => break :ret 1,
                    .Without => break :ret 1,
                    .WithAny => |sub| break :ret sub.len,
                    .WithAll => |sub| break :ret sub.len,
                    .WithoutAny => |sub| break :ret sub.len,
                    .WithoutAll => |sub| break :ret sub.len,
                    .Any => |sub| {
                        var count = 0;
                        for (sub) |m| {
                            count += m.participantCount();
                        }
                        break :ret count;
                    },
                    .All => |sub| {
                        var count = 0;
                        for (sub) |m| {
                            count += m.participantCount();
                        }
                        break :ret count;
                    },
                    .None => |sub| {
                        var count = 0;
                        for (sub) |m| {
                            count += m.participantCount();
                        }
                        break :ret count;
                    }
                }
            };
        }.result;
    }

    fn addParticipants(comptime self: Self, list: anytype) void {
        @setEvalBranchQuota(std.math.maxInt(u32));
        switch (self) {
            .With => |t| list.push(t),
            .Without => |t| list.push(t),
            .WithAny => |sub| {
                for (sub) |s| {
                    list.push(s);
                }
            },
            .WithAll => |sub| {
                for (sub) |s| {
                    list.push(s);
                }
            },
            .WithoutAny => |sub| {
                for (sub) |s| {
                    list.push(s);
                }
            },
            .WithoutAll => |sub| {
                for (sub) |s| {
                    list.push(s);
                }
            },
            .Any => |sub| {
                for (sub) |s| {
                    s.addParticipants(list);
                }
            },
            .All => |sub| {
                for (sub) |s| {
                    s.addParticipants(list);
                }
            },
            .None => |sub| {
                for (sub) |s| {
                    s.addParticipants(list);
                }
            }
        }
    }

    pub fn participants(comptime self: Self) []const type {
        return struct {
            pub const result = ret: {
                @setEvalBranchQuota(std.math.maxInt(u32));
                switch (self) {
                    .With => |t| break :ret comp.internArray(.immut, type, .{t}),
                    .Without => |t| break :ret comp.internArray(.immut, type, .{t}),
                    .WithAny => |sub| break :ret sub,
                    .WithAll => |sub| break :ret sub,
                    .WithoutAny => |sub| break :ret sub,
                    .WithoutAll => |sub| break :ret sub,
                    .Any => |sub| {
                        var list = StackVec(type, self.participantCount()).init();
                        for (sub) |m| {
                            m.addParticipants(&list);
                        }
                        break :ret comp.internArray(.immut, type, comp.dedup(type, list.items));
                    },
                    .All => |sub| {
                        var list = StackVec(type, self.participantCount()).init();
                        for (sub) |m| {
                            m.addParticipants(&list);
                        }
                        break :ret comp.internArray(.immut, type, comp.dedup(type, list.items));
                    },
                    .None => |sub| {
                        var list = StackVec(type, self.participantCount()).init();
                        for (sub) |m| {
                            m.addParticipants(&list);
                        }
                        break :ret comp.internArray(.immut, type, comp.dedup(type, list.items));
                    },
                }
            };
        }.result;
    }

    pub const CfgEvalMod = enum {
        auto,
        never_inline,
        always_inline,

        pub fn callModifier(comptime self: @This()) CallMod {
            return switch (comptime self) {
                .auto => .auto,
                .never_inline => .never_inline,
                .always_inline => .always_inline,
            };
        }
    };

    pub fn cfgEval(comptime self: Self, comptime modifier: CfgEvalMod, set: anytype) bool {
        const callmod = comptime modifier.callModifier();
        const Set = blk: {
            const SetT = @TypeOf(set);
            const inf = @typeInfo(SetT);
            if (inf == .pointer) {
                break :blk inf.pointer.child;
            } else {
                @compileError("Expected pointer");
            }
        };
        @setEvalBranchQuota(std.math.maxInt(u32));
        switch (comptime self) {
            .With => |t| return @call(callmod, Set.has, .{set, t}),
            .Without => |t| return !@call(callmod, Set.has, .{set, t}),
            .WithAny => |sub| return @call(callmod, Set.hasAny, .{set, sub}),
            .WithAll => |sub| return @call(callmod, Set.hasAll, .{set, sub}),
            .WithoutAny => |sub| return @call(callmod, Set.missingAny, .{set, sub}),
            .WithoutAll => |sub| return @call(callmod, Set.missingAll, .{set, sub}),
            .Any => |sub| {
                inline for (sub) |q| {
                    if (q.cfgEval(modifier, set)) return true;
                }
                return false;
            },
            .All => |sub| {
                inline for (sub) |q| {
                    if (!q.cfgEval(modifier, set)) return false;
                }
                return true;
            },
            .None => |sub| {
                inline for (sub) |q| {
                    if (q.cfgEval(modifier, set)) return false;
                }
                return true;
            },
        }
    }

    pub fn eval(comptime self: Self, set: anytype) bool {
        return @call(.always_inline, cfgEval, .{self, .auto, set});
    }

    pub inline fn with(comptime T: type) Self {
        return .{.With = T};
    }

    pub inline fn without(comptime T: type) Self {
        return .{.Without = T};
    }

    pub inline fn withAny(comptime markers: []const type) Self {
        return .{.WithAny = markers};
    }

    pub inline fn withAll(comptime markers: []const type) Self {
        return .{.WithAll = markers};
    }

    pub inline fn withoutAny(comptime markers: []const type) Self {
        return .{.WithoutAny = markers};
    }

    pub inline fn withoutAll(comptime markers: []const type) Self {
        return .{.WithoutAll = markers};
    }

    pub inline fn any(comptime subqueries: []const Self) Self {
        return .{.Any = subqueries};
    }

    pub inline fn all(comptime subqueries: []const Self) Self {
        return .{.All = subqueries};
    }

    pub inline fn none(comptime subqueries: []const Self) Self {
        return .{.None = subqueries};
    }

    pub inline fn not(comptime self: Self) Self {
        return switch (comptime self){
            .With => |t| .{.Without = t},
            .Without => |t| .{.With = t},
            .WithAny => |sub| .{.WithoutAll = sub},
            .WithAll => |sub| .{.WithoutAll = sub},
            .WithoutAny => |sub| .{.WithAll = sub},
            .WithoutAll => |sub| .{.WithAll = sub},
            .Any => |sub| .{.None = sub},
            .All => |sub| .{.None = sub},
            .None => |sub| .{.Any = sub},
        };
    }
};
