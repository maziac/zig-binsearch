# Cheatsheet


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
