const std = @import("std");

pub fn getGpuInfo(allocator: std.mem.Allocator) ?[]const u8 {
    if (tryNvidiaSmi(allocator)) |gpu| return gpu;
    if (tryLspci(allocator)) |gpu| return gpu;
    if (tryNvidiaProc(allocator)) |gpu| return gpu;
    return null;
}

fn tryNvidiaSmi(allocator: std.mem.Allocator) ?[]const u8 {
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ "nvidia-smi", "--query-gpu=name", "--format=csv,noheader" },
    }) catch return null;
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);
    const trimmed = std.mem.trim(u8, result.stdout, " \t\n\r\"");
    if (trimmed.len > 0) {
        return allocator.dupe(u8, trimmed) catch null;
    }
    return null;
}

fn tryLspci(allocator: std.mem.Allocator) ?[]const u8 {
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ "lspci" },
    }) catch return null;
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

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
                        return allocator.dupe(u8, trimmed) catch null;
                    }
                } else {
                    const trimmed = std.mem.trim(u8, after_colon, " \t");
                    if (trimmed.len > 0) {
                        return allocator.dupe(u8, trimmed) catch null;
                    }
                }
            }
        }
    }
    return null;
}

fn tryNvidiaProc(allocator: std.mem.Allocator) ?[]const u8 {
    var gpus_dir = std.fs.openDirAbsolute("/proc/driver/nvidia/gpus", .{ .iterate = true }) catch return null;
    defer gpus_dir.close();
    var iter = gpus_dir.iterate();
    while (iter.next() catch return null) |entry| {
        if (entry.kind == .directory) {
            var path_buf: [512]u8 = undefined;
            const info_path = std.fmt.bufPrint(&path_buf, "/proc/driver/nvidia/gpus/{s}/information", .{entry.name}) catch continue;
            var file = std.fs.openFileAbsolute(info_path, .{}) catch continue;
            defer file.close();
            var buf: [4096]u8 = undefined;
            const bytes_read = file.readAll(&buf) catch continue;
            const contents = buf[0..bytes_read];
            var lines = std.mem.splitSequence(u8, contents, "\n");
            while (lines.next()) |line| {
                if (std.mem.startsWith(u8, line, "Model:")) {
                    const model = std.mem.trim(u8, line["Model:".len..], " \t\r");
                    if (model.len > 0) {
                        return allocator.dupe(u8, model) catch null;
                    }
                }
            }
        }
    }
    return null;
}