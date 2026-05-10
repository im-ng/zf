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
├── main.zig           # CLI entry, platform dispatch, gatherLinuxInfo/gatherMacosInfo
├── info.zig           # SystemInfo struct, Context, parsers (setValue, setNumericValue, etc.)
├── cli.zig            # Arg parsing (DisplayFlags), printHelp, printVersion
├── output.zig         # formatOutput(), side-by-side logo+info layout, addField
├── logos.zig           # ASCII logos (debian, ubuntu, arch, fedora, macos, zf), getLogo(), visibleLen(), memContains()
├── linux.zig           # Re-exports: cpu, memory, os, utils, gpu, packages, desktop
├── linux/cpu.zig       # getCpuInfoFromString() parses /proc/cpuinfo + readCacheInfo() from sysfs
├── linux/memory.zig    # getMemoryInfoFromString() parses /proc/meminfo
├── linux/os.zig        # parseOsRelease() from /etc/os-release, parseLsbRelease() from /etc/lsb-release
├── linux/utils.zig     # parseUptime() from /proc/uptime
├── linux/gpu.zig       # getGpuInfo() - nvidia-smi, lspci, /proc/driver/nvidia/gpus/
├── linux/packages.zig  # getPackages() - dpkg, rpm, pacman, apk, snap, flatpak
├── linux/desktop.zig   # getDe() - XDG_CURRENT_DESKTOP/DESKTOP_SESSION, getWm() - /proc scan
├── macos.zig           # Re-exports: cpu, memory, os, utils, gpu, packages, desktop
├── macos/cpu.zig       # getCpuInfo() via sysctl + readCacheSize() for hw.l{1d,2,3}cachesize
├── macos/memory.zig    # getMemoryInfo() via sysctl hw.memsize
├── macos/os.zig        # getOsInfo() parses SystemVersion.plist + uname + distro_id="macos"
├── macos/utils.zig     # getSystemInfo() reads USER, SHELL, TERM env vars + getcwd + getUptime()
├── macos/gpu.zig       # getGpuInfo() via system_profiler SPDisplaysDataType
├── macos/packages.zig  # getPackages() - brew, port
├── macos/desktop.zig   # getDe() returns "Aqua", getWm() returns "Quartz Compositor"
├── root.zig            # Library root, re-exports modules
└── tests/test_suite.zig # Aggregates all module tests via refAllDecls
```

## Key Facts

- **Executable name**: `zf`
- **Build system**: Zig 0.15.1 native `zig build`
- **Platform detection**: `builtin.os.tag` — Linux reads `/proc/*`, `/sys/*`, `/etc/*`; macOS uses `sysctl`, `SystemVersion.plist`, env vars
- **Logo selection**: `getLogo(distro_id, is_linux)` — matches `ID=` from `/etc/os-release` substring (debian, ubuntu, arch, fedora, macos/darwin, mint, pop, suse/opensuse, manjaro, gentoo, nixos); fallback: zf logo (Linux) / macos logo (macOS)
- **Field formatting**: `addField()` uses `{label_color}{bold}{label}{reset}: {value_color}{val}{reset}`; null values show "Unknown"

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
| `--cpu` | `-c` | show_cpu=true (detailed CPU + GPU) |
| `--mem` | `-m` | show_mem=true (total/free memory) |
| `--os` | `-o` | show_os=true (OS, uptime, packages, shell, DE, WM, terminal, user) |
| `--all` | `-a` | show_all=true, show_logo=false (everything) |

## Output Rendering

Default view shows neofetch-style summary with logo:
- OS (name + version combined), Kernel, Hostname, Uptime, Packages, Shell, DE, WM, Terminal, User
- CPU (model + cores + speed), GPU
- Memory (used / total)

`--os`: OS combined, Kernel, Hostname, Uptime, Packages, Shell, DE, WM, Terminal, User
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
| de | `$XDG_CURRENT_DESKTOP`, `$DESKTOP_SESSION`, `$XDG_SESSION_DESKTOP` |
| wm | `/proc/*/comm` scan for known WM process names |
| shell, user, terminal | env vars `SHELL`, `USER`, `TERM` |
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
| de | hardcoded `"Aqua"` |
| wm | hardcoded `"Quartz Compositor"` |
| uptime | `sysctl kern.boottime` → current time - boot time |
| shell, user, terminal | env vars `SHELL`, `USER`, `TERM` |

## Zig 0.15.1 API Notes

- `std.ArrayList(T).empty` instead of `.init(allocator)`
- `std.fs.File.stdout().writer(&buf)` then `.interface` for writing
- `std.posix.uname()` returns value, not takes pointer
- `builtin.cpu.arch` not `std.Target.current.cpu.arch`
- `std.process.Child.run()` for executing external commands
- `std.posix.getcwd()` returns `?[]const u8` in some APIs
- String concatenation in comptime: use `++` operator with consistent whitespace
- `ArrayList.append(allocator, item)` takes allocator as first arg (not `.init()`)

## Common Mistakes

1. `linux/linux.zig` and `macos/macos.zig` are at `src/linux.zig` and `src/macos.zig`, NOT at repo root
2. Memory leaks in tests: must `defer deinit()` for `ArrayList`
3. `main.zig` is CLI entrypoint; `root.zig` is library root
4. Logo string constants for comptime concatenation must be at module scope
5. `readSmallFile()` returns optional slice from stack buffer — data valid only within scope
6. `setValue`/`setNumericValue`/`setFloatValue` are in `info.zig` and prefixed with module import
7. `ArrayList.append()` takes `(allocator, item)` in Zig 0.15.1, not just `(item)`
8. `ArrayList` initialization: use `.empty` not `.init(allocator)`

## Testing

```bash
zig build test
```

- Tests discovered in `src/main.zig`, `src/tests/test_suite.zig`, and inline in each module
- `test_suite.zig` uses named module imports matching `build.zig` module graph
- `test "fuzz example"` expects input `canyoufindme` to fail