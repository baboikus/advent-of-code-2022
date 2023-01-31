const std = @import("std");
const print = std.debug.print;

fn readInt(reader: anytype, buf: []u8, delimiter: u8) !i64 {
    const maybe_int = try reader.readUntilDelimiterOrEof(buf, delimiter);
    if (maybe_int == null) return error.EOF;

    return try std.fmt.parseInt(i64, maybe_int.?, 0);
}

const Number = struct {
    name: [4]u8,
    value: i64,
};

const Operation = struct {
    name: [4]u8,
    arg1: [4]u8,
    arg2: [4]u8,
    op: u8,
};

const allocator = std.heap.page_allocator;

const MonkeyTree = struct {
    const Self = @This();

    const Node = union(enum) {
        number: Number,
        operation: Operation,
    };
    const HashMap = std.AutoHashMap([4]u8, *Node);
    table: HashMap = HashMap.init(allocator),

    fn addNode(self: *Self, node: *Node) !void {
        switch (node.*) {
            .number => |n| try self.table.put(n.name, node),
            .operation => |o| try self.table.put(o.name, node),
        }
    }

    fn calcNodeValue(self: Self, name: *const [4]u8) ?i64 {
        if (std.mem.eql(u8, name, &[4]u8{ 'h', 'u', 'm', 'n' })) return null;

        const node = self.table.get(name.*).?;
        switch (node.*) {
            .number => |n| return n.value,
            .operation => |o| {
                const arg1 = self.calcNodeValue(&o.arg1);
                const arg2 = self.calcNodeValue(&o.arg2);
                if (arg1 == null or arg2 == null) return null;
                switch (o.op) {
                    '+' => return arg1.? + arg2.?,
                    '-' => return arg1.? - arg2.?,
                    '*' => return arg1.? * arg2.?,
                    '/' => return @divTrunc(arg1.?, arg2.?),
                    else => unreachable,
                }
            },
        }
    }

    fn findHumnValue(self: *Self, name: *const [4]u8, value: i64) i64 {
        if (std.mem.eql(u8, name, &[4]u8{ 'h', 'u', 'm', 'n' })) return value;

        const node = self.table.get(name.*).?;
        switch (node.*) {
            .number => |n| return n.value,

            .operation => |o| {
                var arg1 = self.calcNodeValue(&o.arg1);
                var arg2 = self.calcNodeValue(&o.arg2);
                switch (o.op) {
                    '+' => if (arg1 == null) {
                        return self.findHumnValue(&o.arg1, value - arg2.?);
                    } else {
                        return self.findHumnValue(&o.arg2, value - arg1.?);
                    },

                    '-' => if (arg1 == null) {
                        return self.findHumnValue(&o.arg1, value + arg2.?);
                    } else {
                        return self.findHumnValue(&o.arg2, arg1.? - value);
                    },

                    '*' => if (arg1 == null) {
                        return self.findHumnValue(&o.arg1, @divTrunc(value, arg2.?));
                    } else {
                        return self.findHumnValue(&o.arg2, @divTrunc(value, arg1.?));
                    },

                    '/' => if (arg1 == null) {
                        return self.findHumnValue(&o.arg1, value * arg2.?);
                    } else {
                        return self.findHumnValue(&o.arg2, @divTrunc(arg1.?, value));
                    },

                    else => unreachable,
                }
            },
        }
    }
};

pub fn main() !void {
    const file = try std.fs.cwd().openFile(
        "input.txt",
        .{},
    );
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    var in = reader.reader();
    var buf: [512]u8 = undefined;

    var tree = MonkeyTree{};
    var nodes: [1024 * 4]MonkeyTree.Node = undefined;
    var nodes_idx: usize = 0;
    while (true) {
        const name: [4]u8 = in.readBytesNoEof(4) catch break;
        try in.skipBytes(": ".len, .{});
        const line = (try in.readUntilDelimiterOrEof(&buf, '\n')).?;
        if (line.len == 11) {
            var arg1: [4]u8 = undefined;
            std.mem.copy(u8, &arg1, line[0..4]);

            const op = line[5];

            var arg2: [4]u8 = undefined;
            std.mem.copy(u8, &arg2, line[7..11]);

            var node = &nodes[nodes_idx];
            node.* = MonkeyTree.Node{ .operation = Operation{ .name = name, .arg1 = arg1, .arg2 = arg2, .op = op } };
            try tree.addNode(node);
        } else {
            const number = try std.fmt.parseInt(i64, line, 0);

            var node = &nodes[nodes_idx];
            node.* = MonkeyTree.Node{ .number = Number{ .name = name, .value = number } };
            try tree.addNode(node);
        }
        nodes_idx += 1;
    }
    //    print("{any}\n", .{tree.calcNodeValue(&[4]u8{ 'p', 'p', 'p', 'w' })});
    //    print("{any}\n", .{tree.calcNodeValue(&[4]u8{ 's', 'j', 'm', 'n' })});
    //    print("{any}\n", .{tree.findHumnValue(&[4]u8{ 'p', 'p', 'p', 'w' }, 150)});

    print("{any}\n", .{tree.calcNodeValue(&[4]u8{ 's', 'b', 't', 'm' })});
    print("{any}\n", .{tree.calcNodeValue(&[4]u8{ 'b', 'm', 'g', 'f' })});
    print("humn = {any}\n", .{tree.findHumnValue(&[4]u8{ 's', 'b', 't', 'm' }, 12725480108701)});
}

test "1" {
    var tree = MonkeyTree{};

    const names = [_][4]u8{ [4]u8{ 'r', 'o', 'o', 't' }, [4]u8{ 'p', 'p', 'p', 'w' }, [4]u8{ 's', 'j', 'm', 'n' } };

    const nodes = [_]MonkeyTree.Node{ MonkeyTree.Node{ .operation = Operation{ .name = names[0], .arg1 = names[1], .arg2 = names[2], .op = '+' } }, MonkeyTree.Node{ .number = Number{ .name = names[1], .value = 42 } }, MonkeyTree.Node{ .number = Number{ .name = names[2], .value = 451 } } };

    try tree.addNode(&nodes[0]);
    try tree.addNode(&nodes[1]);
    try tree.addNode(&nodes[2]);

    {
        var it = tree.table.iterator();
        while (it.next()) |kv| {
            print("{any}\n", .{kv.key_ptr.*});
        }
    }

    try std.testing.expectEqual(@as(usize, 3), tree.table.count());
    try std.testing.expectEqual(true, tree.table.contains(nodes[0].operation.name));

    const rootValue = tree.calcNodeValue(&names[0]);
    try std.testing.expectEqual(@as(i64, 42 + 451), rootValue);
}
