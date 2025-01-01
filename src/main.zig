pub const version = "0.0.1";

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    defer _ = general_purpose_allocator.deinit();

    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    if (args.len <= 0) {
        nverror.errorfn(args);
    }

    try nov_command.command(args);
}

const std = @import("std");
const nverror = @import("error.zig");
const nov_command = @import("command.zig");
