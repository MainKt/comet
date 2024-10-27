const std = @import("std");
const x11 = @import("x11.zig");
const config = @import("config.zig");

pub const Commet = struct {
    display: *x11.Display,
    root: x11.Window,
    xdo: *x11.xdo,
    config: std.AutoHashMap(x11.KeyCode, config.Op),

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

        const configuration = try config.Config.loadOrCreate(allocator);

        return .{
            .display = display,
            .root = x11.DefaultRootWindow(display),
            .xdo = xdo,
            .config = try configuration.generateKeyCodeToOpMap(allocator, display),
        };
    }

    pub fn deinit(self: *Self) void {
        _ = x11.xdo_free(self.xdo);
        self.config.deinit();
    }

    pub fn run(self: Self) void {
        _ = x11.XGrabKeyboard(self.display, self.root, x11.True, x11.GrabModeAsync, x11.GrabModeAsync, x11.CurrentTime);

        var iterator = self.config.iterator();
        std.debug.print("---------------------\n", .{});
        while (iterator.next()) |entry| {
            std.debug.print("({d}:{})\n", .{ entry.key_ptr.*, entry.value_ptr.* });
        }
        std.debug.print("---------------------\n", .{});

        const speed: i16 = 10;
        var event: x11.XEvent = undefined;
        while (true) {
            _ = x11.XNextEvent(self.display, &event);
            const op = self.config.get(@intCast(event.xkey.keycode)) orelse {
                const key = x11.XKeysymToString(x11.XLookupKeysym(&event.xkey, 0));
                std.debug.print("Key: ({d}:{s})\n", .{ event.xkey.keycode, key });
                continue;
            };
            switch (op) {
                .quit => {
                    break;
                },
                .move_left => {
                    _ = x11.xdo_move_mouse_relative(self.xdo, -speed, 0);
                },
                .move_down => {
                    _ = x11.xdo_move_mouse_relative(self.xdo, 0, speed);
                },
                .move_up => {
                    _ = x11.xdo_move_mouse_relative(self.xdo, 0, -speed);
                },
                .move_right => {
                    _ = x11.xdo_move_mouse_relative(self.xdo, speed, 0);
                },
                .scroll_up => {
                    var window: x11.Window = undefined;
                    _ = x11.xdo_get_window_at_mouse(self.xdo, &window);
                    _ = x11.xdo_click_window_multiple(self.xdo, window, 4, 1, 25);
                },
                .scroll_down => {
                    var window: x11.Window = undefined;
                    _ = x11.xdo_get_window_at_mouse(self.xdo, &window);
                    _ = x11.xdo_click_window_multiple(self.xdo, window, 5, 1, 25);
                },
                .scroll_left => {
                    var window: x11.Window = undefined;
                    _ = x11.xdo_get_window_at_mouse(self.xdo, &window);
                    _ = x11.xdo_click_window_multiple(self.xdo, window, 7, 1, 25);
                },
                .scroll_right => {
                    var window: x11.Window = undefined;
                    _ = x11.xdo_get_window_at_mouse(self.xdo, &window);
                    _ = x11.xdo_click_window_multiple(self.xdo, window, 6, 1, 25);
                },
                .mouse_left => {
                    var window: x11.Window = undefined;
                    _ = x11.xdo_get_window_at_mouse(self.xdo, &window);
                    _ = x11.xdo_click_window_multiple(self.xdo, window, 1, 1, 25);
                },
                .mouse_middle => {
                    var window: x11.Window = undefined;
                    _ = x11.xdo_get_window_at_mouse(self.xdo, &window);
                    _ = x11.xdo_click_window_multiple(self.xdo, window, 2, 1, 25);
                },
                .mouse_right => {
                    var window: x11.Window = undefined;
                    _ = x11.xdo_get_window_at_mouse(self.xdo, &window);
                    _ = x11.xdo_click_window_multiple(self.xdo, window, 3, 1, 25);
                },
                .index => {},
                .drag_toggle => {},
                .drag_copy => {},
            }
        }
    }
};
