const std = @import("std");

const TokenType = enum {
    Identifier,
    Keyword,
    Integer,
    Float,
    Operator,
    Separator,
    StringLiteral,
    CharLiteral,
    EOF,
};

const Token = struct {
    type: TokenType,
    lexeme: []const u8,
    line: usize,
    column: usize,
};

const Lexer = struct {
    input: []const u8,
    position: usize,
    line: usize,
    column: usize,

    const Self = @This();

    fn init(input: []const u8) Self {
        return Self{
            .input = input,
            .position = 0,
            .line = 1,
            .column = 1,
        };
    }

    fn nextToken(self: *Self) !Token {
        self.skipWhitespace();

        if (self.position >= self.input.len) {
            return Token{ .type = .EOF, .lexeme = "", .line = self.line, .column = self.column };
        }

        const char = self.input[self.position];

        if (std.ascii.isAlphabetic(char) or char == '_') {
            return self.lexIdentifierOrKeyword();
        } else if (std.ascii.isDigit(char)) {
            return self.lexNumber();
        } else if (char == '"') {
            return self.lexString();
        } else if (char == '\'') {
            return self.lexChar();
        } else {
            return self.lexOperatorOrSeparator();
        }
    }

    fn lexIdentifierOrKeyword(self: *Self) Token {
        const start = self.position;
        while (self.position < self.input.len) : (self.position += 1) {
            const char = self.input[self.position];
            if (!std.ascii.isAlphanumeric(char) and char != '_') {
                break;
            }
        }
        const lexeme = self.input[start..self.position];
        const token = Token{
            .type = if (isKeyword(lexeme)) .Keyword else .Identifier,
            .lexeme = lexeme,
            .line = self.line,
            .column = self.column,
        };
        self.column += lexeme.len;
        return token;
    }

    fn lexNumber(self: *Self) Token {
        const start = self.position;
        var has_dot = false;
        while (self.position < self.input.len) : (self.position += 1) {
            const char = self.input[self.position];
            if (char == '.') {
                if (has_dot) break;
                has_dot = true;
            } else if (!std.ascii.isDigit(char)) {
                break;
            }
        }
        const lexeme = self.input[start..self.position];
        const token = Token{
            .type = if (has_dot) .Float else .Integer,
            .lexeme = lexeme,
            .line = self.line,
            .column = self.column,
        };
        self.column += lexeme.len;
        return token;
    }

    fn lexString(self: *Self) Token {
        const start = self.position;
        self.position += 1; // Skip opening quote
        while (self.position < self.input.len) : (self.position += 1) {
            const char = self.input[self.position];
            if (char == '"' and self.input[self.position - 1] != '\\') {
                self.position += 1; // Include closing quote
                break;
            }
        }
        const lexeme = self.input[start..self.position];
        const token = Token{ .type = .StringLiteral, .lexeme = lexeme, .line = self.line, .column = self.column };
        self.column += lexeme.len;
        return token;
    }

    fn lexChar(self: *Self) Token {
        const start = self.position;
        self.position += 1; // Skip opening quote
        while (self.position < self.input.len) : (self.position += 1) {
            const char = self.input[self.position];
            if (char == '\'' and self.input[self.position - 1] != '\\') {
                self.position += 1; // Include closing quote
                break;
            }
        }
        const token = Token{ .type = .CharLiteral, .lexeme = self.input[start..self.position], .line = self.line, .column = self.column };
        self.column += self.position - start;
        return token;
    }

    fn lexOperatorOrSeparator(self: *Self) Token {
        const start = self.position;
        const char = self.input[self.position];
        self.position += 1;
        self.column += 1;

        const token_type: TokenType = switch (char) {
            '(', ')', '[', ']', '{', '}', ';', ',' => .Separator,
            else => .Operator,
        };

        return Token{ .type = token_type, .lexeme = self.input[start..self.position], .line = self.line, .column = self.column - 1 };
    }

    fn skipWhitespace(self: *Self) void {
        while (self.position < self.input.len) : (self.position += 1) {
            switch (self.input[self.position]) {
                ' ', '\t' => self.column += 1,
                '\n' => {
                    self.line += 1;
                    self.column = 1;
                },
                '\r' => {
                    if (self.position + 1 < self.input.len and self.input[self.position + 1] == '\n') {
                        self.position += 1;
                    }
                    self.line += 1;
                    self.column = 1;
                },
                else => return,
            }
        }
    }
};

fn isKeyword(lexeme: []const u8) bool {
    const keywords = [_][]const u8{ "auto", "break", "case", "char", "const", "continue", "default", "do", "double", "else", "enum", "extern", "float", "for", "goto", "if", "int", "long", "register", "return", "short", "signed", "sizeof", "static", "struct", "switch", "typedef", "union", "unsigned", "void", "volatile", "while" };

    for (keywords) |keyword| {
        if (std.mem.eql(u8, lexeme, keyword)) {
            return true;
        }
    }
    return false;
}

pub fn main() !void {
    const input =
        \\int main() {
        \\    int x = 42;
        \\    float y = 3.14;
        \\    char* str = "Hello, World!";
        \\    return 0;
        \\}
    ;
    var lexer = Lexer.init(input);

    while (true) {
        const token = try lexer.nextToken();
        if (token.type == .EOF) break;

        std.debug.print("Token: {any}, Lexeme: {s}\n", .{ token.type, token.lexeme });
    }
}
