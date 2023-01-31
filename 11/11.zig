const std = @import("std");
const print = std.debug.print;

const Worry = u64;
const Items = std.BoundedArray(Worry, 32);

const Monkey = struct {
    items: Items,
    counter: u32 = 0,
    increaseWorry: *const fn (worry: Worry) Worry,
    testItem: *const fn (worry: Worry) usize,
};

// TEST DATA
// // MONKEY 0
// fn monkey0IncreaseWorry(worry: Worry) Worry {
//     return worry * 19;
// }
// fn monkey0TestItem(worry: Worry) usize {
//     return if (worry % 23 == 0) 2 else 3;
// }

// // MONKEY 1
// fn monkey1IncreaseWorry(worry: Worry) Worry {
//     return worry + 6;
// }
// fn monkey1TestItem(worry: Worry) usize {
//     return if (worry % 19 == 0) 2 else 0;
// }

// // MONKEY 2
// fn monkey2IncreaseWorry(worry: Worry) Worry {
//     return worry * worry;
// }
// fn monkey2TestItem(worry: Worry) usize {
//     return if (worry % 13 == 0) 1 else 3;
// }

// // MONKEY 3
// fn monkey3IncreaseWorry(worry: Worry) Worry {
//     return worry + 3;
// }
// fn monkey3TestItem(worry: Worry) usize {
//     return if (worry % 17 == 0) 0 else 1;
// }

// MONKEY 0
fn monkey0IncreaseWorry(worry: Worry) Worry {
    return worry * 11;
}
fn monkey0TestItem(worry: Worry) usize {
    return if (worry % 13 == 0) 1 else 7;
}

// MONKEY 1
fn monkey1IncreaseWorry(worry: Worry) Worry {
    return worry + 1;
}
fn monkey1TestItem(worry: Worry) usize {
    return if (worry % 7 == 0) 3 else 6;
}

// MONKEY 2
fn monkey2IncreaseWorry(worry: Worry) Worry {
    return worry * worry;
}
fn monkey2TestItem(worry: Worry) usize {
    return if (worry % 3 == 0) 5 else 4;
}

// MONKEY 3
fn monkey3IncreaseWorry(worry: Worry) Worry {
    return worry + 2;
}
fn monkey3TestItem(worry: Worry) usize {
    return if (worry % 19 == 0) 2 else 6;
}

// MONKEY 4
fn monkey4IncreaseWorry(worry: Worry) Worry {
    return worry + 6;
}
fn monkey4TestItem(worry: Worry) usize {
    return if (worry % 5 == 0) 0 else 5;
}

// MONKEY 5
fn monkey5IncreaseWorry(worry: Worry) Worry {
    return worry + 7;
}
fn monkey5TestItem(worry: Worry) usize {
    return if (worry % 2 == 0) 7 else 0;
}

// MONKEY 6
fn monkey6IncreaseWorry(worry: Worry) Worry {
    return worry * 7;
}
fn monkey6TestItem(worry: Worry) usize {
    return if (worry % 11 == 0) 2 else 4;
}

// MONKEY 7
fn monkey7IncreaseWorry(worry: Worry) Worry {
    return worry + 8;
}
fn monkey7TestItem(worry: Worry) usize {
    return if (worry % 17 == 0) 1 else 3;
}

fn model() void {
    // var monkeys = [_]Monkey{ Monkey{
    //     .items = Items.fromSlice(&[_]Worry{ 79, 98 }) catch unreachable,
    //     .increaseWorry = monkey0IncreaseWorry,
    //     .testItem = monkey0TestItem,
    // }, Monkey{
    //     .items = Items.fromSlice(&[_]Worry{ 54, 65, 75, 74 }) catch unreachable,
    //     .increaseWorry = monkey1IncreaseWorry,
    //     .testItem = monkey1TestItem,
    // }, Monkey{
    //     .items = Items.fromSlice(&[_]Worry{ 79, 60, 97 }) catch unreachable,
    //     .increaseWorry = monkey2IncreaseWorry,
    //     .testItem = monkey2TestItem,
    // }, Monkey{
    //     .items = Items.fromSlice(&[_]Worry{74}) catch unreachable,
    //     .increaseWorry = monkey3IncreaseWorry,
    //     .testItem = monkey3TestItem,
    // } };

    var monkeys = [_]Monkey{
        Monkey{
            .items = Items.fromSlice(&[_]Worry{ 71, 56, 50, 73 }) catch unreachable,
            .increaseWorry = monkey0IncreaseWorry,
            .testItem = monkey0TestItem,
        },
        Monkey{
            .items = Items.fromSlice(&[_]Worry{ 70, 89, 82 }) catch unreachable,
            .increaseWorry = monkey1IncreaseWorry,
            .testItem = monkey1TestItem,
        },
        Monkey{
            .items = Items.fromSlice(&[_]Worry{ 52, 95 }) catch unreachable,
            .increaseWorry = monkey2IncreaseWorry,
            .testItem = monkey2TestItem,
        },
        Monkey{
            .items = Items.fromSlice(&[_]Worry{ 94, 64, 69, 87, 70 }) catch unreachable,
            .increaseWorry = monkey3IncreaseWorry,
            .testItem = monkey3TestItem,
        },
        Monkey{
            .items = Items.fromSlice(&[_]Worry{ 98, 72, 98, 53, 97, 51 }) catch unreachable,
            .increaseWorry = monkey4IncreaseWorry,
            .testItem = monkey4TestItem,
        },
        Monkey{
            .items = Items.fromSlice(&[_]Worry{79}) catch unreachable,
            .increaseWorry = monkey5IncreaseWorry,
            .testItem = monkey5TestItem,
        },
        Monkey{
            .items = Items.fromSlice(&[_]Worry{ 77, 55, 63, 93, 66, 90, 88, 71 }) catch unreachable,
            .increaseWorry = monkey6IncreaseWorry,
            .testItem = monkey6TestItem,
        },
        Monkey{
            .items = Items.fromSlice(&[_]Worry{ 54, 97, 87, 70, 59, 82, 59 }) catch unreachable,
            .increaseWorry = monkey7IncreaseWorry,
            .testItem = monkey7TestItem,
        },
    };

    var round: u32 = 0;
    while (round < 10000) : (round += 1) {
        var i: u32 = 0;
        while (i < monkeys.len) : (i += 1) {
            var monkey = &monkeys[i];
            while (monkey.items.popOrNull()) |old_worry| {
                monkey.counter += 1;
                const new_worry = monkey.increaseWorry(old_worry) % (13 * 7 * 3 * 19 * 5 * 2 * 11 * 17);
                monkeys[monkey.testItem(new_worry)].items.append(new_worry) catch unreachable;
            }
        }
    }

    for (monkeys) |monkey| {
        print("{!}\n", .{monkey.counter});
    }

    std.debug.assert(monkeys[0].counter == 83587);
}

pub fn main() !void {
    while (true) {
        model();
    }
}
