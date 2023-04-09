const std = @import("std");
const bin_dumper = @import("bin_dumper.zig");

const version = "1.1.0";

//  Get an allocator
var gp = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
//defer _ = gp.deinit();
const allocator = gp.allocator();

pub fn main() !void {
    var args = try std.process.argsAlloc(allocator);
    defer allocator.free(args);

    // Read in the stdin (in case data is piped)
    try bin_dumper.read_stdio();

    // Parse arguments
    const stdout = std.io.getStdOut().writer();
    try parse_args(args, stdout);
}

/// Loops through the passed arguments.
/// Any dump is written to 'writer'.
fn parse_args(args_array: [][:0]const u8, writer: anytype) !void {
    var offs: i64 = 0;
    var i: usize = 1; // Skip first (path)
    const len = args_array.len;

    while (i < len) {
        const arg = args_array[i];

        if (std.cstr.cmp(arg, "--help") == 0) {
            args_help();
        } else if (std.cstr.cmp(arg, "--version") == 0) {
            std.io.getStdOut().writer().print("Version {s}\n", .{version}) catch {};
        } else if (std.cstr.cmp(arg, "--offs") == 0) {
            // Get next arg
            const o = get_next_arg(&i, args_array) orelse {
                return anyerror.expected_offset; // "Expected an offset value."
            };
            // Check value
            if ((o[0] == '+') or (o[0] == '-')) {
                offs += try std.fmt.parseInt(i64, o, 0);
            } else {
                offs = try std.fmt.parseInt(i64, o, 0);
            }
        } else if (std.cstr.cmp(arg, "--size") == 0) {
            // Get next arg
            const s = get_next_arg(&i, args_array) orelse {
                return anyerror.expected_size; // "Expected a size value."
            };
            // Check for max
            var size: i64 = std.math.maxInt(i64);
            if (std.cstr.cmp(s, "all") != 0) {
                // It's not "all":
                size = try std.fmt.parseInt(i64, s, 0);
            }
            try bin_dumper.dump(offs, size, writer);
            offs += size;
        } else if (std.cstr.cmp(arg, "--search") == 0) {
            // Get next arg
            const s = get_next_arg(&i, args_array) orelse {
                return anyerror.expected_search_value; // "Expected a value sequence to search for."
            };
            try bin_dumper.search(&offs, s);
        } else {
            // // It is the filename. Open file.
            try bin_dumper.read_file(arg);
            offs = 0;
        }

        // Next
        i += 1;
    }
}

/// Returns the next argument in 'args_array' or an error if none exists.
/// - 'index' - The current index. Will get increased by 1.
/// - 'args_array' - The array of strings.
/// Returns: The string at 'index' or null if out of range.
fn get_next_arg(index: *usize, args_array: [][:0]const u8) ?[:0]const u8 {
    index.* += 1;
    if (index.* >= args_array.len) {
        return null;
    }
    const o = args_array[index.*];
    return o;
}

/// Prints the help.
fn args_help() void {
    std.io.getStdOut().writer().print(
        \\Usage:
        \\--help: Prints this help.
        \\--version: Prints the version number.
        \\--offs offset: Offset from start of file. Moves last position. It is possible to use relative offset with the '+' or '-' sign. In that case the value is added to the current offset.
        \\--size size: The number of bytes to evaluate. Moves last position (offset:=offset+size).
        \\--search tokens: Searches for the first occurrence of tokens. Token can be a decimal of hex number or a string. The search starts at last position.
        \\--format format: The output format:
        \\  - bin: Binary output. The default.
        \\  - text: Textual output. Showing the offset and values in rows.
        \\Examples:
        \\- "binsearch --offs 10 --size 100": Outputs the bytes from position 10 to 109.
        \\- "binsearch --offs 10 --size 100 --offs 200 --size 10": Outputs the bytes from position 10 to 109, directly followed by 200 to 209.
        \\- "binsearch --offs 10 --size 100 --offs +10 --size 20": Outputs the bytes from position 10 to 109, directly followed by 120 to 129.
        \\- "binsearch --search abc --size 10": Outputs 10 bytes from the first occurrence of 'abc'.
        \\- "binsearch --search \d130 --size 10": Outputs 10 bytes from the first occurrence of decimal number 130. Only bytes are searched.
        \\- "binsearch --search \xFF --size 10": Outputs 10 bytes from the first occurrence of hex number 0xFF. Only bytes are searched.
        \\- "binsearch --search abc\xFF,xyz\d0 --size 10": Outputs 10 bytes from the first occurrence of the sequence 97,98,99,255,120,121,122,0. Only bytes are searched.
        \\Please note: when searching for a sequence of bytes, a 0 is **not** automatically added at the end.
        \\
    , .{}) catch {};
}

