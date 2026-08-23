
const std = @import("std");

pub fn build(b: *std.Build) void {
  const target = b.standardTargetOptions(.{});
  const optimize = b.standardOptimizeOption(.{});
  
  const tulip = b.addModule("Tulip", .{
    .root_source_file = b.path("source/root.zig"),
    .target = target,
    .optimize = optimize,
  });
  
  tulip.addIncludePath(b.path("libraries/SDL3-3.4.14/include"));
  tulip.addIncludePath(b.path("libraries/stb-master"));
  tulip.addCSourceFile(.{ .file = b.path("libraries/stb-master/stb_image.c") });
  tulip.addObjectFile(b.path("libraries/SDL3-3.4.14/lib/x64/SDL3.lib"));
  tulip.link_libc = true;
  
  const exe = b.addExecutable(.{
    .name = "Tulip",
    .root_module = b.createModule(.{
      .root_source_file = b.path("source/main.zig"),
      .target = target,
      .optimize = optimize,
      .imports = &.{.{ .name = "Tulip", .module = tulip }},
    }),
  });
  
  b.installArtifact(exe);
  b.installBinFile("libraries/SDL3-3.4.14/lib/x64/SDL3.dll", "SDL3.dll");
  
  const run_cmd = b.addRunArtifact(exe);
  run_cmd.step.dependOn(b.getInstallStep());
  run_cmd.setCwd(.{ .cwd_relative = b.getInstallPath(.bin, "") });
  if (b.args) |args| run_cmd.addArgs(args);
  
  const run_step = b.step("run", "Run Tulip");
  run_step.dependOn(&run_cmd.step);
  
  const mod_tests = b.addTest(.{ .root_module = tulip });
  const exe_tests = b.addTest(.{ .root_module = exe.root_module });
  
  const test_step = b.step("test", "Run all tests");
  test_step.dependOn(&b.addRunArtifact(mod_tests).step);
  test_step.dependOn(&b.addRunArtifact(exe_tests).step);
}

