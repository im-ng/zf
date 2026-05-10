const std = @import("std");
const info = @import("info");

pub fn parseOsRelease(allocator: std.mem.Allocator, sys: *info.SystemInfo, contents: []const u8) void {
    var lines = std.mem.splitSequence(u8, contents, "\n");
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "NAME=")) {
            const val = std.mem.trim(u8, line["NAME=".len..], "=\"");
            if (val.len > 0) sys.os_name = allocator.dupe(u8, val) catch null;
        }
        if (std.mem.startsWith(u8, line, "VERSION=")) {
            const val = std.mem.trim(u8, line["VERSION=".len..], "=\"");
            if (val.len > 0) sys.os_version = allocator.dupe(u8, val) catch null;
        }
        if (std.mem.startsWith(u8, line, "ID=")) {
            const val = std.mem.trim(u8, line["ID=".len..], "=\"");
            if (sys.distro_id == null and val.len > 0) sys.distro_id = allocator.dupe(u8, val) catch null;
        }
    }
}

pub fn parseLsbRelease(allocator: std.mem.Allocator, sys: *info.SystemInfo, contents: []const u8) void {
    var lines = std.mem.splitSequence(u8, contents, "\n");
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "DISTRIB_ID=")) {
            const val = std.mem.trim(u8, line["DISTRIB_ID=".len..], "=\"");
            if (sys.os_name == null and val.len > 0) sys.os_name = allocator.dupe(u8, val) catch null;
            if (sys.distro_id == null and val.len > 0) sys.distro_id = allocator.dupe(u8, val) catch null;
        }
        if (std.mem.startsWith(u8, line, "DISTRIB_RELEASE=")) {
            const val = std.mem.trim(u8, line["DISTRIB_RELEASE=".len..], "=\"");
            if (sys.os_version == null and val.len > 0) sys.os_version = allocator.dupe(u8, val) catch null;
        }
    }
}

test "parse os-release" {
    const allocator = std.testing.allocator;
    const sample =
        \\NAME="Ubuntu"
        \\VERSION="22.04 LTS (Jammy Jellyfish)"
        \\ID=ubuntu
        \\
    ;
    var sys = info.SystemInfo{ .allocator = allocator };
    defer sys.deinit();
    parseOsRelease(allocator, &sys, sample);
    try std.testing.expect(sys.os_name != null);
    try std.testing.expectEqualStrings("Ubuntu", sys.os_name.?);
    try std.testing.expect(sys.os_version != null);
    try std.testing.expectEqualStrings("22.04 LTS (Jammy Jellyfish)", sys.os_version.?);
}

test "parse empty os-release" {
    const allocator = std.testing.allocator;
    var sys = info.SystemInfo{ .allocator = allocator };
    defer sys.deinit();
    parseOsRelease(allocator, &sys, "");
    try std.testing.expect(sys.os_name == null);
    try std.testing.expect(sys.os_version == null);
}