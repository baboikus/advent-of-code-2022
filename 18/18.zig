const std = @import("std");
const print = std.debug.print;

fn readInt(reader: anytype, buf: []u8, delimiter: u8) !u32 {
    const maybe_int = try reader.readUntilDelimiterOrEof(buf, delimiter);
    if (maybe_int == null) return error.EOF;

    return try std.fmt.parseInt(u32, maybe_int.?, 0);
}

const LIMIT = 32;

const Cube = struct { x: u32, y: u32, z: u32 };

const LavaTree = struct {
    const Self = @This();
    const Q = std.TailQueue(Cube);

    lava: [LIMIT][LIMIT][LIMIT]bool = undefined,
    visited: [LIMIT][LIMIT][LIMIT]bool = undefined,

    node_idx: usize = 0,
    nodes: [LIMIT * LIMIT * LIMIT * 6]Q.Node = undefined,
    queue: Q = Q{},

    area_counter: u32 = 0,

    fn addForFutureVisit(self: *Self, x: u32, y: u32, z: u32) void {
        if (self.visited[x][y][z]) return;

        self.nodes[self.node_idx].data = Cube{ .x = x, .y = y, .z = z };
        self.queue.append(&self.nodes[self.node_idx]);
        self.node_idx += 1;
    }

    fn visit(self: *Self, x: u32, y: u32, z: u32) void {
        if (self.visited[x][y][z]) return;

        if (!self.lava[x][y][z]) {
            self.visited[x][y][z] = true;
            if (x > 0) self.addForFutureVisit(x - 1, y, z);
            if (x < LIMIT - 1) self.addForFutureVisit(x + 1, y, z);
            if (y > 0) self.addForFutureVisit(x, y - 1, z);
            if (y < LIMIT - 1) self.addForFutureVisit(x, y + 1, z);
            if (z > 0) self.addForFutureVisit(x, y, z - 1);
            if (z < LIMIT - 1) self.addForFutureVisit(x, y, z + 1);
        } else {
            self.area_counter += 1;
        }
    }

    fn countArea(self: *Self) u32 {
        self.area_counter = 0;
        self.addForFutureVisit(0, 0, 0);

        while (self.queue.popFirst()) |node| {
            const cube = node.data;
            self.visit(cube.x, cube.y, cube.z);
        }

        return self.area_counter;
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

    var lava_tree = LavaTree{};

    while (true) {
        const x = readInt(in, &buf, ',') catch break;
        const y = try readInt(in, &buf, ',');
        const z = try readInt(in, &buf, '\n');

        lava_tree.lava[x + 1][y + 1][z + 1] = true;
    }

    const area = lava_tree.countArea();
    print("area = {!}\n", .{area});
}
