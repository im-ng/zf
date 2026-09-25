const std = @import("std");

pub const SystemInfo = struct {
    os_name: ?[]const u8 = null,
    os_version: ?[]const u8 = null,
    kernel: ?[]const u8 = null,
    hostname: ?[]const u8 = null,
    distro_id: ?[]const u8 = null,

    cpu_arch: ?[]const u8 = null,
    cpu_vendor: ?[]const u8 = null,
    cpu_family: ?[]const u8 = null,
    cpu_model: ?[]const u8 = null,
    cpu_model_name: ?[]const u8 = null,
    cpu_cores: ?usize = null,
    cpu_speed: ?f64 = null,
    microcode: ?[]const u8 = null,
    l1_cache: ?[]const u8 = null,
    l2_cache: ?[]const u8 = null,
    l3_cache: ?[]const u8 = null,

    gpu: ?[]const u8 = null,
    packages: ?[]const u8 = null,
    de: ?[]const u8 = null,
    wm: ?[]const u8 = null,

    total_memory: ?usize = null,
    free_memory: ?usize = null,

    shell: ?[]const u8 = null,
    user: ?[]const u8 = null,
    uptime: ?f64 = null,
    terminal: ?[]const u8 = null,
    cwd: ?[]const u8 = null,

    allocator: std.mem.Allocator = undefined,

    pub fn deinit(self: *SystemInfo) void {
        const alloc = self.allocator;
        if (self.os_name) |v| alloc.free(v);
        if (self.os_version) |v| alloc.free(v);
        if (self.kernel) |v| alloc.free(v);
        if (self.hostname) |v| alloc.free(v);
        if (self.distro_id) |v| alloc.free(v);
        if (self.cpu_arch) |v| alloc.free(v);
        if (self.cpu_vendor) |v| alloc.free(v);
        if (self.cpu_family) |v| alloc.free(v);
        if (self.cpu_model) |v| alloc.free(v);
        if (self.cpu_model_name) |v| alloc.free(v);
        if (self.microcode) |v| alloc.free(v);
        if (self.l1_cache) |v| alloc.free(v);
        if (self.l2_cache) |v| alloc.free(v);
        if (self.l3_cache) |v| alloc.free(v);
        if (self.gpu) |v| alloc.free(v);
        if (self.packages) |v| alloc.free(v);
        if (self.de) |v| alloc.free(v);
        if (self.wm) |v| alloc.free(v);
        if (self.shell) |v| alloc.free(v);
        if (self.user) |v| alloc.free(v);
        if (self.terminal) |v| alloc.free(v);
        if (self.cwd) |v| alloc.free(v);
    }
};

pub const Context = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    environ: *std.process.Environ.Map,
};

pub fn setValue(allocator: std.mem.Allocator, comptime T: type, field: *?[]const u8, line: []const u8, key: []const u8) !void {
    _ = T;
    if (!std.mem.startsWith(u8, line, key)) return;
    const separator_pos = std.mem.indexOfScalar(u8, line, ':') orelse return;
    const value = std.mem.trim(u8, line[separator_pos + 1 ..], " \t");
    if (value.len == 0) return;
    const owned = try allocator.dupe(u8, value);
    if (field.*) |old| allocator.free(old);
    field.* = owned;
}

pub fn setNumericValue(field: *?usize, line: []const u8, key: []const u8) void {
    if (!std.mem.startsWith(u8, line, key)) return;
    const separator_pos = std.mem.indexOfScalar(u8, line, ':') orelse return;
    const value = std.mem.trim(u8, line[separator_pos + 1 ..], " \t");
    field.* = std.fmt.parseInt(usize, value, 10) catch null;
}

pub fn setFloatValue(field: *?f64, line: []const u8, key: []const u8) void {
    if (!std.mem.startsWith(u8, line, key)) return;
    const separator_pos = std.mem.indexOfScalar(u8, line, ':') orelse return;
    const value = std.mem.trim(u8, line[separator_pos + 1 ..], " \t");
    field.* = std.fmt.parseFloat(f64, value) catch null;
}

pub fn readFileAlloc(allocator: std.mem.Allocator, io: std.Io, path: []const u8) ?[]const u8 {
    const file = std.Io.Dir.openFileAbsolute(io, path, .{}) catch return null;
    defer file.close(io);
    const st = file.stat(io) catch return null;
    const size: usize = @intCast(st.size);
    const buf = allocator.alloc(u8, size) catch return null;
    const bytes_read = file.readPositionalAll(io, buf, 0) catch return null;
    if (bytes_read < size) {
        allocator.free(buf);
        return null;
    }
    return buf;
}

pub fn readSmallFile(io: std.Io, path: []const u8, buf: []u8) ?[]const u8 {
    const file = std.Io.Dir.openFileAbsolute(io, path, .{}) catch return null;
    defer file.close(io);
    const bytes_read = file.readPositionalAll(io, buf, 0) catch return null;
    return buf[0..bytes_read];
}

