const std = @import("std");
const output = @import("output");

pub const Args = struct {
    show_help: bool = false,
    show_version: bool = false,
    show_info: bool = false,
    show_cpu: bool = false,
    show_mem: bool = false,
    show_os: bool = false,
    show_all: bool = false,
};

pub const VERSION = "1.0.0";

pub fn parseArgs(args: []const []const u8) !Args {
    var result = Args{};
    var has_category = false;

    for (args) |arg| {
        if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            result.show_help = true;
        } else if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--version")) {
            result.show_version = true;
        } else if (std.mem.eql(u8, arg, "-i") or std.mem.eql(u8, arg, "--info")) {
            result.show_info = true;
            has_category = true;
        } else if (std.mem.eql(u8, arg, "-c") or std.mem.eql(u8, arg, "--cpu")) {
            result.show_cpu = true;
            has_category = true;
        } else if (std.mem.eql(u8, arg, "-m") or std.mem.eql(u8, arg, "--mem")) {
            result.show_mem = true;
            has_category = true;
        } else if (std.mem.eql(u8, arg, "-o") or std.mem.eql(u8, arg, "--os")) {
            result.show_os = true;
            has_category = true;
        } else if (std.mem.eql(u8, arg, "-a") or std.mem.eql(u8, arg, "--all")) {
            result.show_all = true;
            has_category = true;
        } else {
            return error.InvalidArgument;
        }
    }

    if (!has_category and !result.show_help and !result.show_version) {
        result.show_info = true;
    }

    return result;
}

pub fn printHelp(writer: *std.Io.Writer) !void {
    try writer.print(
        \\zf - System Information Tool
        \\
        \\Usage: zf [OPTIONS]
        \\
        \\Options:
        \\  -h, --help     Display this help message and exit
        \\  -v, --version  Display version information and exit
        \\  -i, --info     Show all information (default)
        \\  -c, --cpu      Show only CPU information
        \\  -m, --mem      Show only memory information
        \\  -o, --os       Show only OS information
        \\  -a, --all      Show all information without logo
        \\
    , .{});
}

pub fn printVersion(writer: *std.Io.Writer) !void {
    try writer.print("zf version {s}\n", .{VERSION});
}

pub fn argsToDisplayFlags(args: Args) output.DisplayFlags {
    return .{
        .show_cpu = args.show_cpu,
        .show_mem = args.show_mem,
        .show_os = args.show_os,
        .show_all = args.show_all,
        .show_logo = !args.show_all,
    };
}

test "parseArgs default" {
    const args = try parseArgs(&.{});
    try std.testing.expect(!args.show_help);
    try std.testing.expect(!args.show_version);
    try std.testing.expect(args.show_info);
    try std.testing.expect(!args.show_cpu);
    try std.testing.expect(!args.show_mem);
    try std.testing.expect(!args.show_os);
    try std.testing.expect(!args.show_all);
}

test "parseArgs help" {
    const args = try parseArgs(&.{"--help"});
    try std.testing.expect(args.show_help);
}

test "parseArgs cpu" {
    const args = try parseArgs(&.{"--cpu"});
    try std.testing.expect(args.show_cpu);
}

test "parseArgs combined" {
    const args = try parseArgs(&.{ "--cpu", "--mem" });
    try std.testing.expect(args.show_cpu);
    try std.testing.expect(args.show_mem);
}

test "parseArgs invalid" {
    const result = parseArgs(&.{"--invalid"});
    try std.testing.expectError(error.InvalidArgument, result);
}

test "argsToDisplayFlags default" {
    const args = Args{ .show_info = true };
    const flags = argsToDisplayFlags(args);
    try std.testing.expect(!flags.show_cpu);
    try std.testing.expect(flags.show_logo);
}

test "argsToDisplayFlags all" {
    const args = Args{ .show_all = true };
    const flags = argsToDisplayFlags(args);
    try std.testing.expect(flags.show_all);
    try std.testing.expect(!flags.show_logo);
}