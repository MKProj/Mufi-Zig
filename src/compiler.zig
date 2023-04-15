const Scanner = @import("scanner.zig").Scanner;
const print = @import("std").debug.print;
const TokenType = @import("scanner.zig").TokenType;
const Token = @import("scanner.zig").Token;
const Chunk = @import("chunk.zig").Chunk;
const op = @import("chunk.zig").OpCode;
const Value = @import("value.zig").Value;

pub var compilingChunk: *Chunk = null;

fn currentChunk() *Chunk {
    return compilingChunk;
}

pub fn compile(source: []const u8, chunk: *Chunk) !bool {
    var scanner = Scanner.init(source);
    compilingChunk = chunk;
    var parser = Parser.init();
    parser.advance(scanner);
    parser.expression();
    parser.consume(scanner, TokenType.EOF, "Expect end of expression.");
    parser.endCompiler();
    return !parser.hadError;
}

const Parser = struct {
    current: Token,
    previous: Token,
    hadError: bool,
    panicMode: bool,

    pub fn init() Parser {
        return Parser{ .current = undefined, .previous = undefined, .hadError = false, .panicMode = false };
    }
    pub fn advance(self: *Parser, scanner: *Scanner) void {
        self.previous = self.current;
        while (true) {
            self.current = scanner.scanToken();
            if (self.current.ty != TokenType.Error) {
                break;
            }
            self.errorAtCurrent(self.current.start);
        }
    }
    pub fn consume(self: *Parser, scanner: *Scanner, ty: TokenType, message: []const u8) void {
        if (self.current.ty == ty) {
            self.advance(scanner);
            return;
        }
        self.errorAtCurrent(message);
    }
    pub fn emitByte(self: Parser, byte: u8) void {
        currentChunk().write(byte, self.previous.line);
    }
    pub fn emitReturn(self: Parser) void {
        self.emitByte(@enumToInt(op.Return));
    }
    pub fn emitBytes(self: Parser, byte1: u8, byte2: u8) void {
        self.emitByte(byte1);
        self.emitByte(byte2);
    }
    pub fn emitConstant(self: Parser, value: Value) void {
        self.emitBytes(@enumToInt(op.Constant), makeConstant(value));
    }
    fn number(self: Parser) void {
        const value = @as(f64, self.previous.start);
        self.emitConstant(value);
    }
    fn makeConstant(self: Parser, value: Value) u8 {
        const constant = currentChunk().addConstant(value);
        if (constant > 255) {
            self.error_("Too many constants in one chunk.");
            return 0;
        }
        return constant;
    }
    pub fn expression(self: Parser) void {
        _ = self;
        // what goes in here?
    }

    fn endCompiler(self: Parser) void {
        self.emitReturn();
    }
    fn errorAtCurrent(self: *Parser, message: []const u8) void {
        self.errorAt(self.current, message);
    }
    fn error_(self: *Parser, message: []const u8) void {
        self.errorAt(self.previous, message);
    }
    fn errorAt(self: *Parser, token: Token, message: []const u8) void {
        if (self.panicMode) {
            return;
        }
        self.panicMode = true;
        print("[line {d}] Error", .{token.line});
        if (token.ty == TokenType.EOF) {
            print(" at end", .{});
        } else if (token.ty == TokenType.Error) {
            // Nothing.
        } else {
            print(" at '{s}'", .{token.start[0..token.length]});
        }
        print(": {s}\n", .{message});
        self.hadError = true;
    }
};
