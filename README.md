# zf

A neofetch-inspired system information CLI tool written in Zig.

Displays OS, CPU, GPU, memory, packages, DE, WM, and system info alongside a distro-specific ASCII logo.

## Features

- Distro-specific ASCII art logos (Debian, Ubuntu, Arch, Fedora, macOS, and more) with ANSI colors
- Automatic light/dark terminal theme detection — adjusts label and value colors for readability
- Falls back to a default **zf** logo for unrecognized distros
- L1/L2/L3 cache info from sysfs (Linux) or sysctl (macOS)
- GPU detection via nvidia-smi, lspci, or system_profiler
- Package counts from dpkg, rpm, pacman, apk, snap, flatpak (Linux) or brew, port (macOS)
- Desktop Environment detection with version (GNOME, KDE Plasma, XFCE, Cinnamon, MATE, LXQt)
- Window Manager detection with version
- Shell detection with version (bash, zsh, fish, etc.)
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
# Default: neofetch-style summary with logo
zf

# Category filters
zf --cpu          # Detailed CPU info + GPU
zf --mem          # Memory info only
zf --os           # OS, uptime, packages, shell, DE, WM info

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

## Display Sections

### Default (with logo)

OS, Kernel, Hostname, Uptime, Packages, Shell (with version), DE (with version), WM (with version), Terminal, User, CPU, CPU Cores, CPU Speed, L1/L2/L3 Cache, GPU, Memory (used/total)

### `--os`

OS, Kernel, Hostname, Uptime, Packages, Shell (with version), DE (with version), WM (with version), Terminal, User

### `--cpu`

CPU, CPU Arch, CPU Vendor, CPU Family, CPU Model, CPU Cores, CPU Speed, Microcode, L1/L2/L3 Cache, GPU

### `--mem`

Total Memory, Free Memory

### `--all`

All fields, no logo

## Examples

### Default (`zf`)

```
       _,met$$$$$gg.          OS: Debian GNU/Linux 13 (trixie)
    ,g$$$$$$$$$$$$$$$P.      Kernel: 7.0.3-zabbly+
  ,g$$P"        """Y$$..     Hostname: ryzen
 ,$$P'              `$$$.    Uptime: 3h 36m
',$$P       ,ggs.     `$$b:  Packages: 2712 (dpkg), 39 (flatpak)
`d$$'     ,$$P   .    $$$    Shell: bash 5.2.37
 $$P      d$$'     ,    $$P  DE: GNOME 46
 $$:      $$$.   -    ,d$$'  WM: mutter 46.0
 $$;      Y$b._   _,d$P'     Terminal: xterm-256color
 Y$$.    `."Y$$$$P"          User: ng
 `$$b      "-.__              CPU: AMD Ryzen 5 2600 Six-Core Processor
  `Y$$                        CPU Cores: 6
    `Y$$.                     CPU Speed: 3659 MHz
      `$$b.                   L1 Cache: 32K
        `Y$$b.                L2 Cache: 512K
           "Y$b._             L3 Cache: 8192K
               """            GPU: NVIDIA GeForce RTX 4060 Ti
                             Memory: 8.2 GiB / 15.5 GiB
```

### CPU only (`zf --cpu`)

```
       _,met$$$$$gg.          CPU: AMD Ryzen 5 2600 Six-Core Processor
    ,g$$$$$$$$$$$$$$$P.      CPU Arch: x86_64
  ,g$$P"        """Y$$..     CPU Vendor: AuthenticAMD
 ,$$P'              `$$$.    CPU Family: 23
',$$P       ,ggs.     `$$b:  CPU Model: AMD Ryzen 5 2600 Six-Core Processor
`d$$'     ,$$P   .    $$$    CPU Cores: 6
 $$P      d$$'     ,    $$P  CPU Speed: 2461 MHz
 $$:      $$$.   -    ,d$$'  Microcode: 0x800820e
 $$;      Y$b._   _,d$P'     L1 Cache: 32K
 Y$$.    `."Y$$$$P"          L2 Cache: 512K
 `$$b      "-.__              L3 Cache: 8192K
  `Y$$                        GPU: NVIDIA GeForce RTX 4060 Ti
    `Y$$.
      `$$b.
        `Y$$b.
           "Y$b._
               """
```

### All info (`zf --all`)

```
OS: Debian GNU/Linux 13 (trixie)
Kernel: 7.0.3-zabbly+
Hostname: ryzen
Uptime: 3h 37m
Packages: 2712 (dpkg), 39 (flatpak)
Shell: bash 5.2.37
DE: GNOME 46
WM: mutter 46.0
Terminal: xterm-256color
User: ng
CPU: AMD Ryzen 5 2600 Six-Core Processor
CPU Arch: x86_64
CPU Vendor: AuthenticAMD
CPU Family: 23
CPU Model: AMD Ryzen 5 2600 Six-Core Processor
CPU Cores: 6
CPU Speed: 3592 MHz
Microcode: 0x800820e
L1 Cache: 32K
L2 Cache: 512K
L3 Cache: 8192K
GPU: NVIDIA GeForce RTX 4060 Ti
Total Memory: 15.5 GiB
Free Memory: 7.3 GiB
```

