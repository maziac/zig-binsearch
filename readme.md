# binsearch

A binary search command line tool.
The tool allows you to specify one (or more files) and dump out values to stdout from a specific offset ad for a specific size.
It is also possible to search for patterns to set the offset.

The output is written to stdout and can be redirected into a file or piped to another command.



# Arguments

- "**--help**": Prints the help.
- "**--version**": Prints the version number.
- "**--offs** offset": Offset from start of file. Moves last position. You can also move relatively by prefixinge with + or -.
- "**--size** size": The number of bytes to output. Moves last position.
- "**--search** tokens": Searches for the first occurrence of the tokens. The search starts at last position. Tokens can be a decimal of hex number or a string. The search starts at last position.

Examples:
- "binsearch --offs 10 --size 100": Outputs the bytes from position 10 to 109.
- "binsearch --offs 10 --size 100 --offs 200 --size 10": Outputs the bytes from position 10 to 109, directly followed by 200 to 209.
- "binsearch --offs 10 --size 100 --offs +10 --size 20": Outputs the bytes from position 10 to 109, directly followed by 120 to 129.
- "binsearch --search abc --size 10": Outputs 10 bytes from the first occurrence of 'abc'.
- "binsearch --search \d130 --size 10": Outputs 10 bytes from the first occurrence of decimal number 130. Only bytes are searched.
- "binsearch --search \xFF --size 10": Outputs 10 bytes from the first occurrence of hex number 0xFF. Only bytes are searched.
- "binsearch --search abc\xFF,xyz\d0 --size 10": Outputs 10 bytes from the first occurrence of the sequence 97,98,99,255,120,121,122,0. Only bytes are searched.
Please note: when searching for a sequence of bytes, a 0 is **not** automatically added at the end.


# Developemnt

## Debug build

~~~
zig build
~~~

Or through vscode's tasks.json "debug build".

The binary is found at "zig-out/bin/binsearch".


## Release build

~~~
zig build -Drelease-fast=true
~~~

Or through vscode's tasks.json "cross build".

This will execute release builds for macos, linux and windows.
The binary are found at "zig-out/bin":
- binsearch-linux
- binsearch-macos
- binsearch-windows


## Unit tests

To run unitests use
~~~
zig build test
~~~



