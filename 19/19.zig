const std = @import("std");
const print = std.debug.print;

fn readInt(reader: anytype, buf: []u8, delimiter: u8) !u8 {
    const maybe_int = try reader.readUntilDelimiterOrEof(buf, delimiter);
    if (maybe_int == null) return error.EOF;

    return try std.fmt.parseInt(u8, maybe_int.?, 0);
}

const Cost = struct {
    ore: u8 = 0,
    clay: u8 = 0,
    obsidian: u8 = 0,
};

const Blueprint = struct {
    ore_robot_cost: Cost = Cost{},
    clay_robot_cost: Cost = Cost{},
    obsidian_robot_cost: Cost = Cost{},
    geode_robot_cost: Cost = Cost{},
};

const State = struct {
    const Self = @This();

    ore_robot_count: u8 = 1,
    clay_robot_count: u8 = 0,
    obsidian_robot_count: u8 = 0,
    geode_robot_count: u8 = 0,

    ore_amount: u16 = 0,
    clay_amount: u8 = 0,
    obsidian_amount: u8 = 0,
    geode_amount: u8 = 0,

    fn gatherResources(self: *Self) void {
        self.ore_amount += self.ore_robot_count;
        self.clay_amount += self.clay_robot_count;
        self.obsidian_amount += self.obsidian_robot_count;
        self.geode_amount += self.geode_robot_count;
    }

    fn buildOreRobot(self: Self, b: *const Blueprint) ?State {
        if (self.ore_amount >= b.ore_robot_cost.ore) {
            var new_state = self;
            new_state.gatherResources();
            new_state.ore_robot_count += 1;
            new_state.ore_amount -= b.ore_robot_cost.ore;
            return new_state;
        }
        return null;
    }

    fn buildClayRobot(self: Self, b: *const Blueprint) ?State {
        if (self.ore_amount >= b.clay_robot_cost.ore) {
            var new_state = self;
            new_state.gatherResources();
            new_state.clay_robot_count += 1;
            new_state.ore_amount -= b.clay_robot_cost.ore;
            return new_state;
        }
        return null;
    }

    fn buildObsidianRobot(self: Self, b: *const Blueprint) ?State {
        if (self.ore_amount >= b.obsidian_robot_cost.ore and self.clay_amount >= b.obsidian_robot_cost.clay) {
            var new_state = self;
            new_state.gatherResources();
            new_state.obsidian_robot_count += 1;
            new_state.ore_amount -= b.obsidian_robot_cost.ore;
            new_state.clay_amount -= b.obsidian_robot_cost.clay;
            return new_state;
        }
        return null;
    }

    fn buildGeodeRobot(self: Self, b: *const Blueprint) ?State {
        if (self.ore_amount >= b.geode_robot_cost.ore and self.clay_amount >= b.geode_robot_cost.clay and self.obsidian_amount >= b.geode_robot_cost.obsidian) {
            var new_state = self;
            new_state.gatherResources();
            new_state.geode_robot_count += 1;
            new_state.ore_amount -= b.geode_robot_cost.ore;
            new_state.clay_amount -= b.geode_robot_cost.clay;
            new_state.obsidian_amount -= b.geode_robot_cost.obsidian;
            return new_state;
        }
        return null;
    }
};

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();
const MemTable = std.AutoHashMap(State, u8);

pub fn asc(comptime T: type) fn (void, T, T) bool {
    const impl = struct {
        fn inner(context: void, a: T, b: T) bool {
            _ = context;
            return a < b;
        }
    };

    return impl.inner;
}
const asc_u32 = asc(u32);
const asc_u8 = asc(u8);

const StateLayer = struct {
    const Self = @This();
    const Array = std.ArrayList(State);
    const Set = std.AutoHashMap(State, void);

    blueprint: Blueprint,
    states: Set,

    fn findMaxGatheredGeodes(self: *Self, state: *const State, minute: u8, mem_table: *MemTable) u8 {
        if (minute == 32) return state.geode_amount;

        if (mem_table.get(state.*)) |res| return res;

        var build_counter: u4 = 0;

        var m1: u8 = 0;
        var m2: u8 = 0;
        var m3: u8 = 0;
        var m4: u8 = 0;

        if (state.buildGeodeRobot(&self.blueprint)) |next_state| {
            m4 = self.findMaxGatheredGeodes(&next_state, minute + 1, mem_table);
            build_counter += 1;
        }

        if (build_counter == 0) {
            if (state.buildObsidianRobot(&self.blueprint)) |next_state| {
                m3 = self.findMaxGatheredGeodes(&next_state, minute + 1, mem_table);
                build_counter += 1;
            }
        }

        if (build_counter == 0) {
            if (state.buildOreRobot(&self.blueprint)) |next_state| {
                m1 = self.findMaxGatheredGeodes(&next_state, minute + 1, mem_table);
                build_counter += 1;
            }
        }

        if (build_counter < 2) {
            if (state.buildClayRobot(&self.blueprint)) |next_state| {
                m2 = self.findMaxGatheredGeodes(&next_state, minute + 1, mem_table);
                build_counter += 1;
            }
        }

        var m5: u8 = 0;
        if (build_counter < 4) {
            var next_state = state.*;
            next_state.gatherResources();
            m5 = self.findMaxGatheredGeodes(&next_state, minute + 1, mem_table);
        }

        const max = std.sort.max(u8, &[_]u8{ m1, m2, m3, m4, m5 }, {}, asc_u8).?;
        if (minute < 30) {
            mem_table.put(state.*, max) catch unreachable;
        }
        return max;
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

    var total: u32 = 1;
    var line_num: u32 = 1;
    while (line_num <= 3) : (line_num += 1) {
        in.skipBytes("Blueprint ".len, .{}) catch break;
        const n: u32 = try readInt(in, &buf, ':');

        var b = Blueprint{};
        try in.skipBytes(" Each ore robot costs ".len, .{});
        b.ore_robot_cost.ore = try readInt(in, &buf, ' ');
        try in.skipBytes("ore. Each clay robot costs ".len, .{});
        b.clay_robot_cost.ore = try readInt(in, &buf, ' ');
        try in.skipBytes("ore. Each obsidian robot costs ".len, .{});
        b.obsidian_robot_cost.ore = try readInt(in, &buf, ' ');
        try in.skipBytes("ore and ".len, .{});
        b.obsidian_robot_cost.clay = try readInt(in, &buf, ' ');
        try in.skipBytes("clay. Each geode robot costs ".len, .{});
        b.geode_robot_cost.ore = try readInt(in, &buf, ' ');
        try in.skipBytes("ore and ".len, .{});
        b.geode_robot_cost.obsidian = try readInt(in, &buf, ' ');
        try in.skipBytes("obsidian.\n".len, .{});

        print("{!}\n", .{b});
        var next_layer = StateLayer{ .states = StateLayer.Set.init(allocator), .blueprint = b };
        var mem_table = MemTable.init(allocator);
        defer mem_table.deinit();
        const max = next_layer.findMaxGatheredGeodes(&State{}, 0, &mem_table);
        print("len = {!}, max = {!}, quality = {!}\n", .{ next_layer.states.count(), max, max * n });
        total *= max;
        //total += max * n;
    }
    print("total = {!}\n", .{total});
}