## Exit Codes

| Code | Meaning          |
| ---- | ---------------- |
| 0    | Success          |
| 1    | General error    |
| 2    | Invalid argument |

## Distro Logos

| Distribution       | Logo  | Label Color |
| ------------------ | ----- | ----------- |
| Debian             | Tux   | Red         |
| Ubuntu             | Circle| Red         |
| Arch Linux         | Arch  | Cyan        |
| Fedora             | Hat   | Blue        |
| macOS              | Apple | Green       |
| Linux Mint         | Circle| Green       |
| Pop!\_OS           | Circle| Cyan        |
| openSUSE           | Circle| Green       |
| Manjaro            | Arch  | Green       |
| Gentoo             | Circle| Magenta     |
| NixOS              | Circle| Blue        |
| Other (default)   | zf    | Cyan        |

Detection uses the `ID=` field from `/etc/os-release` or `DISTRIB_ID=` from `/etc/lsb-release`.

## Theme Detection

`zf` automatically detects whether your terminal is using a light or dark theme:

1. Checks `$COLORSCHEME` environment variable (set by many terminals)
2. Checks `$TERM_THEME` environment variable
3. Checks `$BAT_THEME` for "light" keyword
4. On macOS: runs `defaults read -g AppleInterfaceStyle` — if "Dark" is returned, dark theme; otherwise light theme
5. Defaults to **dark theme** if no detection succeeds

On light themes, labels use bold dark colors and values use black for maximum readability.

## Data Sources

### Linux

| Field | Source |
|-------|--------|
| OS name, version, distro_id | `/etc/os-release` |
| Kernel | `/proc/version`, fallback `uname -r` |
| Hostname | `/etc/hostname`, fallback `uname -n` |
| CPU info | `/proc/cpuinfo` |
| L1/L2/L3 cache | `/sys/devices/system/cpu/cpu0/cache/indexN/{level,size,type}` |
| Memory | `/proc/meminfo` |
| Uptime | `/proc/uptime` |
| GPU | `nvidia-smi`, `lspci`, `/proc/driver/nvidia/gpus/` |
| Packages | `dpkg-query`, `rpm -qa`, `pacman -Q`, `apk info`, `snap list`, `flatpak list` |
| DE | `$XDG_CURRENT_DESKTOP`, `$DESKTOP_SESSION`; version via `gnome-shell --version`, `plasmashell --version`, etc. |
| WM | `/proc/*/comm` scan + `--version` |
| Shell | `$SHELL` + `$SHELL --version` |
| User, Terminal | Environment variables |

### macOS

| Field | Source |
|-------|--------|
| OS name, version | `SystemVersion.plist` |
| Kernel, Hostname | `uname()` |
| CPU info | `sysctl` (machdep.cpu.*, hw.ncpu) |
| L1/L2/L3 cache | `sysctl` (hw.l1dcachesize, hw.l2cachesize, hw.l3cachesize) |
| Memory | `sysctl hw.memsize` |
| GPU | `system_profiler SPDisplaysDataType` |
| Packages | `brew list`, `port installed` |
| DE | "Aqua" + `sw_vers -productVersion` |
| WM | "Quartz Compositor" + `sw_vers -productVersion` |
| Uptime | `sysctl kern.boottime` |
| Shell | `$SHELL` + `$SHELL --version` |

## Project Structure

```
src/
├── main.zig           # CLI entry point, platform dispatch, shell version
├── info.zig           # SystemInfo struct, extractVersion(), runVersionCmd()
├── cli.zig            # Arg parsing, printHelp, printVersion
├── output.zig         # Side-by-side formatting, DisplayFlags
├── logos.zig           # ASCII logos, getLogo(), visibleLen()
├── linux.zig           # Linux module index
├── linux/cpu.zig       # /proc/cpuinfo + sysfs cache parser
├── linux/memory.zig    # /proc/meminfo parser
├── linux/os.zig        # /etc/os-release, /etc/lsb-release parser
├── linux/utils.zig     # /proc/uptime parser
├── linux/gpu.zig       # nvidia-smi, lspci, nvidia proc GPU detection
├── linux/packages.zig  # dpkg, rpm, pacman, apk, snap, flatpak counting
├── linux/desktop.zig   # DE from env vars + version, WM from /proc scan + version
├── macos.zig           # macOS module index
├── macos/cpu.zig       # sysctl CPU + cache info
├── macos/memory.zig    # sysctl hw.memsize
├── macos/os.zig        # SystemVersion.plist parser, uname
├── macos/utils.zig     # env vars, getcwd, uptime via sysctl
├── macos/gpu.zig       # system_profiler SPDisplaysDataType
├── macos/packages.zig  # brew, port counting
├── macos/desktop.zig   # Aqua + version, Quartz Compositor + version
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