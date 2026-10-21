
Param Kinds:
- Resources
    Attached to the ECS itself.
    ```zig
    // Resource must not already exist in the ecs!
    ecs.addResource(some_resource);
    // ...
    // Resource must exist in the ecs!
    ecs.removeResource(some_resource);
    // Resource type must be registered to the ecs!
    ecs.hasResource(SomeResource);
    ```
- Components
    Attached to entities.
    ```zig
    ecs.entity(entity_id).addComponent(some_component);
    ```
- Events
    One shot events that execute a single time.
    They only exist on the entity for a single frame. Even if they
    are not consumed by a system, they are discarded.
    Events trigger all systems that they are applicable to for the frame that they are active.
    When an event is fired during a frame, the event is not processed until the following frame.
    #### Event Types
    - World
        Triggered for the entire world
        ```zig
        ecs.triggerEvent(some_event);
        ```
    - Entity
        Triggered for a single entity.
        ```zig
        ecs.entity(entity_id).triggerEvent(some_event);
        ```
    It should also be possible to target specific systems with events.
    ```zig
    ecs.triggerEventIn(some_event, .{some_system1, some_system2}); // the order the systems are specified would be the order that they are triggered.
    ecs.entity(entity_id).triggerEventIn(some_event, .{some_system1, some_system2});
    ```
- Markers
    Can be attached to entities like components, but are only attached as boolean flags.
    Systems that capture the same markers can be executed concurrently.
    Markers are simply types that the user registers into their ECS.
    ```zig
    pub const FooMarker = struct{};
    // ...
    ecs.entities.addMarker(entity_id, FooMarker);
    // ...
    ecs.entities.removeMarker(entity_id, FooMarker);
    // ...
    _ = ecs.entities.markers(); // Get a list of the active markers.
    ```
- Queries
    Used to query rows of system Params.
- Injectables
    These are other values that can also be injected into a system call.
    Things such as the Entity ID, a reference to the ecs, a reference to the system (perhaps),
    or some other user-defined injectable. These injectables can be raw values rather than
    pointers. `EntityId`, `DeltaTime`, or `EcsRef` are examples of types that may be inejected.
