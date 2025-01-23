const std = @import("std");
const main = @import("main.zig");
const os = @import("os.zig");
const cpu = @import("cpu.zig");
const dtb = @import("dtb");

// Declare linker symbols to be used in Zig functions.
extern var __bss_start: usize;
extern const __bss_size: usize;
extern const __bss_end: usize;
extern const __stack_top: usize;

// Whether we should try to parse the DT blob to extract information about
// the memory layout of the hardware. The extracted information is used to
// relocate the stack pointer and heap.
const DYNAMIC_MEMORY_CONFIG = true;

const MemoryInfo = struct {
    base: usize,
    length: usize,
};

var ALREADY_PANICKING: bool = false;

export fn _start() linksection(".boot") callconv(.Naked) void {
    // Preserve a0 and a1 because if we're booting from OpenSBI
    // they hold valuable information.
    asm volatile (
        \\ lui a2, %hi(__stack_top)         // a2 = initial sp
        \\ addi a2, a2, %lo(__stack_top)
        \\ mv sp, a2                        // set the stack pointer
        \\
        \\ lui a3, %hi(kernel_main)         // a3 = kernel entry point
        \\ addi a3, a3, %lo(kernel_main)
        \\ jr a3                            // jump to the kernel main
        ::: "memory");
}

export fn kernel_main(hartid: usize, dtb_address: usize) void {
    // OpenSBI provides the following:
    // a0: hartid
    // a1: device-tree blob address
    // These arguments might not hold true on platforms not running OpenSBI!

    _ = hartid;
    _ = dtb_address;

    // Install the Exception Handler
    cpu.write_csr("stvec", @intFromPtr(&os.kernel_entry));

    // Clear the BSS section
    const bss_size = @intFromPtr(&__bss_size);
    const bss: [*]volatile u8 = @ptrCast(&__bss_start);
    for (0..bss_size) |b| bss[b] = 0;
    main.os_main();
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    _ = error_return_trace;

    if (!ALREADY_PANICKING) {
        ALREADY_PANICKING = true;
        os.println("KERNEL PANIC: {s}", .{msg});
    }

    while (true) {}
}

pub fn put_char(chr: u8) !void {
    const ret = cpu.syscall_1(chr, 0x00, 0x01);
    return if (ret.err != cpu.SbiError.SBI_SUCCESS)
        error.SyscallError;
}

fn parse_dtb(dtb_address_: usize) void {
    // Ensure the given address contains a DT blob
    const dtb_magic = std.mem.readInt(u32, @ptrFromInt(dtb_address_), .big);
    if (dtb_magic != 0xd00dfeed) os.println("DTB Header Magic not found", .{});

    // The full size of the DTB is specified on offset 4
    const dtb_size = std.mem.readInt(u32, @ptrFromInt(dtb_address_ + 4), .big);
    os.println("Found DTB with size {}", .{dtb_size});

    // Create a proper slice using the address and known size
    const dtb_slice: []const u8 = @as([*]const u8, @ptrFromInt(dtb_address_))[0..dtb_size];

    // Allocate memory on the stack to store the DT
    var alloc_base: [1024 * 16]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&alloc_base);
    const alloc = fba.allocator();

    // Try to parse the DT blob
    const dt = dtb.parse(alloc, dtb_slice) catch {
        os.println("Failed parsing the DTB", .{});
        return;
    };

    const memory_node: ?*dtb.Node = for (dt.children) |node| {
        if (std.mem.startsWith(u8, node.name, "memory")) {
            break node;
        }
    } else null;

    os.println("{any}", .{dt});
    os.println("Memory info: {any}", .{memory_node});
}
