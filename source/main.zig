
const std = @import("std");
const tulip = @import("Tulip");
const window = tulip.window;
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
    .{ .pos = .{ .x = 0.0, .y = 0.5, .z = 0.0 }, .color = Color.palette.white(1), .uv = .{ .x = 0, .y = 0 } },
    .{ .pos = .{ .x = 0.5, .y =-0.5, .z = 0.0 }, .color = Color.palette.white(1), .uv = .{ .x = 0, .y = 0 } },
    .{ .pos = .{ .x =-0.5, .y =-0.5, .z = 0.0 }, .color = Color.palette.white(1), .uv = .{ .x = 0, .y = 0 } },
  };
  
  var mesh: Mesh = .create();
  mesh.upload(&vertices);
  defer mesh.destroy();
  
  while (window.isOpen()) {
    window.clear(Color.palette.purple(0.15));
    mesh.draw();
    window.display();
  }
}

