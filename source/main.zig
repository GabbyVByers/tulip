
const std = @import("std");
const tulip = @import("Tulip");
const window = tulip.window;
const camera = tulip.camera;
const Mesh = tulip.Mesh;
const Vertex = tulip.Vertex;
const Color = tulip.Color;
const Image = tulip.Image;

pub fn main() void {
  
  window.create("App Title", 500, 500);
  window.vsync(false);
  defer window.destroy();
  
  var image: Image = .create(.{ .x = 10, .y = 10 });
  defer image.destroy();
  
  image.putPixel(Color.palette.blue(1), .{ .x = 2, .y = 2 });
  
  const pixel: Color = image.getPixel(.{ .x = 2, .y = 2 });
  std.debug.print("Image Size: W: {} H: {}\n", image.size());
  std.debug.print("Pixel: R:{} G:{} B:{} A:{}\n", pixel);
  
  var vertices: [3]Vertex = .{
    .{ .pos = .{ .x = 0.0, .y = 0.5, .z = 7.0 }, .color = Color.palette.white(1), .uv = .{ .x = 0, .y = 0 } },
    .{ .pos = .{ .x = 0.5, .y =-0.5, .z = 7.0 }, .color = Color.palette.white(1), .uv = .{ .x = 0, .y = 0 } },
    .{ .pos = .{ .x =-0.5, .y =-0.5, .z = 7.0 }, .color = Color.palette.white(1), .uv = .{ .x = 0, .y = 0 } },
  };
  
  camera.position.z = 5;
  
  var mesh: Mesh = .create();
  mesh.upload(&vertices);
  defer mesh.destroy();
  
  while (window.isOpen()) {
    window.clear(Color.palette.purple(0.15));
    mesh.draw();
    window.display();
  }
}

//pub fn controlCamera() void {
//  const rotation_speed: f64 = 0.001;
//  var movement_speed: f64 = 0.005;
//  
//  if (Keyboard.pressing(Keyboard.scancode.leftctrl)) { movement_speed *= 5; }
//  
//  if (Keyboard.pressing(Keyboard.scancode.W)) { Camera.position = Vec3(f64).add(Camera.position, Vec3(f64).mult(Camera.forward(), movement_speed)); }
//  if (Keyboard.pressing(Keyboard.scancode.A)) { Camera.position = Vec3(f64).add(Camera.position, Vec3(f64).mult(Camera.right(), -movement_speed)); }
//  if (Keyboard.pressing(Keyboard.scancode.S)) { Camera.position = Vec3(f64).add(Camera.position, Vec3(f64).mult(Camera.forward(), -movement_speed)); }
//  if (Keyboard.pressing(Keyboard.scancode.D)) { Camera.position = Vec3(f64).add(Camera.position, Vec3(f64).mult(Camera.right(), movement_speed)); }
//  
//  if (Keyboard.pressing(Keyboard.scancode.spacebar)) {
//    const up: Vec3(f64) = Vec3(f64).mult(Vec3(f64).ypos(), movement_speed);
//    Camera.position = Vec3(f64).add(Camera.position, up);
//  }
//  
//  if (Keyboard.pressing(Keyboard.scancode.leftshift)) {
//    const down: Vec3(f64) = Vec3(f64).mult(Vec3(f64).yneg(), movement_speed);
//    Camera.position = Vec3(f64).add(Camera.position, down);
//  }
//  
//  if (Mouse.pressed(Mouse.button.left)) { Mouse.hide(); }
//  if (Mouse.released(Mouse.button.left)) { Mouse.reveal(); }
//  if (Mouse.pressing(Mouse.button.left)) {
//    Camera.rotate(Vec3(f64).yneg(), rotation_speed * Mouse.velocity.x);
//    Camera.rotate(Camera.right(), -rotation_speed * Mouse.velocity.y);
//  }
//}

