const std = @import("std");
const print = std.debug.print;

const TOWER_WIDTH = 7;
const Tower = std.ArrayList(Unit);

const Unit = struct { x: i32, y: i32 };

const Rock = struct {
    const Self = @This();

    units: [5]Unit,
    dx: i32 = 0,
    dy: i32 = 0,

    fn reset(self: *Self) void {
        self.dx = 0;
        self.dy = 0;
    }

    fn upTo(self: *Self, dy: i32) void {
        self.dy = dy;
    }

    fn left(self: *Self, tower: *const Tower) bool {
        for (self.units) |rock_unit| {
            if (rock_unit.x + self.dx == 0) return false;
        }

        var i: usize = 1;
        const limit = tower.items.len;
        while (i <= limit) : (i += 1) {
            const tower_unit = tower.items[tower.items.len - i];
            for (self.units) |rock_unit| {
                if (rock_unit.x + self.dx - 1 == tower_unit.x and rock_unit.y + self.dy == tower_unit.y) {
                    return false;
                }
            }
        }

        self.dx -= 1;
        return true;
    }

    fn right(self: *Self, tower: *const Tower) bool {
        for (self.units) |rock_unit| {
            if (rock_unit.x + self.dx == TOWER_WIDTH - 1) return false;
        }

        var i: usize = 1;
        const limit = tower.items.len;
        while (i <= limit) : (i += 1) {
            const tower_unit = tower.items[tower.items.len - i];
            for (self.units) |rock_unit| {
                if (rock_unit.x + self.dx + 1 == tower_unit.x and rock_unit.y + self.dy == tower_unit.y) {
                    return false;
                }
            }
        }

        self.dx += 1;
        return true;
    }

    fn down(self: *Self, tower: *const Tower) bool {
        for (self.units) |rock_unit| {
            if (rock_unit.y + self.dy == 0) return false;
        }

        var i: usize = 1;
        const limit = tower.items.len;
        while (i <= limit) : (i += 1) {
            const tower_unit = tower.items[tower.items.len - i];
            for (self.units) |rock_unit| {
                if (rock_unit.x + self.dx == tower_unit.x and rock_unit.y + self.dy - 1 == tower_unit.y) {
                    return false;
                }
            }
        }

        self.dy -= 1;
        return true;
    }

    fn topY(self: Self) i32 {
        var top_y: i32 = 0;
        for (self.units) |unit| {
            top_y = std.math.max(top_y, unit.y + self.dy);
        }
        return top_y + 1;
    }

    fn getAbsoluteUnits(self: Self) [5]Unit {
        var absolute_units: [self.units.len]Unit = undefined;
        var i: usize = 0;
        while (i < self.units.len) : (i += 1) {
            absolute_units[i] = self.units[i];
            absolute_units[i].x += self.dx;
            absolute_units[i].y += self.dy;
        }
        return absolute_units;
    }
};

const Chamber = struct {
    const Self = @This();

    const allocator = std.heap.page_allocator;

    top_y: i32 = 0,
    next_rock_idx: usize = 2,
    rocks: [5]Rock = [5]Rock{ Rock{ .units = [5]Unit{
        Unit{ .x = 2, .y = 0 },
        Unit{ .x = 2, .y = 1 },
        Unit{ .x = 2, .y = 2 },
        Unit{ .x = 2, .y = 3 },
        Unit{ .x = 2, .y = 3 },
    } }, Rock{ .units = [5]Unit{
        Unit{ .x = 2, .y = 0 },
        Unit{ .x = 3, .y = 0 },
        Unit{ .x = 2, .y = 1 },
        Unit{ .x = 3, .y = 1 },
        Unit{ .x = 3, .y = 1 },
    } }, Rock{ .units = [5]Unit{
        Unit{ .x = 2, .y = 0 },
        Unit{ .x = 3, .y = 0 },
        Unit{ .x = 4, .y = 0 },
        Unit{ .x = 5, .y = 0 },
        Unit{ .x = 5, .y = 0 },
    } }, Rock{ .units = [5]Unit{
        Unit{ .x = 3, .y = 0 },
        Unit{ .x = 2, .y = 1 },
        Unit{ .x = 3, .y = 1 },
        Unit{ .x = 4, .y = 1 },
        Unit{ .x = 3, .y = 2 },
    } }, Rock{ .units = [5]Unit{
        Unit{ .x = 2, .y = 0 },
        Unit{ .x = 3, .y = 0 },
        Unit{ .x = 4, .y = 0 },
        Unit{ .x = 4, .y = 1 },
        Unit{ .x = 4, .y = 2 },
    } } },
    current_rock: ?*Rock = null,
    tower: std.ArrayList(Unit) = std.ArrayList(Unit).init(allocator),

    fn hasFlatFloor(self: Self) bool {
        if (self.tower.items.len == 0) return true;

        var counter: u32 = 0;
        var i = self.tower.items.len;
        while (i > 0) : (i -= 1) {
            const unit = self.tower.items[i - 1];
            if (unit.y == self.top_y - 1) counter += 1;
            if (counter == TOWER_WIDTH) break;
        }

        return counter == TOWER_WIDTH;
    }

    fn spawnRock(self: *Self) void {
        self.current_rock = &self.rocks[self.next_rock_idx];
        self.current_rock.?.reset();
        self.current_rock.?.upTo(self.top_y + 3);

        self.next_rock_idx = (self.next_rock_idx + 1) % 5;
    }

    fn fallRockOneUnitDown(self: *Self, gas: u8) !bool {
        _ = switch (gas) {
            '<' => self.current_rock.?.left(&self.tower),
            '>' => self.current_rock.?.right(&self.tower),
            else => unreachable,
        };

        if (self.current_rock.?.down(&self.tower)) {
            return true;
        } else {
            self.top_y = std.math.max(self.top_y, self.current_rock.?.topY());

            for (self.current_rock.?.getAbsoluteUnits()) |unit| {
                try self.tower.append(unit);
            }

            return false;
        }
    }

    fn draw(self: Self) void {
        var screen: [4000 * 4][7]bool = undefined;

        for (self.tower.items) |unit| screen[screen.len - 1 - @intCast(usize, unit.y)][@intCast(usize, unit.x)] = true;
        for (self.current_rock.?.getAbsoluteUnits()) |unit| screen[screen.len - 1 - @intCast(usize, unit.y)][@intCast(usize, unit.x)] = true;

        for (screen) |row| {
            print("|", .{});
            for (row) |u| {
                const c: u8 = if (u) '#' else '.';
                print("{c}", .{c});
            }
            print("|\n", .{});
        }
        print("+++++++++\n", .{});
    }
};

