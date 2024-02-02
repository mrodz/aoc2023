const std = @import("std");
const parser = @import("parser.zig");
const Almanac = @import("almanac.zig");

const Input = struct {
    seeds: std.ArrayList(u64),
    almanac: Almanac,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Input {
        return Input{
            .allocator = allocator,
            .almanac = Almanac.init(allocator),
            .seeds = std.ArrayList(u64).init(allocator),
        };
    }

    pub fn deinit(self: *Input) void {
        self.almanac.deinit();
        self.seeds.deinit();
        self.* = undefined;
    }
};

pub fn partOne(input: *const Input) std.mem.Allocator.Error!u64 {
    var output: []u64 = try input.allocator.alloc(u64, input.seeds.items.len);
    defer input.allocator.free(output);

    for (input.seeds.items, 0..) |seed, i| {
        if (input.almanac.getOutput(seed)) |out| output[i] = out;
    }

    return std.mem.min(u64, output);
}

pub fn buildInput(path: []const u8, allocator: std.mem.Allocator) !Input {
    var input = Input.init(allocator); // caller-defer
    errdefer input.deinit();

    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var bufferedReader = std.io.bufferedReader(file.reader());
    var stream = bufferedReader.reader();

    var buffer: [512]u8 = undefined;

    if (try stream.readUntilDelimiterOrEof(&buffer, '\n')) |seedsLine| {
        var seeds = std.ArrayList(u64).init(allocator); // caller-defer

        // resource managmenet of `seeds` is moved to `input`, but in the case
        // that parsing fails, must explicitly drop.

        _ = parser.parseSeedsGrammar(seedsLine, &seeds) catch |err| {
            std.log.err("Could not parse seeds: got \"{s}\" ({})", .{ seedsLine, err });
            seeds.deinit();
            return err;
        };

        input.seeds = seeds;
    }

    var rangeFields = try std.ArrayList(u64).initCapacity(allocator, 3);
    defer rangeFields.deinit();

    if (try stream.readUntilDelimiterOrEof(&buffer, '\n')) |empty_line| {
        if (std.mem.trim(u8, empty_line, &std.ascii.whitespace).len != 0) {
            std.log.err("Expected empty line, got \"{s}\"", .{empty_line});
            return error.UnexpectedToken;
        }
    }

    outer: while (true) {
        @memset(&buffer, 0);
        if (try stream.readUntilDelimiterOrEof(&buffer, '\n')) |empty_line| {
            _ = empty_line;
        }

        var section = Almanac.AlmanacSection.init(allocator); // caller-defer
        errdefer section.deinit();

        while (true) {
            @memset(&buffer, 0);
            if (try stream.readUntilDelimiterOrEof(&buffer, '\n')) |seedsLine| {
                if (std.mem.trim(u8, seedsLine, &std.ascii.whitespace).len == 0) break;
                _ = parser.parseConsumeIntRow(seedsLine, &rangeFields) catch |err| {
                    std.log.err("Could not parse number row: got \"{s}\" ({})", .{ seedsLine, err });
                    return err;
                };
            } else {
                try input.almanac.addSection(section);
                break :outer;
            }
            try section.addRange(rangeFields.items[0], rangeFields.items[1], rangeFields.items[2]);
            rangeFields.clearAndFree();
        }

        try input.almanac.addSection(section);
    }

    return input;
}
