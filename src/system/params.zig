
const core = @import("core");

pub const ParamKind = enum(u8) {
    Resource,
    Component,
    Event,
    Marker,
    Query,
    Injectable,
};
