const std = @import("std");
const info = @import("info");

pub fn parseUptime(contents: []const u8) ?f64 {
    const dot_pos = std.mem.indexOfScalar(u8, contents, '.') orelse return null;
    const space_pos = std.mem.indexOfScalar(u8, contents, ' ') orelse return null;
    if (space_pos < dot_pos) return null;
    const seconds_str = contents[0..space_pos];
    return std.fmt.parseFloat(f64, seconds_str) catch null;
}

test "parse uptime string" {
    const result = parseUptime("123456.78 234567.89");
    try std.testing.expect(result != null);
    try std.testing.expectApproxEqAbs(@as(f64, 123456.78), result.?, 0.01);
}

test "parse uptime empty" {
    try std.testing.expect(parseUptime("") == null);
}