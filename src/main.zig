const std = @import("std");
const os = @import("os.zig");
const kernel = @import("kernel.zig");

pub fn os_main() void {
    os.println("Welcome", .{});

    // Should panic
    // @panic("Whoops!");

    var arena = std.heap.ArenaAllocator.init(os.OsAllocator());
    var arr = std.ArrayList(usize).init(arena.allocator());

    for (0..256) |x| {
        arr.append(x) catch @panic("Memory Error");
    }

    while (true) {
        os.println("Current time: {}", .{os.time()});
        arr.append(0) catch @panic("Memory Error");
    }
}
