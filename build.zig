const std = @import("std");

const build_tools = @import("build_tools/root.zig");

const Build = std.Build;

const project = build_tools.project;

const Module = Build.Module;
const Import = Build.Module.Import;

const Project = project.Project;
const Imports = project.BuildCheckImports;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const root_create_opts: Module.CreateOptions = .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    };

    var imports = Imports(16).init();
    const proj = Project.init(b);

    const build_root = b.addModule("viento", root_create_opts);
    const check_root = b.addModule("viento_check", root_create_opts);

    imports.connect("viento", build_root, check_root);

    imports.connectDuped("core", proj.dupedCreateModule(2, .{
        .root_source_file = b.path("src/core/root.zig"),
        .target = target,
        .optimize = optimize,
    }));

    imports.connectDuped("util", proj.dupedCreateModule(2, .{
        .root_source_file = b.path("src/util/root.zig"),
        .target = target,
        .optimize = optimize,
    }));
    
    imports.connectDuped("ecs", proj.dupedCreateModule(2, .{
        .root_source_file = b.path("src/ecs/root.zig"),
        .target = target,
        .optimize = optimize,
    }));

    imports.connectDuped("system", proj.dupedCreateModule(2, .{
        .root_source_file = b.path("src/system/root.zig"),
        .target = target,
        .optimize = optimize,
    }));

    imports.connectDuped("dsa", proj.dupedCreateModule(2, .{
        .root_source_file = b.path("src/dsa/root.zig"),
        .target = target,
        .optimize = optimize,
    }));

    const exe = b.addExecutable(.{
        .name = "viento",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = imports.build.slice(),
        }),
    });
    
    const check_exe = b.addExecutable(.{
        .name = "viento-check",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = imports.check.slice(),
        }),
    });
    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    
    const check_step = b.step("check", "Check the compilation.");
    check_step.dependOn(&check_exe.step);
    const mod_tests = b.addTest(.{
        .root_module = build_root,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
