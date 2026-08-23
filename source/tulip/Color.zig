
const std = @import("std");
const Color = @This();

r: f32,
g: f32,
b: f32,
a: f32,

pub const palette = struct {
  
  const max: f32 = 1.0;
  const min: f32 = 0.0;
  
  pub fn white(brightness: f32) Color {
    std.debug.assert(brightness >= min);
    std.debug.assert(brightness <= max);
    return .{
      .r = brightness,
      .g = brightness,
      .b = brightness,
      .a = 1,
    };
  }
  
  pub fn red(brightness: f32) Color {
    std.debug.assert(brightness >= min);
    std.debug.assert(brightness <= max);
    return .{
      .r = brightness,
      .g = 0,
      .b = 0,
      .a = 1,
    };
  }
  
  pub fn green(brightness: f32) Color {
    std.debug.assert(brightness >= min);
    std.debug.assert(brightness <= max);
    return .{
      .r = 0,
      .g = brightness,
      .b = 0,
      .a = 1,
    };
  }
  
  pub fn blue(brightness: f32) Color {
    std.debug.assert(brightness >= min);
    std.debug.assert(brightness <= max);
    return .{
      .r = 0,
      .g = 0,
      .b = brightness,
      .a = 1,
    };
  }
  
  pub fn purple(brightness: f32) Color {
    std.debug.assert(brightness >= min);
    std.debug.assert(brightness <= max);
    return .{
      .r = brightness,
      .g = 0,
      .b = brightness,
      .a = 1,
    };
  }
  
  pub fn yellow(brightness: f32) Color {
    std.debug.assert(brightness >= min);
    std.debug.assert(brightness <= max);
    return .{
      .r = brightness,
      .g = brightness,
      .b = 0,
      .a = 1,
    };
  }
  
  pub fn cyan(brightness: f32) Color {
    std.debug.assert(brightness >= min);
    std.debug.assert(brightness <= max);
    return .{
      .r = 0,
      .g = brightness,
      .b = brightness,
      .a = 1,
    };
  }
};

