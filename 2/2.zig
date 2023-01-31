const std = @import("std");
const print = std.debug.print;
const eql = std.mem.eql;

fn toU32(bytes: anytype) u32 {
    return std.mem.bytesToValue(u32, bytes);
}

pub fn main() !void {
    const file = try std.fs.cwd().openFile(
        "input2.txt",
        .{},
    );
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    var in = reader.reader();

    var score: i32 = 0;
    while (true) {
        const play = in.readIntNative(u32) catch break;
        score += switch (play) {
            toU32("A X\n") => 0 + 3,
            toU32("A Y\n") => 3 + 1,
            toU32("A Z\n") => 6 + 2,
            toU32("B X\n") => 0 + 1,
            toU32("B Y\n") => 3 + 2,
            toU32("B Z\n") => 6 + 3,
            toU32("C X\n") => 0 + 2,
            toU32("C Y\n") => 3 + 3,
            toU32("C Z\n") => 6 + 1,
            else => unreachable,
        };
    }

    print("score = {!}\n", .{score});
}
