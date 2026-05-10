const std = @import("std");
const info = @import("info");
const logos = @import("logos");

pub const DisplayFlags = packed struct {
    show_cpu: bool = false,
    show_mem: bool = false,
    show_os: bool = false,
    show_all: bool = false,
    show_logo: bool = true,
};

pub fn formatOutput(allocator: std.mem.Allocator, sys: info.SystemInfo, flags: DisplayFlags, is_linux: bool) ![]const u8 {
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(allocator);
    const writer = buf.writer(allocator);

    const logo_set = logos.getLogo(sys.distro_id, is_linux);
    const logo = logo_set.logo;
    const label_color = logo_set.label_color;
    const value_color = logo_set.value_color;
    const reset = "\x1b[0m";

    var lines: std.ArrayList([]const u8) = .empty;
    defer {
        for (lines.items) |line| allocator.free(line);
        lines.deinit(allocator);
    }

    const show_default = !flags.show_os and !flags.show_cpu and !flags.show_mem and !flags.show_all;

    if (flags.show_os or flags.show_all or show_default) {
        if (sys.os_name) |name| {
            if (sys.os_version) |ver| {
                var combined: std.ArrayList(u8) = .empty;
                defer combined.deinit(allocator);
                try combined.appendSlice(allocator, name);
                try combined.appendSlice(allocator, " ");
                try combined.appendSlice(allocator, ver);
                try addField(allocator, &lines, "OS", combined.items, label_color, value_color, reset);
            } else {
                try addField(allocator, &lines, "OS", sys.os_name, label_color, value_color, reset);
            }
        } else {
            try addField(allocator, &lines, "OS", null, label_color, value_color, reset);
        }
        try addField(allocator, &lines, "Kernel", sys.kernel, label_color, value_color, reset);
        try addField(allocator, &lines, "Hostname", sys.hostname, label_color, value_color, reset);
        if (sys.uptime) |u| {
            var num_buf: [64]u8 = undefined;
            const hours = @as(usize, @intFromFloat(u)) / 3600;
            const mins = @as(usize, @intFromFloat(u)) % 3600 / 60;
            const uptime_str = try std.fmt.bufPrint(&num_buf, "{d}h {d}m", .{ hours, mins });
            try addField(allocator, &lines, "Uptime", uptime_str, label_color, value_color, reset);
        } else {
            try addField(allocator, &lines, "Uptime", null, label_color, value_color, reset);
        }
        try addField(allocator, &lines, "Packages", sys.packages, label_color, value_color, reset);
        try addField(allocator, &lines, "Shell", sys.shell, label_color, value_color, reset);
        try addField(allocator, &lines, "DE", sys.de, label_color, value_color, reset);
        try addField(allocator, &lines, "WM", sys.wm, label_color, value_color, reset);
        try addField(allocator, &lines, "Terminal", sys.terminal, label_color, value_color, reset);
        try addField(allocator, &lines, "User", sys.user, label_color, value_color, reset);
    }

    if (flags.show_cpu or flags.show_all or show_default) {
        try addField(allocator, &lines, "CPU", sys.cpu_model_name, label_color, value_color, reset);
        if (flags.show_cpu or flags.show_all) {
            try addField(allocator, &lines, "CPU Arch", sys.cpu_arch, label_color, value_color, reset);
            try addField(allocator, &lines, "CPU Vendor", sys.cpu_vendor, label_color, value_color, reset);
            try addField(allocator, &lines, "CPU Family", sys.cpu_family, label_color, value_color, reset);
            try addField(allocator, &lines, "CPU Model", sys.cpu_model, label_color, value_color, reset);
        }
        if (sys.cpu_cores) |c| {
            var num_buf: [32]u8 = undefined;
            const s = try std.fmt.bufPrint(&num_buf, "{d}", .{c});
            try addField(allocator, &lines, "CPU Cores", s, label_color, value_color, reset);
        } else if (flags.show_cpu or flags.show_all) {
            try addField(allocator, &lines, "CPU Cores", null, label_color, value_color, reset);
        }
        if (sys.cpu_speed) |s| {
            var num_buf: [64]u8 = undefined;
            const str = try std.fmt.bufPrint(&num_buf, "{d:.2} MHz", .{s});
            try addField(allocator, &lines, "CPU Speed", str, label_color, value_color, reset);
        } else if (flags.show_cpu or flags.show_all) {
            try addField(allocator, &lines, "CPU Speed", null, label_color, value_color, reset);
        }
        if (flags.show_cpu or flags.show_all) {
            try addField(allocator, &lines, "Microcode", sys.microcode, label_color, value_color, reset);
            try addField(allocator, &lines, "L1 Cache", sys.l1_cache, label_color, value_color, reset);
            try addField(allocator, &lines, "L2 Cache", sys.l2_cache, label_color, value_color, reset);
            try addField(allocator, &lines, "L3 Cache", sys.l3_cache, label_color, value_color, reset);
        }
        try addField(allocator, &lines, "GPU", sys.gpu, label_color, value_color, reset);
    }

    if (flags.show_mem or flags.show_all) {
        if (sys.total_memory) |m| {
            var mem_buf: [64]u8 = undefined;
            const formatted = formatBytesBuf(&mem_buf, m);
            try addField(allocator, &lines, "Total Memory", formatted, label_color, value_color, reset);
        }
        if (sys.free_memory) |m| {
            var mem_buf: [64]u8 = undefined;
            const formatted = formatBytesBuf(&mem_buf, m);
            try addField(allocator, &lines, "Free Memory", formatted, label_color, value_color, reset);
        }
    } else if (show_default) {
        if (sys.total_memory) |total| {
            var mem_buf: [64]u8 = undefined;
            const total_str = formatBytesBuf(&mem_buf, total);
            if (sys.free_memory) |free| {
                var free_buf: [64]u8 = undefined;
                const used = total - free;
                const used_str = formatBytesBuf(&free_buf, used);
                var combined: std.ArrayList(u8) = .empty;
                defer combined.deinit(allocator);
                try combined.appendSlice(allocator, used_str);
                try combined.appendSlice(allocator, " / ");
                try combined.appendSlice(allocator, total_str);
                try addField(allocator, &lines, "Memory", combined.items, label_color, value_color, reset);
            } else {
                try addField(allocator, &lines, "Memory", total_str, label_color, value_color, reset);
            }
        }
    }

    if (flags.show_logo) {
        const max_lines = @max(logo.len, lines.items.len);
        const logo_visible_width = blk: {
            var w: usize = 0;
            for (logo) |line| {
                const vl = logos.visibleLen(line);
                if (vl > w) w = vl;
            }
            break :blk w;
        };

        for (0..max_lines) |i| {
            if (i < logo.len) {
                try writer.writeAll(logo[i]);
                const vl = logos.visibleLen(logo[i]);
                if (vl < logo_visible_width) {
                    var pad = logo_visible_width - vl;
                    while (pad > 0) : (pad -= 1) {
                        try writer.writeByte(' ');
                    }
                }
            } else {
                var pad = logo_visible_width;
                while (pad > 0) : (pad -= 1) {
                    try writer.writeByte(' ');
                }
            }
            try writer.writeAll("  ");

            if (i < lines.items.len) {
                try writer.writeAll(lines.items[i]);
            }
            try writer.writeByte('\n');
        }
    } else {
        for (lines.items) |line| {
            try writer.writeAll(line);
            try writer.writeByte('\n');
        }
    }

    return buf.toOwnedSlice(allocator);
}

