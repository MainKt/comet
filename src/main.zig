const std = @import("std");
const Comet = @import("root.zig").Comet;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) @panic("Memory Leak!");
    const allocator = gpa.allocator();

    var comet = try Comet.init(allocator);
    defer comet.deinit();

    comet.run();
}
