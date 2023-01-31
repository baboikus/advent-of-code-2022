const std = @import("std");
const print = std.debug.print;

fn readInt(reader: anytype, buf: []u8, delimiter: u8) !i64 {
    const maybe_int = try reader.readUntilDelimiterOrEof(buf, delimiter);
    if (maybe_int == null) return error.EOF;

    return try std.fmt.parseInt(i64, maybe_int.?, 0);
}

pub fn main() !void {
    const file = try std.fs.cwd().openFile(
        "input.txt",
        .{},
    );
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    var in = reader.reader();
    var buf: [512]u8 = undefined;

    var arr: [5000]i64 = undefined;
    var n: usize = 0;
    while (true) {
        const e = readInt(&in, &buf, '\n') catch break;
        arr[n] = e * 811589153;
        n += 1;
    }

    var mix = generateMix(&arr);
    n = 0;
    while (n < 9) : (n += 1) {
        mixIt(&mix);
    }
    const at1000th = nodeAfterZero(&mix, 1000).data;
    const at2000th = nodeAfterZero(&mix, 2000).data;
    const at3000th = nodeAfterZero(&mix, 3000).data;
    print("{!}, {!}, {!}, {!}\n", .{ at1000th, at2000th, at3000th, at1000th + at2000th + at3000th });
}

fn calcIndex(arr: []const i64, nth: usize) usize {
    var i: usize = 0;
    var res = nth;
    for (arr) |v| {
        if (v >= 0) {
            var from = i;
            var to = (i + @intCast(usize, v)) % arr.len;
            if (from > to) std.mem.swap(usize, &from, &to);
            if (res >= from and res <= to) {
                res = ((res + 1) % @intCast(usize, v)) % arr.len;
            }
        } else {}

        i += 1;
    }
    return res;
}

const List = std.TailQueue(i64);
var NODES: [1024 * 8]List.Node = undefined;
var NODES_IDX: usize = 0;

fn printList(list: *const List) void {
    var maybe_node = list.first;
    print("[", .{});
    while (maybe_node) |node| {
        print("{!}, ", .{node.data});
        maybe_node = node.next;
    }
    print("]\n", .{});
}

fn nodeAt(list: *const List, idx: usize) *List.Node {
    var i: usize = 0;
    var node = list.first.?;
    while (i != idx) : (i += 1) {
        node = if (node.next) |next| next else list.first.?;
    }
    return node;
}

fn moveRight(list: *List, node: *List.Node) *List.Node {
    if (node == list.last.?) {
        list.remove(node);
        list.insertAfter(list.first.?, node);
    } else {
        var next = node.next;
        list.remove(node);
        list.insertAfter(next.?, node);
    }
    return node;
}

fn moveLeft(list: *List, node: *List.Node) *List.Node {
    if (node == list.first.?) {
        list.remove(node);
        list.insertBefore(list.last.?, node);
    } else {
        var prev = node.prev;
        list.remove(node);
        list.insertBefore(prev.?, node);
    }
    return node;
}

fn nodeAfterZero(list: *const List, idx: usize) *List.Node {
    var i: usize = 0;
    var node = list.first.?;
    while (node.data != 0) : (node = node.next.?) {}
    while (i < idx % list.len) : (i += 1) {
        node = if (node.next) |next| next else list.first.?;
    }
    return node;
}

fn generateMix(arr: []const i64) List {
    var mix = List{};
    NODES_IDX = 0;
    for (arr) |e| {
        var node = &NODES[NODES_IDX];
        node.data = e;
        mix.append(node);
        NODES_IDX += 1;
    }
    mixIt(&mix);

    return mix;
}

fn mixIt(list: *List) void {
    var i: usize = 0;
    while (i < list.len) : (i += 1) {
        var node = &NODES[i];
        //        var steps = std.math.absCast(node.data);
        var steps = if (node.data > 0) @intCast(usize, node.data) % (list.len - 1) else @intCast(usize, std.math.absCast(node.data)) % (list.len - 1);
        if (node.data > 0) {
            while (steps != 0) : (steps -= 1) {
                node = moveRight(list, node);
            }
        } else if (node.data < 0) {
            while (steps != 0) : (steps -= 1) {
                node = moveLeft(list, node);
            }
        }
        //   print("\n tmp = {!} ", .{tmp.data});

        //  printList(&mix);
    }
}

