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
    var set1 = std.StaticBitSet('z' - 'A' + 1).initEmpty();
    var set2 = std.StaticBitSet('z' - 'A' + 1).initEmpty();
    var p_set1 = &set1;
    var p_set2 = &set2;

    var total: i32 = 0;
    var counter: u8 = 0;
    while (try in.readUntilDelimiterOrEof(&file_buf, '\n')) |sack| : (counter = (counter + 1) % 3) {
        var i: u8 = 0;
        if (counter == 0) {
            p_set1.*.toggleSet(p_set1.*);
            while (i < sack.len) : (i += 1) p_set1.*.set(sack[i] - 'A');
        } else {
            while (i < sack.len) : (i += 1) {
                if (p_set1.*.isSet(sack[i] - 'A')) p_set2.*.set(sack[i] - 'A');
            }
            std.mem.swap(@TypeOf(p_set1.*), p_set1, p_set2);
            p_set2.*.toggleSet(p_set2.*);
        }

        i = 0;
        if (counter == 2) {
            const item: u8 = @truncate(u8, p_set1.*.findFirstSet() orelse unreachable) + 'A';
            total += switch (item) {
                'A'...'Z' => item - 'A' + 27,
                'a'...'z' => item - 'a' + 1,
                else => unreachable,
            };
        }
    }

    print("total = {!}", .{total});

    std.debug.assert(total == 2607);
}
