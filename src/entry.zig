const std = @import("std");
const main = @import("main.zig");
const os = @import("os.zig");

extern var __bss_start: usize;
extern const __bss_size: usize;
extern const __bss_end: usize;
extern const __stack_top: usize;

var ALREADY_PANICKING: bool = false;

export fn _start() linksection(".boot") void {
    asm volatile ("mv sp, %[initial_sp]"
        :
        : [initial_sp] "r" (&__stack_top),
        : "sp"
    );

    const bss_size = @intFromPtr(&__bss_size);
    const bss: [*]volatile u8 = @ptrCast(&__bss_start);
    for (0..bss_size) |b| bss[b] = 0;

    asm volatile ("jr %[main]"
        :
        : [main] "r" (@intFromPtr(&main.os_main)),
    );
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    _ = error_return_trace;

    if (!ALREADY_PANICKING) {
        ALREADY_PANICKING = true;
        os.println("KERNEL PANIC: {s}", .{msg});
    }

    while (true) {}
}
