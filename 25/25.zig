const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

const INPUT_FILE = "input.txt";

fn sum1(a1: u8, a2: u8) [2]u8 {
    return switch (a1) {
        '=' => {
            return switch (a2) {
                '=' => [_]u8{ '1', '-' },
                '-' => [_]u8{ '2', '-' },
                '0' => [_]u8{ '=', '0' },
                '1' => [_]u8{ '-', '0' },
                '2' => [_]u8{ '0', '0' },
                else => unreachable,
            };
        },
        '-' => {
            return switch (a2) {
                '-' => [_]u8{ '=', '0' },
                '0' => [_]u8{ '-', '0' },
                '1' => [_]u8{ '0', '0' },
                '2' => [_]u8{ '1', '0' },
                else => return sum1(a2, a1),
            };
        },
        '0' => {
            return switch (a2) {
                '0' => [_]u8{ '0', '0' },
                '1' => [_]u8{ '1', '0' },
                '2' => [_]u8{ '2', '0' },
                else => return sum1(a2, a1),
            };
        },
        '1' => {
            return switch (a2) {
                '1' => [_]u8{ '2', '0' },
                '2' => [_]u8{ '=', '1' },
                else => return sum1(a2, a1),
            };
        },
        '2' => {
            return switch (a2) {
                '2' => [_]u8{ '-', '1' },
                else => return sum1(a2, a1),
            };
        },
        else => unreachable,
    };
}

fn sum(a1: []const u8, a2: []const u8, s: []u8) void {
    var n1 = a1.len;
    var n2 = a2.len;
    var n: usize = 0;

    var r: [2]u8 = .{ '0', '0' };
    while (true) : (n += 1) {
        const d1 = if (n1 > 0) a1[n1 - 1] else '0';
        const d2 = if (n2 > 0) a2[n2 - 1] else '0';

        s[n] = r[1];
        r = sum1(d1, d2);
        const x = sum1(s[n], r[0]);
        s[n] = x[0];
        r[1] = sum1(r[1], x[1])[0];

        if (n1 > 0) n1 -= 1;
        if (n2 > 0) n2 -= 1;

        if (n1 == 0 and n2 == 0) break;
    }

    if (r[1] != '0') s[n + 1] = r[1];

    std.mem.reverse(u8, s);
}

pub fn main() !void {
    const file = try std.fs.cwd().openFile(
        INPUT_FILE,
        .{},
    );
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    var in = reader.reader();
    var buf: [128]u8 = undefined;

    var s: [128]u8 = undefined;
    std.mem.set(u8, &s, '0');
    while (true) {
        const a = (in.readUntilDelimiterOrEof(&buf, '\n') catch break) orelse break;
        print("a = {s}\n", .{a});
        sum(&s, a, &s);
    }

    print("\nsum = {s}\n", .{s});
}

test "1 + 1 = 2" {
    var s: [1]u8 = undefined;
    sum("1", "1", &s);
    try std.testing.expectEqual([_]u8{'2'}, s);
}

test "1 + 2 = 1=" {
    var s: [2]u8 = undefined;
    sum("1", "2", &s);
    try std.testing.expectEqual([_]u8{ '1', '=' }, s);
    sum("2", "1", &s);
    try std.testing.expectEqual([_]u8{ '1', '=' }, s);
}

test "2 + 2 = 1-" {
    var s: [2]u8 = undefined;
    sum("2", "2", &s);
    try std.testing.expectEqual([_]u8{ '1', '-' }, s);
}

test "2 + 1= = 10" {
    var s: [2]u8 = undefined;
    sum("2", "1=", &s);
    try std.testing.expectEqual([_]u8{ '1', '0' }, s);
    sum("2", "1=", &s);
    try std.testing.expectEqual([_]u8{ '1', '0' }, s);
}

test "1= + 1= = 11" {
    var s: [2]u8 = undefined;
    sum("1=", "1=", &s);
    try std.testing.expectEqual([_]u8{ '1', '1' }, s);
}
