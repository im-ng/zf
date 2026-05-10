const std = @import("std");

pub const LogoSet = struct {
    logo: []const []const u8,
    label_color: []const u8,
    value_color: []const u8,
};

const R = "\x1b[0m";
const red = "\x1b[31m";
const grn = "\x1b[32m";
const yel = "\x1b[33m";
const blu = "\x1b[34m";
const mag = "\x1b[35m";
const cyn = "\x1b[36m";
const wht = "\x1b[37m";
const brd = "\x1b[1;31m";
const bgr = "\x1b[1;32m";
const byl = "\x1b[1;33m";
const bbl = "\x1b[1;34m";
const bcy = "\x1b[1;36m";
const bwh = "\x1b[1;37m";

const zf_logo = [_][]const u8{
    "                           ",
    bcy ++ "       ████" ++ R ++ "                  ",
    bcy ++ "      ██ ███" ++ " " ++ bwh ++ "████" ++ R ++ " " ++ byl ++ "██  ██" ++ R ++ "   ",
    bcy ++ "     ██   ██" ++ " " ++ bwh ++ "█ ███" ++ R ++ " " ++ byl ++ "█ █ █" ++ R ++ "   ",
    bcy ++ "     ████" ++ "   " ++ bwh ++ "█████" ++ R ++ " " ++ byl ++ "█ █ █" ++ R ++ "   ",
    "                           ",
    "                           ",
    "                           ",
    "                           ",
    "                           ",
    "                           ",
    "                           ",
    "                           ",
    "                           ",
};

const debian_logo = [_][]const u8{
    brd ++ "       _,met$$$$$gg." ++ R,
    brd ++ "    ,g$$$$$$$$$$$$$$$P." ++ R,
    brd ++ "  ,g$$P\"        \"\"\"Y$$.." ++ R,
    brd ++ " ,$$P'              `$$$." ++ R,
    brd ++ "',$$P       ,ggs.     `$$b:" ++ R,
    brd ++ "`d$$'     ,$$P" ++ bwh ++ "   .    $$$" ++ R,
    brd ++ " $$P      d$$'     ,    $$P" ++ R,
    brd ++ " $$:      $$$.   " ++ byl ++ "-    ,d$$'" ++ R,
    brd ++ " $$;      Y$b._   _,d$P'" ++ R,
    brd ++ " Y$$.    " ++ bwh ++ "`.\"Y$$$$P\"" ++ R,
    bwh ++ " `$$b      " ++ brd ++ "\"-.__" ++ R,
    bwh ++ "  `Y$$" ++ R,
    brd ++ "    `Y$$." ++ R,
    brd ++ "      `$$b." ++ R,
    brd ++ "        `Y$$b." ++ R,
    bwh ++ "           \"Y$b._" ++ R,
    bwh ++ "               \"\"\"" ++ R,
};

const ubuntu_logo = [_][]const u8{
    brd ++ "            .-/+oossssoo+/-. " ++ R,
    bwh ++ "        " ++ R ++ " " ++ bwh ++ ":+ssssssssssssssssss+:" ++ R,
    brd ++ "      -+ssssssssssssssssssyyssss+-" ++ R,
    brd ++ "    .ossssssssssssssssssdMMMNysssso." ++ R,
    brd ++ "   /ssssssssssshdmmNNmmyNMMMMhssssss/" ++ R,
    brd ++ "  +ssssssssshmydMMMMMMMNddddyssssssss+" ++ R,
    brd ++ " /sssssssshNMMMyhhyyyyhmNMMMNhssssssss/" ++ R,
    brd ++ ".ssssssssdMMMNhsssssssssshNMMMdssssssss." ++ R,
    brd ++ "+sssshhhyNMMNyssssssssssssyNMMMysssssss+" ++ R,
    brd ++ "ossyNMMMNyMMhsssssssssssssshmmmhssssssso" ++ R,
    brd ++ "ossyNMMMNyMMhsssssssssssssshmmmhssssssso" ++ R,
    brd ++ "+sssshhhyNMMNyssssssssssssyNMMMysssssss+" ++ R,
    brd ++ ".ssssssssdMMMNhsssssssssshNMMMdssssssss." ++ R,
    bwh ++ " \\ssssssss" ++ bwh ++ "hNMMM" ++ brd ++ "yhhyyyyhdNMMMNhssssssss/" ++ R,
    brd ++ "  +sssssssssdmydMMMMMMMMddddyssssssss+" ++ R,
    bwh ++ "   " ++ bwh ++ "\\sssssssssss" ++ brd ++ "hdmNNNNmyNMMMMhssssss/" ++ R,
    brd ++ "    .ossssssssssssssssssdMMMNysssso." ++ R,
    brd ++ "      -+ssssssssssssssssyyyssss+-" ++ R,
    bwh ++ "        " ++ bwh ++ ":+ssssssssssssssssss+:" ++ R,
    brd ++ "            .-/+oossssoo+/-. " ++ R,
};

