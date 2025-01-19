const std = @import("std");
const sbi = @import("sbi.zig");

/// Implementation of the GenericWriter interface.
const ConsoleWriter = std.io.Writer(
    void,
    error{},
    struct {
        fn writeFn(context: void, buffer: []const u8) error{}!usize {
            _ = context;
            return write(buffer);
        }
    }.writeFn,
){
    .context = undefined,
};

/// Write `buffer` to the serial console via the SBI
pub fn write(buffer: []const u8) usize {
    var i: usize = 0;
    for (buffer) |c| {
        const ret = sbi.put_char(c);
        if (ret.err != .SBI_SUCCESS) {
            return i;
        }
        i += 1;
    }

    return i;
}

pub fn print(comptime fmt: []const u8, args: anytype) void {
    std.fmt.format(ConsoleWriter, fmt, args) catch @panic("Couldn't format string");
}

pub fn println(comptime fmt: []const u8, args: anytype) void {
    print(fmt ++ "\n", args);
}
