  
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

pub fn create(dimensions: Vec2T(usize)) Image {
  const invalid_dimensions: bool = (dimensions.x == 0) or (dimensions.y == 0);
  if (invalid_dimensions) {
    std.debug.print("Failed to Create Image: Invalid Dimensions!\n", .{});
    std.process.exit(EXIT_FAILURE);
  }
  
  const buffer_size: usize = dimensions.x * dimensions.y * 4;
  const buffer: []u8 = std.heap.c_allocator.alloc(u8, buffer_size) catch {
    std.debug.print("Failed to Create Image: Memory Allocation Failed!\n", .{});
    std.process.exit(EXIT_FAILURE);
  };
  
  @memset(buffer, @as(u8, 255));
  
  return .{
    .private = .{
      .size = dimensions,
      .pixels = buffer,
    },
  };
}

pub fn load(path_cstr: [*c]const u8) Image {
  var w: c_int = undefined;
  var h: c_int = undefined;
  var n: c_int = undefined;
  stb.stbi_set_flip_vertically_on_load(1);
  
  const stbi_image: [*c]u8 = stb.stbi_load(path_cstr, &w, &h, &n, 4);
  defer stb.stbi_image_free(stbi_image);
  
  if (stbi_image == null) {
    std.debug.print("Failed to Load Image: {s}!\n", .{ path_cstr });
    std.process.exit(EXIT_FAILURE);
  }
  
  const dimensions: Vec2T(usize) = .{ .x = @intCast(w), .y = @intCast(h) };
  const buffer_size: usize = dimensions.x * dimensions.y * 4;
  const buffer: []u8 = std.heap.c_allocator.alloc(u8, buffer_size) catch {
    std.debug.print("Failed to Load Image: Memory Allocation Failed!\n", .{});
    std.process.exit(EXIT_FAILURE);
  };
  
  @memcpy(buffer, stbi_image[0..buffer_size]);
  
  return .{
    .private = .{
      .size = dimensions,
      .pixels = buffer,
    },
  };
}

pub fn destroy(this: *Image) void {
  std.heap.c_allocator.free(this.private.pixels);
  this.private.size = .{ .x = 0, .y = 0 };
}

pub fn putPixel(this: *Image, color: Color, position: Vec2T(usize)) void {
  const invalid_position: bool = (position.x >= this.private.size.x) or (position.y >= this.private.size.y);
  if (invalid_position) {
    std.debug.print("Failed to Put Pixel: Invalid Position!\n", .{});
    std.process.exit(EXIT_FAILURE);
  }
  
  const r: f32 = color.r;
  const g: f32 = color.g;
  const b: f32 = color.b;
  const a: f32 = color.a;
  
  const invalid_color: bool =
    (r < 0) or (r > 1) or
    (b < 0) or (b > 1) or
    (g < 0) or (g > 1) or
    (a < 0) or (a > 1);
  
  if (invalid_color) {
    std.debug.print("Failed to Put Pixel: Invalid Color!\n", .{});
    std.process.exit(EXIT_FAILURE);
  }
  
  const index: usize = @intCast(((position.y * this.private.size.x) + position.x) * 4);
  this.private.pixels[index + 0] = @intFromFloat(r * 255);
  this.private.pixels[index + 1] = @intFromFloat(g * 255);
  this.private.pixels[index + 2] = @intFromFloat(b * 255);
  this.private.pixels[index + 3] = @intFromFloat(a * 255);
}

pub fn getPixel(this: *const Image, position: Vec2T(usize)) Color {
  std.debug.assert(position.x < this.private.size.x);
  std.debug.assert(position.y < this.private.size.y);
  
  const index: usize = @intCast(((position.y * this.private.size.x) + position.x) * 4);
  const r: u8 = this.private.pixels[index + 0];
  const g: u8 = this.private.pixels[index + 1];
  const b: u8 = this.private.pixels[index + 2];
  const a: u8 = this.private.pixels[index + 3];
  
  return .{
    .r = @as(f32, r) / 255.0,
    .g = @as(f32, g) / 255.0,
    .b = @as(f32, b) / 255.0,
    .a = @as(f32, a) / 255.0,
  };
}

pub fn size(this: *Image) Vec2T(usize) {
  return this.private.size;
}

