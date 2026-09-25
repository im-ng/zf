const std = @import("std");
const info = @import("info");

pub fn getMemoryInfo(allocator: std.mem.Allocator, io: std.Io) info.SystemInfo {
    var sys = info.SystemInfo{ .allocator = allocator };

    const trimmed = info.runCapture(allocator, io, &.{ "sysctl", "-n", "hw.memsize" }) orelse return sys;
    sys.total_memory = std.fmt.parseInt(usize, trimmed, 10) catch null;

    return sys;
}
