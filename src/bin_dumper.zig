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
    var file = try std.fs.cwd().openFile(spath, .{});
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

/// The function `addOne` adds one to the number given as its argument.
fn addOne(number: i32) i32 {
    return number + 1;
}

test "expect addOne adds one to 41" {

    // The Standard Library contains useful functions to help create tests.
    // `expect` is a function that verifies its argument is true.
    // It will return an error if its argument is false to indicate a failure.
    // `try` is used to return an error to the test runner to notify it that the test failed.
    try std.testing.expect(addOne(41) == 42);
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

test "read_file_not_existing" {
    try std.testing.expectError(std.fs.File.OpenError.FileNotFound, read_file("test_data/not_existing.bin"));
}

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
