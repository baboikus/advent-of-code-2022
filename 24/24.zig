const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

const INPUT_FILE = "input.txt";

const Pos = struct {
    const Self = @This();

    minute: usize = 0,
    r: usize,
    c: usize,
};

const allocator = std.heap.page_allocator;
fn Valley(comptime width: usize, comptime height: usize) type {
    return struct {
        const Self = @This();
        const PosSet = std.AutoHashMap(Pos, void);

        map: [height][width]u8 = undefined,
        w: usize = width,
        h: usize = height,
        cycle: usize = (width - 2) * (height - 2),

        fn cell(self: Self, minute: usize, row: usize, column: usize) u8 {
            if (row == 0 or row == self.h - 1 or column == 0 or column == self.w - 1) {
                return self.map[row][column];
            }

            const w = self.w - 2;
            const h = self.h - 2;

            const from_left = 1 + (column - 1 + (w - minute % w)) % w;
            const from_right = 1 + (column - 1 + (minute % w)) % w;

            const from_top = 1 + (row - 1 + (h - minute % h)) % h;
            const from_bottom = 1 + (row - 1 + (minute % h)) % h;

            //   print("\nrow = {!} column = {!}\n", .{ row, column });
            //   print("from_left = {!} from_right = {!} from_top = {!} from_bottom = {!}\n", .{ from_left, from_right, from_top, from_bottom });

            var counter: u32 = 0;
            var last_char: u8 = '.';
            if (self.map[row][from_left] == '>') {
                counter += 1;
                last_char = self.map[row][from_left];
            }
            if (self.map[row][from_right] == '<') {
                counter += 1;
                last_char = self.map[row][from_right];
            }
            if (self.map[from_top][column] == 'v') {
                counter += 1;
                last_char = self.map[from_top][column];
            }
            if (self.map[from_bottom][column] == '^') {
                counter += 1;
                last_char = self.map[from_bottom][column];
            }

            return if (counter <= 1) last_char else '0' + @intCast(u8, counter);
        }

        fn stay(self: Self, pos: *const Pos) ?Pos {
            if (self.cell(pos.minute + 1, pos.r, pos.c) != '.') {
                return null;
            } else {
                return Pos{ .minute = (pos.minute + 1) % self.cycle, .r = pos.r, .c = pos.c };
            }
        }

        fn left(self: Self, pos: *const Pos) ?Pos {
            if (pos.c == 0 or self.cell(pos.minute + 1, pos.r, pos.c - 1) != '.') {
                return null;
            } else {
                return Pos{ .minute = (pos.minute + 1) % self.cycle, .r = pos.r, .c = pos.c - 1 };
            }
        }

        fn right(self: Self, pos: *const Pos) ?Pos {
            if (pos.c == self.w - 1 or self.cell(pos.minute + 1, pos.r, pos.c + 1) != '.') {
                return null;
            } else {
                return Pos{ .minute = (pos.minute + 1) % self.cycle, .r = pos.r, .c = pos.c + 1 };
            }
        }

        fn top(self: Self, pos: *const Pos) ?Pos {
            if (pos.r == 0 or self.cell(pos.minute + 1, pos.r - 1, pos.c) != '.') {
                return null;
            } else {
                return Pos{ .minute = (pos.minute + 1) % self.cycle, .r = pos.r - 1, .c = pos.c };
            }
        }

        fn bottom(self: Self, pos: *const Pos) ?Pos {
            if (pos.r == self.h - 1 or self.cell(pos.minute + 1, pos.r + 1, pos.c) != '.') {
                return null;
            } else {
                return Pos{ .minute = (pos.minute + 1) % self.cycle, .r = pos.r + 1, .c = pos.c };
            }
        }

        fn findPath(self: Self, start_pos: Pos, end_pos: Pos) !u32 {
            var visited = PosSet.init(allocator);
            defer visited.deinit();

            var front1 = PosSet.init(allocator);
            defer front1.deinit();
            var front2 = PosSet.init(allocator);
            defer front2.deinit();

            var current_front = &front1;
            var next_front = &front2;

            var minutes: u32 = 0;
            try current_front.put(start_pos, {});
            //  var minute: usize = 1;
            while (current_front.count() > 0) {
                var it = current_front.iterator();
                while (it.next()) |kv| {
                    var pos = kv.key_ptr;
                    if (pos.r == end_pos.r and pos.c == end_pos.c) return minutes;

                    if (visited.contains(pos.*)) continue;

                    try visited.put(pos.*, {});

                    if (self.left(pos)) |p| try next_front.put(p, {});
                    if (self.right(pos)) |p| try next_front.put(p, {});
                    if (self.top(pos)) |p| try next_front.put(p, {});
                    if (self.bottom(pos)) |p| try next_front.put(p, {});
                    if (self.stay(pos)) |p| try next_front.put(p, {});
                }

                // self.show(minute);
                // minute += 1;
                // print("\n", .{});
                // it = next_front.iterator();
                // while (it.next()) |kv| {
                //     var pos = kv.key_ptr;
                //     print("{any}\n", .{pos.*});
                // }

                std.mem.swap(*PosSet, &current_front, &next_front);
                next_front.clearRetainingCapacity();

                minutes += 1;
            }

            return minutes;
        }

        fn show(self: Self, minutes: usize) void {
            var r: usize = 0;
            var c: usize = 0;
            print("\n", .{});
            while (r < self.h) : (r += 1) {
                c = 0;
                while (c < self.w) : (c += 1) {
                    print("{c}", .{self.cell(minutes, r, c)});
                }
                print("\n", .{});
            }
        }
    };
}

