
const std = @import("std");

pub fn Vec2T(comptime T: type) type {
  return struct {
    const Vec2 = @This();
    
    x: T,
    y: T,
    
    pub fn xpos() Vec2 { return .{ .x = 1, .y = 0 }; }
    pub fn xneg() Vec2 { return .{ .x =-1, .y = 0 }; }
    pub fn ypos() Vec2 { return .{ .x = 0, .y = 1 }; }
    pub fn yneg() Vec2 { return .{ .x = 0, .y =-1 }; }
    
    pub fn add(a: Vec2, b: Vec2) Vec2 {
      return .{
        .x = a.x + b.x,
        .y = a.y + b.y,
      };
    }
    
    pub fn sub(a: Vec2, b: Vec2) Vec2 {
      return .{
        .x = a.x - b.x,
        .y = a.y - b.y,
      };
    }
    
    pub fn scale(vec: Vec2, scalar: T) Vec2 {
      return .{
        .x = vec.x * scalar,
        .y = vec.y * scalar,
      };
    }
  };
}

pub fn Vec3T(comptime T: type) type {
  return struct {
    const Vec3 = @This();
    
    x: T,
    y: T,
    z: T,
    
    pub fn xpos() Vec3 { return .{ .x = 1, .y = 0, .z = 0 }; }
    pub fn xneg() Vec3 { return .{ .x =-1, .y = 0, .z = 0 }; }
    pub fn ypos() Vec3 { return .{ .x = 0, .y = 1, .z = 0 }; }
    pub fn yneg() Vec3 { return .{ .x = 0, .y =-1, .z = 0 }; }
    pub fn zpos() Vec3 { return .{ .x = 0, .y = 0, .z = 1 }; }
    pub fn zneg() Vec3 { return .{ .x = 0, .y = 0, .z =-1 }; }
  
    pub fn add(a: Vec3, b: Vec3) Vec3 {
      return .{
        .x = a.x + b.x,
        .y = a.y + b.y,
        .z = a.z + b.z,
      };
    }
    
    pub fn sub(a: Vec3, b: Vec3) Vec3 {
      return .{
        .x = a.x - b.x,
        .y = a.y - b.y,
        .z = a.z - b.z,
      };
    }
    
    pub fn scale(vec: Vec3, scalar: T) Vec3 {
      return .{
        .x = vec.x * scalar,
        .y = vec.y * scalar,
        .z = vec.z * scalar,
      };
    }
  };
}