/// Runs `argv` and returns a trimmed copy of its stdout, or `null` on any
/// failure. Caller owns the returned slice. Replaces the removed
/// `std.process.Child.run` for Zig 0.16.
pub fn runCapture(allocator: std.mem.Allocator, io: std.Io, argv: []const []const u8) ?[]const u8 {
    const result = std.process.run(allocator, io, .{ .argv = argv }) catch return null;
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);
    const trimmed = std.mem.trim(u8, result.stdout, " \t\n\r");
    if (trimmed.len == 0) return null;
    return allocator.dupe(u8, trimmed) catch null;
}

/// Returns true when a light color scheme should be used. Reads well-known
/// theme environment variables; defaults to light when unset. macOS
/// `defaults read` auto-detection is intentionally omitted (it required a
/// removed `std.process.Child.run`).
pub fn detectLightTheme() bool {
    if (std.c.getenv("COLORSCHEME")) |cs| {
        const scheme = std.mem.sliceTo(cs, 0);
        if (containsIgnoreCase(scheme, "light")) return true;
        if (containsIgnoreCase(scheme, "dark")) return false;
    }
    if (std.c.getenv("TERM_THEME")) |tt| {
        const theme = std.mem.sliceTo(tt, 0);
        if (containsIgnoreCase(theme, "light")) return true;
        if (containsIgnoreCase(theme, "dark")) return false;
    }
    if (std.c.getenv("BAT_THEME")) |bt| {
        const theme = std.mem.sliceTo(bt, 0);
        if (containsIgnoreCase(theme, "light")) return true;
    }
    return true;
}

pub fn parseUptime(contents: []const u8) ?f64 {
    const dot_pos = std.mem.indexOfScalar(u8, contents, '.') orelse return null;
    const space_pos = std.mem.indexOfScalar(u8, contents, ' ') orelse return null;
    if (space_pos < dot_pos) return null;
    const seconds_str = contents[0..space_pos];
    return std.fmt.parseFloat(f64, seconds_str) catch null;
}

/// Runs `argv` and returns the extracted version string from its stdout, or
/// `null` on any failure. Caller owns the returned slice.
pub fn runVersionCmd(ctx: Context, argv: []const []const u8) ?[]const u8 {
    const result = std.process.run(ctx.allocator, ctx.io, .{ .argv = argv }) catch return null;
    defer ctx.allocator.free(result.stdout);
    defer ctx.allocator.free(result.stderr);
    const trimmed = std.mem.trim(u8, result.stdout, " \t\n\r");
    if (trimmed.len == 0) return null;
    const ver = extractVersion(trimmed) orelse return null;
    return ctx.allocator.dupe(u8, ver) catch null;
}

/// Returns the shell name plus its version (e.g. "bash 5.2.37") by combining
/// the `$SHELL` basename with `$SHELL --version`. Falls back to just the
/// basename when version detection fails.
pub fn getShellWithVersion(ctx: Context) ?[]const u8 {
    const shell = ctx.environ.get("SHELL") orelse return null;
    const base = std.fs.path.basename(shell);
    if (base.len == 0) return null;
    const ver = runVersionCmd(ctx, &.{ shell, "--version" }) orelse {
        return ctx.allocator.dupe(u8, base) catch null;
    };
    const combined = std.fmt.allocPrint(ctx.allocator, "{s} {s}", .{ base, ver }) catch {
        ctx.allocator.free(ver);
        return ctx.allocator.dupe(u8, base) catch null;
    };
    ctx.allocator.free(ver);
    return combined;
}

pub fn extractVersion(text: []const u8) ?[]const u8 {
    var i: usize = 0;
    while (i < text.len) : (i += 1) {
        if (text[i] >= '0' and text[i] <= '9') {
            if (i + 2 < text.len and text[i + 1] == '.' and text[i + 2] >= '0' and text[i + 2] <= '9') {
                var end = i;
                while (end < text.len) {
                    if (text[end] >= '0' and text[end] <= '9') {
                        end += 1;
                    } else if (text[end] == '.' and end + 1 < text.len and text[end + 1] >= '0' and text[end + 1] <= '9') {
                        end += 1;
                    } else {
                        break;
                    }
                }
                if (end > 0 and text[end - 1] == '.') end -= 1;
                if (end - i >= 3) return text[i..end];
            }
        }
    }
    return null;
}

pub fn containsIgnoreCase(haystack: []const u8, needle: []const u8) bool {
    if (needle.len > haystack.len) return false;
    var i: usize = 0;
    while (i <= haystack.len - needle.len) : (i += 1) {
        var match = true;
        for (needle, 0..) |c, j| {
            const hc = if (haystack[i + j] >= 'A' and haystack[i + j] <= 'Z') haystack[i + j] + 32 else haystack[i + j];
            const nc = if (c >= 'A' and c <= 'Z') c + 32 else c;
            if (hc != nc) {
                match = false;
                break;
            }
        }
        if (match) return true;
    }
    return false;
}