const arch_logo = [_][]const u8{
    bcy ++ "                   -`" ++ R,
    bcy ++ "                  .o+`" ++ R,
    bcy ++ "                 `ooo/" ++ R,
    bcy ++ "                `+oooo:" ++ R,
    bcy ++ "               `+oooooo:" ++ R,
    bcy ++ "               -+oooooo+:" ++ R,
    bcy ++ "             `/:-:++oooo+:" ++ R,
    bcy ++ "            `/++++/+++++++:" ++ R,
    bcy ++ "           `/++++++++++++++:" ++ R,
    bcy ++ "          `/+++o" ++ bwh ++ "oooooooo" ++ bcy ++ "oooo/`" ++ R,
    bwh ++ "         " ++ bcy ++ "./" ++ bwh ++ "ooosssso++osssssso" ++ bcy ++ "+`" ++ R,
    bwh ++ "        .oossssso-" ++ bcy ++ "````" ++ bwh ++ "/ossssss+`" ++ R,
    bwh ++ "       -osssssso." ++ R ++ "      " ++ bwh ++ ":ssssssso." ++ R,
    bwh ++ "      :osssssss/        osssso+++." ++ R,
    bwh ++ "     /ossssssss/        +ssssooo/-" ++ R,
    bwh ++ "   `/ossssso+/:-        -:/+osssso+-" ++ R,
    bwh ++ "  `+sso+:-`                 `.-/+oso:" ++ R,
    bwh ++ " `++:-`                         `-/+/" ++ R,
    bwh ++ " .`                                 `/" ++ R,
};

const fedora_logo = [_][]const u8{
    bbl ++ "             .',;::::;,'." ++ R,
    bbl ++ "          .';:cccccccccccc:;,." ++ R,
    bbl ++ "       .;cccccccccccccccccccccc;." ++ R,
    bbl ++ "     .:cccccccccccccccccccccccccc:." ++ R,
    bbl ++ "   .;ccccccccccccc;" ++ bwh ++ ".:dddl:." ++ bbl ++ ";ccccccc;." ++ R,
    bbl ++ "  .:ccccccccccccc;" ++ bwh ++ "OWMKOOXMWd" ++ bbl ++ ";ccccccc:." ++ R,
    bbl ++ " .:ccccccccccccc;" ++ bwh ++ "KMMc" ++ bbl ++ ";cc;" ++ bwh ++ "xMMc" ++ bbl ++ ";ccccccc:." ++ R,
    bbl ++ ",cccccccccccccc;" ++ bwh ++ "MMM." ++ bbl ++ ";cc;" ++ bwh ++ ";WW:" ++ bbl ++ ";cccccccc," ++ R,
    bbl ++ ":cccccccccccccc;" ++ bwh ++ "MMM." ++ bbl ++ ";cccccccccccccccc:" ++ R,
    bbl ++ ":ccccccc;" ++ bwh ++ "oxOOOo" ++ bbl ++ ";" ++ bwh ++ "MMM0OOk." ++ bbl ++ ";cccccccccccc:" ++ R,
    bbl ++ "cccccc;" ++ bwh ++ "0MMKxdd:" ++ bbl ++ ";" ++ bwh ++ "MMMkddc." ++ bbl ++ ";cccccccccccc;" ++ R,
    bbl ++ "ccccc;" ++ bwh ++ "XM0'" ++ bbl ++ ";cccc;" ++ bwh ++ "MMM." ++ bbl ++ ";cccccccccccccccc'" ++ R,
    bbl ++ "ccccc;" ++ bwh ++ "MMo" ++ bbl ++ ";ccccc;" ++ bwh ++ "MMW." ++ bbl ++ ";cccccccccccccc;" ++ R,
    bbl ++ "ccccc;" ++ bwh ++ "0MNc." ++ bbl ++ "ccc" ++ bwh ++ ".xMMd" ++ bbl ++ ";cccccccccccccc;" ++ R,
    bbl ++ "cccccc;" ++ bwh ++ "dNMWXXXWM0:" ++ bbl ++ ";cccccccccccccc:," ++ R,
    bbl ++ "cccccccc;" ++ bwh ++ ".:odl:." ++ bbl ++ ";cccccccccccccc:,." ++ R,
    bbl ++ ":cccccccccccccccccccccccccccc:" ++ bwh ++ "'" ++ R ++ ".      ",
    bbl ++ " .:cccccccccccccccccccccc:;,.." ++ R,
    bbl ++ "   '::cccccccccccccc::;,." ++ R,
};

