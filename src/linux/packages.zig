const std = @import("std");

pub fn getPackages(allocator: std.mem.Allocator) ?[]const u8 {
    var parts: std.ArrayList([]const u8) = .empty;
    defer parts.deinit(allocator);

    if (countDpkg(allocator)) |count| {
        const s = std.fmt.allocPrint(allocator, "{d} (dpkg)", .{count}) catch return null;
        parts.append(allocator, s) catch return null;
    }
    if (countRpm(allocator)) |count| {
        const s = std.fmt.allocPrint(allocator, "{d} (rpm)", .{count}) catch return null;
        parts.append(allocator, s) catch return null;
    }
    if (countPacman(allocator)) |count| {
        const s = std.fmt.allocPrint(allocator, "{d} (pacman)", .{count}) catch return null;
        parts.append(allocator, s) catch return null;
    }
    if (countApk(allocator)) |count| {
        const s = std.fmt.allocPrint(allocator, "{d} (apk)", .{count}) catch return null;
        parts.append(allocator, s) catch return null;
    }
    if (countSnap(allocator)) |count| {
        const s = std.fmt.allocPrint(allocator, "{d} (snap)", .{count}) catch return null;
        parts.append(allocator, s) catch return null;
    }
    if (countFlatpak(allocator)) |count| {
        const s = std.fmt.allocPrint(allocator, "{d} (flatpak)", .{count}) catch return null;
        parts.append(allocator, s) catch return null;
    }

    if (parts.items.len == 0) return null;

    const total = std.mem.join(allocator, ", ", parts.items) catch return null;
    for (parts.items) |p| allocator.free(p);
    return total;
}

fn countLines(allocator: std.mem.Allocator, argv: []const []const u8) ?usize {
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = argv,
    }) catch return null;
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    var count: usize = 0;
    var lines = std.mem.splitSequence(u8, result.stdout, "\n");
    while (lines.next()) |line| {
        if (line.len > 0) count += 1;
    }
    return if (count > 0) count else null;
}

fn countDpkg(allocator: std.mem.Allocator) ?usize {
    return countLines(allocator, &.{ "dpkg-query", "-W", "-f", "${Package}\n" });
}

fn countRpm(allocator: std.mem.Allocator) ?usize {
    return countLines(allocator, &.{ "rpm", "-qa" });
}

fn countPacman(allocator: std.mem.Allocator) ?usize {
    return countLines(allocator, &.{ "pacman", "-Q" });
}

fn countApk(allocator: std.mem.Allocator) ?usize {
    return countLines(allocator, &.{ "apk", "info" });
}

fn countSnap(allocator: std.mem.Allocator) ?usize {
    const count = countLines(allocator, &.{ "snap", "list" }) orelse return null;
    return if (count > 0) count -| 1 else null;
}

fn countFlatpak(allocator: std.mem.Allocator) ?usize {
    return countLines(allocator, &.{ "flatpak", "list", "--app" });
}