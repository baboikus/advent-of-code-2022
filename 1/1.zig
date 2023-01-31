const std = @import("std");
const print = std.debug.print;
const Order = std.math.Order;

fn lessThan(context: void, a: i32, b: i32) Order {
    _ = context;
    return std.math.order(a, b);
}

pub fn main() !void {
    const file = try std.fs.cwd().openFile(
        "input1.txt",
        .{},
    );
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    var in = reader.reader();

    var queue_buf: [32]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&queue_buf);
    var queue = std.PriorityQueue(i32, void, lessThan).init(fba.allocator(), {});
    defer queue.deinit();

    var file_buf: [8]u8 = undefined;
    var current_max: i32 = 0;

    while (try in.readUntilDelimiterOrEof(&file_buf, '\n')) |line| {
        if (std.fmt.parseInt(i32, line, 0)) |number| {
            current_max += number;
        } else |_| {
            if (queue.count() == 3) {
                var e = queue.peek() orelse unreachable;
                if (e < current_max) {
                    try queue.update(e, current_max);
                }
            } else {
                try queue.add(current_max);
            }
            current_max = 0;
        }
    }

    var top_sum: i32 = 0;
    var iter = queue.iterator();
    while (iter.next()) |e| {
        top_sum += e;
    }
    print("top_sum = {!}", .{top_sum});

    std.debug.assert(top_sum == 195625);
}
