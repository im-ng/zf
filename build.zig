const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zf_mod = createZfModule(b, target, optimize);

    const exe = b.addExecutable(.{
        .name = "zf",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zf", .module = zf_mod },
            },
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const mod_tests = b.addTest(.{ .root_module = zf_mod });
    const exe_tests = b.addTest(.{ .root_module = exe.root_module });

    const suite_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/tests/test_suite.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zf", .module = zf_mod },
            },
        }),
    });

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&b.addRunArtifact(mod_tests).step);
    test_step.dependOn(&b.addRunArtifact(exe_tests).step);
    test_step.dependOn(&b.addRunArtifact(suite_tests).step);
}

fn createZfModule(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Module {
    _ = optimize;
    const info = b.createModule(.{ .root_source_file = b.path("src/info.zig") });

    const logos = b.createModule(.{ .root_source_file = b.path("src/logos.zig") });
    logos.addImport("info", info);

    const output = b.createModule(.{ .root_source_file = b.path("src/output.zig") });
    output.addImport("info", info);
    output.addImport("logos", logos);

    const cli = b.createModule(.{ .root_source_file = b.path("src/cli.zig") });
    cli.addImport("output", output);

    const linux_cpu = b.createModule(.{ .root_source_file = b.path("src/linux/cpu.zig") });
    linux_cpu.addImport("info", info);

    const linux_memory = b.createModule(.{ .root_source_file = b.path("src/linux/memory.zig") });
    linux_memory.addImport("info", info);

    const linux_os = b.createModule(.{ .root_source_file = b.path("src/linux/os.zig") });
    linux_os.addImport("info", info);

    const linux_utils = b.createModule(.{ .root_source_file = b.path("src/linux/utils.zig") });
    linux_utils.addImport("info", info);

    const linux_gpu = b.createModule(.{ .root_source_file = b.path("src/linux/gpu.zig") });

    const linux_packages = b.createModule(.{ .root_source_file = b.path("src/linux/packages.zig") });

    const linux_desktop = b.createModule(.{ .root_source_file = b.path("src/linux/desktop.zig") });
    linux_desktop.addImport("info", info);

    const linux = b.createModule(.{ .root_source_file = b.path("src/linux.zig") });
    linux.addImport("cpu", linux_cpu);
    linux.addImport("memory", linux_memory);
    linux.addImport("os", linux_os);
    linux.addImport("utils", linux_utils);
    linux.addImport("gpu", linux_gpu);
    linux.addImport("packages", linux_packages);
    linux.addImport("desktop", linux_desktop);

    const macos_cpu = b.createModule(.{ .root_source_file = b.path("src/macos/cpu.zig") });
    macos_cpu.addImport("info", info);

    const macos_memory = b.createModule(.{ .root_source_file = b.path("src/macos/memory.zig") });
    macos_memory.addImport("info", info);

    const macos_os = b.createModule(.{ .root_source_file = b.path("src/macos/os.zig") });
    macos_os.addImport("info", info);

    const macos_utils = b.createModule(.{ .root_source_file = b.path("src/macos/utils.zig") });
    macos_utils.addImport("info", info);

    const macos_gpu = b.createModule(.{ .root_source_file = b.path("src/macos/gpu.zig") });

    const macos_packages = b.createModule(.{ .root_source_file = b.path("src/macos/packages.zig") });

    const macos_desktop = b.createModule(.{ .root_source_file = b.path("src/macos/desktop.zig") });

    const macos = b.createModule(.{ .root_source_file = b.path("src/macos.zig") });
    macos.addImport("cpu", macos_cpu);
    macos.addImport("memory", macos_memory);
    macos.addImport("os", macos_os);
    macos.addImport("utils", macos_utils);
    macos.addImport("gpu", macos_gpu);
    macos.addImport("packages", macos_packages);
    macos.addImport("desktop", macos_desktop);

    const zf = b.addModule("zf", .{
        .root_source_file = b.path("src/zf.zig"),
        .target = target,
    });
    zf.addImport("info_mod", info);
    zf.addImport("logos_mod", logos);
    zf.addImport("output_mod", output);
    zf.addImport("cli_mod", cli);
    zf.addImport("linux_mod", linux);
    zf.addImport("macos_mod", macos);

    return zf;
}