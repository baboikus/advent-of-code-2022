const std = @import("std");
const print = std.debug.print;

const Map = *[41][62]u8;

const Pos = struct {
    x: usize,
    y: usize,
    step: u32,

    fn up(self: Pos) ?Pos {
        return if (self.y > 0) Pos{ .x = self.x, .y = self.y - 1, .step = self.step + 1 } else null;
    }

    fn down(self: Pos, border: usize) ?Pos {
        return if (self.y < border - 1) Pos{ .x = self.x, .y = self.y + 1, .step = self.step + 1 } else null;
    }

    fn left(self: Pos) ?Pos {
        return if (self.x > 0) Pos{ .x = self.x - 1, .y = self.y, .step = self.step + 1 } else null;
    }

    fn right(self: Pos, border: usize) ?Pos {
        return if (self.x < border - 1) Pos{ .x = self.x + 1, .y = self.y, .step = self.step + 1 } else null;
    }
};

fn Front(comptime map_width: usize, comptime map_height: usize) type {
    return struct {
        const Q = std.TailQueue(Pos);
        var node_idx: usize = 0;
        var nodes: [4096]Q.Node = undefined;

        q: Q = Q{},
        v: [map_height][map_width]bool = undefined,
        map: Map,

        const Self = @This();

        fn take(self: *Self) ?Pos {
            return if (self.q.popFirst()) |node| node.data else null;
        }

        fn move(self: *Self, from: Pos, maybe_to: ?Pos) void {
            if (maybe_to) |to| {
                if (self.v[to.y][to.x]) return;
                if (!self.isValidMove(from, to)) return;

                self.v[to.y][to.x] = true;

                var node = &nodes[node_idx];
                node.* = Q.Node{ .data = to };
                node_idx += 1;
                self.q.append(node);
            }
        }

        fn check(self: Self) void {
            print("\n", .{});
            var r: usize = 0;
            var c: usize = 0;
            while (r < self.v.len) : (r += 1) {
                c = 0;
                while (c < self.v[r].len) : (c += 1) {
                    if (self.map[r][c] == '\n') continue;
                    const s: u8 = if (self.v[r][c]) '*' else self.map[r][c];
                    print("{c}", .{s});
                }
                print("\n", .{});
            }

            print("\n", .{});
        }

        fn isValidMove(self: Self, from: Pos, to: Pos) bool {
            return (self.map[from.y][from.x] <= self.map[to.y][to.x] + 1 and self.map[to.y][to.x] != 'a') or (from.y == to.y and from.x == to.x) or (self.map[from.y][from.x] == 'b' and self.map[to.y][to.x] == 'a');
        }
    };
}

fn solve(comptime width: usize, comptime height: usize, map: Map) u32 {
    var front = Front(width, height){ .map = map };
    front.move(Pos{ .x = 36, .y = 20, .step = 0 }, Pos{ .x = 36, .y = 20, .step = 0 });

    var n: u32 = 0;
    while (front.take()) |pos| {
        if (n % 100 == 0) front.check();
        n += 1;
        if (map[pos.y][pos.x] == 'a') {
            front.check();
            print("{!}\n", .{pos});
            return pos.step;
        }
        front.move(pos, pos.up());
        front.move(pos, pos.down(height));
        front.move(pos, pos.left());
        front.move(pos, pos.right(width));
    }

    return 0;
}

pub fn main() !void {
    const file = try std.fs.cwd().openFile(
        "input.txt",
        .{},
    );
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    var in = reader.reader();
    var map: [41][62]u8 = undefined;
    var i: usize = 0;
    while (i < map.len) : (i += 1) {
        _ = try in.readUntilDelimiterOrEof(&map[i], '\n') orelse break;
    }
    _ = solve(62, 41, &map);
}

test "1" {
    const map = [_][]const u8{
        "aabqponm",
        "abcryxxl",
        "accszExk",
        "acctuvwj",
        "abdefghi",
    };
    try std.testing.expectEqual(@as(u32, 31), solve(8, 5, &map));
}
