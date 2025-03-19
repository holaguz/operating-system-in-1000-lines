const std = @import("std");
const cpu = @import("cpu.zig");
const kernel = @import("kernel.zig");
// const dtb = @import("dtb");

pub fn OsAllocator() std.mem.Allocator {
    return kernel.KernelAlloc.allocator();
}

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
        kernel.put_char(c) catch return i;
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

pub fn time() u32 {
    return cpu.read_csr("time");
}
