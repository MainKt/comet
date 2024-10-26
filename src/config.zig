const std = @import("std");

pub const Config = struct {
    quit: []const u8 = "q",
    index: []const u8 = "f",
    move: struct {
        left: []const u8 = "h",
        up: []const u8 = "j",
        down: []const u8 = "k",
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
};
