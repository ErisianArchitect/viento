

pub fn foo_system(
    // injectables
    cmd: *CommandBuffer,
    entity: Entity,
    dt: DeltaTime,
    // resources
    world: *const World,
    physics: *Physics,
    // components
    transform: *Transform,
    collider: *const Collider,
    // events
    kill_event: KillEvent,
    // events cannot be mutable, because they may be used on multiple threads.
    world_event: *const WorldEvent,
    // queries
    npc_query: Query(struct {
        entity: Entity,
        npc: *const Npc,

        pub const @"viento:query_markers" = q.all(&.{
            q.with(Killable),
            q.without(Immortal),
        });

        pub inline fn @"viento:query_filter"(
            // Use a SystemParam to extract a parameter from the system row.
            system_entity: SystemParam(Entity),
            entity: Entity,
            name: *const Name,
            // QueryArg can be used to take arguments 
            input: QueryArg(struct {
                entity: Entity,
            }),
        ) bool {
            if (input.entity == entity) return false;
            if (name.eql("Fred")) return false;
            return true;
        }
    }),
) void {
    
}
