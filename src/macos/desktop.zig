const std = @import("std");
const info = @import("info");

pub fn getDe(allocator: std.mem.Allocator) ?[]const u8 {
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ "sw_vers", "-productVersion" },
    }) catch return allocator.dupe(u8, "Aqua") catch null;
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);
    const ver = std.mem.trim(u8, result.stdout, " \t\n\r");
    if (ver.len > 0) {
        return std.fmt.allocPrint(allocator, "Aqua {s}", .{ver}) catch allocator.dupe(u8, "Aqua") catch null;
    }
    return allocator.dupe(u8, "Aqua") catch null;
}

pub fn getWm(allocator: std.mem.Allocator) ?[]const u8 {
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ "sw_vers", "-productVersion" },
    }) catch return allocator.dupe(u8, "Quartz Compositor") catch null;
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);
    const ver = std.mem.trim(u8, result.stdout, " \t\n\r");
    if (ver.len > 0) {
        return std.fmt.allocPrint(allocator, "Quartz Compositor {s}", .{ver}) catch allocator.dupe(u8, "Quartz Compositor") catch null;
    }
    return allocator.dupe(u8, "Quartz Compositor") catch null;
}