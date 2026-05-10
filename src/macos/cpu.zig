const std = @import("std");
const builtin = @import("builtin");
const info = @import("info");

pub fn getCpuInfo(allocator: std.mem.Allocator) info.SystemInfo {
    var sys = info.SystemInfo{ .allocator = allocator };

    sys.cpu_arch = allocator.dupe(u8, @tagName(builtin.cpu.arch)) catch null;

    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ "sysctl", "-n", "machdep.cpu.vendor" },
    }) catch return sys;
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);
    const trimmed = std.mem.trim(u8, result.stdout, " \t\n\r");
    if (trimmed.len > 0) {
        sys.cpu_vendor = allocator.dupe(u8, trimmed) catch null;
    }

    const family_result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ "sysctl", "-n", "machdep.cpu.family" },
    }) catch return sys;
    defer allocator.free(family_result.stdout);
    defer allocator.free(family_result.stderr);
    const family_trimmed = std.mem.trim(u8, family_result.stdout, " \t\n\r");
    if (family_trimmed.len > 0) {
        sys.cpu_family = allocator.dupe(u8, family_trimmed) catch null;
    }

    const brand_result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ "sysctl", "-n", "machdep.cpu.brand_string" },
    }) catch return sys;
    defer allocator.free(brand_result.stdout);
    defer allocator.free(brand_result.stderr);
    const brand_trimmed = std.mem.trim(u8, brand_result.stdout, " \t\n\r");
    if (brand_trimmed.len > 0) {
        sys.cpu_model_name = allocator.dupe(u8, brand_trimmed) catch null;
    }

    const ncpu_result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ "sysctl", "-n", "hw.ncpu" },
    }) catch return sys;
    defer allocator.free(ncpu_result.stdout);
    defer allocator.free(ncpu_result.stderr);
    const ncpu_trimmed = std.mem.trim(u8, ncpu_result.stdout, " \t\n\r");
    sys.cpu_cores = std.fmt.parseInt(usize, ncpu_trimmed, 10) catch null;

    readCacheSize(allocator, &sys, "hw.l1dcachesize", &sys.l1_cache);
    readCacheSize(allocator, &sys, "hw.l2cachesize", &sys.l2_cache);
    readCacheSize(allocator, &sys, "hw.l3cachesize", &sys.l3_cache);

    return sys;
}

fn readCacheSize(allocator: std.mem.Allocator, sys: *info.SystemInfo, comptime key: []const u8, field: *?[]const u8) void {
    _ = sys;
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ "sysctl", "-n", key },
    }) catch return;
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);
    const trimmed = std.mem.trim(u8, result.stdout, " \t\n\r");
    if (trimmed.len > 0) {
        const bytes = std.fmt.parseInt(usize, trimmed, 10) catch return;
        var buf: [32]u8 = undefined;
        if (bytes >= 1073741824) {
            const gb: f64 = @as(f64, @floatFromInt(bytes)) / 1073741824.0;
            const s = std.fmt.bufPrint(&buf, "{d:.1} GiB", .{gb}) catch return;
            field.* = allocator.dupe(u8, s) catch null;
        } else if (bytes >= 1048576) {
            const mb: f64 = @as(f64, @floatFromInt(bytes)) / 1048576.0;
            const s = std.fmt.bufPrint(&buf, "{d:.1} MiB", .{mb}) catch return;
            field.* = allocator.dupe(u8, s) catch null;
        } else if (bytes >= 1024) {
            const kb: f64 = @as(f64, @floatFromInt(bytes)) / 1024.0;
            const s = std.fmt.bufPrint(&buf, "{d:.1} KiB", .{kb}) catch return;
            field.* = allocator.dupe(u8, s) catch null;
        } else {
            const s = std.fmt.bufPrint(&buf, "{d} B", .{bytes}) catch return;
            field.* = allocator.dupe(u8, s) catch null;
        }
    }
}