const std = @import("std");
const bin_dumper = @import("bin_dumper.zig");

const stdout = std.io.getStdOut();

pub fn main() !void {
    var offs: i32 = 0;
    //var mut bin_dumper = BinDumper::new();

    //    std.debug.print("Hello, {s}!\n", .{"World"});

    var args = try std.process.argsWithAllocator(std.heap.page_allocator);
    defer args.deinit();

    // Skip path
    const executable_name = args.next();

    while (true) {
        var arg = args.next() orelse break;

        if (std.cstr.cmp(arg, "--help") == 0) {
            args_help();
            return anyerror.my_error;
        } else if (std.cstr.cmp(arg, "--offs") == 0) {
            const o = args.next() orelse {
                return anyerror.expected_offset; //;"Expected an offset value.");
            };
            if ((o[0] == '+') or (o[0] == '-')) {
                offs += try std.fmt.parseInt(i32, o, 0);
            } else {
                offs = try std.fmt.parseInt(i32, o, 0);
            }
        } else if (std.cstr.cmp(arg, "--size") == 0) {
            const s = args.next() orelse {
                return anyerror.expected_size; //;"Expected a size value.");
            };
            // Check for max
            var size: i32 = std.math.maxInt(i32);
            if (std.cstr.cmp(s, "all") != 0) {
                // It's not "all":
                size = try std.fmt.parseInt(i32, s, 0);
            }
          //  bin_dumper.dump(offs, size, output);
            offs += size;
        } else if (std.cstr.cmp(arg, "--search") == 0) {
            // let s = args.get_next_check("Expected a string.");
            // println!("search: {}", s);
            // bin_dumper.search(&mut offs, &s);
        } else {
            // // It is the filename. Open file.
            try bin_dumper.read_file(arg);
            // offs = 0;
        }
    }

    std.debug.print("executable_name={any}\n", .{executable_name});
}

/// Prints the help.
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
