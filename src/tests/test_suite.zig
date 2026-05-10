const std = @import("std");

const info = @import("info");
const cli = @import("cli");
const output_mod = @import("output");
const logos_mod = @import("logos");
const linux_cpu = @import("linux_cpu");
const linux_memory = @import("linux_memory");
const linux_os = @import("linux_os");
const linux_utils = @import("linux_utils");
const macos_os = @import("macos_os");

test {
    _ = info;
    _ = cli;
    _ = output_mod;
    _ = logos_mod;
    _ = linux_cpu;
    _ = linux_memory;
    _ = linux_os;
    _ = linux_utils;
    _ = macos_os;
}