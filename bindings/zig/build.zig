//! Raven for Zig: the package.
//!
//! Two modules:
//!
//!   raven     the idiomatic API (src/raven.zig): typed handles with methods,
//!             error unions, optionals, slices, allocators, Zig callbacks
//!   raven_c   the C API as it is (raven.zig), also reachable as `raven.c`
//!
//! Both link the shared library of Raven, built with CMake
//! (`cmake -B build -DRAVEN_BUILD_SHARED=ON && cmake --build build --config Release`).
//! Inside the repository it is found in ../../build; elsewhere give its folder:
//!
//!   zig build test -Dlib-dir=/path/to/lib            (raven.lib, libraven.so, libraven.dylib)
//!   zig build test -Dlib-dir=C:/raven/lib -Dbin-dir=C:/raven/bin   (where raven.dll is, on Windows)
//!
//! Steps:
//!
//!   zig build check     compiles every declaration of both modules; links nothing,
//!                       so it needs neither the library nor a GPU
//!   zig build test      the headless tests (src/tests.zig) and the example with --test
//!   zig build run       the example (example/main.zig) in a window
//!
//! From another package (build.zig.zon: .raven = .{ .path = "<Raven>/bindings/zig" }):
//!
//!   const raven = b.dependency("raven", .{ .target = target, .optimize = optimize, .@"lib-dir" = "<lib>" });
//!   exe.root_module.addImport("raven", raven.module("raven"));

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const os = target.result.os.tag;

    const lib_dir = b.option([]const u8, "lib-dir", "Folder of the Raven library to link (raven.lib, libraven.so, libraven.dylib)") orelse
        findLibrary(b, os, &.{ "../../build/Release", "../../build/RelWithDebInfo", "../../build/MinSizeRel", "../../build/Debug", "../../build", "../../build/lib" });
    const bin_dir = b.option([]const u8, "bin-dir", "Folder of raven.dll, to run the tests and the example on Windows (default: found beside lib-dir)") orelse
        if (os == .windows) findDll(b, lib_dir) else lib_dir;

    // ---- the modules
    const raven_c = b.addModule("raven_c", .{
        .root_source_file = b.path("raven.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    raven_c.linkSystemLibrary("raven", .{});
    if (lib_dir) |dir| {
        raven_c.addLibraryPath(.{ .cwd_relative = dir });
        if (os != .windows) raven_c.addRPath(.{ .cwd_relative = dir });
    }

    const raven = b.addModule("raven", .{
        .root_source_file = b.path("src/raven.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "raven_c", .module = raven_c }},
    });

    // ---- check: semantic analysis of every declaration, nothing linked or run
    const check = b.step("check", "Compile every declaration of the bindings (no library needed)");
    const raven_c_unlinked = b.createModule(.{ .root_source_file = b.path("raven.zig"), .target = target, .optimize = optimize });
    const check_wrapper = b.addTest(.{
        .name = "check-raven",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/raven.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "raven_c", .module = raven_c_unlinked }},
        }),
    });
    const check_raw = b.addTest(.{
        .name = "check-raven-c",
        .root_module = b.createModule(.{ .root_source_file = b.path("check.zig"), .target = target, .optimize = optimize }),
    });
    // only the compile steps are depended on: no binary is asked for, so none is emitted (-fno-emit-bin)
    check.dependOn(&check_wrapper.step);
    check.dependOn(&check_raw.step);

    // ---- tests: Raven headless (null backend, no window system)
    const test_step = b.step("test", "Run the headless tests and the example with --test (needs the library)");
    const tests = b.addTest(.{
        .name = "raven-tests",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/tests.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "raven", .module = raven }},
        }),
    });
    const run_tests = b.addRunArtifact(tests);
    findDllAtRun(b, run_tests, os, bin_dir);
    test_step.dependOn(&run_tests.step);

    // ---- the example
    const example = b.addExecutable(.{
        .name = "raven-zig-example",
        .root_module = b.createModule(.{
            .root_source_file = b.path("example/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "raven", .module = raven }},
        }),
    });
    b.installArtifact(example);

    const run_example = b.addRunArtifact(example);
    findDllAtRun(b, run_example, os, bin_dir);
    run_example.addPassthruArgs();
    const run_step = b.step("run", "Run the example in a window");
    run_step.dependOn(&run_example.step);

    const test_example = b.addRunArtifact(example);
    findDllAtRun(b, test_example, os, bin_dir);
    test_example.addArg("--test");
    test_example.expectExitCode(0);
    test_step.dependOn(&test_example.step);
}

/// The first folder (relative to this file) holding the library, or null:
/// the linker then looks where it always does.
fn findLibrary(b: *std.Build, os: std.Target.Os.Tag, folders: []const []const u8) ?[]const u8 {
    const file = switch (os) {
        .windows => "raven.lib",
        .macos, .ios => "libraven.dylib",
        else => "libraven.so",
    };
    for (folders) |folder| {
        const sub = b.pathJoin(&.{ folder, file });
        b.root.access(b.graph.io, sub, .{}) catch continue;
        return b.root.joinString(b.graph.arena, folder) catch @panic("OOM");
    }
    return null;
}

/// Where raven.dll is: the folder of the import library, or bin/<config> of the CMake build.
fn findDll(b: *std.Build, lib_dir: ?[]const u8) ?[]const u8 {
    const folders = [_][]const u8{ "../../build/bin/Release", "../../build/bin/RelWithDebInfo", "../../build/bin/MinSizeRel", "../../build/bin/Debug", "../../build/bin", "../../build" };
    if (lib_dir) |dir| {
        const sub = b.pathJoin(&.{ dir, "raven.dll" });
        if (std.Io.Dir.cwd().access(b.graph.io, sub, .{})) |_| return dir else |_| {}
    }
    for (folders) |folder| {
        const sub = b.pathJoin(&.{ folder, "raven.dll" });
        b.root.access(b.graph.io, sub, .{}) catch continue;
        return b.root.joinString(b.graph.arena, folder) catch @panic("OOM");
    }
    return lib_dir;
}

/// Windows finds a DLL on the PATH (the other systems use the rpath).
fn findDllAtRun(b: *std.Build, run: *std.Build.Step.Run, os: std.Target.Os.Tag, bin_dir: ?[]const u8) void {
    if (os != .windows) return;
    const dir = bin_dir orelse return;
    const path = b.graph.environ_map.get("PATH") orelse "";
    run.setEnvironmentVariable("PATH", b.fmt("{s};{s}", .{ dir, path }));
}
