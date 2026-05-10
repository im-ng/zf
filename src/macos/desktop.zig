const std = @import("std");

pub fn getDe(allocator: std.mem.Allocator) ?[]const u8 {
    _ = allocator;
    return "Aqua";
}

pub fn getWm(allocator: std.mem.Allocator) ?[]const u8 {
    _ = allocator;
    return "Quartz Compositor";
}