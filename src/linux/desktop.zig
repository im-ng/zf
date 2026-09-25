const std = @import("std");
const info = @import("info");

pub fn getDe(ctx: info.Context) ?[]const u8 {
    const allocator = ctx.allocator;
    var de_source: ?[]const u8 = null;

    if (ctx.environ.get("XDG_CURRENT_DESKTOP")) |de| {
        const trimmed = std.mem.trim(u8, de, " \t\n\r");
        if (trimmed.len > 0) de_source = trimmed;
    }
    if (de_source == null) {
        if (ctx.environ.get("DESKTOP_SESSION")) |session| {
            const trimmed = std.mem.trim(u8, session, " \t\n\r");
            if (trimmed.len > 0) de_source = trimmed;
        }
    }
    if (de_source == null) {
        if (ctx.environ.get("XDG_SESSION_DESKTOP")) |desktop| {
            const trimmed = std.mem.trim(u8, desktop, " \t\n\r");
            if (trimmed.len > 0) de_source = trimmed;
        }
    }

    const raw_name = de_source orelse return null;

    const name = if (std.mem.lastIndexOfScalar(u8, raw_name, ':')) |pos|
        std.mem.trim(u8, raw_name[pos + 1 ..], " \t")
    else
        std.mem.trim(u8, raw_name, " \t");

    if (name.len == 0) return null;

    if (tryDeVersion(ctx, name)) |ver| {
        const combined = std.fmt.allocPrint(allocator, "{s} {s}", .{ name, ver }) catch {
            allocator.free(ver);
            return allocator.dupe(u8, name) catch null;
        };
        allocator.free(ver);
        return combined;
    }

    return allocator.dupe(u8, name) catch null;
}

fn tryDeVersion(ctx: info.Context, de_name: []const u8) ?[]const u8 {
    if (info.containsIgnoreCase(de_name, "gnome")) {
        return info.runVersionCmd(ctx, &.{ "gnome-shell", "--version" });
    }
    if (info.containsIgnoreCase(de_name, "kde") or info.containsIgnoreCase(de_name, "plasma")) {
        return info.runVersionCmd(ctx, &.{ "plasmashell", "--version" });
    }
    if (info.containsIgnoreCase(de_name, "xfce")) {
        return info.runVersionCmd(ctx, &.{ "xfce4-panel", "--version" });
    }
    if (info.containsIgnoreCase(de_name, "cinnamon")) {
        return info.runVersionCmd(ctx, &.{ "cinnamon", "--version" });
    }
    if (info.containsIgnoreCase(de_name, "mate")) {
        return info.runVersionCmd(ctx, &.{ "mate-panel", "--version" });
    }
    if (info.containsIgnoreCase(de_name, "lxqt")) {
        return info.runVersionCmd(ctx, &.{ "lxqt-panel", "--version" });
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

pub fn getWm(ctx: info.Context) ?[]const u8 {
    const allocator = ctx.allocator;
    if (ctx.environ.get("HM")) |wm_env| {
        const trimmed = std.mem.trim(u8, wm_env, " \t\n\r");
        if (trimmed.len > 0) {
            const name = std.fs.path.basename(trimmed);
            if (tryWmVersion(ctx, trimmed)) |ver| {
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

    const wm_name = findWmProcess(ctx) orelse return null;

    var path_buf: [256]u8 = undefined;
    const wm_path = std.fmt.bufPrint(&path_buf, "/usr/bin/{s}", .{wm_name}) catch {
        return wm_name;
    };

    if (tryWmVersion(ctx, wm_path)) |ver| {
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

fn tryWmVersion(ctx: info.Context, cmd_path: []const u8) ?[]const u8 {
    return info.runVersionCmd(ctx, &.{ cmd_path, "--version" });
}

fn findWmProcess(ctx: info.Context) ?[]const u8 {
    const allocator = ctx.allocator;
    var proc_dir = std.Io.Dir.openDirAbsolute(ctx.io, "/proc", .{ .iterate = true }) catch return null;
    defer proc_dir.close(ctx.io);
    var iter = std.Io.Dir.iterate(proc_dir);
    while (iter.next(ctx.io) catch return null) |entry| {
        if (entry.kind != .directory) continue;
        _ = std.fmt.parseInt(u32, entry.name, 10) catch continue;
        var path_buf: [128]u8 = undefined;
        const path = std.fmt.bufPrint(&path_buf, "/proc/{s}/comm", .{entry.name}) catch continue;
        var comm_buf: [64]u8 = undefined;
        const comm_data = info.readSmallFile(ctx.io, path, &comm_buf) orelse continue;
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