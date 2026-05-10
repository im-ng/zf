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

    return sys;
}