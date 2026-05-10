# zf

A neofetch-inspired system information CLI tool written in Zig.

Displays OS, CPU, memory, and system info alongside a distro-specific ASCII logo.

## Features

- Distro-specific ASCII art logos (Debian, Ubuntu, Arch, Fedora, macOS) with ANSI colors
- Falls back to a default **zf** logo for unrecognized distros
- L1/L2/L3 cache info from sysfs (Linux) or sysctl (macOS)
- Side-by-side logo + info layout (like neofetch)
- `--all` mode shows all info without logo
- Category filters: `--cpu`, `--mem`, `--os`
- Zero external dependencies

## Requirements

- Zig 0.15.1

## Build

```bash
zig build
```

## Usage

```bash
# Default: logo + OS/CPU info
zf

# Category filters
zf --cpu          # CPU info only
zf --mem          # Memory info only
zf --os           # OS info only

# All info, no logo
zf --all

# General
zf --help
zf --version
```

## Options

| Option      | Short | Description                          |
| ----------- | ----- | ------------------------------------ |
| `--help`    | `-h`  | Display help message and exit        |
| `--version` | `-v`  | Display version information and exit |
| `--info`    | `-i`  | Show all information (default)       |
| `--cpu`     | `-c`  | Show only CPU information            |
| `--mem`     | `-m`  | Show only memory information         |
| `--os`      | `-o`  | Show only OS information             |
| `--all`     | `-a`  | Show all information without logo    |

## Examples

```
$ zf
       _,met$$$$$gg.          OS: Debian GNU/Linux
    ,g$$$$$$$$$$$$$$$P.      Kernel: 7.0.3-zabbly+
  ,g$$P"        """Y$$..     Hostname: ryzen
 ,$$P'              `$$$.    CPU: AMD Ryzen 5 2600 Six-Core Processor
',$$P       ,ggs.     `$$b:  CPU Arch: x86_64
`d$$'     ,$$P   .    $$$    CPU Vendor: AuthenticAMD
 $$P      d$$'     ,    $$P  CPU Family: 23
 $$:      $$$.   -    ,d$$'  CPU Model: AMD Ryzen 5 2600 Six-Core Processor
 $$;      Y$b._   _,d$P'     CPU Cores: 6
 Y$$.    `."Y$$$$P"          CPU Speed: 1517.84 MHz
 `$$b      "-.__              Microcode: 0x800820e
  `Y$$                        L1 Cache: 32K
    `Y$$.                     L2 Cache: 512K
      `$$b.                   L3 Cache: 8192K
        `Y$$b.
           "Y$b._
               """

$ zf --cpu
       _,met$$$$$gg.          CPU: AMD Ryzen 5 2600 Six-Core Processor
    ,g$$$$$$$$$$$$$$$P.      CPU Arch: x86_64
  ,g$$P"        """Y$$..     CPU Vendor: AuthenticAMD
 ,$$P'              `$$$.    CPU Family: 23
',$$P       ,ggs.     `$$b:  CPU Model: AMD Ryzen 5 2600 Six-Core Processor
`d$$'     ,$$P   .    $$$    CPU Cores: 6
 $$P      d$$'     ,    $$P  CPU Speed: 1517.84 MHz
 $$:      $$$.   -    ,d$$'  Microcode: 0x800820e
 $$;      Y$b._   _,d$P'     L1 Cache: 32K
 Y$$.    `."Y$$$$P"          L2 Cache: 512K
 `$$b      "-.__              L3 Cache: 8192K
  `Y$$
    `Y$$.
      `$$b.
        `Y$$b.
           "Y$b._
               """

$ zf --all
OS: Debian GNU/Linux
Kernel: 7.0.3-zabbly+
Hostname: ryzen
Total Memory: 15.5 GiB
Free Memory: 3.0 GiB
Shell: /bin/bash
User: ng
Terminal: xterm-256color
Uptime: 2h 46m
```

## Exit Codes

| Code | Meaning          |
| ---- | ---------------- |
| 0    | Success          |
| 1    | General error    |
| 2    | Invalid argument |

## Distro Logos

| Distribution    | Logo   | Label Color |
| --------------- | ------ | ----------- |
| Debian          | Tux    | Red         |
| Ubuntu          | Circle | Red         |
| Arch Linux      | Arch   | Cyan        |
| Fedora          | Hat    | Blue        |
| macOS           | Apple  | Green       |
| Linux Mint      | Circle | Green       |
| Pop!\_OS        | Circle | Cyan        |
| openSUSE        | Circle | Green       |
| Manjaro         | Arch   | Green       |
| Gentoo          | Circle | Magenta     |
| NixOS           | Circle | Blue        |
| Other (default) | zf     | Cyan        |

Detection uses the `ID=` field from `/etc/os-release` or `DISTRIB_ID=` from `/etc/lsb-release`.

## Project Structure

```
src/
├── main.zig           # CLI entry point, platform dispatch
├── info.zig           # SystemInfo struct, Context, parsers
├── cli.zig            # Arg parsing, printHelp, printVersion
├── output.zig         # Side-by-side formatting, DisplayFlags
├── logos.zig           # ASCII logos, getLogo(), visibleLen()
├── linux.zig           # Linux module index
├── linux/cpu.zig       # /proc/cpuinfo + sysfs cache parser
├── linux/memory.zig    # /proc/meminfo parser
├── linux/os.zig        # /etc/os-release, /etc/lsb-release parser
├── linux/utils.zig     # /proc/uptime parser
├── macos.zig           # macOS module index
├── macos/cpu.zig       # sysctl CPU + cache info
├── macos/memory.zig    # sysctl hw.memsize
├── macos/os.zig        # SystemVersion.plist parser, uname
├── macos/utils.zig     # env var reading
├── root.zig            # Library root, re-exports
└── tests/test_suite.zig
```

## Testing

```bash
zig build test
```

## Attribution

_This entire project coded through GLM 5.1_

## License

MIT
