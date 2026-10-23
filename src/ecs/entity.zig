
const dsa = @import("dsa");

const ObjectId = dsa.object_pool.ObjectId;
const ObjectPool = dsa.object_pool.ObjectPoolUnmanaged;

pub const Entity = extern struct {
    const Self = @This();
    
    obj_id: ObjectId,

    pub inline fn init(entity_id: u32, entity_generation: u32) Self {
        return .{.obj_id = .{.id = entity_id, .generation = entity_generation}};
    }

    pub inline fn id(self: Self) u32 {
        return self.obj_id.id;
    }

    pub inline fn generation(self: Self) u32 {
        return self.obj_id.generation;
    }

    pub inline fn index(self: Self) usize {
        return self.obj_id.id;
    }
};
