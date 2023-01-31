const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

pub fn readInt(comptime T: type, reader: anytype, buf: []u8, delimiter: u8) !T {
    return try std.fmt.parseInt(T, (try reader.readUntilDelimiterOrEof(buf, delimiter)).?, 0);
}
const Array = std.BoundedArray(u16, 64);
const Valve = *const [2]u8;

const MemKey = struct { opened_valves: std.StaticBitSet(16), rest_time: u8, your_valve: u16 = 0, elephants_valve: u16 = 0 };
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Cave = struct {
    const Self = @This();

    valves: Array = undefined,
    edges: [256 * 256]Array = undefined,
    rates: [256 * 256]u32 = undefined,

    conv_table_idx: u16 = 0,
    conv_table: [256 * 256]?u16 = undefined,
    opened_valves: std.StaticBitSet(16) = std.StaticBitSet(16).initEmpty(),
    mem_table: std.AutoHashMap(MemKey, u32) = std.AutoHashMap(MemKey, u32).init(allocator),

    fn init(self: *Self) !void {
        for (self.edges) |*edge| edge.* = try Array.init(0);
        for (self.rates) |*rate| rate.* = 0;
        for (self.conv_table) |*idx| idx.* = null;
    }

    fn addValve(self: *Self, valve: Valve, rate: u32) !void {
        if (rate > 0) {
            assert(self.conv_table_idx < 16);
            self.conv_table[valveIdx(valve)] = self.conv_table_idx;
            self.conv_table_idx += 1;
        }

        self.rates[valveIdx(valve)] = rate;
        try self.valves.append(valveIdx(valve));
    }

    fn isValveOpen(self: Self, valve: u16) bool {
        if (self.conv_table[valve]) |idx| {
            assert(idx < 16);
            return self.opened_valves.isSet(idx);
        } else return true;
    }

    fn openOrCloseValve(self: *Self, valve: u16, is_open: bool) void {
        if (self.conv_table[valve]) |idx| {
            assert(idx < 16);
            if (is_open) {
                self.opened_valves.set(idx);
            } else {
                self.opened_valves.unset(idx);
            }
        }
    }

    fn addConnection(self: *Self, from: Valve, to: Valve) !void {
        try self.edges[valveIdx(from)].append(valveIdx(to));
    }

    fn valveIdx(valve: Valve) u16 {
        return std.mem.readIntNative(u16, valve);
    }

    fn findBestRate(self: *Self, you: u16, elephant: u16, rest_time: u8) !u32 {
        //print("you = {!} elephant = {!} rest_time = {!}\n", .{ you, elephant, rest_time });

        if (rest_time == 0) return 0;

        var mem_key = MemKey{ .opened_valves = self.opened_valves, .rest_time = rest_time, .your_valve = you, .elephants_valve = elephant };
        //  std.mem.copy(bool, &mem_key.opened_valves, &self.opened_valves);
        if (self.mem_table.get(mem_key)) |rate| {
            //    print("!\n", .{});
            return rate;
        }
        std.mem.swap(u16, &mem_key.your_valve, &mem_key.elephants_valve);
        if (self.mem_table.get(mem_key)) |rate| {
            return rate;
        }
        std.mem.swap(u16, &mem_key.your_valve, &mem_key.elephants_valve);

        var best_rate: u32 = 0;

        //   print("1\n", .{});
        if (self.rates[you] > 0 and !self.isValveOpen(you) and self.rates[elephant] > 0 and !self.isValveOpen(elephant) and elephant != you) {
            self.openOrCloseValve(you, true);
            self.openOrCloseValve(elephant, true);
            best_rate = std.math.max(best_rate, (rest_time - 1) * self.rates[you] + (rest_time - 1) * self.rates[elephant] + try self.findBestRate(you, elephant, rest_time - 1));
            self.openOrCloseValve(you, false);
            self.openOrCloseValve(elephant, false);
        }

        //  print("2\n", .{});

        for (self.edges[you].constSlice()) |you_to| {
            for (self.edges[elephant].constSlice()) |elephant_to| {
                //     print("2.1\n", .{});
                best_rate = std.math.max(best_rate, try self.findBestRate(you_to, elephant_to, rest_time - 1));
                //      print("2.2\n", .{});
                if (self.rates[you] > 0 and !self.isValveOpen(you)) {
                    //         print("2.3\n", .{});
                    self.openOrCloseValve(you, true);
                    best_rate = std.math.max(best_rate, (rest_time - 1) * self.rates[you] + try self.findBestRate(you, elephant_to, rest_time - 1));
                    self.openOrCloseValve(you, false);
                    //         print("2.4\n", .{});
                }
            }

            if (self.rates[elephant] > 0 and !self.isValveOpen(elephant) and elephant != you) {
                //       print("2.5\n", .{});
                self.openOrCloseValve(elephant, true);
                best_rate = std.math.max(best_rate, (rest_time - 1) * self.rates[elephant] + try self.findBestRate(you_to, elephant, rest_time - 1));
                self.openOrCloseValve(elephant, false);
                //       print("2.6\n", .{});
            }
            //        print("2.7\n", .{});
        }
        // print("2.8 {!}\n", .{self.mem_table.count()});

        try self.mem_table.put(mem_key, best_rate);

        // print("2.9\n", .{});

        return best_rate;
    }

    // fn findBestRateStacked(self: Self) !u32 {
    //     var stack = std.ArrayList(MemKey).init(allocator);
    //     defer stack.deinit();

    //     var mem_key = MemKey{ .rest_time = rest_time, .your_valve = you, .elephants_valve = elephant };
    //     std.mem.copy(bool, &mem_key.opened_valves, &self.opened_valves);
    //     try stack.append(mem_key);

    //     while(stack.getLastOrNull()) |key| {

    //     }
    // }
};

pub fn main() !void {
    const file = try std.fs.cwd().openFile(
        "input.txt",
        .{},
    );
    defer file.close();

    var cave = Cave{};
    try cave.init();

    var reader = std.io.bufferedReader(file.reader());
    var in = reader.reader();
    var buf: [512]u8 = undefined;
    while (true) {
        in.skipBytes(6, .{}) catch break;
        var valve: [2]u8 = undefined;
        std.mem.copy(u8, &valve, (try in.readUntilDelimiterOrEof(&buf, ' ')).?);
        try in.skipUntilDelimiterOrEof('=');
        const rate = try readInt(u32, in, &buf, ';');

        try cave.addValve(&valve, rate);

        try in.skipBytes(20, .{});
        try in.skipUntilDelimiterOrEof(' ');
        print("{s}, {!} -> ", .{ valve, rate });
        while (true) {
            const conn = try in.readBytesNoEof(2);
            try cave.addConnection(&valve, &conn);
            print("{s}, ", .{conn});
            if ((in.readBytesNoEof(1) catch break)[0] == ',') {
                in.skipBytes(1, .{}) catch break;
            } else {
                break;
            }
        }
        print("\n", .{});
    }

    const best_rate = cave.findBestRate(Cave.valveIdx("AA"), Cave.valveIdx("AA"), 26);
    print("best_rate = {!}\n", .{best_rate});
}
