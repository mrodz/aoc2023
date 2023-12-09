//! A C-style state machine parsing implementation.

const std = @import("std");

pub fn ParserState(comptime data_type: type) type {
    return struct {
        value: data_type,
        next: []u8,
    };
}



pub fn parseCard(line: []u8) error{ NoCard, Overflow, InvalidCharacter }!ParserState(u8) {
    const cardEnd = 4;

    if (!std.mem.eql(u8, line[0..cardEnd], "Card")) return error.NoCard;

    var digitStart: usize = cardEnd;

    for (line[cardEnd..]) |c| {
        if (std.ascii.isDigit(c)) break;
        digitStart += 1;
    }

    var digitEnd: usize = digitStart;
    for (line[digitStart..]) |c| {
        if (!std.ascii.isDigit(c)) break;
        digitEnd += 1;
    }

    const id = try std.fmt.parseUnsigned(u8, line[digitStart..digitEnd], 10);

    return .{ .value = id, .next = line[digitEnd + 1 ..] };
}

pub fn parseAdvance(line: []u8) error{InvalidSepToken}!?ParserState(enum { NUMBER, PIPE }) {
    if (line.len == 0) return null;

    var startOfTerm: usize = 0;

    for (line) |c| {
        if (std.ascii.isDigit(c)) return .{ .value = .NUMBER, .next = line[startOfTerm..] };
        if (c != ' ') break;
        startOfTerm += 1;
    }

    const term = line[startOfTerm];

    if (term == 12 or term == 13) return null;

    var startOfInput = startOfTerm;

    for (line[startOfTerm + 1 ..]) |c| {
        if (std.ascii.isDigit(c)) {
            break;
        }
        if (c != ' ') {
            return error.InvalidSepToken;
        }
        startOfInput += 1;
    }

    return .{
        .next = line[startOfInput..],
        .value = if (term == '|') .PIPE else .NUMBER,
    };
}

pub fn parseNumber(line: []u8) error{ ParseIntError, Overflow, InvalidCharacter }!ParserState(u8) {
    var startOfNumber: usize = 0;

    for (line[0..]) |c| {
        if (std.ascii.isDigit(c)) break;
        startOfNumber += 1;
    }

    var endOfNumber: usize = startOfNumber;

    for (line[startOfNumber..]) |c| {
        if (!std.ascii.isDigit(c)) break;
        endOfNumber += 1;
    }

    const entry = try std.fmt.parseUnsigned(u8, line[startOfNumber..endOfNumber], 10);

    return .{
        .next = line[endOfNumber..],
        .value = entry,
    };
}
