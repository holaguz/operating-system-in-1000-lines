const std = @import("std");
const os = @import("os.zig");
const kernel = @import("kernel.zig");

pub fn os_main() void {
    os.println("Welcome", .{});

    // Should panic
    // @panic("Whoops!");

    while (true) {
        // os.println("Current time: {}", .{os.time()});
        // asm volatile ("wfi");
    }
}
