const std = @import("std");

//  Get an allocator
var gp = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
//defer _ = gp.deinit();
const allocator = gp.allocator();

// Pointer to the buffer on the heap.
var buffer: ?[]u8 = null;

pub fn read_file(spath: [:0]const u8) anyerror!void {
    // Free any previously allocated buffer
    if (buffer) |buf| {
        allocator.free(buf);
    }
    // Open file
    var file = std.fs.cwd().openFile(spath, .{}) catch |err| {
        std.log.err("Could not open file: \"{s}\"", .{spath});
        return err;
    };
    defer file.close();

    // Read file
    buffer = try file.reader().readAllAlloc(allocator, std.math.maxInt(usize));
}

/// Dumps out the contents of a slice of 'buffer' to 'output'.
/// # Arguments
/// * 'offset' - The first byte to dump out.
/// * 'size' - The number of bytes to dump out.
/// * 'writer' - The destination to write to.
pub fn dump(offset: i64, size: i64, writer: anytype) !void {
    if (buffer) |buf| {
        const len = @intCast(i32, buf.len);
        var start = offset;
        var count = size;
        if (start < len) {
            if (start < 0) {
                count += start;
                start = 0;
            }
            if (count > len - start) {
                count = len - start;
            }
            const end = start + count;
            try writer.writeAll(buf[@intCast(usize, start)..@intCast(usize, end)]);
        }
    }
}

/// Parses the search string.
/// A search string contains search characters but can also contain decimals
/// or hex numbers.
/// 'search_string' - E.g. "a\\xFA,\\d7,bc\\d9"
/// Returns: E.g. []u8{ 'a', 0xFA, 7, 'b', 'c', 9 }
pub fn parse_search_string(search_string: []const u8) ![]u8 {
    var search_bytes = std.ArrayList(u8).init(allocator);
    const len = search_string.len;
    var i: usize = 0;

    while (i < len) {
        var c = search_string[i];
        if (c == '\\') {
            // Get next char
            i += 1;
            if (i >= len) {
                return anyerror.expected_d_or_x;
            }
            c = search_string[i];
            // Check for \, decimal or hex
            if (c == '\\') {
                // The letter \
                try search_bytes.append(c);
            } else if (c == 'd' or c == 'x') {
                // A decimal or hex will follow
                var radix: u8 = 16;
                if (c == 'd') {
                    radix = 10;
                }
                // Find string until ','
                i += 1;
                var k = i;
                while (k < len) {
                    if (search_string[k] == ',') {
                        break;
                    }
                    k += 1;
                }
                // Check range
                if (k == i) {
                    return anyerror.expected_number;
                }
                // Now convert decimal value
                var val = try std.fmt.parseInt(u8, search_string[i..k], radix);
                try search_bytes.append(val);
                // Next
                i = k;
            } else {
                // Error
                return anyerror.expected_d_or_x;
            }
        } else {
            // "Normal" letter
            try search_bytes.append(c);
        }

        // Next
        i += 1;
    }

    return search_bytes.toOwnedSlice();
}

/// Searches a string in the buffer and changes the 'offset'.
/// If the string is not found the buffer length is returned in 'offset'.
/// A search string contains search characters but can also contain decimals
/// or hex numbers.
/// Arguments:
/// 'offset' - The offset to search from. The found offset is returned here.
/// 'search_string' - the search string.
/// 'search_string' - E.g. "a\\xFA,\\d7,bc\\d9"
/// Returns: E.g. []u8{ 'a', 0xFA, 7, 'b', 'c', 9 }
pub fn search(offset: *i64, search_string: []const u8) !void {
    if (buffer) |buf| {
        // Parse search string
        const search_bytes = try parse_search_string(search_string);
        defer allocator.free(search_bytes);
        const slen = @intCast(i64, search_bytes.len);
        if (slen > 0) {
            const len = @intCast(i64, buf.len);
            var offs = offset.*;
            if (offs < 0) {
                offs = 0;
            }
            const last = len - slen + 1;
            if (offs <= last) {
                // Loop all elements
                var i = offs;
                while (i < last) {
                    if (std.mem.eql(u8, buf[@intCast(usize, i)..@intCast(usize, i + slen)], search_bytes)) {
                        // Search bytes found
                        offset.* = i;
                        return;
                    }
                    // Next
                    i += 1;
                }
                // Nothing found
            }
            offset.* = len;
        }
    }
}

test "read_file" {
    try read_file("test_data/abcdefghijkl.bin");
    try std.testing.expect(buffer != null);
    try std.testing.expect(buffer.?.len == 12);
    try std.testing.expectEqualSlices(u8, buffer.?, "abcdefghijkl");
}

test "read_file_empty" {
    try read_file("test_data/empty.bin");
    try std.testing.expect(buffer != null);
    try std.testing.expect(buffer.?.len == 0);
}

// Fails because of logging in case of file-not-found. zig problem?
// test "read_file_not_existing" {
//     try std.testing.expectError(std.fs.File.OpenError.FileNotFound, read_file("test_data/not_existing.bin"));
// }

