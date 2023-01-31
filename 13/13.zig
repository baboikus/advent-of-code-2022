const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = arena.allocator();

// List = [Elems] | []
// Elems = Elem | Elem, Elems
// Elem = int | List

const Elem = union(enum) {
    int: i32,
    list: *const List,
};

const Elems = struct {
    elem: Elem,
    rest: ?*const Elems = null,
};

const List = union(enum) { empty: void, elems: Elems };

fn compareElems(elems1: Elems, elems2: Elems) i4 {
    var res: i4 = 0;
    switch (elems1.elem) {
        Elem.int => |int1| {
            switch (elems2.elem) {
                Elem.int => |int2| {
                    //     print("compareElems: {!} and {!}\n", .{ int1, int2 });
                    if (int1 > int2) return -1;
                    if (int1 < int2) return 1;
                },
                Elem.list => |list2| {
                    res = compareLists(List{ .elems = Elems{ .elem = elems1.elem } }, list2.*);
                },
            }
        },
        Elem.list => |list1| {
            switch (elems2.elem) {
                Elem.int => {
                    res = compareLists(list1.*, List{ .elems = Elems{ .elem = elems2.elem } });
                },
                Elem.list => |list2| {
                    res = compareLists(list1.*, list2.*);
                },
            }
        },
    }
    if (res != 0) return res;

    if (elems1.rest) |rest1| {
        if (elems2.rest) |rest2| {
            return compareElems(rest1.*, rest2.*);
        } else {
            //    print("list2 ended", .{});
            return -1;
        }
    } else {
        if (elems2.rest != null) {
            //   print("list1 ended", .{});
            return 1;
        } else {
            //    print("both lists ended", .{});
            return 0;
        }
    }
}

fn compareLists(l1: List, l2: List) i4 {
    // print("compareLists: ", .{});
    // printList(l1);
    // print(" and ", .{});
    // printList(l2);
    // print("\n", .{});

    switch (l1) {
        List.empty => switch (l2) {
            List.empty => return 0,
            List.elems => return 1,
        },
        List.elems => |elems1| {
            switch (l2) {
                List.empty => return -1,
                List.elems => |elems2| return compareElems(elems1, elems2),
            }
        },
    }
}

fn compare(str1: []const u8, str2: []const u8) bool {
    const res1 = parseList(str1, 0);
    assert(res1.idx == str1.len);
    const res2 = parseList(str2, 0);
    assert(res2.idx == str2.len);

    return compareLists(res1.list, res2.list) == 1;
}

const ParseListRes = struct {
    list: List,
    idx: usize,
};

const ParseElemsRes = struct {
    elems: Elems,
    idx: usize,
};

const ParseIntRes = struct {
    int: i32,
    idx: usize,
};

fn parseInt(str: []const u8, from: usize) ParseIntRes {
    //  print("parseInt {!}, rest = {s}\n", .{ from, str[from..] });
    var n: usize = from;
    while (str[n] >= '0' and str[n] <= '9') : (n += 1) {}
    return ParseIntRes{ .int = std.fmt.parseInt(i32, str[from..n], 10) catch -1, .idx = n };
}

fn parseElems(str: []const u8, from: usize) ParseElemsRes {
    //  print("parseElems {!}, rest = {s}\n", .{ from, str[from..] });
    if (str[from] == '[') {
        const res = parseList(str, from);
        var list_ptr = allocator.create(List) catch unreachable;
        list_ptr.* = res.list;
        if (str[res.idx] == ',') {
            const rest_res = parseElems(str, res.idx + 1);
            var rest_ptr = allocator.create(Elems) catch unreachable;
            rest_ptr.* = rest_res.elems;
            return ParseElemsRes{ .elems = Elems{ .elem = Elem{ .list = list_ptr }, .rest = rest_ptr }, .idx = rest_res.idx };
        } else {
            return ParseElemsRes{ .elems = Elems{ .elem = Elem{ .list = list_ptr }, .rest = null }, .idx = res.idx + 1 };
        }
    } else if (str[from] >= '0' and str[from] <= '9') {
        const res = parseInt(str, from);
        if (str[res.idx] == ',') {
            const rest_res = parseElems(str, res.idx + 1);
            var rest_ptr = allocator.create(Elems) catch unreachable;
            rest_ptr.* = rest_res.elems;
            return ParseElemsRes{ .elems = Elems{ .elem = Elem{ .int = res.int }, .rest = rest_ptr }, .idx = rest_res.idx };
        } else {
            return ParseElemsRes{ .elems = Elems{ .elem = Elem{ .int = res.int }, .rest = null }, .idx = res.idx + 1 };
        }
    } else {
        unreachable;
    }
}

