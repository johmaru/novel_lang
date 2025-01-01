//Arg構造体
const cmd_args = struct {
    args: []const u8,
    start: usize,
    end: usize,
};
const CmdArgsList = std.ArrayList(cmd_args);

fn searchArg(args: [][:0]u8) bool {
    for (args) |arg| {
        if (arg.len < 1) continue;
        if (arg[0] == '-') return true;
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
        if (arg[0] == '-') {
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

fn argsIndex(args: [][:0]u8) cmd_args {
    for (args) |arg| {
        if (arg.len < 1) continue;
        if (arg[0] == '-') {
            if (findSpaceIndex(arg[1..])) |space_index| {
                return .{ .args = arg[1 .. space_index + 1], .start = 1, .end = space_index + 1 };
            }
            return .{ .args = arg[1..], .start = 1, .end = arg.len };
        }
    }
    return .{ .args = "none", .start = 0, .end = 4 };
}

pub fn command(args: [][:0]u8) !void {
    if (args.len <= 1) return;
    if (searchArg(args)) {
        if (std.mem.eql(u8, args[1], "version")) {
            std.debug.print("Version Command has not Args\n", .{});
        } else if (std.mem.eql(u8, args[1], "help")) {
            try helpCommand(args);
        } else {
            nverror.errorfn(args);
        }
    } else {
        std.debug.print("Non Exist Args\n", .{});

        if (std.mem.eql(u8, args[1], "version")) {
            versionCommand();
        } else if (std.mem.eql(u8, args[1], "help")) {
            try helpCommand(args);
        } else {
            nverror.errorfn(args);
        }
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
            if (std.mem.eql(u8, arg.args, "version")) {
                std.debug.print("\n\nUsage: {s} version\n\n", .{all_args[0]});
            } else if (std.mem.eql(u8, arg.args, "help")) {
                std.debug.print("\n\nUsage: {s} help\n\n", .{all_args[0]});
            } else {
                nverror.errorfn(all_args);
            }
        }
    } else {
        std.debug.print("\n\nUsage: {s} [command]\n\n", .{all_args[0]});
        std.debug.print("Commands:\n\n", .{});
        std.debug.print("       version\n", .{});
        std.debug.print("       help\n", .{});
    }
}

fn versionCommand() void {
    std.debug.print("NowVersion : {s}\n", .{nov.version});
}

const std = @import("std");
const nverror = @import("error.zig");
const nov = @import("main.zig");
