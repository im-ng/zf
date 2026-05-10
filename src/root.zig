const std = @import("std");

pub const info = @import("info");
pub const logos = @import("logos");
pub const output = @import("output");
pub const cli = @import("cli");
pub const linux = @import("linux");
pub const macos = @import("macos");

pub const SystemInfo = info.SystemInfo;
pub const Context = info.Context;

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try std.testing.expect(add(3, 7) == 10);
}