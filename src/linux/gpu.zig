const std = @import("std");
const info = @import("info");

pub fn getGpuInfo(ctx: info.Context) ?[]const u8 {
    if (tryNvidiaSmi(ctx)) |gpu| return gpu;
    if (tryLspci(ctx)) |gpu| return gpu;
    if (tryNvidiaProc(ctx)) |gpu| return gpu;
    return null;
}

fn tryNvidiaSmi(ctx: info.Context) ?[]const u8 {
    const result = std.process.run(ctx.allocator, ctx.io, .{
        .argv = &.{ "nvidia-smi", "--query-gpu=name", "--format=csv,noheader" },
    }) catch return null;
    defer ctx.allocator.free(result.stdout);
    defer ctx.allocator.free(result.stderr);
    const trimmed = std.mem.trim(u8, result.stdout, " \t\n\r\"");
    if (trimmed.len > 0) {
        return ctx.allocator.dupe(u8, trimmed) catch null;
    }
    return null;
}

fn tryLspci(ctx: info.Context) ?[]const u8 {
    const result = std.process.run(ctx.allocator, ctx.io, .{
        .argv = &.{ "lspci" },
    }) catch return null;
    defer ctx.allocator.free(result.stdout);
    defer ctx.allocator.free(result.stderr);

    var lines = std.mem.splitSequence(u8, result.stdout, "\n");
    while (lines.next()) |line| {
        if (std.mem.containsAtLeast(u8, line, 1, "VGA") or
            std.mem.containsAtLeast(u8, line, 1, "3D") or
            std.mem.containsAtLeast(u8, line, 1, "Display"))
        {
            if (std.mem.indexOfScalar(u8, line, ':')) |colon_pos| {
                const after_colon = line[colon_pos + 1 ..];
                if (std.mem.indexOfScalar(u8, after_colon, ':')) |second_colon| {
                    const gpu_part = std.mem.trim(u8, after_colon[second_colon + 1 ..], " \t");
                    const paren_pos = std.mem.indexOfScalar(u8, gpu_part, '(');
                    const end = paren_pos orelse gpu_part.len;
                    const trimmed = std.mem.trim(u8, gpu_part[0..end], " \t");
                    if (trimmed.len > 0) {
                        return ctx.allocator.dupe(u8, trimmed) catch null;
                    }
                } else {
                    const trimmed = std.mem.trim(u8, after_colon, " \t");
                    if (trimmed.len > 0) {
                        return ctx.allocator.dupe(u8, trimmed) catch null;
                    }
                }
            }
        }
    }
    return null;
}

fn tryNvidiaProc(ctx: info.Context) ?[]const u8 {
    var gpus_dir = std.Io.Dir.openDirAbsolute(ctx.io, "/proc/driver/nvidia/gpus", .{ .iterate = true }) catch return null;
    defer gpus_dir.close(ctx.io);
    var iter = std.Io.Dir.iterate(gpus_dir);
    while (iter.next(ctx.io) catch return null) |entry| {
        if (entry.kind == .directory) {
            var path_buf: [512]u8 = undefined;
            const info_path = std.fmt.bufPrint(&path_buf, "/proc/driver/nvidia/gpus/{s}/information", .{entry.name}) catch continue;
            var buf: [4096]u8 = undefined;
            const contents = info.readSmallFile(ctx, info_path, &buf) orelse continue;
            var lines = std.mem.splitSequence(u8, contents, "\n");
            while (lines.next()) |line| {
                if (std.mem.startsWith(u8, line, "Model:")) {
                    const model = std.mem.trim(u8, line["Model:".len..], " \t\r");
                    if (model.len > 0) {
                        return ctx.allocator.dupe(u8, model) catch null;
                    }
                }
            }
        }
    }
    return null;
}
