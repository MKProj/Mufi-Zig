const std = @import("std");
const ValueArray = @import("value.zig").ValueArray;
const Value = @import("value.zig").Value;
const mem = @import("mem.zig");
pub const array = std.ArrayList(u8);
const line_array = std.ArrayList(u32);
const allocator = std.mem.Allocator;

pub const OpCode = enum(u8) {
    Constant,
    Add,
    Subtract,
    Multiply,
    Divide,
    Negate,
    Return,
};

pub const Chunk = struct {
    code: array,
    count: usize,
    capacity: usize,
    constants: ValueArray,
    lines: line_array,

    pub fn init(alloc: allocator) Chunk {
        return Chunk{ .code = array.init(alloc), .count = 0, .capacity = 0, .constants = ValueArray.init(alloc), .lines = line_array.init(alloc) };
    }
    pub fn write(self: *Chunk, byte: OpCode, line: u32) !void {
        try self.code.append(@enumToInt(byte));
        try self.lines.append(line);
        self.count += 1;
    }
    pub fn addConstant(self: *Chunk, value: Value) !usize {
        try self.constants.write(value);
        return self.constants.count - 1;
    }
    pub fn deinit(self: *Chunk) void {
        // free the array
        self.code.deinit();
        self.constants.deinit();
        self.lines.deinit();
    }
};
