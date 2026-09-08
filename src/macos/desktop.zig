const std = @import("std");
const info = @import("info");

pub fn getDe(ctx: info.Context) ?[]const u8 {
    const result = std.process.run(ctx.allocator, ctx.io, .{
        .argv = &.{ "sw_vers", "-productVersion" },
    }) catch return ctx.allocator.dupe(u8, "Aqua") catch null;
    defer ctx.allocator.free(result.stdout);
    defer ctx.allocator.free(result.stderr);
    const ver = std.mem.trim(u8, result.stdout, " \t\n\r");
    if (ver.len > 0) {
        return std.fmt.allocPrint(ctx.allocator, "Aqua {s}", .{ver}) catch ctx.allocator.dupe(u8, "Aqua") catch null;
    }
    return ctx.allocator.dupe(u8, "Aqua") catch null;
}

pub fn getWm(ctx: info.Context) ?[]const u8 {
    const result = std.process.run(ctx.allocator, ctx.io, .{
        .argv = &.{ "sw_vers", "-productVersion" },
    }) catch return ctx.allocator.dupe(u8, "Quartz Compositor") catch null;
    defer ctx.allocator.free(result.stdout);
    defer ctx.allocator.free(result.stderr);
    const ver = std.mem.trim(u8, result.stdout, " \t\n\r");
    if (ver.len > 0) {
        return std.fmt.allocPrint(ctx.allocator, "Quartz Compositor {s}", .{ver}) catch ctx.allocator.dupe(u8, "Quartz Compositor") catch null;
    }
    return ctx.allocator.dupe(u8, "Quartz Compositor") catch null;
}
