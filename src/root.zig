const std = @import("std");
const x11 = @import("x11.zig");
const Config = @import("config.zig").Config;

pub const Commet = struct {
    display: *x11.Display,
    root: x11.Window,
    xdo: *x11.xdo,
    config: Config,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !Self {
        const display = x11.XOpenDisplay(null) orelse return blk: {
            std.debug.print("comet: cannot open X display\n", .{});
            break :blk error.UnableToOpenDisplay;
        };

        const xdo = x11.xdo_new_with_opened_display(display, null, x11.True) orelse return blk: {
            std.debug.print("comet: failed to create xdo instance", .{});
            break :blk error.UnableToCreateXdoInstance;
        };

        const config = try Config.loadOrCreate(allocator);

        return .{
            .display = display,
            .root = x11.DefaultRootWindow(display),
            .xdo = xdo,
            .config = config,
        };
    }

    pub fn deinit(self: Self) void {
        _ = x11.xdo_free(self.xdo);
    }

    pub fn run(self: Self) void {
        _ = x11.XGrabKeyboard(self.display, self.root, x11.True, x11.GrabModeAsync, x11.GrabModeAsync, x11.CurrentTime);

        var speed: i16 = 10;
        const acceleration = 5;
        var event: x11.XEvent = undefined;
        while (true) {
            _ = x11.XNextEvent(self.display, &event);
            if (event.type == x11.KeyPress) {
                if (event.xkey.keycode == self.getKeycode("Escape")) {
                    break;
                } else if (event.xkey.keycode == self.getKeycode("h")) {
                    _ = x11.xdo_move_mouse_relative(self.xdo, -speed, 0);
                } else if (event.xkey.keycode == self.getKeycode("j")) {
                    _ = x11.xdo_move_mouse_relative(self.xdo, 0, speed);
                } else if (event.xkey.keycode == self.getKeycode("k")) {
                    _ = x11.xdo_move_mouse_relative(self.xdo, 0, -speed);
                } else if (event.xkey.keycode == self.getKeycode("l")) {
                    _ = x11.xdo_move_mouse_relative(self.xdo, speed, 0);
                } else if (event.xkey.keycode == self.getKeycode("a")) {
                    speed += acceleration;
                } else if (event.xkey.keycode == self.getKeycode("u")) {
                    var window: x11.Window = undefined;
                    _ = x11.xdo_get_window_at_mouse(self.xdo, &window);
                    _ = x11.xdo_click_window_multiple(self.xdo, window, 4, 1, 25);
                } else if (event.xkey.keycode == self.getKeycode("d")) {
                    var window: x11.Window = undefined;
                    _ = x11.xdo_get_window_at_mouse(self.xdo, &window);
                    _ = x11.xdo_click_window_multiple(self.xdo, window, 5, 1, 25);
                } else if (event.xkey.keycode == self.getKeycode("f")) {
                    var window: x11.Window = undefined;
                    _ = x11.xdo_get_window_at_mouse(self.xdo, &window);
                    _ = x11.xdo_click_window_multiple(self.xdo, window, 7, 1, 25);
                } else if (event.xkey.keycode == self.getKeycode("b")) {
                    var window: x11.Window = undefined;
                    _ = x11.xdo_get_window_at_mouse(self.xdo, &window);
                    _ = x11.xdo_click_window_multiple(self.xdo, window, 6, 1, 25);
                } else if (event.xkey.keycode == self.getKeycode("m")) {
                    var window: x11.Window = undefined;
                    _ = x11.xdo_get_window_at_mouse(self.xdo, &window);
                    _ = x11.xdo_click_window_multiple(self.xdo, window, 1, 1, 25);
                } else if (event.xkey.keycode == self.getKeycode("comma")) {
                    var window: x11.Window = undefined;
                    _ = x11.xdo_get_window_at_mouse(self.xdo, &window);
                    _ = x11.xdo_click_window_multiple(self.xdo, window, 2, 1, 25);
                } else if (event.xkey.keycode == self.getKeycode("period")) {
                    var window: x11.Window = undefined;
                    _ = x11.xdo_get_window_at_mouse(self.xdo, &window);
                    _ = x11.xdo_click_window_multiple(self.xdo, window, 3, 1, 25);
                } else {
                    const key = x11.XKeysymToString(x11.XLookupKeysym(&event.xkey, 0));
                    std.debug.print("Key: {s}\n", .{key});
                }
            }
        }
    }

    fn getKeycode(self: Self, key: [*c]const u8) x11.KeyCode {
        return x11.XKeysymToKeycode(self.display, x11.XStringToKeysym(key));
    }
};
