const std = @import("std");
const builtin = @import("builtin");

const zf = @import("zf");

pub fn main(init: std.process.Init) !u8 {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args_it = std.process.Args.Iterator.initAllocator(init.minimal.args, allocator) catch {
        std.debug.print("Error: failed to allocate arguments\n", .{});
        return 1;
    };
    defer args_it.deinit();
    var args = std.ArrayList([]const u8).empty;
    defer args.deinit(allocator);
    while (args_it.next()) |arg| {
        args.append(allocator, arg) catch {
            std.debug.print("Error: failed to allocate arguments\n", .{});
            return 1;
        };
    }

    var parsed_args: zf.Args = .{ .show_info = true };
    if (args.items.len > 1) {
        parsed_args = zf.cli.parseArgs(args.items[1..]) catch {
            std.debug.print("Error: invalid argument. Use --help for usage.\n", .{});
            return 2;
        };
    }

    if (parsed_args.show_help) {
        var out_buf: [4096]u8 = undefined;
        var out = std.Io.File.stdout().writer(init.io, &out_buf);
        try zf.cli.printHelp(&out.interface);
        try std.Io.Writer.flush(&out.interface);
        return 0;
    }

    if (parsed_args.show_version) {
        var out_buf: [256]u8 = undefined;
        var out = std.Io.File.stdout().writer(init.io, &out_buf);
        try zf.cli.printVersion(&out.interface);
        try std.Io.Writer.flush(&out.interface);
        return 0;
    }

    const display_flags = zf.cli.argsToDisplayFlags(parsed_args);
    const is_linux = builtin.os.tag == .linux;

    var sys: zf.SystemInfo = zf.gather.gather(allocator, init.io);
    defer sys.deinit();

    const result = zf.output.formatOutput(allocator, sys, display_flags, is_linux) catch |err| {
        std.debug.print("Error formatting output: {}\n", .{err});
        return 1;
    };
    defer allocator.free(result);

    var out_buf: [8192]u8 = undefined;
    var out = std.Io.File.stdout().writer(init.io, &out_buf);
    out.interface.writeAll(result) catch {
        return 1;
    };
    try std.Io.Writer.flush(&out.interface);

    return 0;
}
