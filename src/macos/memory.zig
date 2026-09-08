const std = @import("std");
const info = @import("info");

pub fn getMemoryInfo(ctx: info.Context) info.SystemInfo {
    const allocator = ctx.allocator;
    var sys = info.SystemInfo{ .allocator = allocator };

    const result = std.process.run(ctx.allocator, ctx.io, .{
        .argv = &.{ "sysctl", "-n", "hw.memsize" },
    }) catch return sys;
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    const trimmed = std.mem.trim(u8, result.stdout, " \t\n\r");
    sys.total_memory = std.fmt.parseInt(usize, trimmed, 10) catch null;

    return sys;
}