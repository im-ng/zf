const std = @import("std");
const info = @import("info");

pub fn getGpuInfo(ctx: info.Context) ?[]const u8 {
    const result = std.process.run(ctx.allocator, ctx.io, .{
        .argv = &.{ "system_profiler", "SPDisplaysDataType" },
    }) catch return null;
    defer ctx.allocator.free(result.stdout);
    defer ctx.allocator.free(result.stderr);

    var lines = std.mem.splitSequence(u8, result.stdout, "\n");
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t");
        if (std.mem.startsWith(u8, trimmed, "Chipset Model:")) {
            const colon_pos = std.mem.indexOfScalar(u8, trimmed, ':') orelse continue;
            const model = std.mem.trim(u8, trimmed[colon_pos + 1 ..], " \t");
            if (model.len > 0) {
                return ctx.allocator.dupe(u8, model) catch null;
            }
        }
        if (std.mem.startsWith(u8, trimmed, "Marketing Name:")) {
            const colon_pos = std.mem.indexOfScalar(u8, trimmed, ':') orelse continue;
            const name = std.mem.trim(u8, trimmed[colon_pos + 1 ..], " \t");
            if (name.len > 0) {
                return ctx.allocator.dupe(u8, name) catch null;
            }
        }
    }
    return null;
}
