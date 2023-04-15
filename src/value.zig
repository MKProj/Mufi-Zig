const std = @import("std");
const mem = @import("mem.zig");
const allocator = std.mem.Allocator;
const array = std.ArrayList(Value);
const stdout = std.io.getStdOut().writer();

pub const Value = f64;

pub fn printValue(value: Value) !void {
    try stdout.print("{:0>1}", .{value});
}

pub const ValueArray = struct {
    capacity: usize,
    count: usize,
    values: array,

    pub fn init(alloc: allocator) ValueArray {
        return ValueArray{ .capacity = 0, .count = 0, .values = array.init(alloc) };
    }
    pub fn write(self: *ValueArray, value: Value) !void {
        try self.values.append(value);
        self.count += 1;
    }
    pub fn deinit(self: ValueArray) void {
        self.values.deinit();
    }
};
