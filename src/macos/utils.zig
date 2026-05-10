const std = @import("std");
const info = @import("info");

pub fn getSystemInfo(allocator: std.mem.Allocator) info.SystemInfo {
    var sys = info.SystemInfo{ .allocator = allocator };

    if (std.posix.getenv("USER")) |user| {
        sys.user = allocator.dupe(u8, user) catch null;
    }

    if (std.posix.getenv("SHELL")) |shell| {
        sys.shell = allocator.dupe(u8, shell) catch null;
    }

    if (std.posix.getenv("TERM")) |term| {
        sys.terminal = allocator.dupe(u8, term) catch null;
    }

    var cwd_buf: [std.posix.PATH_MAX]u8 = undefined;
    if (std.posix.getcwd(&cwd_buf)) |cwd| {
        sys.cwd = allocator.dupe(u8, cwd) catch null;
    } else |_| {}

    sys.uptime = getUptime();

    return sys;
}

pub fn getUptime() ?f64 {
    const result = std.process.Child.run(.{
        .allocator = std.heap.page_allocator,
        .argv = &.{ "sysctl", "-n", "kern.boottime" },
    }) catch return null;
    defer std.heap.page_allocator.free(result.stdout);
    defer std.heap.page_allocator.free(result.stderr);

    const trimmed = std.mem.trim(u8, result.stdout, " \t\n\r");
    const sec_prefix = "sec = ";
    const sec_start = std.mem.indexOf(u8, trimmed, sec_prefix) orelse return null;
    const after = trimmed[sec_start + sec_prefix.len ..];
    const comma_pos = std.mem.indexOfScalar(u8, after, ',') orelse std.mem.indexOfScalar(u8, after, ' ') orelse after.len;
    const sec_str = after[0..comma_pos];
    const boot_time = std.fmt.parseInt(i64, sec_str, 10) catch return null;
    const now: i64 = std.time.timestamp();
    const uptime_seconds = now - boot_time;
    if (uptime_seconds < 0) return null;
    return @floatFromInt(uptime_seconds);
}