test "parse_args simple" {
    var outbuffer = std.ArrayList(u8).init(allocator);
    defer outbuffer.deinit();
    const writer = outbuffer.writer();

    {
        outbuffer.clearAndFree();
        var args = [_][:0]const u8{"path"};
        try parse_args(&args, writer);
        try std.testing.expectEqualSlices(u8, "", outbuffer.items);
    }

    {
        outbuffer.clearAndFree();
        var args = [_][:0]const u8{ "path", "test_data/abcdefghijkl.bin" };
        try parse_args(&args, writer);
        try std.testing.expectEqualSlices(u8, "", outbuffer.items);
    }

    {
        outbuffer.clearAndFree();
        var args = [_][:0]const u8{ "path", "test_data/abcdefghijkl.bin", "--size", "all" };
        try parse_args(&args, writer);
        try std.testing.expectEqualSlices(u8, "abcdefghijkl", outbuffer.items);
    }
}

test "parse_args dump offs" {
    var outbuffer = std.ArrayList(u8).init(allocator);
    defer outbuffer.deinit();
    const writer = outbuffer.writer();
    var args = [_][:0]const u8{ "path", "test_data/abcdefghijkl.bin", "--offs", "3", "--size", "4" };
    try parse_args(&args, writer);
    try std.testing.expectEqualSlices(u8, "defg", outbuffer.items);
}

test "parse_args 2 slices" {
    var outbuffer = std.ArrayList(u8).init(allocator);
    defer outbuffer.deinit();
    const writer = outbuffer.writer();
    var args = [_][:0]const u8{ "path", "test_data/abcdefghijkl.bin", "--offs", "2", "--size", "3", "--size", "4" };
    try parse_args(&args, writer);
    //std.debug.print("{any}", .{outbuffer.items});
    try std.testing.expectEqualSlices(u8, "cdefghi", outbuffer.items);
}

test "parse_args 2 slices" {
    var outbuffer = std.ArrayList(u8).init(allocator);
    defer outbuffer.deinit();
    const writer = outbuffer.writer();
    var args = [_][:0]const u8{ "path", "test_data/abcdefghijkl.bin", "--offs", "+1", "--size", "3", "--offs", "+4", "--size", "2" };
    try parse_args(&args, writer);
    try std.testing.expectEqualSlices(u8, "bcdij", outbuffer.items);
}

test "parse_args out of range 1" {
    var outbuffer = std.ArrayList(u8).init(allocator);
    defer outbuffer.deinit();
    const writer = outbuffer.writer();
    var args = [_][:0]const u8{ "path", "test_data/abcdefghijkl.bin", "--offs", "-1", "--size", "3" };
    try parse_args(&args, writer);
    try std.testing.expectEqualSlices(u8, "ab", outbuffer.items);
}

test "parse_args out of range 2" {
    var outbuffer = std.ArrayList(u8).init(allocator);
    defer outbuffer.deinit();
    const writer = outbuffer.writer();
    var args = [_][:0]const u8{ "path", "test_data/abcdefghijkl.bin", "--offs", "11", "--size", "3" };
    try parse_args(&args, writer);
    try std.testing.expectEqualSlices(u8, "l", outbuffer.items);
}

test "parse_args out of range 3" {
    var outbuffer = std.ArrayList(u8).init(allocator);
    defer outbuffer.deinit();
    const writer = outbuffer.writer();
    var args = [_][:0]const u8{ "path", "test_data/abcdefghijkl.bin", "--offs", "-3", "--size", "3" };
    try parse_args(&args, writer);
    try std.testing.expectEqualSlices(u8, "", outbuffer.items);
}

test "parse_args out of range 4" {
    var outbuffer = std.ArrayList(u8).init(allocator);
    defer outbuffer.deinit();
    const writer = outbuffer.writer();
    var args = [_][:0]const u8{ "path", "test_data/abcdefghijkl.bin", "--offs", "12", "--size", "1" };
    try parse_args(&args, writer);
    try std.testing.expectEqualSlices(u8, "", outbuffer.items);
}

