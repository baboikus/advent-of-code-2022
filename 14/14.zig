const std = @import("std");
const print = std.debug.print;

fn readInt(reader: anytype, buf: []u8, delimiter: u8) !i32 {
    return try std.fmt.parseInt(i32, (try reader.readUntilDelimiterOrEof(buf, delimiter)).?, 0);
}

const MAP_WIDTH = 1024;
const GLOBAL_X_OFFSET = 0;

const Cave = struct {
    const Self = @This();

    map: [256][MAP_WIDTH]u8 = undefined,

    fn init(self: *Self) void {
        for (self.map) |*row| {
            for (row) |*c| {
                c.* = ' ';
            }
        }
    }

    fn addRockPath(self: *Self, path: []const u8) !i32 {
        var fis = std.io.fixedBufferStream(path);
        const reader = fis.reader();
        var buf: [32]u8 = undefined;
        var x1 = try readInt(reader, &buf, ',');
        var y1 = try readInt(reader, &buf, ' ');

        var max_y = y1;
        while (true) {
            reader.skipBytes(3, .{}) catch {
                break;
            };
            const x2 = try readInt(reader, &buf, ',');
            const y2 = try readInt(reader, &buf, ' ');

            if (x1 == x2) {
                var from = if (y1 <= y2) y1 else y2;
                var to = if (y1 > y2) y1 else y2;
                while (from <= to) : (from += 1) {
                    self.map[@intCast(usize, from)][@intCast(usize, x1) - GLOBAL_X_OFFSET] = '#';
                }
            } else if (y1 == y2) {
                var from = if (x1 <= x2) x1 else x2;
                var to = if (x1 > x2) x1 else x2;
                while (from <= to) : (from += 1) {
                    self.map[@intCast(usize, y1)][@intCast(usize, from) - GLOBAL_X_OFFSET] = '#';
                }
            } else {
                unreachable;
            }

            if (y2 > max_y) {
                max_y = y2;
            }

            x1 = x2;
            y1 = y2;
        }

        return max_y;
    }

    fn isFree(self: Self, x: usize, y: usize) bool {
        return self.map[y][x - GLOBAL_X_OFFSET] == ' ';
    }

    fn produceSand(self: *Self) bool {
        var sand_x: usize = 500;
        var sand_y: usize = 0;

        if (self.map[sand_y][sand_x - GLOBAL_X_OFFSET] == 'o') return false;

        while (sand_y != self.map.len - 1) {
            if (self.isFree(sand_x, sand_y + 1)) {
                sand_y += 1;
            } else if (self.isFree(sand_x - 1, sand_y + 1)) {
                sand_x -= 1;
                sand_y += 1;
            } else if (self.isFree(sand_x + 1, sand_y + 1)) {
                sand_x += 1;
                sand_y += 1;
            } else {
                self.map[sand_y][sand_x - GLOBAL_X_OFFSET] = 'o';
                return true;
            }
        }

        unreachable;
    }

    fn draw(self: Self) void {
        for (self.map) |row| print("{s}\n", .{row});
    }
};

pub fn main() !void {
    const file = try std.fs.cwd().openFile(
        "input.txt",
        .{},
    );
    defer file.close();

    var cave = Cave{};
    cave.init();

    var reader = std.io.bufferedReader(file.reader());
    var in = reader.reader();
    var buf: [512]u8 = undefined;
    var max_y: i32 = 0;
    while (try in.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        max_y = std.math.max(try cave.addRockPath(line), max_y);
    }

    var x: usize = 0;
    while (x < MAP_WIDTH) : (x += 1) {
        cave.map[@intCast(usize, max_y + 2)][x] = '#';
    }

    var counter: u32 = 0;
    while (cave.produceSand()) {
        counter += 1;
    }
    cave.draw();
    print("counter = {!}\n", .{counter});
}
