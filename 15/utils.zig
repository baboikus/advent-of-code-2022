const std = @import("std");

pub fn readInt(comptime T: type, reader: anytype, buf: []u8, delimiter: u8) !T {
    return try std.fmt.parseInt(T, (try reader.readUntilDelimiterOrEof(buf, delimiter)).?, 0);
}
