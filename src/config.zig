const std = @import("std");
const x11 = @import("x11.zig");

pub const Op = enum { quit, index, move_left, move_up, move_down, move_right, scroll_up, scroll_down, scroll_left, scroll_right, mouse_left, mouse_middle, mouse_right, drag_toggle, drag_copy };

pub const Config = struct {
    quit: []const u8 = "q",
    index: []const u8 = "f",
    move: struct {
        left: []const u8 = "h",
        up: []const u8 = "k",
        down: []const u8 = "j",
        right: []const u8 = "l",
    } = .{},
    scroll: struct {
        up: []const u8 = "u",
        down: []const u8 = "d",
        left: []const u8 = "zh",
        right: []const u8 = "zl",
    } = .{},
    mouse: struct {
        left: []const u8 = "m",
        middle: []const u8 = "comma",
        right: []const u8 = "period",
    } = .{},
    drag: struct {
        toggle: []const u8 = "v",
        copy: []const u8 = "y",
    } = .{},

    pub fn loadOrCreate(allocator: std.mem.Allocator) !Config {
        const config_dir = try (if (std.posix.getenv("XDG_CONFIG_HOME")) |xdg_config_home|
            try std.fs.openDirAbsolute(xdg_config_home, .{})
        else blk: {
            const home = try std.fs.openDirAbsolute(std.posix.getenv("HOME") orelse "~", .{});
            break :blk try home.makeOpenPath(".config", .{});
        })
            .makeOpenPath("commet", .{});

        const config_file = try config_dir.createFile("config.json", .{
            .read = true,
            .truncate = false,
        });
        defer config_file.close();
        try config_file.seekTo(0);

        const stats = try config_file.stat();
        if (stats.size == 0) {
            const default_config = Config{};
            const content = try std.json.stringifyAlloc(allocator, default_config, .{ .whitespace = .indent_2 });
            try config_file.writeAll(content);
            return default_config;
        }

        const content = try config_file.readToEndAlloc(allocator, 1024);
        const json = std.json.parseFromSlice(Config, allocator, content, .{}) catch |err| {
            std.debug.print("commet: error reading config\n", .{});
            return err;
        };
        defer json.deinit();
        return json.value;
    }

    pub fn generateKeyCodeToOpMap(self: Config, allocator: std.mem.Allocator, display: *x11.Display) !std.AutoHashMap(x11.KeyCode, Op) {
        var map = std.AutoHashMap(x11.KeyCode, Op).init(allocator);

        var arenabuf = std.heap.ArenaAllocator.init(allocator);
        defer arenabuf.deinit();
        const arena = arenabuf.allocator();

        try map.put(getKeycode(display, try arena.dupeZ(u8, self.quit)), .quit);
        try map.put(getKeycode(display, try arena.dupeZ(u8, self.index)), .index);
        try map.put(getKeycode(display, try arena.dupeZ(u8, self.move.left)), .move_left);
        try map.put(getKeycode(display, try arena.dupeZ(u8, self.move.down)), .move_down);
        try map.put(getKeycode(display, try arena.dupeZ(u8, self.move.up)), .move_up);
        try map.put(getKeycode(display, try arena.dupeZ(u8, self.move.right)), .move_right);
        try map.put(getKeycode(display, try arena.dupeZ(u8, self.scroll.up)), .scroll_up);
        try map.put(getKeycode(display, try arena.dupeZ(u8, self.scroll.down)), .scroll_down);
        try map.put(getKeycode(display, try arena.dupeZ(u8, self.scroll.left)), .scroll_left);
        try map.put(getKeycode(display, try arena.dupeZ(u8, self.scroll.right)), .scroll_right);
        try map.put(getKeycode(display, try arena.dupeZ(u8, self.mouse.left)), .mouse_left);
        try map.put(getKeycode(display, try arena.dupeZ(u8, self.mouse.middle)), .mouse_middle);
        try map.put(getKeycode(display, try arena.dupeZ(u8, self.mouse.right)), .mouse_right);
        try map.put(getKeycode(display, try arena.dupeZ(u8, self.drag.toggle)), .drag_toggle);
        try map.put(getKeycode(display, try arena.dupeZ(u8, self.drag.copy)), .drag_copy);

        return map;
    }
};

fn getKeycode(display: *x11.Display, key: [:0]const u8) x11.KeyCode {
    return x11.XKeysymToKeycode(display, x11.XStringToKeysym(key));
}
