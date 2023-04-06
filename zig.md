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