test "{ 0, -2, 0, 0, 0, 0, 0}" {
    const arr = [_]i64{ 0, -2, 0, 0, 0, 0, 0 };
    const mix = generateMix(&arr);

    printList(&mix);
    try std.testing.expectEqual(@as(i64, -2), nodeAt(&mix, 5).data);
}

test "{ 0, -6, 0, 0, 0, 0, 0}" {
    const arr = [_]i64{ 0, -6, 0, 0, 0, 0, 0 };
    const mix = generateMix(&arr);

    printList(&mix);
    try std.testing.expectEqual(@as(i64, -6), nodeAt(&mix, 1).data);
}

test "{ 0, -12, 0, 0, 0, 0, 0}" {
    const arr = [_]i64{ 0, -12, 0, 0, 0, 0, 0 };
    const mix = generateMix(&arr);

    printList(&mix);
    try std.testing.expectEqual(@as(i64, -12), nodeAt(&mix, 1).data);
}

test "{ 1, 2, -3, 3, -2, 0, 4 }" {
    const arr = [_]i64{ 1, 2, -3, 3, -2, 0, 4 };

    const mix = generateMix(&arr);

    try std.testing.expectEqual(@as(i64, 3), nodeAfterZero(&mix, 1).data);
    try std.testing.expectEqual(@as(i64, -2), nodeAfterZero(&mix, 2).data);
    try std.testing.expectEqual(@as(i64, 1), nodeAfterZero(&mix, 3).data);
    try std.testing.expectEqual(@as(i64, 4), nodeAfterZero(&mix, 1000).data);
    try std.testing.expectEqual(@as(i64, -3), nodeAfterZero(&mix, 2000).data);
    try std.testing.expectEqual(@as(i64, 2), nodeAfterZero(&mix, 3000).data);
}

test "{ 1, 2, -3, 3, -2, 0, 4 } * 811589153" {
    var arr = [_]i64{ 1, 2, -3, 3, -2, 0, 4 };
    for (arr) |*e| {
        e.* *= 811589153;
    }

    var mix = generateMix(&arr);
    //0, -2434767459, 3246356612, -1623178306, 2434767459, 1623178306, 811589153
    try std.testing.expectEqual(@as(i64, 0), nodeAt(&mix, 0).data);
    try std.testing.expectEqual(@as(i64, -2434767459), nodeAt(&mix, 1).data);
    try std.testing.expectEqual(@as(i64, 3246356612), nodeAt(&mix, 2).data);
    try std.testing.expectEqual(@as(i64, -1623178306), nodeAt(&mix, 3).data);
    try std.testing.expectEqual(@as(i64, 2434767459), nodeAt(&mix, 4).data);
    try std.testing.expectEqual(@as(i64, 1623178306), nodeAt(&mix, 5).data);
    try std.testing.expectEqual(@as(i64, 811589153), nodeAt(&mix, 6).data);
    var n: u32 = 0;
    while (n < 9) : (n += 1) {
        mixIt(&mix);
    }

    try std.testing.expectEqual(@as(i64, 811589153), nodeAfterZero(&mix, 1000).data);
    try std.testing.expectEqual(@as(i64, 2434767459), nodeAfterZero(&mix, 2000).data);
    try std.testing.expectEqual(@as(i64, -1623178306), nodeAfterZero(&mix, 3000).data);
}

test "{1, 2}" {
    const arr = [_]i64{ 1, 2 };
    // {2, 1} 1
    // {1, 2} 2
    const mix = generateMix(&arr);

    try std.testing.expectEqual(@as(i64, 1), nodeAt(&mix, 0).data);
    try std.testing.expectEqual(@as(i64, 2), nodeAt(&mix, 1).data);
}

test "{1, 2, 3}" {
    const arr = [_]i64{ 1, 2, 3 };
    // {2, 1, 3} 1
    // {2, 1, 3} 2
    // {2, 3, 1} 3
    const mix = generateMix(&arr);

    try std.testing.expectEqual(@as(i64, 2), nodeAt(&mix, 0).data);
    try std.testing.expectEqual(@as(i64, 3), nodeAt(&mix, 1).data);
    try std.testing.expectEqual(@as(i64, 1), nodeAt(&mix, 2).data);
}

