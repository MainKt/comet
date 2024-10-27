const std = @import("std");
const Commet = @import("root.zig").Commet;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var connection = try Commet.init(allocator);
    defer connection.deinit();

    connection.run();
}
