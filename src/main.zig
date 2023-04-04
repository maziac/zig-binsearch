const std = @import("std");

pub fn main() void {
    //var a: i32 = 13;
    std.debug.print("Hello, {s}!\n", .{"World"});
    //std.debug.print("the value a = {}\n", "gg");

    var args = try std.process.argsWithAllocator(std.heap.page_allocator);
    defer args.deinit();

    const executable_name = args.next();
    //  orelse {
    //     try .print.process(error.NoExecutableName, Error{
    //         .option = "",
    //         .kind = .missing_executable_name,
    //     });

    //     // we do not assume any more arguments appear here anyways...
    //     return error.NoExecutableName;
    // };

    std.debug.print("executable_name={any}\n", .{executable_name});
}