test "{-1, 0, 0, 0}" {
    const arr = [_]i64{ -1, 0, 0, 0 };
    const mix = generateMix(&arr);

    try std.testing.expectEqual(@as(i64, 0), nodeAt(&mix, 0).data);
    try std.testing.expectEqual(@as(i64, 0), nodeAt(&mix, 1).data);
    try std.testing.expectEqual(@as(i64, -1), nodeAt(&mix, 2).data);
    try std.testing.expectEqual(@as(i64, 0), nodeAt(&mix, 3).data);
}

test "{-2, 0, 0, 0}" {
    const arr = [_]i64{ -2, 0, 0, 0 };
    const mix = generateMix(&arr);

    try std.testing.expectEqual(@as(i64, 0), nodeAt(&mix, 0).data);
    try std.testing.expectEqual(@as(i64, -2), nodeAt(&mix, 1).data);
    try std.testing.expectEqual(@as(i64, 0), nodeAt(&mix, 2).data);
    try std.testing.expectEqual(@as(i64, 0), nodeAt(&mix, 3).data);
}

test "{-3, 0, 0, 0}" {
    const arr = [_]i64{ -3, 0, 0, 0 };
    const mix = generateMix(&arr);

    try std.testing.expectEqual(@as(i64, -3), nodeAt(&mix, 0).data);
    try std.testing.expectEqual(@as(i64, 0), nodeAt(&mix, 1).data);
    try std.testing.expectEqual(@as(i64, 0), nodeAt(&mix, 2).data);
    try std.testing.expectEqual(@as(i64, 0), nodeAt(&mix, 3).data);
}

test "{-4, 0, 0, 0}" {
    const arr = [_]i64{ -4, 0, 0, 0 };
    const mix = generateMix(&arr);

    try std.testing.expectEqual(@as(i64, 0), nodeAt(&mix, 0).data);
    try std.testing.expectEqual(@as(i64, 0), nodeAt(&mix, 1).data);
    try std.testing.expectEqual(@as(i64, -4), nodeAt(&mix, 2).data);
    try std.testing.expectEqual(@as(i64, 0), nodeAt(&mix, 3).data);
}

test "{0, 0, 0, 1}" {
    const arr = [_]i64{ 0, 0, 0, 1 };
    const mix = generateMix(&arr);

    try std.testing.expectEqual(@as(i64, 0), nodeAt(&mix, 0).data);
    try std.testing.expectEqual(@as(i64, 1), nodeAt(&mix, 1).data);
    try std.testing.expectEqual(@as(i64, 0), nodeAt(&mix, 2).data);
    try std.testing.expectEqual(@as(i64, 0), nodeAt(&mix, 3).data);
}

test "{3, 0, 0, 0}" {
    const arr = [_]i64{ 3, 0, 0, 0 };
    const mix = generateMix(&arr);

    try std.testing.expectEqual(@as(i64, 3), nodeAt(&mix, 0).data);
    try std.testing.expectEqual(@as(i64, 0), nodeAt(&mix, 1).data);
    try std.testing.expectEqual(@as(i64, 0), nodeAt(&mix, 2).data);
    try std.testing.expectEqual(@as(i64, 0), nodeAt(&mix, 3).data);
}

test "{4, 0, 0, 0}" {
    const arr = [_]i64{ 4, 0, 0, 0 };
    const mix = generateMix(&arr);

    try std.testing.expectEqual(@as(i64, 0), nodeAt(&mix, 0).data);
    try std.testing.expectEqual(@as(i64, 4), nodeAt(&mix, 1).data);
    try std.testing.expectEqual(@as(i64, 0), nodeAt(&mix, 2).data);
    try std.testing.expectEqual(@as(i64, 0), nodeAt(&mix, 3).data);
}

test "{5, 0, 0, 0}" {
    const arr = [_]i64{ 5, 0, 0, 0 };
    const mix = generateMix(&arr);

    try std.testing.expectEqual(@as(i64, 0), nodeAt(&mix, 0).data);
    try std.testing.expectEqual(@as(i64, 0), nodeAt(&mix, 1).data);
    try std.testing.expectEqual(@as(i64, 5), nodeAt(&mix, 2).data);
    try std.testing.expectEqual(@as(i64, 0), nodeAt(&mix, 3).data);
}
