const x11 = @import("x11.zig");
const std = @import("std");
const Config = @import("config.zig").Config;
const Op = @import("config.zig").Op;

pub const State = struct {
    display: *x11.Display,
    key_bindings: KeyBindings,
    last_key: x11.KeyCode = 0,
    speed: c_int = 15,
    acceleration: c_int = 0,
    scroll_delay: c_uint = 25,
    latch: bool = false,
    xdo: *x11.xdo,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, display: *x11.Display, config: Config) !State {
        const key_bindings = try KeyBindings.init(allocator, display, config);

        const xdo = x11.xdo_new_with_opened_display(display, null, x11.True) orelse return blk: {
            std.debug.print("comet: failed to create xdo instance", .{});
            break :blk error.UnableToCreateXdoInstance;
        };

        return .{ .display = display, .key_bindings = key_bindings, .xdo = xdo };
    }

    pub fn deinit(self: *Self) void {
        _ = x11.xdo_free(self.xdo);
    }

    fn move(self: *Self, direction: enum { up, down, left, right }) void {
        const keyBinding = switch (direction) {
            .up => self.key_bindings.move.up,
            .down => self.key_bindings.move.down,
            .left => self.key_bindings.move.left,
            .right => self.key_bindings.move.right,
        };

        self.acceleration = if (self.last_key == keyBinding) self.acceleration + 1 else 0;

        const offset = switch (direction) {
            .up => .{ @as(c_int, 0), -self.speed - self.acceleration },
            .down => .{ @as(c_int, 0), self.speed + self.acceleration },
            .left => .{ -self.speed - self.acceleration, @as(c_int, 0) },
            .right => .{ self.speed + self.acceleration, @as(c_int, 0) },
        };

        _ = x11.xdo_move_mouse_relative(self.xdo, offset[0], offset[1]);
    }

    fn mouse_op(
        self: *Self,
        op: enum(u8) {
            left = 1,
            middle = 2,
            right = 3,
            scroll_up = 4,
            scroll_down = 5,
            scroll_left = 6,
            scroll_right = 7,
        },
    ) void {
        _ = x11.xdo_click_window_multiple(self.xdo, x11.CURRENTWINDOW, @intFromEnum(op), 1, self.scroll_delay);
    }

    fn toggle_latch(self: *Self) void {
        _ = if (self.latch) x11.xdo_mouse_up(self.xdo, x11.CURRENTWINDOW, 1) else x11.xdo_mouse_down(self.xdo, x11.CURRENTWINDOW, 1);
        self.latch = !self.latch;
    }

    fn index(self: *Self) void {
        const startIndex = getKeycode(self.display, "1");
        const endIndex = getKeycode(self.display, "0");

        var event: x11.XEvent = undefined;
        while (true) {
            _ = x11.XNextEvent(self.display, &event);
            const y_key = event.xkey.keycode;

            if (event.xkey.type == x11.KeyRelease) continue;
            if (y_key == self.key_bindings.quit) return;

            if (y_key >= startIndex and y_key <= endIndex) {
                while (true) {
                    _ = x11.XNextEvent(self.display, &event);
                    const x_key = event.xkey.keycode;

                    if (event.xkey.type == x11.KeyRelease) continue;
                    if (x_key == getKeycode(self.display, "BackSpace")) break;
                    if (x_key == self.key_bindings.quit) return;

                    if (x_key >= startIndex and x_key <= endIndex) {
                        const x_index = (x_key - 9) % 11;
                        const y_index = (y_key - 9) % 11;

                        var width: c_uint = undefined;
                        var height: c_uint = undefined;
                        _ = x11.xdo_get_viewport_dimensions(self.xdo, &width, &height, 0);

                        _ = x11.xdo_move_mouse(
                            self.xdo,
                            @intCast(width / 11 * x_index),
                            @intCast(height / 11 * y_index),
                            0,
                        );

                        return;
                    }
                }
            }
        }
    }

    pub fn process_key(self: *Self, event: x11.XKeyEvent) void {
        const key = event.keycode;
        const keys = self.key_bindings;

        if (key == keys.move.up) {
            self.move(.up);
        } else if (key == keys.move.down) {
            self.move(.down);
        } else if (key == keys.move.left) {
            self.move(.left);
        } else if (key == keys.move.right) {
            self.move(.right);
        } else if (key == keys.mouse.left) {
            self.mouse_op(.left);
        } else if (key == keys.mouse.right) {
            self.mouse_op(.right);
        } else if (key == keys.mouse.middle) {
            self.mouse_op(.middle);
        } else if (key == keys.scroll.left) {
            self.mouse_op(.scroll_left);
        } else if (key == keys.scroll.down) {
            self.mouse_op(.scroll_down);
        } else if (key == keys.scroll.up) {
            self.mouse_op(.scroll_up);
        } else if (key == keys.scroll.right) {
            self.mouse_op(.scroll_right);
        } else if (key == keys.latch) {
            self.toggle_latch();
        } else if (key == keys.index) {
            self.index();
        }

        self.last_key = @intCast(key);
    }
};

fn getKeycode(display: *x11.Display, key: [:0]const u8) x11.KeyCode {
    return x11.XKeysymToKeycode(display, x11.XStringToKeysym(key));
}

pub const KeyBindings = struct {
    quit: x11.KeyCode,
    index: x11.KeyCode,
    move: struct {
        left: x11.KeyCode,
        up: x11.KeyCode,
        down: x11.KeyCode,
        right: x11.KeyCode,
    },
    scroll: struct {
        up: x11.KeyCode,
        down: x11.KeyCode,
        left: x11.KeyCode,
        right: x11.KeyCode,
    },
    mouse: struct {
        left: x11.KeyCode,
        middle: x11.KeyCode,
        right: x11.KeyCode,
    },
    latch: x11.KeyCode,

    pub fn init(allocator: std.mem.Allocator, display: *x11.Display, config: Config) !KeyBindings {
        var arenabuf = std.heap.ArenaAllocator.init(allocator);
        defer arenabuf.deinit();
        const arena = arenabuf.allocator();

        return .{
            .quit = getKeycode(display, try arena.dupeZ(u8, config.quit)),
            .index = getKeycode(display, try arena.dupeZ(u8, config.index)),
            .move = .{
                .left = getKeycode(display, try arena.dupeZ(u8, config.move.left)),
                .up = getKeycode(display, try arena.dupeZ(u8, config.move.up)),
                .down = getKeycode(display, try arena.dupeZ(u8, config.move.down)),
                .right = getKeycode(display, try arena.dupeZ(u8, config.move.right)),
            },
            .scroll = .{
                .up = getKeycode(display, try arena.dupeZ(u8, config.scroll.up)),
                .down = getKeycode(display, try arena.dupeZ(u8, config.scroll.down)),
                .left = getKeycode(display, try arena.dupeZ(u8, config.scroll.left)),
                .right = getKeycode(display, try arena.dupeZ(u8, config.scroll.right)),
            },
            .mouse = .{
                .left = getKeycode(display, try arena.dupeZ(u8, config.mouse.left)),
                .middle = getKeycode(display, try arena.dupeZ(u8, config.mouse.middle)),
                .right = getKeycode(display, try arena.dupeZ(u8, config.mouse.right)),
            },
            .latch = getKeycode(display, try arena.dupeZ(u8, config.latch)),
        };
    }
};
