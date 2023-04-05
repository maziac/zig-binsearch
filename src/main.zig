const std = @import("std");

pub fn main() !void {
    //var a: i32 = 13;
    std.debug.print("Hello, {s}!\n", .{"World"});
    //std.debug.print("the value a = {}\n", "gg");

    var args = try std.process.argsWithAllocator(std.heap.page_allocator);
    defer args.deinit();

    // Skip path
    const executable_name = args.next();

    while (true) {
        var arg = args.next() orelse break;

        if (std.cstr.cmp(arg, "--help") == 0) {
            try args_help();
        }
    }

    std.debug.print("executable_name={any}\n", .{executable_name});
}

fn args_help() !void {
    try std.io.getStdOut().writer().print("Help {any}", .{""});
}

// const std = @import("std");

// pub fn main() anyerror!void {
//     var args = try std.process.argsWithAllocator(std.heap.page_allocator);
//     defer args.deinit();

//     // Skip path
//     const executable_name = args.next() orelse return;
//     //_ = executable_name;
//     if (std.cstr.cmp(executable_name, "--help") == 0) {}
// }
