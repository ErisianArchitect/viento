
const markerset = @import("markerset.zig");
pub const marker = @import("marker.zig");

const util = @import("util");

const TypeMap = util.typemap.StaticTypeMap;
const TypeSet = util.typemap.StaticTypeSet;

pub const MarkerSet = markerset.MarkerSet;

// { key, value }
pub const TypeKV = struct { type, type };

pub const TypeKVs = []const TypeKV;

pub const EcsTypes = struct {
    components: TypeKVs,
    resources: TypeKVs   = &.{},
    events: TypeKVs      = &.{},
    markers: TypeKVs     = &.{},
    queries: TypeKVs     = &.{},
    injectables: TypeKVs = &.{},
};

pub const EcsSystems = struct {
    systems: []const type,
};

pub const EcsConfig = struct {
    types: EcsTypes,
    systems: EcsSystems,
};

pub fn Ecs() type {
    
}
