const std = @import("std");
const parser = @import("parser.zig");

pub const Almanac = struct {
    allocator: std.mem.Allocator,
    root: ?AlmanacSection,
    last: *?AlmanacSection,

    pub fn init(allocator: std.mem.Allocator) Almanac {
        return Almanac{
            .root = undefined,
            .last = undefined,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Almanac) void {
        if (self.root) |root| @constCast(&root).deinit();
        self.* = undefined;
    }

    pub fn addSection(self: *Almanac, section: AlmanacSection) !void {
        if (self.root == undefined) {
            self.root = section;
            self.last = &self.root;
        } else {
            const ptr: *AlmanacSection = (self.last orelse unreachable).next;
            ptr.* = section;
            self.last = ptr;
        }
    }
};

const AlmanacSection = struct {
    mappings: std.ArrayList(AlmanacRange),
    allocator: std.mem.Allocator,
    next: ?*AlmanacSection,

    fn init(allocator: std.mem.Allocator) AlmanacSection {
        const mappings = std.ArrayList(AlmanacRange).init(allocator);
        return AlmanacSection{ mappings, allocator };
    }

    fn deinit(self: *AlmanacSection) void {
        self.mappings.deinit();
        if (self.next) |next| next.deinit();
        self.* = undefined;
    }

    fn addRange(self: *AlmanacSection, src_start: i32, dst_start: i32, len: usize) AlmanacRange {
        self.mappings.append(AlmanacRange.init(src_start, dst_start, len));
    }

    fn pursueNumber(self: *AlmanacSection, number: i32) !i32 {
        for (self.mappings) |range| {
            if (range.getOutput(number)) |output| {
                return output;
            }
        }
        return error.DoesNotExist;
    }
};

const AlmanacRange = struct {
    src_start: i32,
    dst_start: i32,
    len: usize,

    fn init(src_start: i32, dst_start: i32, len: usize) AlmanacRange {
        return AlmanacRange{
            src_start,
            dst_start,
            len,
        };
    }

    fn getOutput(self: AlmanacRange, number: i32) ?i32 {
        if (number >= self.src_start and number <= self.src_start + self.len) {
            const offset = number - self.src_start;
            return self.dst_start + offset;
        }
    }
};

const Input = struct {
    seeds: std.ArrayList(i32),
    almanac: Almanac,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Input {
        return Input{
            .allocator = allocator,
            .almanac = Almanac.init(allocator),
            .seeds = std.ArrayList(i32).init(allocator),
        };
    }

    pub fn deinit(self: *Input) void {
        self.almanac.deinit();
        self.seeds.deinit();
        self.* = undefined;
    }
};

pub fn buildInput(path: []const u8, allocator: std.mem.Allocator) !?Input {
    var input = Input.init(allocator); // // caller-defer
    defer input.deinit();

    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var bufferedReader = std.io.bufferedReader(file.reader());
    var stream = bufferedReader.reader();

    var buffer: [512]u8 = undefined;

    if (try stream.readUntilDelimiterOrEof(&buffer, '\n')) |seedsLine| {
        var seeds = std.ArrayList(i32).init(allocator); // // caller-defer
        defer seeds.deinit();
        _ = try parser.parseSeedsGrammar(seedsLine, &seeds);

        for (seeds.items) |seed| {
            std.log.debug("{}, ", .{seed});
        }
    }

    return undefined;
}
