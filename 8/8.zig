const std = @import("std");
const print = std.debug.print;

const input = @embedFile("input.txt");

fn count(comptime height: usize, comptime width: usize, comptime from: usize, comptime to: usize, comptime is_by_rows: bool, data: []const u8, flags: *[height][width]bool) u32 {
    const forest = @ptrCast(*const [height][width]u8, data);

    var counter: u32 = 0;
    var y: usize = 0;
    var x: usize = 0;
    if (is_by_rows) {
        while (y < height) : (y += 1) {
            var current_max: u8 = 0;
            x = from;
            while (x != to) : (x = if (from <= to) x + 1 else x - 1) {
                const tree = forest[y][x];
                if (x == 0 or x == width - 1 or tree > current_max) {
                    if (!flags[y][x]) {
                        counter += 1;
                        flags[y][x] = true;
                    }
                    current_max = tree;
                }
            }
        }
    } else {
        while (x < width) : (x += 1) {
            var current_max: u8 = 0;
            y = from;
            while (y != to) : (y = if (from <= to) y + 1 else y - 1) {
                const tree = forest[y][x];
                if (y == 0 or y == height - 1 or tree > current_max) {
                    if (!flags[y][x]) {
                        counter += 1;
                        flags[y][x] = true;
                    }
                    current_max = tree;
                }
            }
        }
    }

    return counter;
}

fn solve(comptime height: usize, comptime width: usize, data: []const u8) u32 {
    var flags: [height][width]bool = undefined;

    const res = count(height, width, 0, width - 1, true, data, &flags) + count(height, width, width - 1, 0, true, data, &flags) + count(height, width, 0, height - 1, false, data, &flags) + count(height, width, height - 1, 0, false, data, &flags);

    return res;
}

pub fn main() !void {
    const solution = solve(99, 99, input);
    print("solution = {!}\n", .{solution});
}

test "1" {
    const test_data = "3037325512653323354935390";
    try std.testing.expectEqual(@as(u32, 16 + 5), solve(5, 5, test_data));
}
