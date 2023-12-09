const std = @import("std");
const root = @import("root.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) @panic("memory leak");

    var input = try root.buildInput(".\\input\\input.txt", gpa.allocator());
    defer input.deinit();

    const dur_p1 = try std.time.Instant.now();
    const solution_p1 = try root.partOne(&input, gpa.allocator());
    const elapsed_p1 = try std.time.Instant.now();

    std.log.info("part one = {} (took {} microseconds)", .{ solution_p1, elapsed_p1.since(dur_p1) / std.time.ns_per_us });

    const dur_p2 = try std.time.Instant.now();
    const solution_p2 = try root.partTwo(&input, gpa.allocator());
    const elapsed_p2 = try std.time.Instant.now();

    std.log.info("part two = {} (took {} microseconds)", .{ solution_p2, elapsed_p2.since(dur_p2) / std.time.ns_per_us });
}
