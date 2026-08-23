
const std = @import("std");
const Quaternion = @import("Quaternion.zig");
const vectors = @import("vectors.zig");
const Vec2T = vectors.Vec2T;
const Vec3T = vectors.Vec3T;
const Matrix = @This();

grid: [16]f64,

pub fn identity() Matrix {
  return .{
    .grid = .{
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1,
    },
  };
}

pub fn scalar(scale: f64) Matrix {
  const s: f64 = scale;
  return .{
    .grid = .{
      s, 0, 0, 0,
      0, s, 0, 0,
      0, 0, s, 0,
      0, 0, 0, 1,
    },
  };
}

pub fn translation(position: Vec3T(f64)) Matrix {
  const x: f64 = position.x;
  const y: f64 = position.y;
  const z: f64 = position.z;
  return .{
    .grid = .{
      1, 0, 0, x,
      0, 1, 0, y,
      0, 0, 1, z,
      0, 0, 0, 1,
    },
  };
}

pub fn rotation(quaternion: Quaternion) Matrix {
  const w: f64 = quaternion.w;
  const x: f64 = quaternion.x;
  const y: f64 = quaternion.y;
  const z: f64 = quaternion.z;
  return .{
    .grid = .{
      1 - 2 * (y * y + z * z), 2 * (x * y - w * z), 2 * (x * z + w * y), 0,
      2 * (x * y + w * z), 1 - 2 * (x * x + z * z), 2 * (y * z - w * x), 0,
      2 * (x * z - w * y), 2 * (y * z + w * x), 1 - 2 * (x * x + y * y), 0,
      0, 0, 0, 1,
    },
  };
}

pub fn model(scale: f64, position: Vec3T(f64), quaternion: Quaternion) Matrix {
  const scalar_matrix: Matrix = .scalar(scale);
  const translation_matrix: Matrix = .translation(position);
  const rotation_matrix: Matrix = .rotation(quaternion);
  return .mul(.mul(translation_matrix, rotation_matrix), scalar_matrix);
}

pub fn view(position: Vec3T(f64), quaternion: Quaternion) Matrix {
  const quaternion_conjugate: Quaternion = .complexconj(quaternion);
  const position_inverse: Vec3T(f64) = .scale(position, -1);
  const rotation_matrix_transpose: Matrix = .rotation(quaternion_conjugate);
  const translation_matrix_inverse: Matrix = .translation(position_inverse);
  return .mul(rotation_matrix_transpose, translation_matrix_inverse);
}

pub fn project(fov: f64, aspect_ratio: f64) Matrix {
  const s: f64 = 1.0 / std.math.tan(fov / 2.0);
  const a: f64 = aspect_ratio;
  return .{
    .grid = .{
      s / a, 0, 0, 0,
      0, s, 0, 0,
      0, 0, 1,-1,
      0, 0, 1, 0,
    },
  };
}

pub fn mul(this: *Matrix, other: Matrix) Matrix {
  var result: Matrix = undefined;
  for (0..4) |i| {
    for (0..4) |j| {
      var sum: f64 = 0;
      for (0..4) |k| {
        sum += this.grid[(i * 4) + k] * other.grid[(k * 4) + j];
      } result.grid[(i * 4) + j] = sum;
    }
  } return result;
}

pub fn columnmajor(this: *Matrix) [16]f32 {
  var result: [16]f32 = undefined;
  for (0..4) |i| {
    for (0..4) |j| {
      result.grid[(i * 4) + j] = @floatCast(this.grid[(j * 4) + i]);
    }
  } return result;
}

