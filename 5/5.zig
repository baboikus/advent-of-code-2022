const std = @import("std");
const print = std.debug.print;

const Array = std.BoundedArray;
const Stack = Array(u8, 64);

fn readIntUntilDelimiterOrEof(comptime T: type, reader: anytype, buf: []u8, delimiter: u8) !T {
    const maybe_int = reader.*.readUntilDelimiterOrEof(buf, delimiter) catch |err| return err;
    return std.fmt.parseInt(T, maybe_int orelse "", 0);
}

pub fn main() !void {
    const file = try std.fs.cwd().openFile(
        "input.txt",
        .{},
    );
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    var in = reader.reader();

    //var top: [9]u8 = "";
    var buf: [4]u8 = undefined;
    var stacks = Array(*Stack, 9).init(0) catch unreachable;
    var stack1 = Stack.fromSlice("DMSZRFWN") catch unreachable;
    stacks.append(&stack1) catch unreachable;
    var stack2 = Stack.fromSlice("WPQGS") catch unreachable;
    stacks.append(&stack2) catch unreachable;
    var stack3 = Stack.fromSlice("WRVQFNJC") catch unreachable;
    stacks.append(&stack3) catch unreachable;
    var stack4 = Stack.fromSlice("FZPCGDL") catch unreachable;
    stacks.append(&stack4) catch unreachable;
    var stack5 = Stack.fromSlice("TPS") catch unreachable;
    stacks.append(&stack5) catch unreachable;
    var stack6 = Stack.fromSlice("HDFWRL") catch unreachable;
    stacks.append(&stack6) catch unreachable;
    var stack7 = Stack.fromSlice("ZNDC") catch unreachable;
    stacks.append(&stack7) catch unreachable;
    var stack8 = Stack.fromSlice("WNRFVSJQ") catch unreachable;
    stacks.append(&stack8) catch unreachable;
    var stack9 = Stack.fromSlice("RMSGZWV") catch unreachable;
    stacks.append(&stack9) catch unreachable;

    var i: usize = 0;
    while (i < 10) : (i += 1) in.skipUntilDelimiterOrEof('\n') catch unreachable;
    while (true) {
        in.skipUntilDelimiterOrEof(' ') catch break;
        const crate_count = readIntUntilDelimiterOrEof(i32, &in, &buf, ' ') catch break;
        in.skipUntilDelimiterOrEof(' ') catch unreachable;
        const stack_index_from = (readIntUntilDelimiterOrEof(usize, &in, &buf, ' ') catch unreachable) - 1;
        in.skipUntilDelimiterOrEof(' ') catch unreachable;
        const stack_index_to = (readIntUntilDelimiterOrEof(usize, &in, &buf, '\n') catch unreachable) - 1;

        print("move {!} from {!} to {!}\n", .{ crate_count, stack_index_from, stack_index_to });

        var stack = Stack.init(0) catch unreachable;
        i = 0;
        while (i < crate_count) : (i += 1) {
            const crate = stacks.get(stack_index_from).pop();
            stack.append(crate) catch unreachable;
        }
        i = 0;
        while (i < crate_count) : (i += 1) {
            stacks.get(stack_index_to).append(stack.pop()) catch unreachable;
        }
    }

    i = 0;
    while (i < 9) : (i += 1) {
        const stack = stacks.get(i);
        print("{c}", .{stack.get(stack.len - 1)});
    }
    print("\n", .{});
    // FWNSHLDNZ
    //    print("count = {!}\n", .{count});

    //    std.debug.assert(count == 931);
}
