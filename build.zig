const std = @import("std");

fn linkPlatformLibraries(exe: *std.Build.Step.Compile, target: std.Build.ResolvedTarget) void {
    exe.linkLibC();
    switch (target.result.os.tag) {
        .linux => {},
        .macos => {
            exe.linkFramework("Security");
            exe.linkFramework("CoreFoundation");
        },
        .windows => {
            exe.linkSystemLibrary("ws2_32");
            exe.linkSystemLibrary("crypt32");
            exe.linkSystemLibrary("secur32");
        },
        else => {
            std.log.warn("Networking libraries for target OS '{s}' are not explicitly configured in build.zig. std.http might not work.", .{@tagName(target.result.os.tag)});
        },
    }
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const detect_leaks = b.option(bool, "detect-leaks", "Enable memory leak detection") orelse false;
    const opencage_mod = b.addModule("opencage", .{
        .root_source_file = b.path("src/opencage.zig"),
    });
    const forward_exe = b.addExecutable(.{
        .name = "forward_example",
        .root_source_file = b.path("examples/forward_geocoding.zig"),
        .target = target, // <--- CHANGE: Pass the full ResolvedTarget
        .optimize = optimize,
    });
    forward_exe.root_module.addImport("opencage", opencage_mod);
    linkPlatformLibraries(forward_exe, target);
    b.installArtifact(forward_exe);
    const reverse_exe = b.addExecutable(.{
        .name = "reverse_example",
        .root_source_file = b.path("examples/reverse_geocoding.zig"),
        .target = target, // <--- CHANGE: Pass the full ResolvedTarget
        .optimize = optimize,
    });
    reverse_exe.root_module.addImport("opencage", opencage_mod);
    linkPlatformLibraries(reverse_exe, target);
    b.installArtifact(reverse_exe);
    if (detect_leaks) {
        forward_exe.root_module.addCMacro("DETECT_LEAKS", "1");
        reverse_exe.root_module.addCMacro("DETECT_LEAKS", "1");
    }
    const run_forward_cmd = b.addRunArtifact(forward_exe);
    run_forward_cmd.step.dependOn(b.getInstallStep());
    const run_reverse_cmd = b.addRunArtifact(reverse_exe);
    run_reverse_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_forward_cmd.addArgs(args);
        run_reverse_cmd.addArgs(args);
    }
    const run_forward_step = b.step("run-forward", "Run the forward geocoding example");
    run_forward_step.dependOn(&run_forward_cmd.step);
    const run_reverse_step = b.step("run-reverse", "Run the reverse geocoding example");
    run_reverse_step.dependOn(&run_reverse_cmd.step);
    const run_step = b.step("run", "Run the forward and reverse geocoding examples");
    run_step.dependOn(&run_forward_cmd.step);
    run_step.dependOn(&run_reverse_cmd.step);
    const test_step = b.step("test", "Run library tests");
    const lib_tests = b.addTest(.{
        .root_source_file = b.path("src/opencage.zig"),
        .target = target,
        .optimize = optimize,
    });
    linkPlatformLibraries(lib_tests, target);
    const run_lib_tests = b.addRunArtifact(lib_tests);
    test_step.dependOn(&run_lib_tests.step);
}
