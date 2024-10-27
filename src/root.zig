const std = @import("std");
const x11 = @import("x11.zig");
const utils = @import("utils.zig");
const Config = @import("config.zig").Config;
const State = utils.State;
const KeyBindings = utils.KeyBindings;

pub const Commet = struct {
    display: *x11.Display,
    root: x11.Window,
    xdo: *x11.xdo,
    config: Config,
    state: State,

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

        const state = State.init(xdo, try KeyBindings.init(allocator, display, config));

        return .{
            .display = display,
            .root = x11.DefaultRootWindow(display),
            .xdo = xdo,
            .config = config,
            .state = state,
        };
    }

    pub fn deinit(self: *Self) void {
        _ = x11.xdo_free(self.xdo);
    }

    pub fn run(self: *Self) void {
        _ = x11.XGrabKeyboard(self.display, self.root, x11.True, x11.GrabModeAsync, x11.GrabModeAsync, x11.CurrentTime);

        var event: x11.XEvent = undefined;
        _ = x11.XNextEvent(self.display, &event);
        while (true) {
            _ = x11.XNextEvent(self.display, &event);
            if (event.type == x11.KeyRelease) continue;
            if (event.xkey.keycode == self.state.key_bindings.quit) break;
            self.state.process_key(event.xkey);
        }
    }
};
