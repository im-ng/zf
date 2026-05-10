const std = @import("std");
const info = @import("info");

pub fn getDe(allocator: std.mem.Allocator) ?[]const u8 {
    if (std.posix.getenv("XDG_CURRENT_DESKTOP")) |de| {
        const trimmed = std.mem.trim(u8, de, " \t\n\r");
        if (trimmed.len > 0) return allocator.dupe(u8, trimmed) catch null;
    }
    if (std.posix.getenv("DESKTOP_SESSION")) |session| {
        const trimmed = std.mem.trim(u8, session, " \t\n\r");
        if (trimmed.len > 0) return allocator.dupe(u8, trimmed) catch null;
    }
    if (std.posix.getenv("XDG_SESSION_DESKTOP")) |desktop| {
        const trimmed = std.mem.trim(u8, desktop, " \t\n\r");
        if (trimmed.len > 0) return allocator.dupe(u8, trimmed) catch null;
    }
    return null;
}

const known_wms = [_][]const u8{
    "i3",           "sway",        "bspwm",
    "awesome",      "dwm",         "openbox",
    "xfwm4",        "kwin_wayland", "kwin_x11",
    "mutter",       "gnome-shell", "compiz",
    "fluxbox",      "icewm",       "xmonad",
    "hyprland",     "wayfire",     "marco",
    "metacity",     "muffin",      "enlightenment",
    "weston",       "river",       "dwl",
    "labwc",        "picom",
};

pub fn getWm(allocator: std.mem.Allocator) ?[]const u8 {
    if (std.posix.getenv("HM")) |wm| {
        const trimmed = std.mem.trim(u8, wm, " \t\n\r");
        if (trimmed.len > 0) return allocator.dupe(u8, trimmed) catch null;
    }
    return findWmProcess(allocator);
}

fn findWmProcess(allocator: std.mem.Allocator) ?[]const u8 {
    var proc_dir = std.fs.openDirAbsolute("/proc", .{ .iterate = true }) catch return null;
    defer proc_dir.close();
    var iter = proc_dir.iterate();
    while (iter.next() catch return null) |entry| {
        if (entry.kind != .directory) continue;
        _ = std.fmt.parseInt(u32, entry.name, 10) catch continue;
        var path_buf: [128]u8 = undefined;
        const path = std.fmt.bufPrint(&path_buf, "/proc/{s}/comm", .{entry.name}) catch continue;
        var comm_buf: [64]u8 = undefined;
        const comm_data = info.readSmallFile(path, &comm_buf) orelse continue;
        const comm = std.mem.trim(u8, comm_data, " \n\r\t");
        if (comm.len == 0) continue;
        for (known_wms) |wm| {
            if (std.mem.eql(u8, comm, wm)) {
                return allocator.dupe(u8, comm) catch null;
            }
        }
    }
    return null;
}