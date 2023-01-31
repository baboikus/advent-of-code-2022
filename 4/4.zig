const std = @import("std");
const print = std.debug.print;

fn readIntUntilDelimiterOrEof(reader: anytype, buf: []u8, delimiter: u8) !i32 {
    const maybe_int = reader.*.readUntilDelimiterOrEof(buf, delimiter) catch |err| return err;
    return std.fmt.parseInt(i32, maybe_int orelse "", 0);
}

fn isOverlap(from1: i32, to1: i32, from2: i32, _: i32) bool {
    return from1 <= from2 and from2 <= to1;
}

pub fn main() !void {
    const file = try std.fs.cwd().openFile(
        "input.txt",
        .{},
    );
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    var in = reader.reader();

    var count: i32 = 0;
    var buf: [4]u8 = undefined;

    while (true) {
        const from1 = readIntUntilDelimiterOrEof(&in, &buf, '-') catch break;
        const to1 = readIntUntilDelimiterOrEof(&in, &buf, ',') catch unreachable;
        const from2 = readIntUntilDelimiterOrEof(&in, &buf, '-') catch unreachable;
        const to2 = readIntUntilDelimiterOrEof(&in, &buf, '\n') catch unreachable;

        if (isOverlap(from1, to1, from2, to2) or isOverlap(from2, to2, from1, to1)) {
            count += 1;
        }
    }

    print("count = {!}\n", .{count});

    std.debug.assert(count == 931);
}
