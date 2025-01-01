const std = @import("std");

pub const TokenType = enum {
    // 基本トークン
    EOF, // ファイル終端
    IDENTIFIER, // 識別子
    NUMBER, // 数値
    STRING, // 文字列

    // 演算子
    PLUS, // +
    MINUS, // -
    STAR, // *
    SLASH, // /
    EQUAL, // =

    // 区切り文字
    LPAREN, // (
    RPAREN, // )
    SEMICOLON, // ;
};

pub const Token = struct {
    type: TokenType,
    literal: []const u8,
    line: usize,
    column: usize,
};

pub const Lexer = struct {
    input: []const u8,
    position: usize,
    read_position: usize,
    line: usize,
    column: usize,
    current_char: []const u8,

    const Self = @This();

    pub fn init(input: []const u8) Self {
        var lexer = Self{
            .input = input,
            .position = 0,
            .read_position = 0,
            .line = 1,
            .column = 0,
            .current_char = &[_]u8{},
        };
        lexer.readChar();
        return lexer;
    }

    pub fn readChar(self: *Self) void {
        if (self.read_position >= self.input.len) {
            self.current_char = &[_]u8{0};
            return;
        }

        const first_byte = self.input[self.read_position];
        const utf8_len = getUtf8Len(first_byte);

        if (self.read_position + utf8_len <= self.input.len) {
            self.current_char = self.input[self.read_position .. self.read_position + utf8_len];
        } else {
            self.current_char = &[_]u8{0};
        }

        self.position = self.read_position;
        self.read_position += utf8_len;
        self.column += 1;
    }

    pub fn nextToken(self: *Self) Token {
        self.skipWhitespace();

        const token = if (self.current_char.len == 1) switch (self.current_char[0]) {
            '+' => Token{ .type = .PLUS, .literal = "+", .line = self.line, .column = self.column },
            '-' => Token{ .type = .MINUS, .literal = "-", .line = self.line, .column = self.column },
            '=' => Token{ .type = .EQUAL, .literal = "=", .line = self.line, .column = self.column },
            0 => Token{ .type = .EOF, .literal = "", .line = self.line, .column = self.column },
            else => if (isLetter(self.current_char))
                self.readIdentifier()
            else if (isDigit(self.current_char))
                self.readNumber()
            else
                Token{ .type = .EOF, .literal = "", .line = self.line, .column = self.column },
        } else if (isJpLatter(self.current_char)) {
            return self.readJpIdentifier();
        } else {
            return Token{ .type = .EOF, .literal = "", .line = self.line, .column = self.column };
        };

        self.readChar();
        return token;
    }

    fn readIdentifier(self: *Self) Token {
        const position = self.position;
        while (isLetter(self.current_char)) {
            self.readChar();
        }
        return Token{
            .type = .IDENTIFIER,
            .literal = self.input[position..self.position],
            .line = self.line,
            .column = self.column,
        };
    }

    fn readJpIdentifier(self: *Self) Token {
        const position = self.position;
        while (isJpLatter(self.current_char)) {
            self.readChar();
        }
        return Token{
            .type = .IDENTIFIER,
            .literal = self.input[position..self.position],
            .line = self.line,
            .column = self.column,
        };
    }

    fn readNumber(self: *Self) Token {
        const position = self.position;
        while (isDigit(self.current_char)) {
            self.readChar();
        }
        return Token{
            .type = .NUMBER,
            .literal = self.input[position..self.position],
            .line = self.line,
            .column = self.column,
        };
    }

    fn skipWhitespace(self: *Self) void {
        while (self.current_char.len == 1 and
            (self.current_char[0] == ' ' or
            self.current_char[0] == '\t' or
            self.current_char[0] == '\n' or
            self.current_char[0] == '\r'))
        {
            if (self.current_char[0] == '\n') {
                self.line += 1;
                self.column = 0;
            }
            self.readChar();
        }
    }

    fn isLetter(ch: []const u8) bool {
        if (ch.len != 1) return false;
        const c = ch[0];
        return ('a' <= c and c <= 'z') or ('A' <= c and c <= 'Z') or c == '_';
    }

    fn isJpLatter(text: []const u8) bool {
        if (text.len == 0) return false;
        if (text.len == 1) return false;

        const first_byte = text[0];
        if ((first_byte & 0b1110_0000) != 0b1110_0000) return false;

        return true;
    }

    fn isMultiByteChar(input: []const u8, pos: usize) bool {
        if (pos >= input.len) return false;
        const first_byte = input[pos];
        return (first_byte & 0b1000_0000) != 0;
    }

    fn getUtf8Len(first_byte: u8) usize {
        if ((first_byte & 0b1000_0000) == 0) return 1;
        if ((first_byte & 0b1110_0000) == 0b1100_0000) return 2;
        if ((first_byte & 0b1111_0000) == 0b1110_0000) return 3;
        if ((first_byte & 0b1111_1000) == 0b1111_0000) return 4;
        return 1;
    }

    fn isDigit(ch: []const u8) bool {
        if (ch.len != 1) return false;
        const c = ch[0];
        return '0' <= c and c <= '9';
    }
};
