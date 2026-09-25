const std = @import("std");
const info = @import("info");

pub fn getPackages(ctx: info.Context) ?[]const u8 {
    const allocator = ctx.allocator;
    var parts: std.ArrayList([]const u8) = .empty;
    defer parts.deinit(allocator);

    if (countDpkg(ctx)) |count| {
        const s = std.fmt.allocPrint(allocator, "{d} (dpkg)", .{count}) catch return null;
        parts.append(allocator, s) catch return null;
    }
    if (countRpm(ctx)) |count| {
        const s = std.fmt.allocPrint(allocator, "{d} (rpm)", .{count}) catch return null;
        parts.append(allocator, s) catch return null;
    }
    if (countPacman(ctx)) |count| {
        const s = std.fmt.allocPrint(allocator, "{d} (pacman)", .{count}) catch return null;
        parts.append(allocator, s) catch return null;
    }
    if (countApk(ctx)) |count| {
        const s = std.fmt.allocPrint(allocator, "{d} (apk)", .{count}) catch return null;
        parts.append(allocator, s) catch return null;
    }
    if (countSnap(ctx)) |count| {
        const s = std.fmt.allocPrint(allocator, "{d} (snap)", .{count}) catch return null;
        parts.append(allocator, s) catch return null;
    }
    if (countFlatpak(ctx)) |count| {
        const s = std.fmt.allocPrint(allocator, "{d} (flatpak)", .{count}) catch return null;
        parts.append(allocator, s) catch return null;
    }

    if (parts.items.len == 0) return null;

    const total = std.mem.join(allocator, ", ", parts.items) catch return null;
    for (parts.items) |p| allocator.free(p);
    return total;
}

fn countLines(ctx: info.Context, argv: []const []const u8) ?usize {
    const result = std.process.run(ctx.allocator, ctx.io, .{
        .argv = argv,
    }) catch return null;
    defer ctx.allocator.free(result.stdout);
    defer ctx.allocator.free(result.stderr);

    var count: usize = 0;
    var lines = std.mem.splitSequence(u8, result.stdout, "\n");
    while (lines.next()) |line| {
        if (line.len > 0) count += 1;
    }
    return if (count > 0) count else null;
}

fn countDpkg(ctx: info.Context) ?usize {
    return countLines(ctx, &.{ "dpkg-query", "-W", "-f", "${Package}\n" });
}

fn countRpm(ctx: info.Context) ?usize {
    return countLines(ctx, &.{ "rpm", "-qa" });
}

fn countPacman(ctx: info.Context) ?usize {
    return countLines(ctx, &.{ "pacman", "-Q" });
}

fn countApk(ctx: info.Context) ?usize {
    return countLines(ctx, &.{ "apk", "info" });
}

fn countSnap(ctx: info.Context) ?usize {
    const count = countLines(ctx, &.{ "snap", "list" }) orelse return null;
    return if (count > 0) count -| 1 else null;
}

fn countFlatpak(ctx: info.Context) ?usize {
    return countLines(ctx, &.{ "flatpak", "list", "--app" });
}