const macos_logo = [_][]const u8{
    grn ++ "                    c.'" ++ R,
    grn ++ "                  ,xNMM." ++ R,
    grn ++ "                .OMMMMo" ++ R,
    grn ++ "                lMM\"" ++ R,
    grn ++ "      .;loddo:.  .olloddol;." ++ R,
    grn ++ "    cKMMMMMMMMMMNWMMMMMMMMMM0:" ++ R,
    byl ++ " .KMMMMMMMMMMMMMMMMMMMMMMMWd." ++ R,
    byl ++ "  XMMMMMMMMMMMMMMMMMMMMMMMX." ++ R,
    brd ++ ";MMMMMMMMMMMMMMMMMMMMMMMM:" ++ R,
    brd ++ ":MMMMMMMMMMMMMMMMMMMMMMMM:" ++ R,
    mag ++ ".MMMMMMMMMMMMMMMMMMMMMMMMX." ++ R,
    mag ++ "  lMMMMMMMMMMMMMMMMMMMMMMMWd." ++ R,
    blu ++ "  'XMMMMMMMMMMMMMMMMMMMMMMMMMMk" ++ R,
    blu ++ "   'XMMMMMMMMMMMMMMMMMMMMMMMMK." ++ R,
    blu ++ "     kMMMMMMMMMMMMMMMMMMMMMMd" ++ R,
    blu ++ "      ;KMMMMMMMWXXWMMMMMMMk." ++ R,
    bwh ++ "        \"cooc*\"    \"*coo'\"" ++ R,
};

pub fn getLogo(distro_id: ?[]const u8, is_linux: bool) LogoSet {
    if (distro_id) |id| {
        if (memContains(id, "debian")) return .{ .logo = &debian_logo, .label_color = red, .value_color = wht };
        if (memContains(id, "ubuntu")) return .{ .logo = &ubuntu_logo, .label_color = red, .value_color = wht };
        if (memContains(id, "arch")) return .{ .logo = &arch_logo, .label_color = cyn, .value_color = wht };
        if (memContains(id, "fedora")) return .{ .logo = &fedora_logo, .label_color = blu, .value_color = wht };
        if (memContains(id, "macos") or memContains(id, "darwin")) return .{ .logo = &macos_logo, .label_color = grn, .value_color = wht };
        if (memContains(id, "mint")) return .{ .logo = &ubuntu_logo, .label_color = grn, .value_color = wht };
        if (memContains(id, "pop")) return .{ .logo = &ubuntu_logo, .label_color = cyn, .value_color = wht };
        if (memContains(id, "suse") or memContains(id, "opensuse")) return .{ .logo = &ubuntu_logo, .label_color = grn, .value_color = wht };
        if (memContains(id, "manjaro")) return .{ .logo = &arch_logo, .label_color = grn, .value_color = wht };
        if (memContains(id, "gentoo")) return .{ .logo = &ubuntu_logo, .label_color = mag, .value_color = wht };
        if (memContains(id, "nixos")) return .{ .logo = &ubuntu_logo, .label_color = blu, .value_color = wht };
    }
    if (is_linux) {
        return .{ .logo = &zf_logo, .label_color = cyn, .value_color = wht };
    }
    return .{ .logo = &macos_logo, .label_color = grn, .value_color = wht };
}

fn memContains(haystack: []const u8, needle: []const u8) bool {
    if (needle.len > haystack.len) return false;
    var i: usize = 0;
    while (i <= haystack.len - needle.len) : (i += 1) {
        if (std.mem.eql(u8, haystack[i .. i + needle.len], needle)) return true;
    }
    return false;
}

pub fn visibleLen(line: []const u8) usize {
    var len: usize = 0;
    var i: usize = 0;
    while (i < line.len) : (i += 1) {
        if (line[i] == '\x1b' and i + 1 < line.len and line[i + 1] == '[') {
            while (i < line.len and line[i] != 'm') : (i += 1) {}
        } else {
            len += 1;
        }
    }
    return len;
}

pub fn getLinuxLogo() []const []const u8 {
    return &debian_logo;
}

pub fn getMacosLogo() []const []const u8 {
    return &macos_logo;
}