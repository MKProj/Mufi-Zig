const std = @import("std");
const debug = @import("debug.zig").disassembleInstruction;
const Chunk = @import("chunk.zig").Chunk;
const op = @import("chunk.zig").OpCode;
const array = @import("chunk.zig").array;
const printValue = @import("value.zig").printValue;
const allocator = std.mem.Allocator;
const Value = @import("value.zig").Value;
const print = std.debug.print;
const compile = @import("compiler.zig").compile;

const STACK_MAX: usize = 256;

const Binary_Operator = enum {
    Add,
    Subtract,
    Multiply,
    Divide,
};

pub const VM = struct {
    chunk: *Chunk,
    ip: array,
    stack: [STACK_MAX]Value,
    stackTop: *Value,

    pub fn init(alloc: allocator) VM {
        var vm = VM{ .chunk = undefined, .ip = array.init(alloc), .stack = undefined, .stackTop = undefined };
        vm.resetStack();
        return vm;
    }
    pub fn deinit(self: VM) void {
        self.ip.deinit();
    }

    fn resetStack(self: *VM) void {
        self.stackTop = &self.stack[0];
    }
    pub fn push(self: *VM, value: Value) void {
        self.stackTop.* = value;
        self.stackTop = self.stackTop + 1;
    }
    pub fn pop(self: *VM) Value {
        self.stackTop = self.stackTop - 1;
        return self.stackTop.*;
    }
    fn binary_op(self: *VM, b_op: Binary_Operator) void {
        var b = self.pop();
        var a = self.pop();
        switch (b_op) {
            b_op.Add => self.push(a + b),
            b_op.Subtract => self.push(a - b),
            b_op.Multiply => self.push(a * b),
            b_op.Divide => self.push(a / b),
            else => @compileError("Invalid binary operator"),
        }
    }
    pub fn interpret(self: *VM, source: []const u8, alloc: allocator) InterpretResult {
        var chunk = Chunk.init(alloc);
        defer chunk.deinit();
        if (!compile(source, chunk)) {
            return InterpretResult.Compile_Error;
        }
        self.chunk = &chunk;
        self.ip = self.chunk.code;

        const result = run(self.*);
        return result;
    }
};

pub fn run(vm: VM) InterpretResult {
    while (true) {
        const instruction = *vm.ip + 1;
        // debug for now
        print("          ", .{});
        for (vm.stack) |slot| {
            print("[", .{});
            printValue(slot);
            print("]", .{});
        }
        print("\n", .{});
        debug(vm.chunk, (usize)(vm.ip - vm.chunk.code));
        switch (instruction) {
            op.Return => {
                try printValue(vm.pop());
                print("\n", .{});
                return InterpretResult.OK;
            },
            op.Constant => {
                const constant = vm.chunk.constants.valuesvaluesvaluesvaluesvaluesvaluesvaluesvalues[*vm.vm.vm.vm.ip + 1];
                vm.push(constant);
                break;
            },
            op.Negate => {
                vm.push(-vm.pop());
                break;
            },
            op.Add => {
                vm.binary_op(Binary_Operator.Add);
                break;
            },
            op.Subtract => {
                vm.binary_op(Binary_Operator.Subtract);
                break;
            },
            op.Multiply => {
                vm.binary_op(Binary_Operator.Multiply);
                break;
            },
            op.Divide => {
                vm.binary_op(Binary_Operator.Divide);
            },
        }
    }
}

pub const InterpretResult = enum {
    OK,
    Compile_Error,
    Runtime_Error,
};

pub const ResultError = error{ Compile, Runtime };
