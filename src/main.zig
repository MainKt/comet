const std = @import("std");
const Commet = @import("root.zig").Commet;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) @panic("Memory Leak!");
    const allocator = gpa.allocator();

    var comet = try Commet.init(allocator);
    defer comet.deinit();

    comet.run();
}
