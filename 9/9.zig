const std = @import("std");
const print = std.debug.print;

const Command = struct {
    const Direction = enum { left, right, down, up };
    direction: Direction,
    distance: u32,

    fn fromString(str: []u8) Command {
        const d = switch (str[0]) {
            'L' => Direction.left,
            'R' => Direction.right,
            'D' => Direction.down,
            'U' => Direction.up,
            else => unreachable,
        };
        return Command{
            .direction = d,
            .distance = std.fmt.parseUnsigned(u32, str[2..], 10) catch unreachable,
        };
    }

    fn move(self: anytype, x: *i32, y: *i32) void {
        switch (self.direction) {
            .left => x.* -= 1,
            .right => x.* += 1,
            .up => y.* += 1,
            .down => y.* -= 1,
        }
    }
};

fn Field(comptime side_lenght: usize, comptime rope_lenght: usize) type {
    return struct {
        const Self = @This();
        const Pos = struct {
            x: i32,
            y: i32,

            fn isEqual(self: Pos, other: Pos) bool {
                return self.x == other.x and self.y == other.y;
            }
        };
        bits: [side_lenght][side_lenght]bool = undefined,
        rope: [rope_lenght]Pos = undefined,

        fn init() Self {
            var t = Self{};
            var i: usize = 0;
            while (i < t.rope.len) : (i += 1) t.rope[i] = Pos{ .x = side_lenght / 2, .y = side_lenght / 2 };
            t.bits[@intCast(usize, t.rope[t.rope.len - 1].y)][@intCast(usize, t.rope[t.rope.len - 1].x)] = true;
            return t;
        }

        fn applyCommand(self: anytype, command: Command) void {
            var i: u32 = 0;
            while (i < command.distance) : (i += 1) {
                command.move(&self.rope[0].x, &self.rope[0].y);
                var n: usize = 1;
                while (n < self.rope.len) : (n += 1) {
                    const dx = self.rope[n - 1].x - self.rope[n].x;
                    const dy = self.rope[n - 1].y - self.rope[n].y;

                    if (dx == -2 or dx == 2 or dy == 2 or dy == -2) {
                        self.rope[n].x += std.math.sign(dx);
                        self.rope[n].y += std.math.sign(dy);
                    }
                }
                //  print("{!}\n", .{self.tail_pos});
                self.bits[@intCast(usize, self.rope[self.rope.len - 1].y)][@intCast(usize, self.rope[self.rope.len - 1].x)] = true;
            }
        }

        fn countVisited(self: anytype) u32 {
            var counter: u32 = 0;
            for (self.bits) |row| {
                for (row) |p| {
                    if (p) counter += 1;
                }
            }

            return counter;
        }
    };
}

pub fn main() !void {
    const file = try std.fs.cwd().openFile(
        "input.txt",
        .{},
    );
    defer file.close();

    var field = Field(1024, 10).init();

    var reader = std.io.bufferedReader(file.reader());
    var in = reader.reader();
    var buf: [8]u8 = undefined;
    while (try in.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const command = Command.fromString(line);
        field.applyCommand(command);
    }
    print("visited = {!}", .{field.countVisited()});
}

test "init" {
    var field = Field(64, 3).init();
    const visited = field.countVisited();
    try std.testing.expectEqual(@as(u32, 1), visited);
}

test "commands" {
    var field = Field(64, 2).init();

    field.applyCommand(Command{ .direction = Command.Direction.right, .distance = 4 });
    try std.testing.expectEqual(@as(u32, 4), field.countVisited());

    field.applyCommand(Command{ .direction = Command.Direction.up, .distance = 4 });
    try std.testing.expectEqual(@as(u32, 7), field.countVisited());

    field.applyCommand(Command{ .direction = Command.Direction.left, .distance = 3 });
    try std.testing.expectEqual(@as(u32, 9), field.countVisited());

    field.applyCommand(Command{ .direction = Command.Direction.down, .distance = 1 });
    try std.testing.expectEqual(@as(u32, 9), field.countVisited());

    field.applyCommand(Command{ .direction = Command.Direction.right, .distance = 4 });
    try std.testing.expectEqual(@as(u32, 10), field.countVisited());

    field.applyCommand(Command{ .direction = Command.Direction.down, .distance = 1 });
    try std.testing.expectEqual(@as(u32, 10), field.countVisited());

    field.applyCommand(Command{ .direction = Command.Direction.left, .distance = 5 });
    try std.testing.expectEqual(@as(u32, 13), field.countVisited());

    field.applyCommand(Command{ .direction = Command.Direction.right, .distance = 2 });
    try std.testing.expectEqual(@as(u32, 13), field.countVisited());
}
