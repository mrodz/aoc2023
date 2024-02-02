const std = @import("std");
const root = @import("root.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) @panic("memory leak");

    var input = try root.buildInput("input/input.txt", gpa.allocator());
    defer input.deinit();

    const dur_p1 = try std.time.Instant.now();
    const partOneResult = try root.partOne(&input);
    const elapsed_p1 = try std.time.Instant.now();

    std.log.info("part one = {} (took {} microseconds)", .{ partOneResult, elapsed_p1.since(dur_p1) / std.time.ns_per_us });
}
