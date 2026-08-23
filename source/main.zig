
const std = @import("std");
const Io = std.Io;

const tulip = @import("Tulip");
const window = tulip.window;
const Color = tulip.Color;

pub fn main() void {
  window.create("App Title", 500, 500);
  window.vsync(false);
  defer window.destroy();
  
  while (window.isOpen()) {
    window.clear(Color.palette.purple(0.15));
    window.display();
  }
}

