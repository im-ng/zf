# AGENTS.md

## Project Summary

**zf** is a Zig CLI tool that displays neofetch-style system information with distro-specific ASCII logos for Linux and macOS.

## Build & Run

```bash
zig build          # Build
zig build run      # Run
zig build test     # Run all tests
```

## Project Structure

```
src/
├── main.zig           # CLI entry, platform dispatch, gatherLinuxInfo/gatherMacosInfo, getShellWithVersion()
├── info.zig           # SystemInfo struct, extractVersion(), runVersionCmd(), containsIgnoreCase(), detectLightTheme()
├── cli.zig            # Arg parsing (DisplayFlags), printHelp, printVersion
├── output.zig         # formatOutput(), side-by-side logo+info layout, addField, theme detection
├── logos.zig           # ASCII logos, getLogo(distro_id, is_linux, light_theme), visibleLen(), memContains()
├── linux.zig           # Re-exports: cpu, memory, os, utils, gpu, packages, desktop
├── linux/cpu.zig       # getCpuInfoFromString() parses /proc/cpuinfo + readCacheInfo() from sysfs
├── linux/memory.zig    # getMemoryInfoFromString() parses /proc/meminfo
├── linux/os.zig        # parseOsRelease() from /etc/os-release, parseLsbRelease() from /etc/lsb-release
├── linux/utils.zig     # parseUptime() from /proc/uptime
├── linux/gpu.zig       # getGpuInfo() - nvidia-smi, lspci, /proc/driver/nvidia/gpus/
├── linux/packages.zig  # getPackages() - dpkg, rpm, pacman, apk, snap, flatpak
├── linux/desktop.zig   # getDe() - XDG_CURRENT_DESKTOP/DESKTOP_SESSION + version; getWm() - /proc scan + version
├── macos.zig           # Re-exports: cpu, memory, os, utils, gpu, packages, desktop
├── macos/cpu.zig       # getCpuInfo() via sysctl + readCacheSize() for hw.l{1d,2,3}cachesize
├── macos/memory.zig    # getMemoryInfo() via sysctl hw.memsize
├── macos/os.zig        # getOsInfo() parses SystemVersion.plist + uname + distro_id="macos"
├── macos/utils.zig     # getSystemInfo() reads USER, SHELL, TERM env vars + getcwd + getUptime()
├── macos/gpu.zig       # getGpuInfo() via system_profiler SPDisplaysDataType
├── macos/packages.zig  # getPackages() - brew, port
├── macos/desktop.zig   # getDe() returns "Aqua <version>", getWm() returns "Quartz Compositor <version>"
├── root.zig            # Library root, re-exports modules
└── tests/test_suite.zig # Aggregates all module tests via refAllDecls
```

## Key Facts

- **Executable name**: `zf`
- **Build system**: Zig 0.15.1 native `zig build`
- **Platform detection**: `builtin.os.tag` — Linux reads `/proc/*`, `/sys/*`, `/etc/*`; macOS uses `sysctl`, `SystemVersion.plist`, env vars
- **Logo selection**: `getLogo(distro_id, is_linux, light_theme)` — matches `ID=` from `/etc/os-release` substring; returns dark-theme or light-theme colors based on `detectLightTheme()`
- **Theme detection**: `detectLightTheme()` checks `$COLORSCHEME`, `$TERM_THEME`, `$BAT_THEME` env vars, then runs `defaults read -g AppleInterfaceStyle` on macOS; defaults to dark theme
- **Field formatting**: `addField()` uses `{label_color}{bold}{label}{reset}: {value_color}{val}{reset}`; null values show "Unknown"
- **Version detection**: `extractVersion()` in info.zig finds X.Y.Z patterns in command output; `runVersionCmd()` runs a command and extracts version
- **Shell version**: `$SHELL --version` parsed via `extractVersion()`, shown as "bash 5.2.37" etc.
- **DE version**: `getDe()` runs DE-specific version commands (gnome-shell, plasmashell, etc.)
- **WM version**: `getWm()` tries `--version` flag on WM binary
- **DE name**: Handles `XDG_CURRENT_DESKTOP` formats like "ubuntu:GNOME" (takes last component)

## SystemInfo Fields

- `os_name`, `os_version`, `kernel`, `hostname`, `distro_id`
- `cpu_arch`, `cpu_vendor`, `cpu_family`, `cpu_model`, `cpu_model_name`, `cpu_cores`, `cpu_speed`, `microcode`
- `l1_cache`, `l2_cache`, `l3_cache`
- `gpu`, `packages`, `de`, `wm`
- `total_memory`, `free_memory`
- `shell`, `user`, `uptime`, `terminal`, `cwd`

## DisplayFlags & CLI Options

| Flag | Short | DisplayFlags |
|------|-------|-------------|
| `--info` | `-i` | default (all sections with logo) |
| `--cpu` | `-c` | show_cpu=true (detailed CPU + GPU + cache) |
| `--mem` | `-m` | show_mem=true (total/free memory) |
| `--os` | `-o` | show_os=true (OS, uptime, packages, shell, DE, WM, terminal, user) |
| `--all` | `-a` | show_all=true, show_logo=false (everything) |

## Output Rendering

