const std = @import("std");
const os = @import("os.zig");

pub fn os_main() void {
    os.println("{} + {} = {}", .{ 30, 39, 30 + 39 });

    // Should panic
    // @panic("Whoops!");

    while (true) {
        os.println("Current time: {}", .{os.time()});
        // asm volatile ("wfi");
    }
}
