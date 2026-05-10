const std = @import("std");
const info = @import("info");

pub fn getMemoryInfo(allocator: std.mem.Allocator) info.SystemInfo {
    var sys = info.SystemInfo{ .allocator = allocator };

    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ "sysctl", "-n", "hw.memsize" },
    }) catch return sys;
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    const trimmed = std.mem.trim(u8, result.stdout, " \t\n\r");
    sys.total_memory = std.fmt.parseInt(usize, trimmed, 10) catch null;

    return sys;
}