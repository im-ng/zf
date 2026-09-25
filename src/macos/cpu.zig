const std = @import("std");
const builtin = @import("builtin");
const info = @import("info");

pub fn getCpuInfo(allocator: std.mem.Allocator, io: std.Io) info.SystemInfo {
    var sys = info.SystemInfo{ .allocator = allocator };

    sys.cpu_arch = allocator.dupe(u8, @tagName(builtin.cpu.arch)) catch null;

    if (info.runCapture(allocator, io, &.{ "sysctl", "-n", "machdep.cpu.vendor" })) |trimmed| {
        sys.cpu_vendor = allocator.dupe(u8, trimmed) catch null;
    }

    if (info.runCapture(allocator, io, &.{ "sysctl", "-n", "machdep.cpu.family" })) |family_trimmed| {
        sys.cpu_family = allocator.dupe(u8, family_trimmed) catch null;
    }

    if (info.runCapture(allocator, io, &.{ "sysctl", "-n", "machdep.cpu.brand_string" })) |brand_trimmed| {
        sys.cpu_model_name = allocator.dupe(u8, brand_trimmed) catch null;
    }

    if (info.runCapture(allocator, io, &.{ "sysctl", "-n", "hw.ncpu" })) |ncpu_trimmed| {
        sys.cpu_cores = std.fmt.parseInt(usize, ncpu_trimmed, 10) catch null;
    }

    readCacheSize(allocator, io, &sys, "hw.l1dcachesize", &sys.l1_cache);
    readCacheSize(allocator, io, &sys, "hw.l2cachesize", &sys.l2_cache);
    readCacheSize(allocator, io, &sys, "hw.l3cachesize", &sys.l3_cache);

    return sys;
}

fn readCacheSize(allocator: std.mem.Allocator, io: std.Io, sys: *info.SystemInfo, comptime key: []const u8, field: *?[]const u8) void {
    _ = sys;
    const trimmed = info.runCapture(allocator, io, &.{ "sysctl", "-n", key }) orelse return;
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
