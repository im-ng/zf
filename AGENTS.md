# AGENTS.md

## Project Summary

**zf** is a Zig CLI tool that displays system information (OS, kernel, CPU, memory, hostname, user) for Linux and macOS platforms.

## Build & Run

```bash
# Build the executable
zig build

# Run the executable
zig build run

# Run tests
zig build test

# Run a single test
zig build test --test-test_name

# Run with fuzzing
zig build test --fuzz
```

## Project Structure

```
zf/
├── build.zig              # Build configuration
├── zf.zig                 # Core logic (SystemInfo, formatOutput)
├── main.zig               # Entry point (calls zf.zig)
├── linux/linux.zig        # Linux platform implementation
├── macos/macos.zig        # macOS platform implementation
├── src/
│   ├── main.zig           # Library entrypoint with tests
│   └── root.zig           # Library root utilities
├── tests/
│   └── test_suite.zig     # Unit tests
└── spec/
    └── spec.md            # Original requirements
```

## Key Facts

- **Executable name**: `zf` (not `main`)
- **Build system**: Zig's native `zig build` (no Make, CMake, or npm)
- **Platform support**: Linux (reads /proc/*), macOS (mocked stubs)
- **Test fixtures**: Empty `tests/fixtures/` directory (no fixtures to load)
- **Test pattern**: Uses `std.testing.allocator` in tests, requires explicit `defer deinit` for `ArrayList` to avoid memory leaks

## Platform Detection

Platform is detected via `builtin.os.tag`:
- Linux: reads `/proc/cpuinfo`, `/proc/meminfo`, `/etc/os-release`, `/etc/hostname`
- macOS: returns hardcoded values (not real system info)

## Common Mistakes

1. **Wrong source path**: `linux/linux.zig` and `macos/macos.zig` are at repo root, NOT under `src/`
2. **Memory leaks in tests**: Must `defer list.deinit(gpa)` after using `ArrayList`
3. **Executable vs library**: `main.zig` is the CLI entrypoint; `src/main.zig` is the library

## Testing Gotchas

- Tests in `src/main.zig` and `tests/test_suite.zig` are both discovered
- Fuzz test: `test "fuzz example"` expects input `canyoufindme` to fail
- Allocator errors: tests may fail if memory allocation fails
