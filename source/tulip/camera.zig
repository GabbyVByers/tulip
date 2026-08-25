
const Quaternion = @import("Quaternion.zig");
const vectors = @import("vectors.zig");
const Vec2T = vectors.Vec2T;
const Vec3T = vectors.Vec3T;

pub const private = struct {
  pub var quaternion: Quaternion = .unit();
};

pub var fov: f64 = 0.77;
pub var position: Vec3T(f64) = .{ .x = 0, .y = 0, .z = 0 };

pub fn reset() void {
  fov = 0.77;
  position = .{ .x = 0, .y = 0, .z = 0 };
  private.quaternion = .unit();
}

pub fn forward() Vec3T(f64) {
  const direction: Vec3T(f64) = .zneg();
  return Quaternion.applyRotation(direction, private.quaternion);
}

pub fn right() Vec3T(f64) {
  const direction: Vec3T(f64) = .xpos();
  return Quaternion.applyRotation(direction, private.quaternion);
}

pub fn up() Vec3T(f64) {
  const direction: Vec3T(f64) = .ypos();
  return Quaternion.applyRotation(direction, private.quaternion);
}

pub fn rotate(axis: Vec3T(f64), theta: f64) void {
  const rotation: Quaternion = .rotation(axis, theta);
  private.quaternion = Quaternion.mult(rotation, private.quaternion);
}

