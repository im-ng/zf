const std = @import("std");
const info = @import("info");

pub fn getMemoryInfoFromString(allocator: std.mem.Allocator, contents: []const u8) info.SystemInfo {
    var sys = info.SystemInfo{ .allocator = allocator };
    var lines = std.mem.splitSequence(u8, contents, "\n");
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "MemTotal:")) {
            const sep = std.mem.indexOfScalar(u8, line, ':') orelse continue;
            const val = std.mem.trim(u8, line[sep + 1 ..], " \t");
            const num_str = std.mem.trimRight(u8, val, " kB");
            const kb = std.fmt.parseInt(usize, num_str, 10) catch continue;
            sys.total_memory = kb * 1024;
        }
        if (std.mem.startsWith(u8, line, "MemAvailable:")) {
            const sep = std.mem.indexOfScalar(u8, line, ':') orelse continue;
            const val = std.mem.trim(u8, line[sep + 1 ..], " \t");
            const num_str = std.mem.trimRight(u8, val, " kB");
            const kb = std.fmt.parseInt(usize, num_str, 10) catch continue;
            sys.free_memory = kb * 1024;
        }
    }
    return sys;
}

test "parse meminfo" {
    const allocator = std.testing.allocator;
    const sample =
        \\MemTotal:       16384000 kB
        \\MemFree:          123456 kB
        \\MemAvailable:    8192000 kB
        \\
    ;
    var sys = getMemoryInfoFromString(allocator, sample);
    defer sys.deinit();

    try std.testing.expect(sys.total_memory != null);
    try std.testing.expectEqual(@as(usize, 16384000 * 1024), sys.total_memory.?);
    try std.testing.expect(sys.free_memory != null);
    try std.testing.expectEqual(@as(usize, 8192000 * 1024), sys.free_memory.?);
}

test "parse empty meminfo" {
    const allocator = std.testing.allocator;
    var sys = getMemoryInfoFromString(allocator, "");
    defer sys.deinit();
    try std.testing.expect(sys.total_memory == null);
    try std.testing.expect(sys.free_memory == null);
}