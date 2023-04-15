const equal = @import("std").mem.eql;

pub const Scanner = struct {
    start: []const u8,
    current: []const u8,
    line: u32,

    pub fn init(source: []const u8) Scanner {
        return Scanner{ .start = source, .current = source, .line = 1 };
    }
    fn isAtEnd(self: Scanner) bool {
        return equal(u8, self.current, "\\x00");
    }
    pub fn advance(self: *Scanner) u8 {
        const byte = self.current[0];
        self.current = self.current[1..];
        return byte;
    }
    fn match(self: *Scanner, expected: []const u8) bool {
        if (self.isAtEnd()) {
            return false;
        }
        if (!equal(u8, self.current, expected)) {
            return false;
        }
        self.current = self.current[1..];
        return true;
    }
    fn peek(self: Scanner) u8 {
        return *self.current;
    }
    fn peekNext(self: *Scanner) u8 {
        if (self.isAtEnd()) {
            return "\\x00";
        }
        return self.current[1];
    }
    fn skipWhiteSpace(self: *Scanner) void {
        while (true) {
            const c = self.*.peek();
            switch (c) {
                ' ' => {
                    self.advance();
                    break;
                },
                '\r' => {
                    self.advance();
                    break;
                },
                '\t' => {
                    self.advance();
                    break;
                },
                '\n' => {
                    self.line += 1;
                    self.advance();
                    break;
                },
                '/' => {
                    if (self.peekNext() == '/') {
                        while (self.peek() != '\n' and !self.isAtEnd()) {
                            self.advance();
                        }
                    } else {
                        return;
                    }
                    break;
                },
                else => return,
            }
        }
    }
    fn string(self: *Scanner) Token {
        while (self.peek() != '\"' and !self.isAtEnd()) {
            if (self.peek() == '\n') {
                self.line += 1;
            }
            self.advance();
        }
        if (self.isAtEnd()) {
            return Token.errorToken("Unterminated string,", self.line);
        }
        self.advance();
        return Token.init(self.*, TokenType.String);
    }
    fn number(self: *Scanner) Token {
        while (isDigit(self.peek())) {
            self.advance();
        }
        if (self.peek() == '.' and isDigit(self.peekNext())) {
            self.advance();
            while (isDigit(self.peek())) {
                self.advance();
            }
        }
        return Token.init(self.*, TokenType.Number);
    }
    fn identifier(self: *Scanner) Token {
        while (isAlpha(self.peek()) or isDigit(self.peek())) {
            self.advance();
        }
        return Token.init(self.*, identifierType());
    }
    fn identifierType(self: Scanner) TokenType {
        switch (self.start[0]) {
            'a' => return self.checkKeyword(1, 2, "nd", TokenType.And),
            'c' => return self.checkKeyword(1, 4, "lass", TokenType.Class),
            'e' => return self.checkKeyword(1, 3, "lse", TokenType.Else),
            'f' => {
                if (self.current - self.start > 1) {
                    switch (self.start[1]) {
                        'a' => return self.checkKeyword(2, 3, "lse", TokenType.False),
                        'o' => return self.checkKeyword(2, 1, "r", TokenType.For),
                        'u' => return self.checkKeyword(2, 1, "n", TokenType.Fun),
                    }
                }
            },
            'i' => return self.checkKeyword(1, 1, "f", TokenType.If),
            'n' => return self.checkKeyword(1, 2, "il", TokenType.Nil),
            'o' => return self.checkKeyword(1, 1, "r", TokenType.Or),
            'p' => return self.checkKeyword(1, 4, "rint", TokenType.Print),
            'r' => return self.checkKeyword(1, 5, "eturn", TokenType.Return),
            's' => return self.checkKeyword(1, 4, "uper", TokenType.Super),
            't' => {
                if (self.current - self.start > 1) {
                    switch (self.start[1]) {
                        'h' => return self.checkKeyword(2, 2, "is", TokenType.This),
                        'r' => return self.checkKeyword(2, 2, "ue", TokenType.True),
                    }
                }
            },
            'v' => return self.checkKeyword(1, 2, "ar", TokenType.Var),
            'w' => return self.checkKeyword(1, 4, "hile", TokenType.While),
        }
        return TokenType.Identifier;
    }
    fn checkKeyword(self: Scanner, start: u8, length: usize, rest: []const u8, ty: TokenType) TokenType {
        if (self.current - self.start == start + length and self.start + start == rest) {
            return ty;
        }
        return TokenType.Identifier;
    }
    pub fn scanToken(self: *Scanner) Token {
        self.start = self.current;
        if (self.isAtEnd()) {
            return Token.init(self.*, TokenType.EOF);
        }

        const c = self.advance();
        if (isAlpha(c)) {
            return self.identifier();
        }
        if (isDigit(c)) {
            return self.number();
        }
        switch (c) {
            '(' => return Token.init(self.*, TokenType.LParen),
            ')' => return Token.init(self.*, TokenType.RParen),
            '{' => return Token.init(self.*, TokenType.LBrace),
            '}' => return Token.init(self.*, TokenType.RBrace),
            ';' => return Token.init(self.*, TokenType.SemiColon),
            ',' => return Token.init(self.*, TokenType.Comma),
            '.' => return Token.init(self.*, TokenType.Dot),
            '+' => return Token.init(self.*, TokenType.Plus),
            '-' => return Token.init(self.*, TokenType.Minus),
            '*' => return Token.init(self.*, TokenType.Star),
            '/' => return Token.init(self.*, TokenType.Slash),
            '!' => {
                if (self.match("=")) {
                    return Token.init(self.*, TokenType.Bang_Equal);
                } else {
                    return Token.init(self.*, TokenType.Bang);
                }
            },
            '=' => {
                if (self.match("=")) {
                    return Token.init(self.*, TokenType.Equal_Equal);
                } else {
                    return Token.init(self.*, TokenType.Equal);
                }
            },
            '<' => {
                if (self.match("=")) {
                    return Token.init(self.*, TokenType.Less_Equal);
                } else {
                    return Token.init(self.*, TokenType.Less);
                }
            },
            '>' => {
                if (self.match("=")) {
                    return Token.init(self.*, TokenType.Greater_Equal);
                } else {
                    return Token.init(self.*, TokenType.Greater);
                }
            },
            '\"' => return self.string(),
            else => return Token.errorToken("Unexpected character.", self.line),
        }
    }
};

fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

fn isAlpha(c: u8) bool {
    return (c >= 'a' and c <= 'z') or
        (c >= 'A' and c <= 'Z') or
        c == '_';
}

pub const Token = struct {
    ty: TokenType,
    start: []const u8,
    length: usize,
    line: u32,

    pub fn init(scanner: Scanner, ty: TokenType) Token {
        return Token{ .ty = ty, .start = scanner.start, .line = scanner.line, .length = scanner.current.len - scanner.start.len };
    }
    pub fn errorToken(message: []const u8, line: u32) Token {
        return Token{ .ty = TokenType.Error, .start = message, .length = message.len, .line = line };
    }
};

pub const TokenType = enum {
    // single character tokens
    LParen,
    RParen,
    LBrace,
    RBrace,
    Comma,
    Dot,
    Minus,
    Plus,
    SemiColon,
    Slash,
    Star,

    // one or two character tokens
    Bang,
    Bang_Equal,
    Equal,
    Equal_Equal,
    Greater,
    Greater_Equal,
    Less,
    Less_Equal,

    // literals
    Identifier,
    String,
    Number,

    //keywords
    And,
    Class,
    Else,
    False,
    For,
    Fun,
    If,
    Nil,
    Or,
    Print,
    Return,
    Super,
    This,
    True,
    Var,
    While,

    // Misc
    Error,
    EOF,
};
