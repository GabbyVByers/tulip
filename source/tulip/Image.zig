
const std = @import("std");
const stb = @cImport({@cInclude("stb_image.h");});
const vectors = @import("vectors.zig");
const Vec2T = vectors.Vec2T;
const Vec3T = vectors.Vec3T;

const Private = struct {
  size: Vec2T(usize),
  pixels: []u8,
};

pub fn forceZigCompile() void {
  stb.stbi_set_flip_vertically_on_load(1);
  std.debug.print("HELLO\n", .{});
}

