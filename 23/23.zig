const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

const INPUT_FILE = "input.txt";

const Pos = struct {
    const Self = @This();

    x: i32 = 0,
    y: i32 = 0,

    fn north(self: Self) Pos {
        return Pos{ .x = self.x, .y = self.y - 1 };
    }

    fn northWest(self: Self) Pos {
        return Pos{ .x = self.x - 1, .y = self.y - 1 };
    }

    fn northEast(self: Self) Pos {
        return Pos{ .x = self.x + 1, .y = self.y - 1 };
    }

    fn south(self: Self) Pos {
        return Pos{ .x = self.x, .y = self.y + 1 };
    }

    fn southWest(self: Self) Pos {
        return Pos{ .x = self.x - 1, .y = self.y + 1 };
    }

    fn southEast(self: Self) Pos {
        return Pos{ .x = self.x + 1, .y = self.y + 1 };
    }

    fn east(self: Self) Pos {
        return Pos{ .x = self.x + 1, .y = self.y };
    }

    fn west(self: Self) Pos {
        return Pos{ .x = self.x - 1, .y = self.y };
    }
};

const ElfRecord = struct {
    const Self = @This();

    current_pos: Pos,
    proposed_pos: ?Pos = null,
    direction: u4 = 0,

    fn calcProposedPos(self: *Self, map: *const Map) void {
        const hasAnyElfsNorth = map.hasAnyElfsNorth(self.current_pos);
        const hasAnyElfsSouth = map.hasAnyElfsSouth(self.current_pos);
        const hasAnyElfsWest = map.hasAnyElfsWest(self.current_pos);
        const hasAnyElfsEast = map.hasAnyElfsEast(self.current_pos);
        if (!hasAnyElfsNorth and !hasAnyElfsSouth and !hasAnyElfsWest and !hasAnyElfsEast) {
            self.proposed_pos = null;
            self.direction = (self.direction + 1) % 4;
            return;
        }

        var n: u32 = 0;
        const first_direction = self.direction;
        while (n < 4) : (n += 1) {
            self.proposed_pos = switch (self.direction) {
                0 => if (!hasAnyElfsNorth) self.current_pos.north() else null,
                1 => if (!hasAnyElfsSouth) self.current_pos.south() else null,
                2 => if (!hasAnyElfsWest) self.current_pos.west() else null,
                3 => if (!hasAnyElfsEast) self.current_pos.east() else null,
                else => unreachable,
            };
            self.direction = (self.direction + 1) % 4;
            if (self.proposed_pos != null) break;
        }
        self.direction = (first_direction + 1) % 4;
    }
};

