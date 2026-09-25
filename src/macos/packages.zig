const std = @import("std");
const info = @import("info");

pub fn getPackages(ctx: info.Context) ?[]const u8 {
    const allocator = ctx.allocator;
    var parts: std.ArrayList([]const u8) = .empty;
    defer parts.deinit(allocator);

    if (countBrew(ctx)) |count| {
        const s = std.fmt.allocPrint(allocator, "{d} (brew)", .{count}) catch return null;
        parts.append(allocator, s) catch return null;
    }
    if (countPort(ctx)) |count| {
        const s = std.fmt.allocPrint(allocator, "{d} (port)", .{count}) catch return null;
        parts.append(allocator, s) catch return null;
    }

    if (parts.items.len == 0) return null;

    const total = std.mem.join(allocator, ", ", parts.items) catch return null;
    for (parts.items) |p| allocator.free(p);
    return total;
}

fn countBrew(ctx: info.Context) ?usize {
    const result = std.process.run(ctx.allocator, ctx.io, .{
        .argv = &.{ "brew", "list", "-1" },
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

fn countPort(ctx: info.Context) ?usize {
    const result = std.process.run(ctx.allocator, ctx.io, .{
        .argv = &.{ "port", "installed" },
    }) catch return null;
    defer ctx.allocator.free(result.stdout);
    defer ctx.allocator.free(result.stderr);

    var count: usize = 0;
    var lines = std.mem.splitSequence(u8, result.stdout, "\n");
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t");
        if (trimmed.len > 0 and !std.mem.startsWith(u8, trimmed, "The following") and !std.mem.startsWith(u8, trimmed, "--")) {
            count += 1;
        }
    }
    return if (count > 0) count else null;
}
