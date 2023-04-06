const std = @import("std");
const stdout = std.io.getStdOut();

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
            args_help();
        }
    }

    std.debug.print("executable_name={any}\n", .{executable_name});
}

fn args_help() void {
    stdout.writer().print(
        \\Usage:
        \\--help: Prints this help.
        \\--offs offset: Offset from start of file. Moves last position. It is possible to use relative offset with the '+' or '-' sign. In that case the value is added to the current offset.
        \\--size size: The number of bytes to evaluate. Moves last position (offset:=offset+size).
        \\--search token [token ...]: Searches for the first occurrence of tokens. Token can be a decimal of hex number or a string. The search starts at last position.
        \\--format format: The output format:
        \\  - bin: Binary output. The default.
        \\  - text: Textual output. Showing the offset and values in rows.
        \\Examples:
        \\- \"binsearch --offs 10 --size 100\": Outputs the bytes from position 10 to 109.
        \\- \"binsearch --offs 10 --size 100 --offs 200 --size 10\": Outputs the bytes from position 10 to 109, directly followed by 200 to 209.
        \\- \"binsearch --offs 10 --size 100 --reloffs 10 --size 20\": Outputs the bytes from position 10 to 109, directly followed by 120 to 129.
        \\- \"binsearch --search 'abc' --size 10\": Outputs 10 bytes from the first occurrence of 'abc'. If not fould nothing is output.
        \\
    , .{}) catch {};
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
