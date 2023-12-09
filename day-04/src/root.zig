const std = @import("std");
const parser = @import("parser.zig");

pub const Scratcher = struct {
    id: u8,
    winners: std.AutoHashMap(u8, void),
    present: []u8,
    presentAllocator: std.mem.Allocator,

    /// `winners` does not have to be owned, as it will be copied into a `Set` on the heap.
    /// `ownedPresent` must be owned. Passing its allocator as `presentAllocator` allows a `Scratcher` instance
    /// to deinitialize its owned resources in a self-contained manner.
    pub fn init(id: u8, winners: []u8, ownedPresent: []u8, allocator: std.mem.Allocator, presentAllocator: std.mem.Allocator) !Scratcher {
        var map = std.AutoHashMap(u8, void).init(allocator);

        for (winners) |winner| try map.put(winner, void{});

        return .{
            .id = id,
            .winners = map,
            .present = ownedPresent,
            .presentAllocator = presentAllocator,
        };
    }

    pub fn deinit(self: *Scratcher) void {
        self.winners.deinit();
        self.presentAllocator.free(self.present);
        self.* = undefined;
    }

    pub fn intersection(self: *const Scratcher, resultBuffer: ?[]u32) error{OutOfBounds}!u32 {
        var sum: u32 = 0;

        var rIdx: usize = 0;

        for (self.present) |present| {
            if (self.winners.contains(present)) {
                if (resultBuffer) |result| {
                    if (rIdx >= result.len) return error.OutOfBounds;
                    result[rIdx] = present;
                    rIdx += 1;
                }

                sum += 1;
            }
        }

        return sum;
    }
};

const Input = struct {
    tickets: std.ArrayList(Scratcher),
    parserBuffer: std.ArrayList(u8),
    allocator: std.mem.Allocator,
    isWinner: bool,

    pub fn init(ticketsAllocator: std.mem.Allocator, bufferAllocator: std.mem.Allocator) Input {
        const tickets = std.ArrayList(Scratcher).init(ticketsAllocator);
        const parserBuffer = std.ArrayList(u8).init(bufferAllocator);
        return .{
            .isWinner = false,
            .tickets = tickets,
            .parserBuffer = parserBuffer,
            .allocator = ticketsAllocator,
        };
    }

    pub fn deinit(self: *Input) void {
        for (self.tickets.items) |*ticket| {
            ticket.deinit();
        }
        self.tickets.deinit();
        self.parserBuffer.deinit();
        self.* = undefined;
    }
};

pub fn buildInput(path: []const u8, allocator: std.mem.Allocator) !Input {
    var input = Input.init(allocator, allocator);

    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var bufferedReader = std.io.bufferedReader(file.reader());
    var stream = bufferedReader.reader();

    var buffer: [128]u8 = undefined;

    while (try stream.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        const id = try parser.parseCard(line);

        var nextStr = id.next;

        var ownedWinners: ?[]u8 = null;

        defer if (ownedWinners) |allocated| allocator.free(allocated);

        while (true) {
            const space = try parser.parseAdvance(nextStr) orelse break;

            if (space.value == .PIPE) {
                ownedWinners = try input.parserBuffer.toOwnedSlice();
            }

            const num = try parser.parseNumber(space.next);

            try input.parserBuffer.append(num.value);

            nextStr = num.next;
        }

        const ownedPresent = try input.parserBuffer.toOwnedSlice();

        errdefer allocator.free(ownedPresent);

        const scratcher = try Scratcher.init(id.value, ownedWinners orelse return error.NoPipe, ownedPresent, allocator, allocator);

        try input.tickets.append(scratcher);
    }

    return input;
}

pub fn partOne(input: *Input, allocator: std.mem.Allocator) !u32 {
    var sum: u32 = 0;

    for (input.tickets.items) |ticket| {
        const buffer = try allocator.alloc(u32, ticket.present.len);
        defer allocator.free(buffer);

        const numberOfIntersections: u32 = try ticket.intersection(buffer);

        if (numberOfIntersections != 0) sum += try std.math.powi(u32, 2, numberOfIntersections - 1);

        std.log.debug("{any}", .{buffer[0..numberOfIntersections]});
    }

    return sum;
}

fn partTwoRecursive(original: []Scratcher, mod: []Scratcher, allocator: *std.mem.Allocator, cache: *std.AutoHashMap(u8, u32), depth: u32) !u32 {
    var sum: u32 = 0;

    for (mod) |ticket| {
        const entry = try cache.getOrPut(ticket.id);

        if (!entry.found_existing) {
            entry.value_ptr.* = try ticket.intersection(null);
        }

        const numberOfIntersections: u32 = entry.value_ptr.*;

        const min = ticket.id;
        const max = @min(min + numberOfIntersections, original.len);

        if (numberOfIntersections != 0) {
            sum += try partTwoRecursive(original, original[min..max], allocator, cache, depth + 1);
        }

        sum += 1;
    }

    return sum;
}

pub fn partTwo(input: *Input, allocator: std.mem.Allocator) !u32 {
    var cache = std.AutoHashMap(u8, u32).init(allocator);
    var tmp = allocator;
    defer cache.deinit();
    return partTwoRecursive(input.tickets.items, input.tickets.items, &tmp, &cache, 0);
}
