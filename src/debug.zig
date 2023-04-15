const std = @import("std");
const chunk = @import("chunk.zig");
const printValue = @import("value.zig").printValue;

const op = chunk.OpCode;
const stdout = std.io.getStdOut().writer();

pub fn disassembleChunk(c: chunk.Chunk, name: []const u8) !void {
    try stdout.print("== {s} ==\n", .{name});
    var offset: usize = 0;
    while (offset < c.count) {
        offset = try disassembleInstruction(c, offset);
    }
}

pub fn disassembleInstruction(c: chunk.Chunk, offset: usize) !usize {
    try stdout.print("{:0>4} ", .{offset});
    if ((offset > 0) and (c.lines.items[offset] == c.lines.items[offset - 1])) {
        try stdout.print("   | ", .{});
    } else {
        try stdout.print("{:>4} ", .{c.lines.items[offset]});
    }
    const instruction = c.code.items[offset];
    const inst = @intToEnum(op, instruction);
    switch (inst) {
        op.Return => return try simpleInstruction("OP_RETURN", offset),
        op.Constant => return try constantInstruction("OP_CONSTANT", c, offset),
        op.Negate => return try simpleInstruction("OP_NEGATE", offset),
        op.Add => return try simpleInstruction("OP_ADD", offset),
        op.Subtract => return try simpleInstruction("OP_SUBTRACT", offset),
        op.Multiply => return try simpleInstruction("OP_MULTIPLY", offset),
        op.Divide => return try simpleInstruction("OP_DIVIDE", offset),
    }
}

fn simpleInstruction(name: []const u8, offset: usize) !usize {
    try stdout.print("{s}\n", .{name});
    return offset + 1;
}

fn constantInstruction(name: []const u8, c: chunk.Chunk, offset: usize) !usize {
    const constant = c.code.items[offset];
    try stdout.print("{s} {:0>4}", .{ name, offset });
    try printValue(c.constants.values.items[constant]);
    try stdout.print("'\n", .{});
    return offset + 2;
}
