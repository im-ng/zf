const std = @import("std");
const info = @import("info");

pub fn getDe(allocator: std.mem.Allocator) ?[]const u8 {
    var de_source: ?[]const u8 = null;

    if (std.posix.getenv("XDG_CURRENT_DESKTOP")) |de| {
        const raw = std.mem.sliceTo(de, 0);
        const trimmed = std.mem.trim(u8, raw, " \t\n\r");
        if (trimmed.len > 0) de_source = trimmed;
    }
    if (de_source == null) {
        if (std.posix.getenv("DESKTOP_SESSION")) |session| {
            const raw = std.mem.sliceTo(session, 0);
            const trimmed = std.mem.trim(u8, raw, " \t\n\r");
            if (trimmed.len > 0) de_source = trimmed;
        }
    }
    if (de_source == null) {
        if (std.posix.getenv("XDG_SESSION_DESKTOP")) |desktop| {
            const raw = std.mem.sliceTo(desktop, 0);
            const trimmed = std.mem.trim(u8, raw, " \t\n\r");
            if (trimmed.len > 0) de_source = trimmed;
        }
    }

    const raw_name = de_source orelse return null;

    const name = if (std.mem.lastIndexOfScalar(u8, raw_name, ':')) |pos|
        std.mem.trim(u8, raw_name[pos + 1 ..], " \t")
    else
        std.mem.trim(u8, raw_name, " \t");

    if (name.len == 0) return null;

    if (tryDeVersion(allocator, name)) |ver| {
        const combined = std.fmt.allocPrint(allocator, "{s} {s}", .{ name, ver }) catch {
            allocator.free(ver);
            return allocator.dupe(u8, name) catch null;
        };
        allocator.free(ver);
        return combined;
    }

    return allocator.dupe(u8, name) catch null;
}

fn tryDeVersion(allocator: std.mem.Allocator, de_name: []const u8) ?[]const u8 {
    if (info.containsIgnoreCase(de_name, "gnome")) {
        return info.runVersionCmd(allocator, &.{ "gnome-shell", "--version" });
    }
    if (info.containsIgnoreCase(de_name, "kde") or info.containsIgnoreCase(de_name, "plasma")) {
        return info.runVersionCmd(allocator, &.{ "plasmashell", "--version" });
    }
    if (info.containsIgnoreCase(de_name, "xfce")) {
        return info.runVersionCmd(allocator, &.{ "xfce4-panel", "--version" });
    }
    if (info.containsIgnoreCase(de_name, "cinnamon")) {
        return info.runVersionCmd(allocator, &.{ "cinnamon", "--version" });
    }
    if (info.containsIgnoreCase(de_name, "mate")) {
        return info.runVersionCmd(allocator, &.{ "mate-panel", "--version" });
    }
    if (info.containsIgnoreCase(de_name, "lxqt")) {
        return info.runVersionCmd(allocator, &.{ "lxqt-panel", "--version" });
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
    if (std.posix.getenv("HM")) |wm_env| {
        const raw = std.mem.sliceTo(wm_env, 0);
        const trimmed = std.mem.trim(u8, raw, " \t\n\r");
        if (trimmed.len > 0) {
            const name = std.fs.path.basename(trimmed);
            if (tryWmVersion(allocator, trimmed)) |ver| {
                const combined = std.fmt.allocPrint(allocator, "{s} {s}", .{ name, ver }) catch {
                    allocator.free(ver);
                    return allocator.dupe(u8, name) catch null;
                };
                allocator.free(ver);
                return combined;
            }
            return allocator.dupe(u8, name) catch null;
        }
    }

    const wm_name = findWmProcess(allocator) orelse return null;

    var path_buf: [256]u8 = undefined;
    const wm_path = std.fmt.bufPrint(&path_buf, "/usr/bin/{s}", .{wm_name}) catch {
        return wm_name;
    };

    if (tryWmVersion(allocator, wm_path)) |ver| {
        const combined = std.fmt.allocPrint(allocator, "{s} {s}", .{ wm_name, ver }) catch {
            allocator.free(ver);
            return wm_name;
        };
        allocator.free(ver);
        allocator.free(wm_name);
        return combined;
    }

    return wm_name;
}

fn tryWmVersion(allocator: std.mem.Allocator, cmd_path: []const u8) ?[]const u8 {
    return info.runVersionCmd(allocator, &.{ cmd_path, "--version" });
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