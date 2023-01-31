const std = @import("std");
const print = std.debug.print;

fn drawPixel(comptime height: i32, comptime width: i32, screen: *[height][width]u8, cycle: i32, x: i32) void {
    const y = @divFloor(cycle - 1, width);
    const mx = @mod(cycle - 1, width);
    screen.*[@intCast(usize, y)][@intCast(usize, mx)] =
        if (std.math.absInt(x - mx) catch 0 <= 1) '#' else '.';
}

pub fn main() !void {
    const file = try std.fs.cwd().openFile(
        "input.txt",
        .{},
    );
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    var in = reader.reader();
    var buf: [16]u8 = undefined;

    var b_index: usize = 0;
    const breakpoints = [_]i32{ 20, 60, 100, 140, 180, 220 };

    var x: i32 = 1;
    var cycle: i32 = 1;
    var total_power: i32 = 0;
    var screen: [6][40]u8 = undefined;

    while (try in.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (b_index < breakpoints.len and cycle == breakpoints[b_index]) {
            //   print("x = {!}, ", .{x});
            total_power += x * breakpoints[b_index];
            b_index += 1;
        }
        drawPixel(6, 40, &screen, cycle, x);
        switch (line[0]) {
            'n' => cycle += 1,
            'a' => {
                cycle += 1;
                if (b_index < breakpoints.len and cycle == breakpoints[b_index]) {
                    //   print("x = {!}, ", .{x});
                    total_power += x * breakpoints[b_index];
                    b_index += 1;
                }
                drawPixel(6, 40, &screen, cycle, x);
                cycle += 1;

                x += std.fmt.parseInt(i32, line[5..], 10) catch unreachable;
            },
            else => unreachable,
        }
    }

    print("total_power = {!}\n", .{total_power});

    for (screen) |row| print("{s}\n", .{row});
}