fn addField(allocator: std.mem.Allocator, lines: *std.ArrayList([]const u8), label: []const u8, value: ?[]const u8, label_color: []const u8, value_color: []const u8, reset: []const u8) !void {
    const val = value orelse "Unknown";
    const bold = "\x1b[1m";

    var buf: std.ArrayList(u8) = .empty;
    const writer = buf.writer(allocator);
    try writer.print("{s}{s}{s}{s}: {s}{s}{s}", .{ label_color, bold, label, reset, value_color, val, reset });
    try lines.append(allocator, try buf.toOwnedSlice(allocator));
}

fn formatBytesBuf(buf: []u8, bytes: usize) []const u8 {
    if (bytes > 1073741824) {
        const gb = @as(f64, @floatFromInt(bytes)) / 1073741824.0;
        return std.fmt.bufPrint(buf, "{d:.1} GiB", .{gb}) catch "? GiB";
    } else if (bytes > 1048576) {
        const mb = @as(f64, @floatFromInt(bytes)) / 1048576.0;
        return std.fmt.bufPrint(buf, "{d:.1} MiB", .{mb}) catch "? MiB";
    } else if (bytes > 1024) {
        const kb = @as(f64, @floatFromInt(bytes)) / 1024.0;
        return std.fmt.bufPrint(buf, "{d:.1} KiB", .{kb}) catch "? KiB";
    } else {
        return std.fmt.bufPrint(buf, "{d} B", .{bytes}) catch "? B";
    }
}

test "formatOutput produces output" {
    const allocator = std.testing.allocator;
    var sys = info.SystemInfo{ .allocator = allocator };
    sys.os_name = try allocator.dupe(u8, "TestOS");
    sys.kernel = try allocator.dupe(u8, "5.15.0");
    defer sys.deinit();

    const output = try formatOutput(allocator, sys, .{ .show_os = true, .show_logo = false }, true);
    defer allocator.free(output);
    try std.testing.expect(output.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, output, "TestOS") != null);
}

test "formatOutput with logo" {
    const allocator = std.testing.allocator;
    var sys = info.SystemInfo{ .allocator = allocator };
    sys.os_name = try allocator.dupe(u8, "TestOS");
    sys.distro_id = try allocator.dupe(u8, "debian");
    defer sys.deinit();

    const output = try formatOutput(allocator, sys, .{ .show_os = true, .show_logo = true }, true);
    defer allocator.free(output);
    try std.testing.expect(output.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, output, "TestOS") != null);
}