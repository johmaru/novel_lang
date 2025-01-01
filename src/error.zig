const std = @import("std");

pub const Error = error{
    UnknownError,
    UnknownCommand,
    MissingArgument,
};

fn processCommand(args: [][:0]u8) Error!void {
    if (args.len == 0) {
        return Error.UnknownError;
    } else if (args.len < 2) {
        if (std.mem.eql(u8, args.ptr[1], "version")) {
            return Error.UnknownError;
        } else {
            return Error.UnknownCommand;
        }
    } else {
        return Error.UnknownCommand;
    }
}

pub fn errorfn(args: [][:0]u8) void {
    processCommand(args) catch |err| {
        switch (err) {
            Error.UnknownCommand => std.debug.print("不明なコマンド{s}\n", .{args.ptr[1]}),
            Error.UnknownError => std.debug.print("不明なエラー\n", .{}),
            Error.MissingArgument => std.debug.print("引数が見つかりません\n", .{}),
        }
    };
}
