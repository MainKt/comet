const std = @import("std");
const x11 = @import("x11.zig");
const utils = @import("utils.zig");
const Config = @import("config.zig").Config;
const State = utils.State;
const KeyBindings = utils.KeyBindings;

pub const Comet = struct {
    allocator: std.mem.Allocator,
    state: State,
    config_content: []const u8,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !Self {
        const display = x11.XOpenDisplay(null) orelse return blk: {
            std.debug.print("comet: cannot open X display\n", .{});
            break :blk error.UnableToOpenDisplay;
        };

        const config_content = try Config.readConfigFile(allocator);
        const config = try Config.parseConfig(allocator, config_content);
        const state = try State.init(allocator, display, config);

        return .{
            .allocator = allocator,
            .state = state,
            .config_content = config_content,
        };
    }

    pub fn deinit(self: *Self) void {
        self.state.deinit();
        self.allocator.free(self.config_content);
    }

    pub fn run(self: *Self) void {
        const display = self.state.display;
        _ = x11.XGrabKeyboard(display, x11.DefaultRootWindow(display), x11.True, x11.GrabModeAsync, x11.GrabModeAsync, x11.CurrentTime);

        var event: x11.XEvent = undefined;
        _ = x11.XNextEvent(display, &event);
        while (true) {
            _ = x11.XNextEvent(display, &event);
            if (event.type == x11.KeyRelease) continue;
            if (event.xkey.keycode == self.state.key_bindings.quit) break;
            self.state.process_key(event.xkey);
        }
    }
};
