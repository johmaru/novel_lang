//コマンド構造体
const Command = struct {
    const Self = @This();
    const arg_prefix: u8 = '-';
    const version: []const u8 = "version";
    const help: []const u8 = "help";
    const compile: []const u8 = "compile";

    pub fn init() type {
        return Self;
    }

    pub fn isValidCommand(comptime cmd: []const u8) bool {
        return std.mem.eql(u8, cmd, Self.version) or
            std.mem.eql(u8, cmd, Self.help);
    }
};

//Arg構造体
const cmd_args = struct {
    args: []const u8,
    start: usize,
    end: usize,
};
const cmd_args_char = struct {
    args: u8,
    start: usize,
    end: usize,
};
const CmdArgsList = std.ArrayList(cmd_args);
const nov_cmd = Command.init();

fn searchArg(args: [][:0]u8) bool {
    for (args) |arg| {
        if (arg.len < 1) continue;
        if (arg[0] == nov_cmd.arg_prefix) return true;
    }
    return false;
}

fn findSpaceIndex(text: []const u8) ?usize {
    for (text, 0..) |char, i| {
        if (char == ' ') return i;
    }
    return null;
}

fn argsIndexMultiple(allocator: std.mem.Allocator, args: [][:0]u8) !CmdArgsList {
    var list = CmdArgsList.init(allocator);

    for (args) |arg| {
        if (arg.len < 1) continue;
        if (arg[0] == nov_cmd.arg_prefix) {
            const new_args: cmd_args = if (findSpaceIndex(arg[1..])) |space_index| .{
                .args = arg[1 .. space_index + 1],
                .start = 1,
                .end = space_index + 1,
            } else .{
                .args = arg[1..],
                .start = 1,
                .end = arg.len,
            };

            var found = false;
            for (list.items) |item| {
                if (std.mem.eql(u8, item.args, new_args.args)) {
                    found = true;
                    break;
                }
            }

            if (!found) {
                try list.append(new_args);
            }
        }
    }

    if (list.items.len == 0) {
        try list.append(.{
            .args = "none",
            .start = 0,
            .end = 4,
        });
    }

    return list;
}

fn argsIndex(args: [][:0]u8) !cmd_args {
    for (args) |arg| {
        if (arg.len < 1) continue;
        if (arg[0] == nov_cmd.arg_prefix) {
            if (findSpaceIndex(arg[1..])) |space_index| {
                return .{ .args = arg[1 .. space_index + 1], .start = 1, .end = space_index + 1 };
            }
            return .{ .args = arg[1..], .start = 1, .end = arg.len };
        }
    }
    return .{ .args = "none", .start = 0, .end = 4 };
}

fn argsCharIndex(args: [][:0]u8) !cmd_args_char {
    for (args) |arg| {
        if (arg.len < 1) continue;
        if (arg[0] == nov_cmd.arg_prefix) {
            return .{ .args = arg[1], .start = 1, .end = 2 };
        }
    }
    return .{ .args = 'n', .start = 0, .end = 4 };
}

pub fn command(args: [][:0]u8) !void {
    if (args.len <= 1) return;
    if (searchArg(args)) {
        if (std.mem.eql(u8, args[1], nov_cmd.version)) {
            std.debug.print("バージョンコマンドに引数は存在しません\n", .{});
        } else if (std.mem.eql(u8, args[1], nov_cmd.help)) {
            try helpCommand(args);
        } else if (std.mem.eql(u8, args[1], nov_cmd.compile)) {
            const arg = try argsCharIndex(args);
            try compileCommand(args[2], arg.args);
        } else {
            nverror.errorfn(args);
        }
    } else {
        if (std.mem.eql(u8, args[1], nov_cmd.version)) {
            versionCommand();
        } else if (std.mem.eql(u8, args[1], nov_cmd.help)) {
            try helpCommand(args);
        } else if (std.mem.eql(u8, args[1], nov_cmd.compile)) {
            try compileCommand(args[2], 'r');
        } else {
            nverror.errorfn(args);
        }
    }
}
const compile_mode = enum(u8) {
    PathRelative = 'r',
    PathAbsolute = 'a',
};

fn compileCommand(path: []const u8, mode: u8) !void {
    switch (mode) {
        'r' => {
            var gpa = std.heap.GeneralPurposeAllocator(.{}){};
            defer _ = gpa.deinit();
            const allocator = gpa.allocator();
            const complete_path = try std.fs.path.join(allocator, &[_][]const u8{ ".", path });
            std.debug.print("{s}\n", .{complete_path});
            defer allocator.free(complete_path);
            const file = try std.fs.cwd().openFile(complete_path, .{});
            defer file.close();

            const content = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
            std.debug.print("{s}\n", .{content});
            defer allocator.free(content);
            var lexer = novlexer.Lexer.init(content);
            while (true) {
                const token = lexer.nextToken();
                if (token.type == novlexer.TokenType.EOF) {
                    break;
                }
                std.debug.print("{d}:{d} {} {s}\n", .{ token.line, token.column, token.type, token.literal });
            }
        },
        'a' => {
            const file = try std.fs.cwd().openFile(path, .{});
            defer file.close();
            var gpa = std.heap.GeneralPurposeAllocator(.{}){};
            defer _ = gpa.deinit();
            const allocator = gpa.allocator();
            const content = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
            defer allocator.free(content);
            var lexer = novlexer.Lexer.init(content);
            while (true) {
                const token = lexer.nextToken();
                if (token.type == novlexer.TokenType.EOF) {
                    break;
                }
                std.debug.print("{d}:{d} {} {s}\n", .{ token.line, token.column, token.type, token.literal });
            }
        },
        else => {
            var gpa = std.heap.GeneralPurposeAllocator(.{}){};
            defer _ = gpa.deinit();
            const allocator = gpa.allocator();
            const complete_path = try std.fs.path.join(allocator, &[_][]const u8{ ".", path });
            defer allocator.free(complete_path);
            const file = try std.fs.cwd().openFile(complete_path, .{});
            defer file.close();
            const content = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
            defer allocator.free(content);
            var lexer = novlexer.Lexer.init(content);
            while (true) {
                const token = lexer.nextToken();
                if (token.type == novlexer.TokenType.EOF) {
                    break;
                }
                std.debug.print("{d}:{d} {} {s}\n", .{ token.line, token.column, token.type, token.literal });
            }
        },
    }
}

fn helpCommand(all_args: [][:0]u8) !void {
    if (searchArg(all_args)) {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();
        const argument_index = try argsIndexMultiple(allocator, all_args);
        defer argument_index.deinit();
        for (argument_index.items) |arg| {
            if (std.mem.eql(u8, arg.args, nov_cmd.version)) {
                std.debug.print("\n\n使い方: {s} version\n\n", .{all_args[0]});
            } else if (std.mem.eql(u8, arg.args, nov_cmd.help)) {
                std.debug.print("\n\n使い方: {s} help\n\n", .{all_args[0]});
            } else {
                nverror.errorfn(all_args);
            }
        }
    } else {
        std.debug.print("\n\n使い方: {s} [command]\n\n", .{all_args[0]});
        std.debug.print("コマンド:\n\n", .{});
        std.debug.print("       version\n", .{});
        std.debug.print("       help\n", .{});
    }
}

fn versionCommand() void {
    std.debug.print("現在のバージョン : {s}\n", .{nov.version});
}

const std = @import("std");
const nverror = @import("error.zig");
const nov = @import("main.zig");
const novlexer = @import("lexer.zig");
