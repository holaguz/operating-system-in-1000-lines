const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // const target = b.standardTargetOptions(.{
    //     .default_target = .{
    //         .cpu_arch = .riscv32,
    //         .os_tag = .freestanding,
    //         // .abi = .eabi,
    //     },
    // });

    const target = b.resolveTargetQuery(.{
        .cpu_arch = .riscv32,
        .os_tag = .freestanding,
        .abi = .none,
    });

    const optimize = b.standardOptimizeOption(.{});

    var exe = b.addExecutable(.{
        .name = "kernel",
        .root_source_file = b.path("src/entry.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.verbose = true;
    exe.setLinkerScript(b.path("src/kernel.ld"));
    exe.setVerboseCC(true);
    exe.setVerboseLink(true);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // Standard run step
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // QEMU run step
    const qemu_cmd = b.addSystemCommand(&[_][]const u8{
        "qemu-arm",
        b.getInstallPath(.bin, exe.name),
    });
    qemu_cmd.step.dependOn(b.getInstallStep());

    const qemu_step = b.step("qemu", "Run the app under QEMU RISCV32 emulator");
    qemu_step.dependOn(&qemu_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