test "parse_args out of range 5" {
    var outbuffer = std.ArrayList(u8).init(allocator);
    defer outbuffer.deinit();
    const writer = outbuffer.writer();
    var args = [_][:0]const u8{ "path", "test_data/abcdefghijkl.bin", "--offs", "-2", "--size", "20" };
    try parse_args(&args, writer);
    try std.testing.expectEqualSlices(u8, "abcdefghijkl", outbuffer.items);
}

test "parse_args two files" {
    var outbuffer = std.ArrayList(u8).init(allocator);
    defer outbuffer.deinit();
    const writer = outbuffer.writer();
    var args = [_][:0]const u8{ "path", "test_data/abcdefghijkl.bin", "--offs", "5", "--size", "2", "test_data/mnopqrstuvwx.bin", "--offs", "+1", "--size", "4" };
    try parse_args(&args, writer);
    try std.testing.expectEqualSlices(u8, "fgnopq", outbuffer.items);
}

test "parse_args search 1" {
    var outbuffer = std.ArrayList(u8).init(allocator);
    defer outbuffer.deinit();
    const writer = outbuffer.writer();
    var args = [_][:0]const u8{ "path", "test_data/abcdefghijkl.bin", "--search", "a", "--size", "2" };
    try parse_args(&args, writer);
    try std.testing.expectEqualSlices(u8, "ab", outbuffer.items);
}

test "parse_args search 2" {
    var outbuffer = std.ArrayList(u8).init(allocator);
    defer outbuffer.deinit();
    const writer = outbuffer.writer();
    var args = [_][:0]const u8{ "path", "test_data/abcdefghijkl.bin", "--search", "bcd", "--size", "2" };
    try parse_args(&args, writer);
    try std.testing.expectEqualSlices(u8, "bc", outbuffer.items);
}

test "parse_args search 3" {
    var outbuffer = std.ArrayList(u8).init(allocator);
    defer outbuffer.deinit();
    const writer = outbuffer.writer();
    var args = [_][:0]const u8{ "path", "test_data/abcdefghijkl.bin", "--search", "kl", "--size", "5" };
    try parse_args(&args, writer);
    try std.testing.expectEqualSlices(u8, "kl", outbuffer.items);
}

test "parse_args search 4" {
    var outbuffer = std.ArrayList(u8).init(allocator);
    defer outbuffer.deinit();
    const writer = outbuffer.writer();
    var args = [_][:0]const u8{ "path", "test_data/abcdefghijkl.bin", "--search", "", "--size", "2" };
    try parse_args(&args, writer);
    try std.testing.expectEqualSlices(u8, "ab", outbuffer.items);
}

test "parse_args search 5" {
    var outbuffer = std.ArrayList(u8).init(allocator);
    defer outbuffer.deinit();
    const writer = outbuffer.writer();
    var args = [_][:0]const u8{ "path", "test_data/abcdefghijkl.bin", "--search", "xy", "--size", "2" };
    try parse_args(&args, writer);
    try std.testing.expectEqualSlices(u8, "", outbuffer.items);
}

test "parse_args search 6" {
    var outbuffer = std.ArrayList(u8).init(allocator);
    defer outbuffer.deinit();
    const writer = outbuffer.writer();
    var args = [_][:0]const u8{ "path", "test_data/abcdabcdaxyz.bin", "--search", "a", "--offs", "+1", "--search", "a", "--offs", "+1", "--search", "a", "--offs", "+1", "--size", "3" };
    try parse_args(&args, writer);
    try std.testing.expectEqualSlices(u8, "xyz", outbuffer.items);
}

test "parse_args search decimal" {
    var outbuffer = std.ArrayList(u8).init(allocator);
    defer outbuffer.deinit();
    const writer = outbuffer.writer();
    var args = [_][:0]const u8{ "path", "test_data/abcdefghijkl.bin", "--search", "\\d98", "--size", "3" };
    try parse_args(&args, writer);
    try std.testing.expectEqualSlices(u8, "bcd", outbuffer.items);
}
test "parse_args search decimal and hex" {
    var outbuffer = std.ArrayList(u8).init(allocator);
    defer outbuffer.deinit();
    const writer = outbuffer.writer();
    var args = [_][:0]const u8{ "path", "test_data/abcdefghijkl.bin", "--search", "\\d99,\\x64", "--size", "3" };
    try parse_args(&args, writer);
    try std.testing.expectEqualSlices(u8, "cde", outbuffer.items);
}