pub fn main() !void {
    const file = try std.fs.cwd().openFile(
        INPUT_FILE,
        .{},
    );
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    var in = reader.reader();

    var valley = Valley(102, 37){};
    var r: usize = 0;
    var c: usize = 0;
    while (r < 37) : (r += 1) {
        c = 0;
        while (c < 102) : (c += 1) {
            valley.map[r][c] = try in.readByte();
        }
        try in.skipBytes(1, .{});
    }

    valley.show(0);

    const minutes1 = try valley.findPath(Pos{ .r = 0, .c = 1 }, Pos{ .r = 36, .c = 100 });
    const minutes2 = try valley.findPath(Pos{ .minute = minutes1, .r = 36, .c = 100 }, Pos{ .r = 0, .c = 1 });
    const minutes3 = try valley.findPath(Pos{ .minute = minutes1 + minutes2, .r = 0, .c = 1 }, Pos{ .r = 36, .c = 100 });

    print("\nminutes = {!}\n", .{minutes1 + minutes2 + minutes3});
}

test "1" {
    var valley = Valley(8, 6){};

    std.mem.copy(u8, &valley.map[0], "#.######");
    std.mem.copy(u8, &valley.map[1], "#>>.<^<#");
    std.mem.copy(u8, &valley.map[2], "#.<..<<#");
    std.mem.copy(u8, &valley.map[3], "#>v.><>#");
    std.mem.copy(u8, &valley.map[4], "#<^v^^>#");
    std.mem.copy(u8, &valley.map[5], "######.#");

    //valley.show(18);

    const minutes1 = try valley.findPath(Pos{ .r = 0, .c = 1 }, Pos{ .r = 5, .c = 6 });
    try std.testing.expectEqual(@as(usize, 18), minutes1);

    const minutes2 = try valley.findPath(Pos{ .minute = minutes1, .r = 5, .c = 6 }, Pos{ .r = 0, .c = 1 });
    try std.testing.expectEqual(@as(usize, 23), minutes2);

    const minutes3 = try valley.findPath(Pos{ .minute = minutes1 + minutes2, .r = 0, .c = 1 }, Pos{ .r = 5, .c = 6 });
    try std.testing.expectEqual(@as(usize, 13), minutes3);
}
