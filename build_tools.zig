
const std = @import("std");

const Module = std.Build.Module;
const Import = std.Build.Module.Import;

pub fn connectModules(modules: []const Import) void {
    for (modules) |a| {
        for (modules) |b| {
            a.module.addImport(b.name, b.module);
        }
    }
}
