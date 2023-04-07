# Cheatsheet


# Pointers etc.

- [5]u8 - array, internally represented by a pointer only, length is known during compile time.
- []u8 - slice, pointer+length, does nto own the memory.
- *u8 - pointer
- [*]u8 - pointer with unknown length (like c-pointers). Is possible to iterate over.
- *[5]u8 - pointer to an array = *u8

Pointers cannot be null. Therefore combine with "optional":
- ?*u8 - pointer or null
- ?[*]u8) - the same
- *?u8 - pointing to null or u8


& - gives the pointer of e.g. an array.
* - gets the value of a pointer. Is used after the variable:
~~~
p.* = Person { .beans = 0 };
~~~
For simple value pointers:
~~~
p.* = 0;
~~~


## strings

There is no explicit string type. A string is: [:0]u8
I.e. a pointer to an u8 slice that is terminated with 0.
0 is here the so.called sentinel or terminator.


## Optionals

A pointer can be defined as
~~~
var p: ?*u8 = null;
~~~

To use the value it needs to be unwrapped with:
~~~
if(p) |ptr| {
	allocator.free(ptr);
}
~~~

In this example ptr gets the type *u8.


# @This

@This() returns the type of the inner most struct/enum/union. For example, the following prints "true":

~~~
const Tea = struct {
  const Self = @This();
};
~~~


# Errors

## Returning errors

~~~
const MyError = error { first_error };
pub fn func() -> MyError!i32 {
	... return MyError.first_error;
	... return 5;
}
~~~

or simpler

~~~
fn func() -> !i32 {
	... return anyerror.first_error;
	... return 5;
}
~~~


## forwarding errors

~~~
fn b() -> !void {
	const x = try func();
}
~~~


## catching errors

~~~
const x = func() catch {
	... do something
}
~~~

Kind of an assert like in C:
~~~
const x = func() catch unreachable;
~~~

Do something with the error:
~~~
const x = func() catch |err| {
	...;
	return;
}
~~~


# Unit tests

Add to your file:
~~~

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
~~~

And add file/test to the build in build.zig:
~~~
    const test_step = b.step("test", "Run unit tests");
    var exe_tests = b.addTest("src/bin_dumper.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);
    test_step.dependOn(&exe_tests.step);
~~~

## vscode

vscode, at the moment (2023), has o support for unit tests for zig.
