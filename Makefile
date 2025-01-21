KERNEL = zig-out/bin/kernel
QEMU = qemu-system-riscv32

DEPS = $(wildcard src/**)
DEPS += build.zig


$(KERNEL): $(DEPS)
	zig build --summary all --verbose --verbose-cc --verbose-link

run: $(KERNEL)
	$(QEMU) -machine virt -bios default -nographic -serial mon:stdio --no-reboot -kernel $(KERNEL)

gdb: $(KERNEL)
	$(QEMU) -machine virt -bios default -nographic -serial mon:stdio --no-reboot -kernel $(KERNEL) -s -S

decomp: $(KERNEL)
	llvm-objdump -dS $(KERNEL)

syms: $(KERNEL)
	llvm-nm $(KERNEL)
