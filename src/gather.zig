const std = @import("std");
const builtin = @import("builtin");
const info = @import("info");
const linux = @import("linux");
const macos = @import("macos");

pub fn gather(allocator: std.mem.Allocator, io: std.Io) info.SystemInfo {
    var env_map = loadEnviron(allocator) catch {
        return .{ .allocator = allocator };
    };
    defer env_map.deinit();

    const ctx: info.Context = .{
        .allocator = allocator,
        .io = io,
        .environ = &env_map,
    };

    return switch (builtin.os.tag) {
        .macos => gatherMacos(ctx),
        else => gatherLinux(ctx),
    };
}

/// Builds an environment map from the process's global environment block so
/// that env-driven probes (shell, desktop, etc.) work without the caller
/// having to thread an `Environ.Map` through `gather`.
fn loadEnviron(allocator: std.mem.Allocator) !std.process.Environ.Map {
    const env_slice = std.mem.span(std.c.environ);
    const block: std.process.Environ.PosixBlock = .{ .slice = @ptrCast(env_slice) };
    const environ: std.process.Environ = .{ .block = block };
    return try std.process.Environ.createMap(environ, allocator);
}

fn gatherLinux(ctx: info.Context) info.SystemInfo {
    const allocator = ctx.allocator;
    const io = ctx.io;
    var sys: info.SystemInfo = .{ .allocator = allocator };

    var cpu_buf: [16384]u8 = undefined;
    if (info.readSmallFile(io, "/proc/cpuinfo", &cpu_buf)) |contents| {
        var cpu = linux.cpu.getCpuInfoFromString(allocator, io, contents);
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
    if (info.readSmallFile(io, "/proc/meminfo", &mem_buf)) |contents| {
        const mem = linux.memory.getMemoryInfoFromString(allocator, contents);
        sys.total_memory = mem.total_memory;
        sys.free_memory = mem.free_memory;
    }

    var os_buf: [4096]u8 = undefined;
    if (info.readSmallFile(io, "/etc/os-release", &os_buf)) |contents| {
        linux.os.parseOsRelease(allocator, &sys, contents);
    }

    var hostname_buf: [256]u8 = undefined;
    if (info.readSmallFile(io, "/etc/hostname", &hostname_buf)) |contents| {
        const trimmed = std.mem.trim(u8, contents, " \t\n\r");
        if (trimmed.len > 0) {
            sys.hostname = allocator.dupe(u8, trimmed) catch null;
        }
    }

    var version_buf: [1024]u8 = undefined;
    if (info.readSmallFile(io, "/proc/version", &version_buf)) |contents| {
        const prefix = "Linux version ";
        if (std.mem.startsWith(u8, contents, prefix)) {
            const rest = contents[prefix.len..];
            const space = std.mem.indexOfScalar(u8, rest, ' ') orelse contents.len;
            sys.kernel = allocator.dupe(u8, rest[0..space]) catch null;
        }
    }

    var uptime_buf: [128]u8 = undefined;
    if (info.readSmallFile(io, "/proc/uptime", &uptime_buf)) |contents| {
        sys.uptime = info.parseUptime(contents);
    }

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
        if (info.readSmallFile(io, "/etc/lsb-release", &lsb_buf)) |contents| {
            linux.os.parseLsbRelease(allocator, &sys, contents);
        }
    }

    if (sys.distro_id == null) {
        sys.distro_id = allocator.dupe(u8, "linux") catch null;
    }

    if (sys.cpu_arch == null) {
        sys.cpu_arch = allocator.dupe(u8, @tagName(builtin.cpu.arch)) catch null;
    }

    if (std.c.getenv("USER")) |user| {
        sys.user = allocator.dupe(u8, std.mem.sliceTo(user, 0)) catch null;
    }
    if (std.c.getenv("TERM")) |term| {
        sys.terminal = allocator.dupe(u8, std.mem.sliceTo(term, 0)) catch null;
    }

    sys.gpu = linux.gpu.getGpuInfo(ctx);
    sys.packages = linux.packages.getPackages(ctx);
    sys.de = linux.desktop.getDe(ctx);
    sys.wm = linux.desktop.getWm(ctx);
    sys.shell = info.getShellWithVersion(ctx) orelse sys.shell;

    return sys;
}

fn gatherMacos(ctx: info.Context) info.SystemInfo {
    const allocator = ctx.allocator;
    const io = ctx.io;
    var sys: info.SystemInfo = .{ .allocator = allocator };

    {
        var cpu = macos.cpu.getCpuInfo(allocator, io);
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

    const mem = macos.memory.getMemoryInfo(allocator, io);
    sys.total_memory = mem.total_memory;
    sys.free_memory = mem.free_memory;

    {
        var os_info = macos.os.getOsInfo(allocator, io);
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

    if (std.c.getenv("USER")) |user| {
        sys.user = allocator.dupe(u8, std.mem.sliceTo(user, 0)) catch null;
    }
    if (std.c.getenv("TERM")) |term| {
        sys.terminal = allocator.dupe(u8, std.mem.sliceTo(term, 0)) catch null;
    }

    sys.gpu = macos.gpu.getGpuInfo(ctx);
    sys.packages = macos.packages.getPackages(ctx);
    sys.de = macos.desktop.getDe(ctx);
    sys.wm = macos.desktop.getWm(ctx);
    sys.shell = info.getShellWithVersion(ctx) orelse sys.shell;
    sys.uptime = macos.utils.getUptime(ctx);

    return sys;
}
