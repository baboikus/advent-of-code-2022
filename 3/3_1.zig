const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    const file = try std.fs.cwd().openFile(
        "input.txt",
        .{},
    );
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    var in = reader.reader();

    var file_buf: [64]u8 = undefined;
    var set = std.StaticBitSet('z' - 'A' + 1).initEmpty();

    var total: i32 = 0;

    while (try in.readUntilDelimiterOrEof(&file_buf, '\n')) |sack| {
        set.toggleSet(set);
        var i: u32 = 0;
        while (i < sack.len / 2) : (i += 1) set.set(sack[i] - 'A');
        while (i < sack.len) : (i += 1) {
            if (set.isSet(sack[i] - 'A')) {
                const item = sack[i];
                total += switch (item) {
                    'A'...'Z' => item - 'A' + 27,
                    'a'...'z' => item - 'a' + 1,
                    else => unreachable,
                };
                break;
            }
        }
    }

    print("total = {!}", .{total});

    std.debug.assert(total == 7597);
}
