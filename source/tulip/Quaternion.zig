
const std = @import("std");
const vectors = @import("vectors.zig");
const Vec2T = vectors.Vec2T;
const Vec3T = vectors.Vec3T;
const Quaternion = @This();

w: f64,
x: f64,
y: f64,
z: f64,

pub fn unit() Quaternion {
  return .{
    .w = 1,
    .x = 0,
    .y = 0,
    .z = 0,
  };
}

pub fn complexconj(quaternion: Quaternion) Quaternion {
  return .{
    .w = quaternion.w,
    .x = -quaternion.x,
    .y = -quaternion.y,
    .z = -quaternion.z,
  };
}

pub fn normalize(quaternion: Quaternion) Quaternion {
  const ww: f64 = quaternion.w * quaternion.w;
  const xx: f64 = quaternion.x * quaternion.x;
  const yy: f64 = quaternion.y * quaternion.y;
  const zz: f64 = quaternion.z * quaternion.z;
  const length: f64 = std.math.sqrt(ww + xx + yy + zz);
  return .{
    .w = quaternion.w / length,
    .x = quaternion.x / length,
    .y = quaternion.y / length,
    .z = quaternion.z / length,
  };
}

pub fn mul(a: Quaternion, b: Quaternion) Quaternion {
  return .{
    .w = (a.w * b.w) - (a.x * b.x) - (a.y * b.y) - (a.z * b.z),
    .x = (a.w * b.x) + (a.x * b.w) + (a.y * b.z) - (a.z * b.y),
    .y = (a.w * b.y) - (a.x * b.z) + (a.y * b.w) + (a.z * b.x),
    .z = (a.w * b.z) + (a.x * b.y) - (a.y * b.x) + (a.z * b.w),
  };
}

pub fn applyRotation(vec: Vec3T(f64), quaternion: Quaternion) Vec3T(f64) {
  const quaternion_conjugate: Quaternion = .complexconj(quaternion);
  const pure_rotation: Quaternion = .{
    .w = 0,
    .x = vec.x,
    .y = vec.y,
    .z = vec.z
  };
  const result: Quaternion = .mul(.mul(quaternion, pure_rotation), quaternion_conjugate);
  return .{
    .x = result.x,
    .y = result.y,
    .z = result.z,
  };
}

