const std = @import("std");
const print = std.debug.print;

const input = @embedFile("input.txt");

fn bruteMaxScore(comptime height: usize, comptime width: usize, forest: *const [height][width]u8) u64 {
    var max_score: u64 = 0;

    var x: usize = 1;
    var y: usize = 1;
    while (y < height - 1) : (y += 1) {
        x = 1;
        while (x < width - 1) : (x += 1) {
            const tree = forest[y][x];
            var current_score: u64 = 0;
            var i: usize = 1;
            while (i < x and forest[y][x - i] < tree) i += 1;
            current_score = i;

            i = 1;
            while (x + i < width - 1 and forest[y][x + i] < tree) i += 1;
            current_score *= i;

            i = 1;
            while (i < y and forest[y - i][x] < tree) i += 1;
            current_score *= i;

            i = 1;
            while (y + i < height - 1 and forest[y + i][x] < tree) i += 1;
            current_score *= i;

            // print("y = {!}, x = {!}, score = {!}\n", .{ y, x, current_score });

            max_score = std.math.max(max_score, current_score);
        }
    }

    return max_score;
}

fn solve(comptime height: usize, comptime width: usize, data: []const u8) u64 {
    const forest = @ptrCast(*const [height][width]u8, data);
    return bruteMaxScore(height, width, forest);
}

pub fn main() !void {
    const solution = solve(99, 99, input);
    print("solution = {!}\n", .{solution});
}

test "1" {
    const test_data = "3037325512653323354935390";
    try std.testing.expectEqual(@as(u64, 8), solve(5, 5, test_data));
}

test "2" {
    const test_data = "111121111";
    try std.testing.expectEqual(@as(u64, 1), solve(3, 3, test_data));
}

test "3" {
    const test_data = "1111112221123211222111111";
    try std.testing.expectEqual(@as(u64, 16), solve(5, 5, test_data));
}
test "4" {
    const test_data = "1111111111113111111111111";
    try std.testing.expectEqual(@as(u64, 16), solve(5, 5, test_data));
}
