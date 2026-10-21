const std = @import("std");

// name.zig
pub const Name = struct {
    str: []const u8,

    pub fn eql(self: @This(), name: []const u8) bool {
        // not real code.
        return std.mem.eql(u8, self.str, name);
    }
};

// example_system.zig
pub const example_system = struct {

    // These markers specify that the entity must be killable,
    // and also that they are not immortal.
    //
    // Markers are like components, but are merely bit flags on an entity.
    // You use the `With` and `Without` wrappers to delineate between markers
    // that must be present, and markers that must be absent. There is not other
    // state. Markers do not prevent systems from running simultaneously if they both
    // require the same marker.
    pub const @"viento:system_markers" = &.{
        with(Killable),
        without(Immortal),
        withAny(&.{Foo, Bar, Baz}),
        withoutAny(&.{Oof, Rab, Zab}),
    };

    pub const @"system config" = VientoConfig(.{
        .markers = marker.query(&.{
            marker.any(&.{
                marker.query(&.{
                    marker.with(&.{Killable}),
                    marker.without(&.{Immortal}),
                }),
                marker.query(&.{
                    marker.with(&.{Destroyable}),
                    marker.without(&.{Indestructible}),
                }),
            }),
            marker.none(&.{
                marker.with(&.{Foo}),
            }),
        }),
    });

    // Conditions execute for every entity in a system.
    pub inline fn condition(
        name: Name,
    ) bool {
        return !name.eql("Fred");
    }

    // system function must be named `system`.
    // Mark system functions as inline so that they can be
    // inlined into the system runner.
    //
    // Order of parameters does not matter. They are injected
    // all the same.
    pub inline fn system(
        // injectables
        cmd: *CommandBuffer,
        entity: Entity,
        ecs: *Ecs,
        // resources
        world: *World,
        physics: *const Physics,
        // components
        npc: *const Npc,
        transform: *Transform,
        // events
        kill_event: KillEvent, // KillEvent is zero-sized, so no pointer is necessary.
        // queries
        npcs: Query(.{
            .row = struct {
                npc: *const Npc,
                transform: *const Transform,
            },
            .markers = &.{
                with(Killable),
                without(Immortal),
            },
            .condition = HasComponent(Human),
        }),
        // bundles
        // When a type is not recognized as an injectable type, the
        // fields will be scanned to see if they are all injectable.
        bundle: *const struct {
            // resources
            idk: Idk, // Params don't need to be pointers if you want the value to be injected.
            //components
            foo: *const Foo,
        },
    ) void {
        var npc_it = npcs.iter();
        while (npc_it.next()) |ent| {
            if (vec3.distanceSq(transform.pos, ent.transform.pos) <= 100.0) {
                cmd.destroyEntity(ent);
            }
        }
    }
}

