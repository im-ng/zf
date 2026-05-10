const std = @import("std");
const info = @import("info");

pub fn parseSystemVersion(allocator: std.mem.Allocator, sys: *info.SystemInfo, contents: []const u8) void {
    var i: usize = 0;
    while (i < contents.len) {
        const key_start = std.mem.indexOfPos(u8, contents, i, "<key>");
        if (key_start == null) break;
        const ks = key_start.?;
        const key_end = std.mem.indexOfPos(u8, contents, ks + 5, "</key>") orelse break;
        const key = std.mem.trim(u8, contents[ks + 5 .. key_end], " \t\n");

        const str_start = std.mem.indexOfPos(u8, contents, key_end, "<string>") orelse break;
        const ss = str_start;
        const str_end = std.mem.indexOfPos(u8, contents, ss + 8, "</string>") orelse break;
        const value = std.mem.trim(u8, contents[ss + 8 .. str_end], " \t\n");

        if (std.mem.eql(u8, key, "ProductName")) {
            sys.os_name = allocator.dupe(u8, value) catch null;
        } else if (std.mem.eql(u8, key, "ProductVersion")) {
            sys.os_version = allocator.dupe(u8, value) catch null;
        }

        i = str_end + 9;
    }
}

pub fn getOsInfo(allocator: std.mem.Allocator) info.SystemInfo {
    var sys = info.SystemInfo{ .allocator = allocator };

    var buf: [8192]u8 = undefined;
    if (info.readSmallFile("/usr/libexec/SystemVersion.plist", &buf)) |contents| {
        parseSystemVersion(allocator, &sys, contents);
    }

    const uts = std.posix.uname();
    const release = std.mem.sliceTo(&uts.release, 0);
    sys.kernel = allocator.dupe(u8, release) catch null;
    const node = std.mem.sliceTo(&uts.nodename, 0);
    sys.hostname = allocator.dupe(u8, node) catch null;
    sys.distro_id = allocator.dupe(u8, "macos") catch null;

    return sys;
}

test "parse SystemVersion.plist" {
    const allocator = std.testing.allocator;
    const sample =
        \\<plist version="1.0">
        \\<dict>
        \\  <key>ProductName</key>
        \\  <string>macOS</string>
        \\  <key>ProductVersion</key>
        \\  <string>14.0</string>
        \\</dict>
        \\</plist>
        \\
    ;
    var sys = info.SystemInfo{ .allocator = allocator };
    defer sys.deinit();
    parseSystemVersion(allocator, &sys, sample);
    try std.testing.expect(sys.os_name != null);
    try std.testing.expectEqualStrings("macOS", sys.os_name.?);
    try std.testing.expect(sys.os_version != null);
    try std.testing.expectEqualStrings("14.0", sys.os_version.?);
}