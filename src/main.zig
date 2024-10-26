const std = @import("std");
const Commet = @import("root.zig").Commet;

pub fn main() !void {
    const connection = try Commet.connect();
    defer connection.disconnect();

    connection.run();
}
