const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const info_mod = b.createModule(.{ .root_source_file = b.path("src/info.zig") });
    const logos_mod = b.createModule(.{ .root_source_file = b.path("src/logos.zig") });
    logos_mod.addImport("info", info_mod);

    const output_mod = b.createModule(.{ .root_source_file = b.path("src/output.zig") });
    output_mod.addImport("info", info_mod);
    output_mod.addImport("logos", logos_mod);

    const cli_mod = b.createModule(.{ .root_source_file = b.path("src/cli.zig") });
    cli_mod.addImport("output", output_mod);

    const linux_cpu_mod = b.createModule(.{ .root_source_file = b.path("src/linux/cpu.zig") });
    linux_cpu_mod.addImport("info", info_mod);

    const linux_memory_mod = b.createModule(.{ .root_source_file = b.path("src/linux/memory.zig") });
    linux_memory_mod.addImport("info", info_mod);

    const linux_os_mod = b.createModule(.{ .root_source_file = b.path("src/linux/os.zig") });
    linux_os_mod.addImport("info", info_mod);

    const linux_utils_mod = b.createModule(.{ .root_source_file = b.path("src/linux/utils.zig") });
    linux_utils_mod.addImport("info", info_mod);

    const linux_gpu_mod = b.createModule(.{ .root_source_file = b.path("src/linux/gpu.zig") });

    const linux_packages_mod = b.createModule(.{ .root_source_file = b.path("src/linux/packages.zig") });

    const linux_desktop_mod = b.createModule(.{ .root_source_file = b.path("src/linux/desktop.zig") });
    linux_desktop_mod.addImport("info", info_mod);

    const linux_mod = b.createModule(.{ .root_source_file = b.path("src/linux.zig") });
    linux_mod.addImport("cpu", linux_cpu_mod);
    linux_mod.addImport("memory", linux_memory_mod);
    linux_mod.addImport("os", linux_os_mod);
    linux_mod.addImport("utils", linux_utils_mod);
    linux_mod.addImport("gpu", linux_gpu_mod);
    linux_mod.addImport("packages", linux_packages_mod);
    linux_mod.addImport("desktop", linux_desktop_mod);

    const macos_cpu_mod = b.createModule(.{ .root_source_file = b.path("src/macos/cpu.zig") });
    macos_cpu_mod.addImport("info", info_mod);

    const macos_memory_mod = b.createModule(.{ .root_source_file = b.path("src/macos/memory.zig") });
    macos_memory_mod.addImport("info", info_mod);

    const macos_os_mod = b.createModule(.{ .root_source_file = b.path("src/macos/os.zig") });
    macos_os_mod.addImport("info", info_mod);

    const macos_utils_mod = b.createModule(.{ .root_source_file = b.path("src/macos/utils.zig") });
    macos_utils_mod.addImport("info", info_mod);

    const macos_gpu_mod = b.createModule(.{ .root_source_file = b.path("src/macos/gpu.zig") });

    const macos_packages_mod = b.createModule(.{ .root_source_file = b.path("src/macos/packages.zig") });

    const macos_desktop_mod = b.createModule(.{ .root_source_file = b.path("src/macos/desktop.zig") });

    const macos_mod = b.createModule(.{ .root_source_file = b.path("src/macos.zig") });
    macos_mod.addImport("cpu", macos_cpu_mod);
    macos_mod.addImport("memory", macos_memory_mod);
    macos_mod.addImport("os", macos_os_mod);
    macos_mod.addImport("utils", macos_utils_mod);
    macos_mod.addImport("gpu", macos_gpu_mod);
    macos_mod.addImport("packages", macos_packages_mod);
    macos_mod.addImport("desktop", macos_desktop_mod);

    const lib_mod = b.addModule("zf", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });
    lib_mod.addImport("info", info_mod);
    lib_mod.addImport("logos", logos_mod);
    lib_mod.addImport("output", output_mod);
    lib_mod.addImport("cli", cli_mod);
    lib_mod.addImport("linux", linux_mod);
    lib_mod.addImport("macos", macos_mod);

    const exe = b.addExecutable(.{
        .name = "zf",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zf", .module = lib_mod },
                .{ .name = "info", .module = info_mod },
                .{ .name = "cli", .module = cli_mod },
                .{ .name = "output", .module = output_mod },
                .{ .name = "linux", .module = linux_mod },
                .{ .name = "macos", .module = macos_mod },
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

    const mod_tests = b.addTest(.{
        .root_module = lib_mod,
    });

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const suite_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/tests/test_suite.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    suite_tests.root_module.addImport("info", info_mod);
    suite_tests.root_module.addImport("cli", cli_mod);
    suite_tests.root_module.addImport("output", output_mod);
    suite_tests.root_module.addImport("logos", logos_mod);
    suite_tests.root_module.addImport("linux_cpu", linux_cpu_mod);
    suite_tests.root_module.addImport("linux_memory", linux_memory_mod);
    suite_tests.root_module.addImport("linux_os", linux_os_mod);
    suite_tests.root_module.addImport("linux_utils", linux_utils_mod);
    suite_tests.root_module.addImport("macos_os", macos_os_mod);

    const run_mod_tests = b.addRunArtifact(mod_tests);
    const run_exe_tests = b.addRunArtifact(exe_tests);
    const run_suite_tests = b.addRunArtifact(suite_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
    test_step.dependOn(&run_suite_tests.step);
}