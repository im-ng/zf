const std = @import("std");
const info = @import("info");

pub fn getSystemInfo(ctx: info.Context) info.SystemInfo {
    const allocator = ctx.allocator;
    var sys = info.SystemInfo{ .allocator = allocator };

    if (ctx.environ.get("USER")) |user| {
        sys.user = allocator.dupe(u8, user) catch null;
    }

    if (ctx.environ.get("SHELL")) |shell| {
        sys.shell = allocator.dupe(u8, shell) catch null;
    }

    if (ctx.environ.get("TERM")) |term| {
        sys.terminal = allocator.dupe(u8, term) catch null;
    }

    var cwd_buf: [std.posix.PATH_MAX]u8 = undefined;
    const cwd_len = std.process.currentPath(ctx.io, &cwd_buf) catch 0;
    if (cwd_len > 0) {
        sys.cwd = allocator.dupe(u8, cwd_buf[0..cwd_len]) catch null;
    }

    sys.uptime = getUptime(ctx);

    return sys;
}

pub fn getUptime(ctx: info.Context) ?f64 {
    const result = std.process.run(ctx.allocator, ctx.io, .{
        .argv = &.{ "sysctl", "-n", "kern.boottime" },
    }) catch return null;
    defer ctx.allocator.free(result.stdout);
    defer ctx.allocator.free(result.stderr);

    const trimmed = std.mem.trim(u8, result.stdout, " \t\n\r");
    const sec_prefix = "sec = ";
    const sec_start = std.mem.indexOf(u8, trimmed, sec_prefix) orelse return null;
    const after = trimmed[sec_start + sec_prefix.len ..];
    const comma_pos = std.mem.indexOfScalar(u8, after, ',') orelse std.mem.indexOfScalar(u8, after, ' ') orelse after.len;
    const sec_str = after[0..comma_pos];
    const boot_time = std.fmt.parseInt(i64, sec_str, 10) catch return null;
    const now_ns = std.Io.Clock.Timestamp.now(ctx.io, .real).raw.nanoseconds;
    const now_seconds = @divTrunc(now_ns, std.time.ns_per_s);
    const uptime_seconds = now_seconds - boot_time;
    if (uptime_seconds < 0) return null;
    return @floatFromInt(uptime_seconds);
}
