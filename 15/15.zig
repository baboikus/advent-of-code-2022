const std = @import("std");
const print = std.debug.print;

const utils = @import("utils.zig");

const Sensor = struct {
    const Self = @This();

    sx: i32,
    sy: i32,
    bx: i32,
    by: i32,
    r: i32,

    fn create(sx: i32, sy: i32, bx: i32, by: i32) !Self {
        return Self{
            .sx = sx,
            .sy = sy,
            .bx = bx,
            .by = by,
            .r = try distance(sx, sy, bx, by),
        };
    }

    fn distance(sx: i32, sy: i32, bx: i32, by: i32) !i32 {
        return @intCast(i32, (try std.math.absInt(sx - bx)) + (try std.math.absInt(sy - by)));
    }

    fn isContain(self: Self, x: i32, y: i32) bool {
        if (x == self.bx and y == self.by) return false;
        return (distance(self.sx, self.sy, x, y) catch return false) <= self.r;
    }
};

pub fn main() !void {
    const file = try std.fs.cwd().openFile(
        "input.txt",
        .{},
    );
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    var in = reader.reader();
    var buf: [512]u8 = undefined;

    var sensors = try std.BoundedArray(Sensor, 32).init(0);

    while (true) {
        in.skipBytes(12, .{}) catch break;
        const sx = try utils.readInt(i32, in, &buf, ',');
        try in.skipUntilDelimiterOrEof('=');
        const sy = try utils.readInt(i32, in, &buf, ':');

        try in.skipUntilDelimiterOrEof('=');
        const bx = try utils.readInt(i32, in, &buf, ',');
        try in.skipUntilDelimiterOrEof('=');
        const by = try utils.readInt(i32, in, &buf, '\n');

        try sensors.append(try Sensor.create(sx, sy, bx, by));
    }

    var y: i32 = 0;
    var x: i32 = 0;

    var found = true;
    while (y <= 4000000) : (y += 1) {
        x = 0;
        while (x <= 4000000) {
            found = true;
            for (sensors.constSlice()) |s| {
                if (s.isContain(x, y)) {
                    found = false;
                    x = s.sx + (s.r - (try std.math.absInt(s.sy - y))) + 1;
                    break;
                }
            }
            if (found) {
                print("x = {!} y = {!} frq = {!}\n", .{ x, y, @intCast(u128, x) * 4000000 + @intCast(u128, y) });
                x += 1;
            }
        }
    }
}
