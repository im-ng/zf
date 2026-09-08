const std = @import("std");
const builtin = @import("builtin");
const info = @import("info");

pub fn getCpuInfoFromString(ctx: info.Context, contents: []const u8) info.SystemInfo {
    const allocator = ctx.allocator;
    var sys = info.SystemInfo{ .allocator = allocator };
    var lines = std.mem.splitSequence(u8, contents, "\n");
    while (lines.next()) |line| {
        info.setValue(allocator, []const u8, &sys.cpu_vendor, line, "vendor_id") catch {};
        info.setValue(allocator, []const u8, &sys.cpu_family, line, "cpu family") catch {};
        info.setValue(allocator, []const u8, &sys.cpu_model, line, "model") catch {};
        info.setValue(allocator, []const u8, &sys.cpu_model_name, line, "model name") catch {};
        info.setValue(allocator, []const u8, &sys.microcode, line, "microcode") catch {};

        if (std.mem.startsWith(u8, line, "cpu cores")) {
            const sep = std.mem.indexOfScalar(u8, line, ':') orelse continue;
            const val = std.mem.trim(u8, line[sep + 1 ..], " \t");
            sys.cpu_cores = std.fmt.parseInt(usize, val, 10) catch null;
        }
        if (std.mem.startsWith(u8, line, "cpu MHz")) {
            const sep = std.mem.indexOfScalar(u8, line, ':') orelse continue;
            const val = std.mem.trim(u8, line[sep + 1 ..], " \t");
            sys.cpu_speed = std.fmt.parseFloat(f64, val) catch null;
        }
    }

    readCacheInfo(ctx, &sys);
    sys.cpu_arch = allocator.dupe(u8, @tagName(builtin.cpu.arch)) catch null;
    return sys;
}

fn readCacheInfo(ctx: info.Context, sys: *info.SystemInfo) void {
    const allocator = ctx.allocator;
    var index: usize = 0;
    while (true) : (index += 1) {
        var level_path_buf: [128]u8 = undefined;
        const level_path = std.fmt.bufPrint(&level_path_buf, "/sys/devices/system/cpu/cpu0/cache/index{d}/level", .{index}) catch break;
        var level_data_buf: [64]u8 = undefined;
        const level_data = info.readSmallFile(ctx, level_path, &level_data_buf) orelse break;
        const level = std.fmt.parseInt(usize, std.mem.trim(u8, level_data, " \n"), 10) catch continue;

        var size_path_buf: [128]u8 = undefined;
        const size_path = std.fmt.bufPrint(&size_path_buf, "/sys/devices/system/cpu/cpu0/cache/index{d}/size", .{index}) catch break;
        var size_data_buf: [64]u8 = undefined;
        const size_data = info.readSmallFile(ctx, size_path, &size_data_buf) orelse continue;
        const size = std.mem.trim(u8, size_data, " \n");

        var type_path_buf: [128]u8 = undefined;
        const type_path = std.fmt.bufPrint(&type_path_buf, "/sys/devices/system/cpu/cpu0/cache/index{d}/type", .{index}) catch break;
        var type_data_buf: [64]u8 = undefined;
        const type_data = info.readSmallFile(ctx, type_path, &type_data_buf) orelse continue;
        const cache_type = std.mem.trim(u8, type_data, " \n");

        if (level == 1) {
            if (sys.l1_cache == null and (std.mem.eql(u8, cache_type, "Data") or std.mem.eql(u8, cache_type, "Unified"))) {
                sys.l1_cache = allocator.dupe(u8, size) catch null;
            }
        } else if (level == 2) {
            if (sys.l2_cache == null) sys.l2_cache = allocator.dupe(u8, size) catch null;
        } else if (level == 3) {
            if (sys.l3_cache == null) sys.l3_cache = allocator.dupe(u8, size) catch null;
        }
    }
}

test "parse cpuinfo" {
    const allocator = std.testing.allocator;
    var environ_map = std.process.Environ.Map.init(allocator);
    defer environ_map.deinit();
    const ctx = info.Context{ .allocator = allocator, .io = std.testing.io, .environ = &environ_map };
    const sample =
        \\processor : 0
        \\vendor_id : GenuineIntel
        \\cpu family : 6
        \\model : 142
        \\model name : Intel(R) Core(TM) i7-8550U CPU @ 1.80GHz
        \\cpu MHz : 2000.000
        \\cache size : 8192 KB
        \\cpu cores : 4
        \\microcode : 0x96
        \\
    ;
    var sys = getCpuInfoFromString(ctx, sample);
    defer sys.deinit();

    try std.testing.expect(sys.cpu_vendor != null);
    try std.testing.expectEqualStrings("GenuineIntel", sys.cpu_vendor.?);
    try std.testing.expect(sys.cpu_family != null);
    try std.testing.expectEqualStrings("6", sys.cpu_family.?);
    try std.testing.expect(sys.cpu_model != null);
    try std.testing.expectEqualStrings("142", sys.cpu_model.?);
    try std.testing.expect(sys.cpu_model_name != null);
    try std.testing.expect(sys.cpu_cores != null);
    try std.testing.expectEqual(@as(usize, 4), sys.cpu_cores.?);
    try std.testing.expect(sys.cpu_speed != null);
    try std.testing.expect(sys.microcode != null);
}

test "parse empty cpuinfo" {
    const allocator = std.testing.allocator;
    var environ_map = std.process.Environ.Map.init(allocator);
    defer environ_map.deinit();
    const ctx = info.Context{ .allocator = allocator, .io = std.testing.io, .environ = &environ_map };
    var sys = getCpuInfoFromString(ctx, "");
    defer sys.deinit();
    try std.testing.expect(sys.cpu_vendor == null);
    try std.testing.expect(sys.cpu_cores == null);
}