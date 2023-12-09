const std = @import("std");
const root = @import("root.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) @panic("memory leak");

    var input = try root.buildInput(".\\input\\input.txt", gpa.allocator());
    defer input.deinit();

    // const solution_p1 = try root.partOne(&input, gpa.allocator());
    // std.log.info("part one = {}", .{solution_p1});

    const solution_p2 = try root.partTwo(&input, gpa.allocator());
    std.log.info("part two = {}", .{solution_p2});
}
