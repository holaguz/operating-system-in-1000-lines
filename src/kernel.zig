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

/// Whether we should try to parse the DT blob to extract information about
/// the memory layout of the hardware. The extracted information is used to
/// relocate the stack pointer and heap.
const DYNAMIC_MEMORY_CONFIG = true;

const MemoryInfo = struct {
    base: usize,
    length: usize,
};

/// The CPU context. Must respect the order of save in the `call_trap_handler`
/// stub.
const TrapFrame = struct {
    ra: u32,
    gp: u32,
    tp: u32,
    t0: u32,
    t1: u32,
    t2: u32,
    t3: u32,
    t4: u32,
    t5: u32,
    t6: u32,
    a0: u32,
    a1: u32,
    a2: u32,
    a3: u32,
    a4: u32,
    a5: u32,
    a6: u32,
    a7: u32,
    s0: u32,
    s1: u32,
    s2: u32,
    s3: u32,
    s4: u32,
    s5: u32,
    s6: u32,
    s7: u32,
    s8: u32,
    s9: u32,
    s10: u32,
    s11: u32,
    sp: u32,
};

var ALREADY_PANICKING: bool = false;

/// The entry point of our program.
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
    cpu.write_csr("stvec", @intFromPtr(&call_trap_handler));

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

fn parse_dtb(dtb_address_: usize) !MemoryInfo {
    // Ensure the given address contains a DT blob
    const dtb_magic = std.mem.readInt(u32, @ptrFromInt(dtb_address_), .big);
    if (dtb_magic != 0xd00dfeed) {
        os.println("DTB Header Magic not found", .{});
        return error.DtbNotFound;
    }

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
    const dt = dtb.parse(alloc, dtb_slice) catch |err| {
        os.println("Failed parsing the DTB", .{});
        return err;
    };

    const memory_node: *dtb.Node = for (dt.children) |node| {
        if (std.mem.startsWith(u8, node.name, "memory")) {
            break node;
        }
    } else return error.MemoryNodeNotFound;

    os.println("{any}", .{dt});
    os.println("Memory info: {any}", .{memory_node});

    return .{
        .base = 0,
        .length = 0,
    };
}

fn call_trap_handler() align(4) callconv(.Naked) void {
    asm volatile (
        \\   csrw sscratch, sp      // save the current CPU context
        \\   addi sp, sp, -4 * 31
        \\   sw ra,  4 * 0(sp)
        \\   sw gp,  4 * 1(sp)
        \\   sw tp,  4 * 2(sp)
        \\   sw t0,  4 * 3(sp)
        \\   sw t1,  4 * 4(sp)
        \\   sw t2,  4 * 5(sp)
        \\   sw t3,  4 * 6(sp)
        \\   sw t4,  4 * 7(sp)
        \\   sw t5,  4 * 8(sp)
        \\   sw t6,  4 * 9(sp)
        \\   sw a0,  4 * 10(sp)
        \\   sw a1,  4 * 11(sp)
        \\   sw a2,  4 * 12(sp)
        \\   sw a3,  4 * 13(sp)
        \\   sw a4,  4 * 14(sp)
        \\   sw a5,  4 * 15(sp)
        \\   sw a6,  4 * 16(sp)
        \\   sw a7,  4 * 17(sp)
        \\   sw s0,  4 * 18(sp)
        \\   sw s1,  4 * 19(sp)
        \\   sw s2,  4 * 20(sp)
        \\   sw s3,  4 * 21(sp)
        \\   sw s4,  4 * 22(sp)
        \\   sw s5,  4 * 23(sp)
        \\   sw s6,  4 * 24(sp)
        \\   sw s7,  4 * 25(sp)
        \\   sw s8,  4 * 26(sp)
        \\   sw s9,  4 * 27(sp)
        \\   sw s10, 4 * 28(sp)
        \\   sw s11, 4 * 29(sp)
        \\
        \\   csrr a0, sscratch
        \\   sw a0, 4 * 30(sp)
        \\
        \\   mv a0, sp
        \\   call handle_trap       // call the trap handler
        \\
        \\   lw ra,  4 * 0(sp)      // recover the saved context
        \\   lw gp,  4 * 1(sp)
        \\   lw tp,  4 * 2(sp)
        \\   lw t0,  4 * 3(sp)
        \\   lw t1,  4 * 4(sp)
        \\   lw t2,  4 * 5(sp)
        \\   lw t3,  4 * 6(sp)
        \\   lw t4,  4 * 7(sp)
        \\   lw t5,  4 * 8(sp)
        \\   lw t6,  4 * 9(sp)
        \\   lw a0,  4 * 10(sp)
        \\   lw a1,  4 * 11(sp)
        \\   lw a2,  4 * 12(sp)
        \\   lw a3,  4 * 13(sp)
        \\   lw a4,  4 * 14(sp)
        \\   lw a5,  4 * 15(sp)
        \\   lw a6,  4 * 16(sp)
        \\   lw a7,  4 * 17(sp)
        \\   lw s0,  4 * 18(sp)
        \\   lw s1,  4 * 19(sp)
        \\   lw s2,  4 * 20(sp)
        \\   lw s3,  4 * 21(sp)
        \\   lw s4,  4 * 22(sp)
        \\   lw s5,  4 * 23(sp)
        \\   lw s6,  4 * 24(sp)
        \\   lw s7,  4 * 25(sp)
        \\   lw s8,  4 * 26(sp)
        \\   lw s9,  4 * 27(sp)
        \\   lw s10, 4 * 28(sp)
        \\   lw s11, 4 * 29(sp)
        \\   lw sp,  4 * 30(sp)
        \\   sret
    );
}

/// The trap handler. Doesn't really handle any traps yet, just prints to console.
/// Marked as `export` to make it easily accessible on `call_trap_handler`.
export fn handle_trap(f: *TrapFrame) callconv(.C) void {
    const scause = cpu.read_csr("scause");
    const stval = cpu.read_csr("stval");
    const user_pc = cpu.read_csr("sepc");

    const scause_str = if (cpu.TrapCause.fromId(scause)) |cause| cause.asString() else "UnknownTrap";

    os.println("unexpected trap - scause={} ({s}), stval={}, user_pc=0x{x:08}\nstack frame: {any}", .{ scause, scause_str, stval, user_pc, f });
    @panic("unexpected trap");
}
