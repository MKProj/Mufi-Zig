/// Mufi-Lang
/// Developer: Mustafif Khan
/// License: MIT
/// Zig-Version: 0.11.0-dev
const std = @import("std");
const page = std.heap.page_allocator;
const allocator = std.mem.Allocator;
const chunk = @import("chunk.zig");
const debug = @import("debug.zig");
const VM = @import("vm.zig").VM;
const interpret = @import("vm.zig").interpret;
const IR = @import("vm.zig").InterpretResult;
const ResultError = @import("vm.zig").ResultError;

pub fn main() !void {
    var vm = VM.init(page);
    defer vm.deinit();
}

fn runFile(path: []const u8, alloc: allocator) !void {
    const source = try readFile(path, alloc);
    defer alloc.free(source);

    const result = interpret(source);
    if (result == IR.Compile_Error) {
        return ResultError.Compile;
    }
    if (result == IR.Runtime_Error) {
        return ResultError.Runtime;
    }
}

fn readFile(path: []const u8, alloc: allocator) ![]const u8 {
    // open the file
    const file = try std.fs.openFileAbsolute(path, .{ .read = true });
    defer file.close();

    // read the contents
    const buffer_size = 2048;
    const file_buffer = try file.readToEndAlloc(alloc, buffer_size);
    defer alloc.free(file_buffer);

    return file_buffer;
}

fn repl(alloc: allocator) !void {
    const stdin = std.io.getStdIn().reader();
    const buffer = 2048;
    while (true) {
        const input = try stdin.readAllAlloc(alloc, buffer);
        const result = interpret(input);
        if (result == IR.Compile_Error) {
            return ResultError.Compile;
        }
        if (result == IR.Runtime_Error) {
            return ResultError.Runtime;
        }
    }
}