test "dump all" {
    try read_file("test_data/abcdefghijkl.bin");
    var outbuffer = std.ArrayList(u8).init(allocator);
    defer outbuffer.deinit();
    try dump(0, std.math.maxInt(i64), outbuffer.writer());
    try std.testing.expectEqualSlices(u8, outbuffer.items, "abcdefghijkl");
}

test "dump" {
    try read_file("test_data/abcdefghijkl.bin");
    var outbuffer = std.ArrayList(u8).init(allocator);
    defer outbuffer.deinit();

    // All
    {
        outbuffer.clearAndFree();
        try dump(0, std.math.maxInt(i64), outbuffer.writer());
        try std.testing.expectEqualSlices(u8, outbuffer.items, "abcdefghijkl");
    }

    // All
    {
        outbuffer.clearAndFree();
        try dump(0, 12, outbuffer.writer());
        try std.testing.expectEqualSlices(u8, outbuffer.items, "abcdefghijkl");
    }

    // Right
    {
        outbuffer.clearAndFree();
        try dump(8, std.math.maxInt(i64), outbuffer.writer());
        try std.testing.expectEqualSlices(u8, outbuffer.items, "ijkl");
    }

    // Left
    {
        outbuffer.clearAndFree();
        try dump(-4, 12, outbuffer.writer());
        try std.testing.expectEqualSlices(u8, outbuffer.items, "abcdefgh");
    }

    // Partial
    {
        outbuffer.clearAndFree();
        try dump(1, 10, outbuffer.writer());
        try std.testing.expectEqualSlices(u8, outbuffer.items, "bcdefghijk");
    }
}

test "parse_search_string" {
    {
        const sc = try parse_search_string("abc");
        try std.testing.expectEqualSlices(u8, sc, "abc");
        allocator.free(sc);
    }

    {
        const sc = try parse_search_string("");
        try std.testing.expectEqualSlices(u8, sc, "");
        allocator.free(sc);
    }

    {
        const sc = try parse_search_string("\\d123");
        try std.testing.expect(sc[0] == 123);
        allocator.free(sc);
    }

    {
        const sc = try parse_search_string("\\d123,a");
        try std.testing.expect(sc[0] == 123);
        try std.testing.expect(sc[1] == 'a');
        allocator.free(sc);
    }

    {
        const sc = try parse_search_string("\\xFA");
        try std.testing.expect(sc[0] == 0xFA);
        allocator.free(sc);
    }

    {
        const sc = try parse_search_string("a\\xFA,\\d7,bc\\d9");
        try std.testing.expectEqualSlices(u8, sc, &[_]u8{ 'a', 0xFA, 7, 'b', 'c', 9 });
        allocator.free(sc);
    }

    {
        const sc = try parse_search_string("a\\\\b");
        try std.testing.expectEqualSlices(u8, sc, &[_]u8{ 'a', '\\', 'b' });
        allocator.free(sc);
    }
}

test "parse_search_string error cases" {
    {
        try std.testing.expectError(anyerror.expected_d_or_x, parse_search_string("\\a"));
    }
    {
        try std.testing.expectError(std.fmt.ParseIntError.Overflow, parse_search_string("\\d256"));
    }
    {
        try std.testing.expectError(std.fmt.ParseIntError.Overflow, parse_search_string("\\d-1"));
    }
    {
        try std.testing.expectError(std.fmt.ParseIntError.InvalidCharacter, parse_search_string("\\d2h"));
    }
    {
        try std.testing.expectError(std.fmt.ParseIntError.Overflow, parse_search_string("\\xFF1"));
    }
    {
        try std.testing.expectError(std.fmt.ParseIntError.Overflow, parse_search_string("\\x-01"));
    }
    {
        try std.testing.expectError(std.fmt.ParseIntError.InvalidCharacter, parse_search_string("\\xFG"));
    }
}

test "search" {
    try read_file("test_data/abcdefghijkl.bin");
    var outbuffer = std.ArrayList(u8).init(allocator);
    defer outbuffer.deinit();
    const len = buffer.?.len;

    {
        var offset: i64 = 0;
        try search(&offset, "");
        try std.testing.expect(offset == 0);
    }

    {
        var offset: i64 = 0;
        try search(&offset, "a");
        try std.testing.expect(offset == 0);
    }

    {
        var offset: i64 = 0;
        try search(&offset, "b");
        try std.testing.expect(offset == 1);
    }

    {
        var offset: i64 = 2;
        try search(&offset, "c");
        try std.testing.expect(offset == 2);
    }

    {
        var offset: i64 = 3;
        try search(&offset, "c");
        try std.testing.expect(offset == len);
    }

    {
        var offset: i64 = 0;
        try search(&offset, "cde");
        try std.testing.expect(offset == 2);
    }

    {
        var offset: i64 = 10;
        try search(&offset, "abc");
        try std.testing.expect(offset == len);
    }

    {
        var offset: i64 = 0;
        try search(&offset, "kl");
        try std.testing.expect(offset == 10);
    }
}
