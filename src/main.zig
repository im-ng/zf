const std = @import("std");
const builtin = @import("builtin");

const zf = @import("zf");

pub fn main() !u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = std.process.argsAlloc(allocator) catch {
        std.debug.print("Error: failed to allocate arguments\n", .{});
        return 1;
    };
    defer std.process.argsFree(allocator, args);

    var parsed_args: zf.Args = .{ .show_info = true };
    if (args.len > 1) {
        parsed_args = zf.cli.parseArgs(args[1..]) catch {
            std.debug.print("Error: invalid argument. Use --help for usage.\n", .{});
            return 2;
        };
    }

    if (parsed_args.show_help) {
        var out_buf: [4096]u8 = undefined;
        var out = std.fs.File.stdout().writer(&out_buf);
        try zf.cli.printHelp(&out.interface);
        try std.Io.Writer.flush(&out.interface);
        return 0;
    }

    if (parsed_args.show_version) {
        var out_buf: [256]u8 = undefined;
        var out = std.fs.File.stdout().writer(&out_buf);
        try zf.cli.printVersion(&out.interface);
        try std.Io.Writer.flush(&out.interface);
        return 0;
    }

    const display_flags = zf.cli.argsToDisplayFlags(parsed_args);
    const is_linux = builtin.os.tag == .linux;

    var sys: zf.SystemInfo = blk: {
        if (is_linux) {
            break :blk try gatherLinuxInfo(allocator);
        } else if (builtin.os.tag == .macos) {
            break :blk gatherMacosInfo(allocator);
        } else {
            std.debug.print("Error: unsupported platform\n", .{});
            return 1;
        }
    };
    defer sys.deinit();

    const result = zf.output.formatOutput(allocator, sys, display_flags, is_linux) catch |err| {
        std.debug.print("Error formatting output: {}\n", .{err});
        return 1;
    };
    defer allocator.free(result);

    var out_buf: [8192]u8 = undefined;
    var out = std.fs.File.stdout().writer(&out_buf);
    out.interface.writeAll(result) catch {
        return 1;
    };
    try std.Io.Writer.flush(&out.interface);

    return 0;
}

fn gatherLinuxInfo(allocator: std.mem.Allocator) !zf.SystemInfo {
    var sys: zf.SystemInfo = .{ .allocator = allocator };

    var cpu_buf: [16384]u8 = undefined;
    if (zf.info.readSmallFile("/proc/cpuinfo", &cpu_buf)) |contents| {
        var cpu = zf.linux.cpu.getCpuInfoFromString(allocator, contents);
        defer {
            cpu.cpu_vendor = null;
            cpu.cpu_family = null;
            cpu.cpu_model = null;
            cpu.cpu_model_name = null;
            cpu.microcode = null;
            cpu.l1_cache = null;
            cpu.l2_cache = null;
            cpu.l3_cache = null;
            cpu.cpu_arch = null;
            cpu.deinit();
        }
        sys.cpu_vendor = cpu.cpu_vendor;
        sys.cpu_family = cpu.cpu_family;
        sys.cpu_model = cpu.cpu_model;
        sys.cpu_model_name = cpu.cpu_model_name;
        sys.cpu_cores = cpu.cpu_cores;
        sys.cpu_speed = cpu.cpu_speed;
        sys.microcode = cpu.microcode;
        sys.l1_cache = cpu.l1_cache;
        sys.l2_cache = cpu.l2_cache;
        sys.l3_cache = cpu.l3_cache;
        sys.cpu_arch = cpu.cpu_arch;
    }

    var mem_buf: [8192]u8 = undefined;
    if (zf.info.readSmallFile("/proc/meminfo", &mem_buf)) |contents| {
        const mem = zf.linux.memory.getMemoryInfoFromString(allocator, contents);
        sys.total_memory = mem.total_memory;
        sys.free_memory = mem.free_memory;
    }

    var os_buf: [4096]u8 = undefined;
    if (zf.info.readSmallFile("/etc/os-release", &os_buf)) |contents| {
        zf.linux.os.parseOsRelease(allocator, &sys, contents);
    }

    var hostname_buf: [256]u8 = undefined;
    if (zf.info.readSmallFile("/etc/hostname", &hostname_buf)) |contents| {
        const trimmed = std.mem.trim(u8, contents, " \t\n\r");
        if (trimmed.len > 0) {
            sys.hostname = allocator.dupe(u8, trimmed) catch null;
        }
    }

    var version_buf: [1024]u8 = undefined;
    if (zf.info.readSmallFile("/proc/version", &version_buf)) |contents| {
        const prefix = "Linux version ";
        if (std.mem.startsWith(u8, contents, prefix)) {
            const rest = contents[prefix.len..];
            const space = std.mem.indexOfScalar(u8, rest, ' ') orelse contents.len;
            sys.kernel = allocator.dupe(u8, rest[0..space]) catch null;
        }
    }

    var uptime_buf: [128]u8 = undefined;
    if (zf.info.readSmallFile("/proc/uptime", &uptime_buf)) |contents| {
        sys.uptime = zf.info.parseUptime(contents);
    }

    sys.gpu = zf.linux.gpu.getGpuInfo(allocator);
    sys.packages = zf.linux.packages.getPackages(allocator);
    sys.de = zf.linux.desktop.getDe(allocator);
    sys.wm = zf.linux.desktop.getWm(allocator);

    if (std.posix.getenv("USER")) |user| {
        sys.user = allocator.dupe(u8, user) catch null;
    }
    if (std.posix.getenv("SHELL")) |shell| {
        sys.shell = getShellWithVersion(allocator, shell);
    }
    if (std.posix.getenv("TERM")) |term| {
        sys.terminal = allocator.dupe(u8, term) catch null;
    }

    var cwd_buf: [std.posix.PATH_MAX]u8 = undefined;
    if (std.posix.getcwd(&cwd_buf)) |cwd| {
        sys.cwd = allocator.dupe(u8, cwd) catch null;
    } else |_| {}

    if (sys.kernel == null) {
        const uts = std.posix.uname();
        const release = std.mem.sliceTo(&uts.release, 0);
        sys.kernel = allocator.dupe(u8, release) catch null;
    }

    if (sys.hostname == null) {
        const uts = std.posix.uname();
        const node = std.mem.sliceTo(&uts.nodename, 0);
        sys.hostname = allocator.dupe(u8, node) catch null;
    }

    if (sys.os_name == null) {
        var lsb_buf: [4096]u8 = undefined;
        if (zf.info.readSmallFile("/etc/lsb-release", &lsb_buf)) |contents| {
            zf.linux.os.parseLsbRelease(allocator, &sys, contents);
        }
    }

    if (sys.distro_id == null) {
        sys.distro_id = allocator.dupe(u8, "linux") catch null;
    }

    if (sys.cpu_arch == null) {
        sys.cpu_arch = allocator.dupe(u8, @tagName(builtin.cpu.arch)) catch null;
    }

    return sys;
}