fn parseList(str: []const u8, from: usize) ParseListRes {
    //   print("parseList {!}, rest = {s}\n", .{ from, str[from..] });

    assert(str[from] == '[');

    if (str[from + 1] == ']') return ParseListRes{ .list = List{ .empty = {} }, .idx = from + 2 };

    const res = parseElems(str, from + 1);
    return ParseListRes{ .list = List{ .elems = res.elems }, .idx = res.idx };
}

fn printElems(elems: Elems) void {
    switch (elems.elem) {
        Elem.int => |int| print("{!}", .{int}),
        Elem.list => |list| printList(list.*),
    }

    if (elems.rest) |rest| {
        print(", ", .{});
        printElems(rest.*);
    }
}

fn printList(l: List) void {
    print("[", .{});
    switch (l) {
        List.empty => {},
        List.elems => |elems| printElems(elems),
    }
    print("]", .{});
}

fn lessThan(context: void, l1: List, l2: List) bool {
    _ = context;
    return compareLists(l1, l2) == 1;
}

pub fn main() !void {
    const file = try std.fs.cwd().openFile(
        "input.txt",
        .{},
    );
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    var in = reader.reader();
    var buf: [2048]u8 = undefined;

    var array_of_lists: [151 * 2]List = undefined;

    var pair_idx: u32 = 1;
    var correct_pair_idx_sum: u32 = 0;
    while (true) : (pair_idx += 1) {
        var str = (in.readUntilDelimiterOrEof(&buf, '\n') catch break) orelse break;
        const res1 = parseList(str, 0);
        assert(res1.idx == str.len);

        str = (in.readUntilDelimiterOrEof(&buf, '\n') catch break) orelse break;
        const res2 = parseList(str, 0);
        assert(res2.idx == str.len);

        array_of_lists[2 * (pair_idx - 1)] = res1.list;
        array_of_lists[2 * (pair_idx - 1) + 1] = res2.list;

        if (compareLists(res1.list, res2.list) == 1) {
            correct_pair_idx_sum += pair_idx;
        }

        in.skipUntilDelimiterOrEof('\n') catch break;
    }

    const devider1 = parseList("[[2]]", 0).list;
    const devider2 = parseList("[[6]]", 0).list;
    array_of_lists[2 * (pair_idx - 1)] = devider1;
    array_of_lists[2 * (pair_idx - 1) + 1] = devider2;

    std.sort.sort(List, &array_of_lists, {}, lessThan);

    var decoder_key: usize = 1;
    for (array_of_lists) |list, idx| {
        if (compareLists(list, devider1) == 0) decoder_key *= (idx + 1);
        if (compareLists(list, devider2) == 0) decoder_key *= (idx + 1);
        print("{!} => ", .{idx + 1});
        printList(list);
        print("\n", .{});
    }

    print("correct_pair_idx_sum = {!} pair_idx = {!} decoder_key = {!}\n", .{ correct_pair_idx_sum, pair_idx, decoder_key });
}

test "1" {
    const res = parseList("[1,1,3,1,1]", 0);
    print("res.idx = {!}\n", .{res.idx});
    printList(res.list);
    try std.testing.expectEqual(true, compare("[1,1,3,1,1]", "[1,1,5,1,1]"));
}

test "2" {
    const res = parseList("[[1],[2,3,4]]", 0);
    print("res.idx = {!}\n", .{res.idx});
    printList(res.list);
    try std.testing.expectEqual(true, compare("[[1],[2,3,4]]", "[[1],4]"));
}

test "3" {
    try std.testing.expectEqual(false, compare("[9]", "[[8,7,6]]"));
}

test "4" {
    try std.testing.expectEqual(true, compare("[[4,4],4,4]", "[[4,4],4,4,4]"));
}

test "5" {
    try std.testing.expectEqual(false, compare("[7,7,7,7]", "[7,7,7]"));
}
test "6" {
    try std.testing.expectEqual(true, compare("[]", "[3]"));
}

test "7" {
    try std.testing.expectEqual(false, compare("[[[]]]", "[[]]"));
}

test "8" {
    try std.testing.expectEqual(false, compare("[1,[2,[3,[4,[5,6,7]]]],8,9]", "[1,[2,[3,[4,[5,6,0]]]],8,9]"));
}

test "real" {
    const res = parseList("[[[[3,0],[0],3],8,4],[[[5,1,1,8],[10,6,1,0],[8,1],7,2],[]],[2,[10]],[[10,7]],[6,5,8,10]]", 0);
    print("res.idx = {!}\n", .{res.idx});
    printList(res.list);
}
