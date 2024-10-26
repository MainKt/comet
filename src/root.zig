const std = @import("std");
const x11 = @import("x11.zig");

pub const Commet = struct {
    display: *x11.Display,
    root: x11.Window,

    const Self = @This();

    pub fn connect() !Self {
        const display = x11.XOpenDisplay(null) orelse
            return blk: {
            std.debug.print("comet: cannot open X display\n", .{});
            break :blk error.UnableToOpenDisplay;
        };
        return .{ .display = display, .root = x11.DefaultRootWindow(display) };
    }

    pub fn disconnect(self: Self) void {
        _ = x11.XCloseDisplay(self.display);
    }

    pub fn run(self: Self) void {
        _ = x11.XGrabKeyboard(self.display, self.root, x11.True, x11.GrabModeAsync, x11.GrabModeAsync, x11.CurrentTime);

        var event: x11.XEvent = undefined;
        while (true) {
            _ = x11.XNextEvent(self.display, &event);
            if (event.type == x11.KeyPress) {
                if (event.xkey.keycode == x11.XKeysymToKeycode(self.display, x11.XStringToKeysym("q"))) {
                    break;
                }
            }
        }
    }
};