fn gatherMacosInfo(allocator: std.mem.Allocator) zf.SystemInfo {
    var sys: zf.SystemInfo = .{ .allocator = allocator };

    {
        var cpu = zf.macos.cpu.getCpuInfo(allocator);
        defer {
            cpu.cpu_vendor = null;
            cpu.cpu_family = null;
            cpu.cpu_model = null;
            cpu.cpu_model_name = null;
            cpu.cpu_arch = null;
            cpu.l1_cache = null;
            cpu.l2_cache = null;
            cpu.l3_cache = null;
            cpu.deinit();
        }
        sys.cpu_vendor = cpu.cpu_vendor;
        sys.cpu_family = cpu.cpu_family;
        sys.cpu_model = cpu.cpu_model;
        sys.cpu_model_name = cpu.cpu_model_name;
        sys.cpu_cores = cpu.cpu_cores;
        sys.cpu_speed = cpu.cpu_speed;
        sys.cpu_arch = cpu.cpu_arch;
        sys.l1_cache = cpu.l1_cache;
        sys.l2_cache = cpu.l2_cache;
        sys.l3_cache = cpu.l3_cache;
    }

    const mem = zf.macos.memory.getMemoryInfo(allocator);
    sys.total_memory = mem.total_memory;
    sys.free_memory = mem.free_memory;

    {
        var os_info = zf.macos.os.getOsInfo(allocator);
        defer {
            os_info.os_name = null;
            os_info.os_version = null;
            os_info.kernel = null;
            os_info.hostname = null;
            os_info.distro_id = null;
            os_info.deinit();
        }
        sys.os_name = os_info.os_name;
        sys.os_version = os_info.os_version;
        sys.kernel = os_info.kernel;
        sys.hostname = os_info.hostname;
        sys.distro_id = os_info.distro_id;
    }

    {
        var util = zf.macos.utils.getSystemInfo(allocator);
        const env_shell = std.posix.getenv("SHELL");
        if (env_shell != null) {
            // getShellWithVersion creates a new allocation; free util.shell since it's orphaned
            if (util.shell) |s| allocator.free(s);
        }
        sys.shell = if (env_shell) |s| getShellWithVersion(allocator, s) else util.shell;
        sys.user = util.user;
        sys.terminal = util.terminal;
        sys.cwd = util.cwd;
        sys.uptime = util.uptime;
        util.shell = null;
        util.user = null;
        util.terminal = null;
        util.cwd = null;
        util.deinit();
    }

    sys.gpu = zf.macos.gpu.getGpuInfo(allocator);
    sys.packages = zf.macos.packages.getPackages(allocator);
    sys.de = zf.macos.desktop.getDe(allocator);
    sys.wm = zf.macos.desktop.getWm(allocator);

    return sys;
}

fn getShellWithVersion(allocator: std.mem.Allocator, shell_path: [*:0]const u8) ?[]const u8 {
    const path = std.mem.sliceTo(shell_path, 0);
    const name = std.fs.path.basename(path);
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ path, "--version" },
    }) catch return allocator.dupe(u8, name) catch null;
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);
    const output = if (result.stdout.len > 0) result.stdout else result.stderr;
    if (zf.info.extractVersion(output)) |ver| {
        return std.fmt.allocPrint(allocator, "{s} {s}", .{ name, ver }) catch allocator.dupe(u8, name) catch null;
    }
    return allocator.dupe(u8, name) catch null;
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa);
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}