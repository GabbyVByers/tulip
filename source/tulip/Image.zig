
const std = @import("std");
const stb = @cImport({@cInclude("stb_image.h");});
const Color = @import("Color.zig");
const vectors = @import("vectors.zig");
const Vec2T = vectors.Vec2T;
const Vec3T = vectors.Vec3T;
const Image = @This();

const EXIT_SUCCESS: u8 = 0;
const EXIT_FAILURE: u8 = 1;

const Private = struct {
  size: Vec2T(usize),
  pixels: []u8,
}; private: Private,

pub fn create(path: []const u8) Image {
  var w: c_int = undefined;
  var h: c_int = undefined;
  var n: c_int = undefined;
  stb.stbi_set_flip_vertically_on_load(1);
  const stbi_image: [*c]u8 = stb.stbi_load(@ptrCast(path), &w, &h, &n, 4);
  defer stb.stbi_image_free(stbi_image);
  
  if (stbi_image == null) {
    std.debug.print("STB Image Failed to Load: {s}!\n", .{ path });
    std.process.exit(EXIT_FAILURE);
  }
  
  const size: Vec2T(usize) = .{ .x = @intCast(w), .y = @intCast(h) };
  const buffer_size: usize = size.x * size.y * 4;
  const buffer: []u8 = std.heap.c_allocator.alloc(u8, buffer_size) catch unreachable;
  @memcpy(buffer, stbi_image[0..buffer_size]);
  
  return .{
    .private = .{
      .size = size,
      .pixels = buffer,
    },
  };
}

pub fn destroy(this: *Image) void {
  
}

//pub fn size(this: *Image) Vec2T(usize) {
//  
//}
//
//pub fn getPixel(this: *const Image) Color {
//  
//}
//
//pub fn putPixel(this: *Image) void {
//  
//}

