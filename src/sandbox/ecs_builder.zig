
pub const EcsBuilderConfig = struct {
    const Self = @This();
    pub const Required = opaque{};
    resources: type = void,
    components: type = void,
    events: type = void,
    markers: type = void,
    queries: type = void,
    injectables:  type = void,

    fn withField(comptime self: Self, comptime field_name: @EnumLiteral(), comptime T: type) Self {
        var new = self;
        @field(new, @tagName(field_name)) = T;
        return new;
    }

    pub fn withResourceList(comptime self: Self, comptime T: type) Self {
        return self.withField(.resources, T);
    }

    pub fn withComponentList(comptime self: Self, comptime T: type) Self {
        return self.withField(.components, T);
    }

    pub fn withEventList(comptime self: Self, comptime T: type) Self {
        return self.withField(.events, T);
    }

    pub fn withMarkerList(comptime self: Self, comptime T: type) Self {
        return self.withField(.markers, T);
    }

    pub fn withQueryList(comptime self: Self, comptime T: type) Self {
        return self.withField(.queries, T);
    }

    pub fn withInjectableList(comptime self: Self, comptime T: type) Self {
        return self.withField(.injectables, T);
    }
};

pub fn Ecs(comptime builder: EcsBuilder(.{}).Complete) type {
    return struct {
        const _builder = builder;
        pub fn foo() void {
            qprintln("foo!");
        }
    };
}

pub fn EcsBuilder(
    comptime cfg: EcsBuilderConfig,
) type {
    return struct {
        const Self = @This();
        const CFG = cfg;
        const Complete = EcsBuilder(.{
            .resources = []const type,
            .components = []const type,
            .events = []const type,
            .markers = []const type,
            .queries = []const type,
            .injectables = []const type,
        });
        const incomplete_fields = blk: {
            var count = 0;
            for (std.meta.fields(Self)) |f| {
                if (@FieldType(Self, f.name) == void) {
                    count += 1;
                }
            }
            var result: [count][]const u8 = undefined;
            var i = 0;
            for (std.meta.fields(Self)) |f| {
                if (@FieldType(Self, f.name) == void) {
                    result[i] = f.name;
                    i += 1;
                }
            }
            break :blk result;
        };
        const incomplete_field_string = joinSlices(.immut, u8, ", ", &incomplete_fields);

        resources: CFG.resources = undefined,
        components: CFG.components = undefined,
        events: CFG.events = undefined,
        markers: CFG.markers = undefined,
        queries: CFG.queries = undefined,
        injectables: CFG.injectables = undefined,

        pub fn init() Self {
            return .{};
        }

        pub fn With(comptime field_name: @EnumLiteral()) type {
            const new_cfg = CFG.withField(field_name, []const type);
            return EcsBuilder(new_cfg);
        }

        pub fn withField(
            comptime self: Self,
            comptime field_name: @EnumLiteral(),
            comptime type_list: []const type
        ) With(field_name) {
            const NewType = With(field_name);
            var uninit: NewType = .{};
            inline for(std.meta.fields(NewType)) |f| {
                if (std.mem.eql(u8, f.name, @tagName(field_name))) {
                    @field(uninit, f.name) = type_list;
                } else {
                    @field(uninit, f.name) = @field(self, f.name);
                }
            }
            return uninit;
        }

        pub fn withResources(comptime self: Self, comptime type_list: []const type) With(.resources) {
            return self.withField(.resources, type_list);
        }

        pub fn withComponents(comptime self: Self, comptime type_list: []const type) With(.components) {
            return self.withField(.components, type_list);
        }

        pub fn withEvents(comptime self: Self, comptime type_list: []const type) With(.events) {
            return self.withField(.events, type_list);
        }

        pub fn withMarkers(comptime self: Self, comptime type_list: []const type) With(.markers) {
            return self.withField(.markers, type_list);
        }

        pub fn withQueries(comptime self: Self, comptime type_list: []const type) With(.queries) {
            return self.withField(.queries, type_list);
        }

        pub fn withInjectables(comptime self: Self, comptime type_list: []const type) With(.injectables) {
            return self.withField(.injectables, type_list);
        }

        pub const build = blk: {
            if (Self == Complete) {
                break :blk struct {
                    pub fn buildfn(comptime self: Complete) type {
                        return Ecs(self);
                    }
                }.buildfn;
            } else {
                break :blk struct {
                    pub fn buildfn(comptime _: Self) noreturn {
                        @compileError(std.fmt.comptimePrint("Missing builder fields: {s}", .{incomplete_field_string}));
                    }
                }.buildfn;
            }
        };
    };
}
