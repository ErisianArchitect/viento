
pub const params = @import("params.zig");
pub const core = @import("core");

const util = @import("util");

const Prototype = util.Prototype;

// const foo_system = struct {
//     pub const markers: []const Marker = &.{
//         with(Foo),
//         without(Bar),
//     };
// }

pub fn System(comptime Sys: type) type {
    
}
