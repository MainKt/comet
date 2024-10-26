const std = @import("std");
const x11 = @import("x11.zig");

pub fn main() !void {
    const display = x11.XOpenDisplay(null) orelse
        return blk: {
        std.debug.print("comet: cannot open X display\n", .{});
        break :blk error.UnableToOpenDisplay;
    };
    defer _ = x11.XCloseDisplay(display);

    const root = x11.DefaultRootWindow(display);
    _ = x11.XGrabKeyboard(display, root, x11.True, x11.GrabModeAsync, x11.GrabModeAsync, x11.CurrentTime);

    var event: x11.XEvent = undefined;
    while (true) {
        _ = x11.XNextEvent(display, &event);
        if (event.type == x11.KeyPress) {
            if (event.xkey.keycode == x11.XKeysymToKeycode(display, x11.XStringToKeysym("q"))) break;
        }
    }
}
