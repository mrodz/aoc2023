const std = @import("std");

pub fn StateMachine(comptime T: type) type {
    return struct {
        data: T,
        next: []u8,
    };
}

pub const TokenError = (error{ InputTooShort, UnexpectedToken, OutOfMemory } || std.fmt.ParseIntError);

fn parseConsumeGreedyWhitespace(in: []u8) StateMachine(bool) {
    for (in, 0..) |c, i| {
        if (!std.ascii.isWhitespace(c)) {
            return StateMachine(bool){ .data = true, .next = in[i..] };
        }
    }

    return StateMachine(bool){ .data = false, .next = in[0..0] };
}

fn parseConsumeSeedLabel(in: []u8) TokenError!StateMachine(void) {
    const label = "seeds:";

    if (in.len < label.len)
        return TokenError.InputTooShort;

    if (!std.mem.eql(u8, in[0..label.len], label))
        return TokenError.UnexpectedToken;

    return StateMachine(void){ .data = void{}, .next = in[label.len..] };
}

fn parseConsumeNumber(in: []u8) TokenError!StateMachine(u64) {
    var endIndex: usize = 0;
    for (in, 0..) |c, i| {
        endIndex = i;
        if (!std.ascii.isDigit(c)) break;
    } else endIndex += 1;

    if (endIndex == 0) {
        std.log.err("Could not parse int from \"{s}\": not a number", .{in[0..1]});
        return TokenError.InvalidCharacter;
    }

    const val = std.fmt.parseInt(u64, in[0..endIndex], 10) catch |err| {
        std.log.err("Could not parse int from \"{s}\": {}", .{ in[0..endIndex], err });
        return err;
    };

    return StateMachine(u64){ .data = val, .next = in[endIndex..] };
}

pub fn parseConsumeIntRow(in: []u8, dst: *std.ArrayList(u64)) TokenError!StateMachine(void) {
    var next = in;

    while (true) {
        const whitespace = parseConsumeGreedyWhitespace(next);
        next = whitespace.next;
        if (!whitespace.data) break;

        const number = try parseConsumeNumber(next);

        try dst.append(number.data);

        next = number.next;
    }

    return StateMachine(void){ .data = void{}, .next = next };
}

pub fn parseSeedsGrammar(in: []u8, dst: *std.ArrayList(u64)) TokenError!StateMachine(void) {
    var next = in;

    next = parseConsumeGreedyWhitespace(next).next;

    next = (try parseConsumeSeedLabel(next)).next;

    next = (try parseConsumeIntRow(next, dst)).next;

    return StateMachine(void){ .data = void{}, .next = in[0..0] };
}