Default view shows neofetch-style summary with logo:
- OS (name + version combined), Kernel, Hostname, Uptime, Packages, Shell (with version), DE (with version), WM (with version), Terminal, User
- CPU (model + cores + speed), L1/L2/L3 Cache, GPU
- Memory (used / total)

`--os`: OS combined, Kernel, Hostname, Uptime, Packages, Shell (with version), DE (with version), WM (with version), Terminal, User
`--cpu`: Full CPU details (arch, vendor, family, model, cores, speed, microcode, L1/L2/L3 cache) + GPU
`--mem`: Total Memory, Free Memory
`--all`: All fields, no logo

## Linux Data Sources

| Field | Source |
|-------|--------|
| os_name, os_version, distro_id | `/etc/os-release` (`NAME=`, `VERSION=`, `ID=`) |
| kernel | `/proc/version` → fallback `uname -r` |
| hostname | `/etc/hostname` → fallback `uname -n` |
| cpu_* | `/proc/cpuinfo` |
| l1/l2/l3_cache | `/sys/devices/system/cpu/cpu0/cache/indexN/{level,size,type}` |
| total/free memory | `/proc/meminfo` (`MemTotal:`, `MemAvailable:`) |
| uptime | `/proc/uptime` |
| gpu | `nvidia-smi`, `lspci`, `/proc/driver/nvidia/gpus/*/information` |
| packages | `dpkg-query`, `rpm -qa`, `pacman -Q`, `apk info`, `snap list`, `flatpak list` |
| de | `$XDG_CURRENT_DESKTOP`, `$DESKTOP_SESSION`, `$XDG_SESSION_DESKTOP`; version via `gnome-shell --version`, `plasmashell --version`, etc. |
| wm | `/proc/*/comm` scan for known WM process names + `--version` |
| shell | `$SHELL` env var + `$SHELL --version` |
| user, terminal | env vars `USER`, `TERM` |
| cwd | `getcwd()` |

## macOS Data Sources

| Field | Source |
|-------|--------|
| os_name, os_version | `/usr/libexec/SystemVersion.plist` |
| kernel, hostname | `uname()` |
| distro_id | hardcoded `"macos"` |
| cpu_vendor | `sysctl machdep.cpu.vendor` |
| cpu_family | `sysctl machdep.cpu.family` |
| cpu_model_name | `sysctl machdep.cpu.brand_string` |
| cpu_cores | `sysctl hw.ncpu` |
| l1/l2/l3_cache | `sysctl hw.l1dcachesize`, `hw.l2cachesize`, `hw.l3cachesize` |
| total_memory | `sysctl hw.memsize` |
| gpu | `system_profiler SPDisplaysDataType` (Chipset Model / Marketing Name) |
| packages | `brew list -1`, `port installed` |
| de | hardcoded `"Aqua"` + `sw_vers -productVersion` |
| wm | hardcoded `"Quartz Compositor"` + `sw_vers -productVersion` |
| uptime | `sysctl kern.boottime` → current time - boot time |
| shell | `$SHELL` env var + `$SHELL --version` |
| user, terminal | env vars `USER`, `TERM` |

## Zig 0.15.1 API Notes

- `std.ArrayList(T).empty` instead of `.init(allocator)`
- `std.fs.File.stdout().writer(&buf)` then `.interface` for writing
- `std.posix.uname()` returns value, not takes pointer
- `builtin.cpu.arch` not `std.Target.current.cpu.arch`
- `std.process.Child.run()` for executing external commands
- `std.posix.getcwd()` returns `?[]const u8` in some APIs
- String concatenation in comptime: use `++` operator with consistent whitespace
- `ArrayList.append(allocator, item)` takes allocator as first arg (not `.init()`)
- `std.fs.path.basename()` for path basename (not `std.mem.basename`)
- `std.posix.getenv()` returns `?[*:0]u8`; use `std.mem.sliceTo(ptr, 0)` for `[]const u8`

## Common Mistakes

1. `linux/linux.zig` and `macos/macos.zig` are at `src/linux.zig` and `src/macos.zig`, NOT at repo root
2. Memory leaks in tests: must `defer deinit()` for `ArrayList`
3. `main.zig` is CLI entrypoint; `root.zig` is library root
4. Logo string constants for comptime concatenation must be at module scope
5. `readSmallFile()` returns optional slice from stack buffer — data valid only within scope
6. `setValue`/`setNumericValue`/`setFloatValue` are in `info.zig` and prefixed with module import
7. `ArrayList.append()` takes `(allocator, item)` in Zig 0.15.1, not just `(item)`
8. `ArrayList` initialization: use `.empty` not `.init(allocator)`
9. `DESKTOP_SESSION` may contain a path like `/usr/bin/gnome`; use `basename` to extract just "gnome"
10. `XDG_CURRENT_DESKTOP` may contain colon-separated values like "ubuntu:GNOME"; take last component
11. Version extraction `extractVersion()` finds first X.Y or X.Y.Z pattern in command output

## Testing

```bash
zig build test
```

- Tests discovered in `src/main.zig`, `src/tests/test_suite.zig`, and inline in each module
- `test_suite.zig` uses named module imports matching `build.zig` module graph
- `test "fuzz example"` expects input `canyoufindme` to fail