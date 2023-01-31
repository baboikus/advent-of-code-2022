const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

const INPUT_FILE = "input.txt";

const TreeNode = struct {
    const Self = @This();
    size: usize = 0,
};

pub fn main() !void {
    const file = try std.fs.cwd().openFile(
        INPUT_FILE,
        .{},
    );
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    var in = reader.reader();
    var buf: [1024]u8 = undefined;

    var dirs_sizes: [256]usize = undefined;
    var dirs_sizes_idx: usize = 0;
    std.mem.set(usize, &dirs_sizes, 0);

    var stack: [32]TreeNode = undefined;
    var stack_idx: usize = 0;

    while (try in.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        print("{s}\n", .{line});
        if (std.mem.startsWith(u8, line, "$ cd ")) {
            if (std.mem.startsWith(u8, line[5..], "..")) {
                const size = stack[stack_idx].size;

                dirs_sizes[dirs_sizes_idx] = size;
                dirs_sizes_idx += 1;

                stack_idx -= 1;
                stack[stack_idx].size += size;
            } else {
                stack_idx += 1;
                stack[stack_idx].size = 0;
            }
        } else if (std.mem.startsWith(u8, line, "$ ls")) {} else if (std.mem.startsWith(u8, line, "dir ")) {} else {
            const to = std.mem.indexOf(u8, line, " ") orelse unreachable;
            const size = try std.fmt.parseInt(usize, line[0..to], 10);
            stack[stack_idx].size += size;
        }
    }

    while (stack_idx > 1) {
        const size = stack[stack_idx].size;

        dirs_sizes[dirs_sizes_idx] = size;
        dirs_sizes_idx += 1;

        stack_idx -= 1;
        stack[stack_idx].size += size;
    }

    const total_size = stack[1].size;
    print("total_size = {!}\n", .{total_size});

    const needed_to_free: usize = @as(usize, 30000000) - (@as(usize, 70000000) - total_size);
    var i: usize = 0;
    var min_size: usize = 0;
    var min_diff: usize = 70000000;
    while (i < dirs_sizes_idx) : (i += 1) {
        if (dirs_sizes[i] >= needed_to_free and dirs_sizes[i] - needed_to_free < min_diff) {
            min_size = dirs_sizes[i];
            min_diff = dirs_sizes[i] - needed_to_free;
        }
    }

    print("needed_to_free = {!} min_size = {!}\n", .{ needed_to_free, min_size });
}
