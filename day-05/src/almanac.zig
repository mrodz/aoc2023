const std = @import("std");

const Sections = std.DoublyLinkedList(AlmanacSection);
const Self = @This();

allocator: std.mem.Allocator,
sections: Sections,

pub fn init(allocator: std.mem.Allocator) Self {
    return Self{
        .sections = .{},
        .allocator = allocator,
    };
}

pub fn deinit(self: *Self) void {
    var it: ?*Sections.Node = self.sections.first;
    while (it) |node| : (self.allocator.destroy(node)) {
        it = node.next;
        node.data.deinit();
    }

    self.* = undefined;
}

pub fn addSection(self: *Self, section: AlmanacSection) std.mem.Allocator.Error!void {
    const raw: *Sections.Node = try self.allocator.create(Sections.Node);
    raw.data = section;
    self.sections.append(raw);
}

pub fn getOutput(self: *const Self, number: u64) ?u64 {
    var it = self.sections.first;
    var output = number;
    while (it) |node| : (it = node.next) {
        if (node.data.pursueNumber(output)) |corresponding| {
            output = corresponding;
        } else {
            // "Any source numbers that aren't mapped correspond to the same
            // destination number"
            continue;
        }
    }
    return output;
}

pub const AlmanacSection = struct {
    mappings: std.ArrayList(AlmanacRange),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) AlmanacSection {
        const mappings = std.ArrayList(AlmanacRange).init(allocator);
        return AlmanacSection{
            .mappings = mappings,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *AlmanacSection) void {
        self.mappings.deinit();
        self.* = undefined;
    }

    pub fn addRange(self: *AlmanacSection, src_start: u64, dst_start: u64, len: usize) std.mem.Allocator.Error!void {
        try self.mappings.append(AlmanacRange.init(src_start, dst_start, len));
    }

    pub fn pursueNumber(self: *AlmanacSection, number: u64) ?u64 {
        for (self.mappings.items) |range| {
            if (range.getOutput(number)) |output| return output;
        }
        return null;
    }
};

const AlmanacRange = struct {
    src_start: u64,
    dst_start: u64,
    len: u64,

    fn init(dst_start: u64, src_start: u64, len: u64) AlmanacRange {
        return AlmanacRange{
            .dst_start = dst_start,
            .src_start = src_start,
            .len = len,
        };
    }

    fn getOutput(self: AlmanacRange, number: u64) ?u64 {
        if ((number >= self.src_start) and (number <= self.src_start + self.len)) {
            return number + self.dst_start - self.src_start;
        }
        return null;
    }
};
