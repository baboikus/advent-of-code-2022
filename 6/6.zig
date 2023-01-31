const std = @import("std");
const print = std.debug.print;

const input = @import("input.zig");

fn solve(seq: []const u8, len: usize) usize {
    var set = std.StaticBitSet('z' + 1).initEmpty();
    var from: usize = 0;
    var to: usize = 0;
    while (to < seq.len) : (to += 1) {
        const c = seq[to];
        if (set.isSet(c)) {
            while (seq[from] != c and from <= to) : (from += 1) set.unset(seq[from]);
            from += 1;
        } else {
            set.set(c);
        }
        if (to - from + 1 == len) break;
    }
    return to + 1;
}

pub fn main() !void {
    print("to = {!}\n", .{solve(input.seq, 14)});
}

test "1" {
    const actual = solve("bvwbjplbgvbhsrlpgdmjqwftvncz", 4);
    try std.testing.expectEqual(@as(usize, 5), actual);
}

test "2" {
    const actual = solve("nppdvjthqldpwncqszvftbrmjlhg", 4);
    try std.testing.expectEqual(@as(usize, 6), actual);
}

test "3" {
    const actual = solve("nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg", 4);
    try std.testing.expectEqual(@as(usize, 10), actual);
}

test "4" {
    const actual = solve("zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw", 4);
    try std.testing.expectEqual(@as(usize, 11), actual);
}
