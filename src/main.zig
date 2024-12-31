const version = "0.0.1";

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    defer _ = general_purpose_allocator.deinit();

    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    if (args.len <= 0) {
        nverror.errorfn(args);
    }

    command(args);
}

fn searchArg(args: [][:0]u8) bool {
    for (args) |arg| {
        const argf = arg[0];
        const first = argf[0];
        if (std.mem.eql(u8, first, "-") || std.mem.eql(u8, first, "--")) {
            return true;
        }
    }
    return false;
}

fn command(args: [][:0]u8) void {
    if (std.mem.eql(u8, args[1], "version")) {
        versionCommand();
    } else if (std.mem.eql(u8, args[1], "help")) {
        helpCommand(args[0]);
    } else {
        nverror.errorfn(args);
    }
}

fn helpCommand(ext: [:0]u8) void {
    std.debug.print("\n\nUsage: {s} [command]\n\n", .{ext});
    std.debug.print("Commands:\n\n", .{});
    std.debug.print("       version\n", .{});
    std.debug.print("       help\n", .{});
}

fn versionCommand() void {
    std.debug.print("NowVersion : {s}\n", .{version});
}

const std = @import("std");
const nverror = @import("error.zig");