const State = struct {
    rock_idx: usize,
    gas_idx: usize,

    start_y: i64 = 0,
    end_y: i64 = 0,
    start_fallen_rock_num: u64,
    end_fallen_rock_num: u64 = 0,
};

pub fn main() !void {
    const file = try std.fs.cwd().openFile(
        "input.txt",
        .{},
    );
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    var in = reader.reader();

    var chamber = Chamber{};
    chamber.spawnRock();
    var step: u32 = 0;
    var gases: [10093]u8 = undefined;
    const n_gases = try in.readAll(&gases) - 1;

    var cached_states: [16]State = undefined;
    cached_states[0] = State{ .rock_idx = chamber.next_rock_idx, .gas_idx = 0, .start_y = 0, .start_fallen_rock_num = 0 };
    var cached_states_idx: usize = 0;

    var i: usize = 0;
    var fallen_rocks: u64 = 0;
    const LIMIT: u64 = 1000000000000;
    //const LIMIT: u64 = 2022;
    var need_caching = true;
    var cycles: u64 = 0;
    var cycle_height: u64 = 0;
    while (fallen_rocks != LIMIT) : (i = (i + 1) % (n_gases)) {
        const gas = gases[i];
        if (!(try chamber.fallRockOneUnitDown(gas))) {
            if (need_caching and chamber.hasFlatFloor()) {
                var state_found = false;
                var found_state = &cached_states[0];
                for (cached_states) |*state| {
                    if (state.rock_idx == chamber.next_rock_idx and state.gas_idx == i) {
                        state_found = true;
                        if (state.end_y == 0) {
                            state.end_y = chamber.top_y;
                            state.end_fallen_rock_num = fallen_rocks;
                        }
                        found_state = state;
                        break;
                    }
                }

                if (state_found) {
                    cycles = (LIMIT - found_state.start_fallen_rock_num) / (found_state.end_fallen_rock_num - found_state.start_fallen_rock_num);
                    const rest = (LIMIT - found_state.start_fallen_rock_num) % (found_state.end_fallen_rock_num - found_state.start_fallen_rock_num);

                    cycle_height = @intCast(u64, found_state.end_y - found_state.start_y);

                    print("cycles = {!}, cycle_height = {!}, rest = {!}\n", .{ cycles, cycle_height, rest });
                    fallen_rocks = LIMIT - rest;
                    need_caching = false;
                } else {
                    cached_states_idx += 1;
                    cached_states[cached_states_idx] = State{ .rock_idx = chamber.next_rock_idx, .gas_idx = i, .start_y = chamber.top_y, .start_fallen_rock_num = fallen_rocks };
                }
            }

            fallen_rocks += 1;
            chamber.spawnRock();
        }
        step += 1;
    }

    //  chamber.draw();
    print("{!} {d:.3}% rocks\n", .{ fallen_rocks, @intToFloat(f32, fallen_rocks) / @intToFloat(f32, LIMIT) * 100.0 });
    print("top_y = {!}\n", .{@intCast(u64, chamber.top_y) + (cycles - 1) * cycle_height});
}
