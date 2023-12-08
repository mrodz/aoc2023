const std = @import("std");

pub const Scratcher = struct {
    id: u8,
    winners: std.ArrayList(u8),
    present: std.ArrayList(u8),

    pub fn init(id: u8, winners: std.ArrayList(u8), present: std.ArrayList(u8)) Scratcher {
        return .{
            .id = id,
            .winners = winners.*,
            .present = present.*,
        };
    }

    pub fn deinit(self: Scratcher) void {
        self.present.deinit();
        self.winners.deinit();
    }
};

fn ParserState(comptime data_type: type) type {
    return struct {
        value: data_type,
        next: []u8,
    };
}

fn parse_card(line: []u8) !ParserState(u8) {
    const digitStart = 5;

    if (!std.mem.eql(u8, line[0..digitStart], "Card ")) return error.NoCard;

    var digitEnd: usize = 5;
    for (line[5..]) |c| {
        if (!std.ascii.isDigit(c)) break;
        digitEnd += 1;
    }

    const id = try std.fmt.parseUnsigned(u8, line[digitStart..digitEnd], 10);

    return .{ .value = id, .next = line[digitEnd + 2 ..] };
}

fn parse_advance(line: []u8) !?ParserState(enum { NUMBER, PIPE }) {
    if (line.len == 0) return null;

    var startOfInput: usize = 0;

    for (line) |c| {
        if (c != ' ') break;
        startOfInput += 1;
    }

    const c = line[startOfInput];

    if (c == '|') {
        return .{
            .next = line[startOfInput + 2 ..],
            .value = .PIPE,
        };
    } else if (std.ascii.isDigit(c)) {
        return .{
            .next = line[startOfInput..],
            .value = .NUMBER,
        };
    } else if (c == 12 or c == 13) {
        return null;
    } else {
        return error.InvalidToken;
    }
}

fn parse_number(line: []u8) !ParserState(u8) {
    var endOfNumber: usize = 0;

    for (line[0..]) |c| {
        if (!std.ascii.isDigit(c)) break;
        endOfNumber += 1;
    }

    const entry = try std.fmt.parseUnsigned(u8, line[0..endOfNumber], 10);

    return .{
        .next = line[endOfNumber..],
        .value = entry,
    };
}

pub fn partOne(path: []const u8) !u32 {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var bufferedReader = std.io.bufferedReader(file.reader());
    var stream = bufferedReader.reader();

    var buffer: [128]u8 = undefined;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const status = gpa.deinit();
        if (status == .leak) @panic("memory leak");
    }
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    var winners = std.ArrayList(u8).init(arena.allocator());
    defer winners.deinit();

    var present = std.ArrayList(u8).init(arena.allocator());
    defer present.deinit();

    var inWinners = false;

    while (try stream.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        const id = try parse_card(line);

        var nextStr = id.next;

        while (true) {
            const space = try parse_advance(nextStr) orelse break;

            if (space.value == .PIPE) {
                inWinners = false;
            }

            const num = try parse_number(space.next);

            if (inWinners) {
                try winners.append(num.value);
            } else {
                try present.append(num.value);
            }

            nextStr = num.next;
        }

        std.debug.print("winners = {}\n, present = {}", .{ winners, present });

        winners.clearAndFree();
        present.clearAndFree();
    }

    return 0;
}