const allocator = std.heap.page_allocator;
const ElfHashMap = std.AutoHashMap(Pos, *ElfRecord);
const PosCounterHashMap = std.AutoHashMap(Pos, u32);
const Map = struct {
    const Self = @This();

    elfs: [1024 * 4]ElfRecord = undefined,
    elfs_idx: usize = 0,
    elfs_table: ElfHashMap = ElfHashMap.init(allocator),

    fn addElf(self: *Self, pos: Pos) !void {
        var elf = &self.elfs[self.elfs_idx];
        elf.* = ElfRecord{ .current_pos = pos };
        self.elfs_idx += 1;

        try self.elfs_table.put(elf.current_pos, elf);
    }

    fn nextState(self: *Self) !bool {
        var counter_table = PosCounterHashMap.init(allocator);
        defer counter_table.deinit();

        var it = self.elfs_table.iterator();
        while (it.next()) |kv| {
            var elf = kv.value_ptr;
            elf.*.calcProposedPos(self);
            if (elf.*.proposed_pos) |pos| {
                if (counter_table.getPtr(pos)) |counter| {
                    counter.* += 1;
                } else {
                    try counter_table.put(pos, 1);
                }
            }
        }

        var new_elfs_table: ElfHashMap = ElfHashMap.init(allocator);
        it = self.elfs_table.iterator();
        var has_changes = false;
        while (it.next()) |kv| {
            var elf = kv.value_ptr;
            if (elf.*.proposed_pos) |pos| {
                if (counter_table.get(pos).? == 1) {
                    elf.*.current_pos = pos;
                    elf.*.proposed_pos = null;
                    has_changes = true;
                }
            }
            try new_elfs_table.put(elf.*.current_pos, elf.*);
        }

        self.elfs_table.deinit();
        self.elfs_table = new_elfs_table;

        return has_changes;
    }

    fn hasAnyElfsNorth(self: Self, pos: Pos) bool {
        return self.elfs_table.get(pos.north()) != null or self.elfs_table.get(pos.northWest()) != null or self.elfs_table.get(pos.northEast()) != null;
    }

    fn hasAnyElfsSouth(self: Self, pos: Pos) bool {
        return self.elfs_table.get(pos.south()) != null or self.elfs_table.get(pos.southWest()) != null or self.elfs_table.get(pos.southEast()) != null;
    }

    fn hasAnyElfsWest(self: Self, pos: Pos) bool {
        return self.elfs_table.get(pos.west()) != null or self.elfs_table.get(pos.northWest()) != null or self.elfs_table.get(pos.southWest()) != null;
    }

    fn hasAnyElfsEast(self: Self, pos: Pos) bool {
        return self.elfs_table.get(pos.east()) != null or self.elfs_table.get(pos.northEast()) != null or self.elfs_table.get(pos.southEast()) != null;
    }

    fn show(self: Self) void {
        var it = self.elfs_table.iterator();
        var min_x: i32 = std.math.maxInt(i32);
        var max_x: i32 = 0;
        var min_y: i32 = std.math.maxInt(i32);
        var max_y: i32 = 0;
        while (it.next()) |kv| {
            var elf = kv.value_ptr;
            min_x = std.math.min(min_x, elf.*.current_pos.x);
            max_x = std.math.max(max_x, elf.*.current_pos.x);
            min_y = std.math.min(min_y, elf.*.current_pos.y);
            max_y = std.math.max(max_y, elf.*.current_pos.y);
        }

        print("\n", .{});
        var x = min_x;
        var y = min_y;
        while (y <= max_y) : (y += 1) {
            x = min_x;
            while (x <= max_x) : (x += 1) {
                const c: u8 = if (self.elfs_table.get(Pos{ .x = x, .y = y }) != null) '#' else '.';
                print("{c}", .{c});
            }
            print("\n", .{});
        }
        const square = (max_x - min_x + 1) * (max_y - min_y + 1);
        print("square = {!}, elfs = {!}, empty = {!}\n", .{ square, self.elfs_table.count(), square - @intCast(i32, self.elfs_table.count()) });
    }
};

pub fn main() !void {
    const file = try std.fs.cwd().openFile(
        INPUT_FILE,
        .{},
    );
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    var in = reader.reader();

    var pos = Pos{};
    var map = Map{};
    while (true) {
        var b = in.readByte() catch break;
        switch (b) {
            '#' => {
                try map.addElf(pos);
                pos.x += 1;
            },
            '.' => pos.x += 1,
            '\n' => {
                pos.x = 0;
                pos.y += 1;
            },
            else => unreachable,
        }
    }

    var n: u32 = 1;
    while (try map.nextState()) : (n += 1) {
        print("n = {!}\n", .{n});
    }
    map.show();
    print("n = {!}\n", .{n});
}

test "1" {
    var map = Map{};
    try map.addElf(Pos{ .x = -1, .y = 0 });
    try map.addElf(Pos{ .x = 1, .y = 0 });
    try map.addElf(Pos{ .x = 0, .y = -1 });
    try map.addElf(Pos{ .x = 0, .y = 1 });

    try map.nextState();

    try std.testing.expectEqual(Pos{ .x = -2, .y = 0 }, map.elfs[0].current_pos);
    try std.testing.expectEqual(Pos{ .x = 2, .y = 0 }, map.elfs[1].current_pos);
    try std.testing.expectEqual(Pos{ .x = 0, .y = -2 }, map.elfs[2].current_pos);
    try std.testing.expectEqual(Pos{ .x = 0, .y = 2 }, map.elfs[3].current_pos);

    try map.nextState();

    try std.testing.expectEqual(Pos{ .x = -2, .y = 0 }, map.elfs[0].current_pos);
    try std.testing.expectEqual(Pos{ .x = 2, .y = 0 }, map.elfs[1].current_pos);
    try std.testing.expectEqual(Pos{ .x = 0, .y = -2 }, map.elfs[2].current_pos);
    try std.testing.expectEqual(Pos{ .x = 0, .y = 2 }, map.elfs[3].current_pos);
}
