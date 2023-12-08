const std = @import("std");
const root = @import("root.zig");

pub fn main() !void {
    const x = try root.partOne(".\\input\\sample.txt");
    _ = x;
}
