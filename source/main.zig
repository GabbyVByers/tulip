
const std = @import("std");
const Io = std.Io;

const tulip = @import("Tulip");
const window = tulip.window;
const Mesh = tulip.Mesh;
const Color = tulip.Color;
const Image = tulip.Image;

pub fn main() void {
  
  window.create("App Title", 500, 500);
  window.vsync(false);
  defer window.destroy();
  
  //var ptr: [*c]i32 = @alignCast(@ptrCast(std.c.malloc(128)));
  //ptr[67] = 67;
  //std.debug.print("num: {}", .{ ptr[67] });
  //std.c.free(ptr);
  
  const image: Image = .create("../../images/test.png");
  std.debug.print("Pixel: R:{} G:{} B:{} A:{}", .{
    image.private.pixels[0],
    image.private.pixels[1],
    image.private.pixels[2],
    image.private.pixels[3],
  });
  //defer image.destroy();
  
  while (window.isOpen()) {
    window.clear(Color.palette.purple(0.15));
    window.display();
  }
}

