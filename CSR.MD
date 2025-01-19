
# RISC-V CSR Listing

## Table 3. Allocation of RISC-V CSR Address Ranges

| CSR Address Hex | Use and Accessibility |
|-----------------|-----------------------|
| **Unprivileged and User-Level CSRs** | |
| `0x000-0x0FF`   | Standard read/write   |
| `0x400-0x4FF`   | Standard read/write   |
| `0x800-0x8FF`   | Custom read/write     |
| `0xC00-0xC7F`   | Standard read-only    |
| `0xC80-0xCBF`   | Standard read-only    |
| `0xCC0-0xCFF`   | Custom read-only      |
| **Supervisor-Level CSRs** | |
| `0x100-0x1FF`   | Standard read/write   |
| `0x500-0x57F`   | Standard read/write   |
| `0x580-0x5BF`   | Standard read/write   |
| `0x5C0-0x5FF`   | Custom read/write     |
| `0x900-0x97F`   | Standard read/write   |
| `0x980-0x9BF`   | Standard read/write   |
| `0x9C0-0x9FF`   | Custom read/write     |
| `0xD00-0xD7F`   | Standard read-only    |
| `0xD80-0xDBF`   | Standard read-only    |
| `0xDC0-0xDFF`   | Custom read-only      |
| **Hypervisor and VS CSRs** | |
| `0x200-0x2FF`   | Standard read/write   |
| `0x600-0x67F`   | Standard read/write   |
| `0x680-0x6BF`   | Standard read/write   |
| `0x6C0-0x6FF`   | Custom read/write     |
| `0xA00-0xA7F`   | Standard read/write   |
| `0xA80-0xABF`   | Standard read/write   |
| `0xAC0-0xAFF`   | Custom read/write     |
| `0xE00-0xE7F`   | Standard read-only    |
| `0xE80-0xEBF`   | Standard read-only    |
| `0xEC0-0xEFF`   | Custom read-only      |
| **Machine-Level CSRs** | |
| `0x300-0x3FF`   | Standard read/write   |
| `0x700-0x77F`   | Standard read/write   |
| `0x780-0x79F`   | Standard read/write   |
| `0x7A0-0x7AF`   | Standard read/write debug CSRs |
| `0x7B0-0x7BF`   | Debug-mode-only CSRs  |
| `0x7C0-0x7FF`   | Custom read/write     |
| `0xB00-0xB7F`   | Standard read/write   |
| `0xB80-0xBBF`   | Standard read/write   |
| `0xBC0-0xBFF`   | Custom read/write     |
| `0xF00-0xF7F`   | Standard read-only    |
| `0xF80-0xFBF`   | Standard read-only    |
| `0xFC0-0xFFF`   | Custom read-only      |

---

## Table 4. Currently Allocated RISC-V Unprivileged CSR Addresses

| Number | Privilege | Name      | Description |
|--------|-----------|-----------|-------------|
| **Unprivileged Floating-Point CSRs** | | | |
| `0x001` | URW       | `fflags`  | Floating-Point Accrued Exceptions. |
| `0x002` | URW       | `frm`     | Floating-Point Dynamic Rounding Mode. |
| `0x003` | URW       | `fcsr`    | Floating-Point Control and Status Register (frm + fflags). |
| **Unprivileged Vector CSRs** | | | |
| `0x008` | URW       | `vstart`  | Vector start position. |
| `0x009` | URW       | `vxsat`   | Fixed-point accrued saturation flag. |
| `0x00A` | URW       | `vxrm`    | Fixed-point rounding mode. |
| `0x00F` | URW       | `vcsr`    | Vector control and status register. |
| `0xC20` | URO       | `vl`      | Vector length. |
| `0xC21` | URO       | `vtype`   | Vector data type register. |
| `0xC22` | URO       | `vlenb`   | Vector register length in bytes. |
| **Unprivileged Zicfiss Extension CSR** | | | |
| `0x011` | URW       | `ssp`     | Shadow Stack Pointer. |
| **Unprivileged Entropy Source Extension CSR** | | | |
| `0x015` | URW       | `seed`    | Seed for cryptographic random bit generators. |
| **Unprivileged Zcmt Extension CSR** | | | |
| `0x017` | URW       | `jvt`     | Table jump base vector and control register. |
| **Unprivileged Counter/Timers** | | | |
| `0xC00` | URO       | `cycle`   | Cycle counter for RDCYCLE instruction. |
| `0xC01` | URO       | `time`    | Timer for RDTIME instruction. |
| `0xC02` | URO       | `instret` | Instructions-retired counter for RDINSTRET instruction. |
| `0xC03` | URO       | `hpmcounter3` | Performance-monitoring counter. |
| `0xC04` | URO       | `hpmcounter4` | Performance-monitoring counter. |
| `⋮`    | URO       | `⋮`       | Performance-monitoring counter. |
| `0xC1F` | URO       | `hpmcounter31` | Performance-monitoring counter. |
| `0xC80` | URO       | `cycleh`  | Upper 32 bits of cycle, RV32 only. |
| `0xC81` | URO       | `timeh`   | Upper 32 bits of time, RV32 only. |
| `0xC82` | URO       | `instreth` | Upper 32 bits of instret, RV32 only. |
| `0xC83` | URO       | `hpmcounter3h` | Upper 32 bits of hpmcounter3, RV32 only. |
| `0xC84` | URO       | `hpmcounter4h` | Upper 32 bits of hpmcounter4, RV32 only. |
| `⋮`    | URO       | `⋮`       | Upper 32 bits of hpmcounter31, RV32 only. |
| `0xC9F` | URO       | `hpmcounter31h` | Upper 32 bits of hpmcounter31, RV32 only. |

---

## Table 5. Currently Allocated RISC-V Supervisor-Level CSR Addresses

| Number | Privilege | Name          | Description |
|--------|-----------|---------------|-------------|
| **Supervisor Trap Setup** | | | |
| `0x100` | SRW       | `sstatus`     | Supervisor status register. |
| `0x104` | SRW       | `sie`         | Supervisor interrupt-enable register. |
| `0x105` | SRW       | `stvec`       | Supervisor trap handler base address. |
| `0x106` | SRW       | `scounteren`  | Supervisor counter enable. |
| **Supervisor Configuration** | | | |
| `0x10A` | SRW       | `senvcfg`     | Supervisor environment configuration register. |
| **Supervisor Counter Setup** | | | |
| `0x120` | SRW       | `scountinhibit` | Supervisor counter-inhibit register. |
| **Supervisor Trap Handling** | | | |
| `0x140` | SRW       | `sscratch`    | Supervisor scratch register. |
| `0x141` | SRW       | `sepc`        | Supervisor exception program counter. |
| `0x142` | SRW       | `scause`      | Supervisor trap cause. |
| `0x143` | SRW       | `stval`       | Supervisor trap value. |
| `0x144` | SRW       | `sip`         | Supervisor interrupt pending. |
| `0xDA0` | SRO       | `scountovf`   | Supervisor count overflow. |
| **Supervisor Protection and Translation** | | | |
| `0x180` | SRW       | `satp`        | Supervisor address translation and protection. |
| **Debug/Trace Registers** | | | |
| `0x5A8` | SRW       | `scontext`    | Supervisor-mode context register. |
| **Supervisor State Enable Registers** | | | |
| `0x10C` | SRW       | `sstateen0`   | Supervisor State Enable 0 Register. |
| `0x10D` | SRW       | `sstateen1`   | Supervisor State Enable 1 Register. |
| `0x10E` | SRW       | `sstateen2`   | Supervisor State Enable 2 Register. |
| `0x10F` | SRW       | `sstateen3`   | Supervisor State Enable 3 Register. |

---

## Table 6. Currently Allocated RISC-V Hypervisor and VS CSR Addresses

| Number | Privilege | Name          | Description |
|--------|-----------|---------------|-------------|
| **Hypervisor Trap Setup** | | | |
| `0x600` | HRW       | `hstatus`     | Hypervisor status register. |
| `0x602` | HRW       | `hedeleg`     | Hypervisor exception delegation register. |
| `0x603` | HRW       | `hideleg`     | Hypervisor interrupt delegation register. |
| `0x604` | HRW       | `hie`         | Hypervisor interrupt-enable register. |
| `0x606` | HRW       | `hcounteren`  | Hypervisor counter enable. |
| `0x607` | HRW       | `hgeie`       | Hypervisor guest external interrupt-enable register. |
| `0x612` | HRW       | `hedelegh`    | Upper 32 bits of hedeleg, RV32 only. |
| **Hypervisor Trap Handling** | | | |
| `0x643` | HRW       | `htval`       | Hypervisor trap value. |
| `0x644` | HRW       | `hip`         | Hypervisor interrupt pending. |
| `0x645` | HRW       | `hvip`        | Hypervisor virtual interrupt pending. |
| `0x64A` | HRW       | `htinst`      | Hypervisor trap instruction (transformed). |
| `0xE12` | HRO       | `hgeip`       | Hypervisor guest external interrupt pending. |
| **Hypervisor Configuration** | | | |
| `0x60A` | HRW       | `henvcfg`     | Hypervisor environment configuration register. |
| `0x61A` | HRM       | `henvcfgh`    | Upper 32 bits of henvcfg, RV32 only. |
| **Hypervisor Protection and Translation** | | | |
| `0x680` | HRW       | `hgatp`       | Hypervisor guest address translation and protection. |
| **Debug/Trace Registers** | | | |
| `0x6A8` | HRW       | `hcontext`    | Hypervisor-mode context register. |
| **Hypervisor Counter/Timer Virtualization Registers** | | | |
| `0x605` | HRW       | `htimedelta`  | Delta for VS/VU-mode timer. |
| `0x615` | HRW       | `htimedeltah` | Upper 32 bits of htimedelta, RV32 only. |
| **Hypervisor State Enable Registers** | | | |
| `0x60C` | HRW       | `hstateen0`   | Hypervisor State Enable 0 Register. |
| `0x60D` | HRW       | `hstateen1`   | Hypervisor State Enable 1 Register. |
| `0x60E` | HRW       | `hstateen2`   | Hypervisor State Enable 2 Register. |
| `0x60F` | HRW       | `hstateen3`   | Hypervisor State Enable 3 Register. |
| `0x61C` | HRW       | `hstateen0h`  | Upper 32 bits of Hypervisor State Enable 0 Register, RV32 only. |
| `0x61D` | HRW       | `hstateen1h`  | Upper 32 bits of Hypervisor State Enable 1 Register, RV32 only. |
| `0x61E` | HRW       | `hstateen2h`  | Upper 32 bits of Hypervisor State Enable 2 Register, RV32 only. |
| `0x61F` | HRW       | `hstateen3h`  | Upper 32 bits of Hypervisor State Enable 3 Register, RV32 only. |
| **Virtual Supervisor Registers** | | | |
| `0x200` | HRW       | `vsstatus`    | Virtual supervisor status register. |
| `0x204` | HRW       | `vsie`        | Virtual supervisor interrupt-enable register. |
| `0x205` | HRW       | `vstvec`      | Virtual supervisor trap handler base address. |
| `0x240` | HRW       | `vsscratch`   | Virtual supervisor scratch register. |
| `0x241` | HRW       | `vsepc`       | Virtual supervisor exception program counter. |
| `0x242` | HRW       | `vscause`     | Virtual supervisor trap cause. |
| `0x243` | HRW       | `vstval`      | Virtual supervisor trap value. |
| `0x244` | HRW       | `vsip`        | Virtual supervisor interrupt pending. |
| `0x280` | HRW       | `vsatp`       | Virtual supervisor address translation and protection. |

---

## Table 7. Currently Allocated RISC-V Machine-Level CSR Addresses

| Number | Privilege | Name          | Description |
|--------|-----------|---------------|-------------|
| **Machine Information Registers** | | | |
| `0xF11` | MRO       | `mvendorid`   | Vendor ID. |
| `0xF12` | MRO       | `marchid`     | Architecture ID. |
| `0xF13` | MRO       | `mimpid`      | Implementation ID. |
| `0xF14` | MRO       | `mhartid`     | Hardware thread ID. |
| `0xF15` | MRO       | `mconfigptr`  | Pointer to configuration data structure. |
| **Machine Trap Setup** | | | |
| `0x300` | MRW       | `mstatus`     | Machine status register. |
| `0x301` | MRW       | `misa`        | ISA and extensions. |
| `0x302` | MRW       | `medeleg`     | Machine exception delegation register. |
| `0x303` | MRW       | `mideleg`     | Machine interrupt delegation register. |
| `0x304` | MRW       | `mie`         | Machine interrupt-enable register. |
| `0x305` | MRW       | `mtvec`       | Machine trap-handler base address. |
| `0x306` | MRW       | `mcounteren`  | Machine counter enable. |
| `0x310` | MRW       | `mstatush`    | Additional machine status register, RV32 only. |
| `0x312` | MRW       | `medelegh`    | Upper 32 bits of medeleg, RV32 only. |
| **Machine Trap Handling** | | | |
| `0x340` | MRW       | `mscratch`    | Machine scratch register. |
| `0x341` | MRW       | `mepc`        | Machine exception program counter. |
| `0x342` | MRW       | `mcause`      | Machine trap cause. |
| `0x343` | MRW       | `mtval`       | Machine trap value. |
| `0x344` | MRW       | `mip`         | Machine interrupt pending. |
| `0x34A` | MRW       | `mtinst`      | Machine trap instruction (transformed). |
| `0x34B` | MRW       | `mtval2`      | Machine second trap value. |
| **Machine Configuration** | | | |
| `0x30A` | MRW       | `menvcfg`     | Machine environment configuration register. |
| `0x31A` | MRW       | `menvcfgh`    | Upper 32 bits of menvcfg, RV32 only. |
| `0x747` | MRW       | `mseccfg`     | Machine security configuration register. |
| `0x757` | MRW       | `mseccfgh`    | Upper 32 bits of mseccfg, RV32 only. |
| **Machine Memory Protection** | | | |
| `0x3A0` | MRW       | `pmpcfg0`     | Physical memory protection configuration. |
| `0x3A1` | MRW       | `pmpcfg1`     | Physical memory protection configuration, RV32 only. |
| `0x3A2` | MRW       | `pmpcfg2`     | Physical memory protection configuration. |
| `0x3A3` | MRW       | `pmpcfg3`     | Physical memory protection configuration, RV32 only. |
| `⋮`    | MRW       | `⋮`           | Physical memory protection configuration. |
| `0x3AE` | MRW       | `pmpcfg14`    | Physical memory protection configuration, RV32 only. |
| `0x3AF` | MRW       | `pmpcfg15`    | Physical memory protection configuration, RV32 only. |
| `0x3B0` | MRW       | `pmpaddr0`    | Physical memory protection address register. |
| `0x3B1` | MRW       | `pmpaddr1`    | Physical memory protection address register. |
| `⋮`    | MRW       | `⋮`           | Physical memory protection address register. |
| `0x3EF` | MRW       | `pmpaddr63`   | Physical memory protection address register. |
| **Machine State Enable Registers** | | | |
| `0x30C` | MRW       | `mstateen0`   | Machine State Enable 0 Register. |
| `0x30D` | MRW       | `mstateen1`   | Machine State Enable 1 Register. |
| `0x30E` | MRW       | `mstateen2`   | Machine State Enable 2 Register. |
| `0x30F` | MRW       | `mstateen3`   | Machine State Enable 3 Register. |
| `0x31C` | MRW       | `mstateen0h`  | Upper 32 bits of Machine State Enable 0 Register, RV32 only. |
| `0x31D` | MRW       | `mstateen1h`  | Upper 32 bits of Machine State Enable 1 Register, RV32 only. |
| `0x31E` | MRW       | `mstateen2h`  | Upper 32 bits of Machine State Enable 2 Register, RV32 only. |
| `0x31F` | MRW       | `mstateen3h`  | Upper 32 bits of Machine State Enable 3 Register, RV32 only. |

---

## Table 8. Currently Allocated RISC-V Machine-Level CSR Addresses

| Number | Privilege | Name          | Description |
|--------|-----------|---------------|-------------|
| **Machine Non-Maskable Interrupt Handling** | | | |
| `0x740` | MRW       | `mnscratch`   | Resumable NMI scratch register. |
| `0x741` | MRW       | `mnepc`       | Resumable NMI program counter. |
| `0x742` | MRW       | `mncause`     | Resumable NMI cause. |
| `0x744` | MRW       | `mnstatus`    | Resumable NMI status. |
| **Machine Counter/Timers** | | | |
| `0xB00` | MRW       | `mcycle`      | Machine cycle counter. |
| `0xB02` | MRW       | `minstret`    | Machine instructions-retired counter. |
| `0xB03` | MRW       | `mhpmcounter3` | Machine performance-monitoring counter. |
| `0xB04` | MRW       | `mhpmcounter4` | Machine performance-monitoring counter. |
| `⋮`    | MRW       | `⋮`           | Machine performance-monitoring counter. |
| `0xB1F` | MRW       | `mhpmcounter31` | Machine performance-monitoring counter. |
| `0xB80` | MRW       | `mcycleh`     | Upper 32 bits of mcycle, RV32 only. |
| `0xB82` | MRW       | `minstreth`   | Upper 32 bits of minstret, RV32 only. |
| `0xB83` | MRW       | `mhpmcounter3h` | Upper 32 bits of mhpmcounter3, RV32 only. |
| `0xB84` | MRW       | `mhpmcounter4h` | Upper 32 bits of mhpmcounter4, RV32 only. |
| `⋮`    | MRW       | `⋮`           | Upper 32 bits of mhpmcounter31, RV32 only. |
| `0xB9F` | MRW       | `mhpmcounter31h` | Upper 32 bits of mhpmcounter31, RV32 only. |
| **Machine Counter Setup** | | | |
| `0x320` | MRW       | `mcountinhibit` | Machine counter-inhibit register. |
| `0x323` | MRW       | `mhpmevent3`  | Machine performance-monitoring event selector. |
| `0x324` | MRW       | `mhpmevent4`  | Machine performance-monitoring event selector. |
| `⋮`    | MRW       | `⋮`           | Machine performance-monitoring event selector. |
| `0x33F` | MRW       | `mhpmevent31` | Machine performance-monitoring event selector. |
| `0x723` | MRW       | `mhpmevent3h` | Upper 32 bits of mhpmevent3, RV32 only. |
| `0x724` | MRW       | `mhpmevent4h` | Upper 32 bits of mhpmevent4, RV32 only. |
| `⋮`    | MRW       | `⋮`           | Upper 32 bits of mhpmevent31, RV32 only. |
| `0x73F` | MRW       | `mhpmevent31h` | Upper 32 bits of mhpmevent31, RV32 only. |
| **Debug/Trace Registers (shared with Debug Mode)** | | | |
| `0x7A0` | MRW       | `tselect`     | Debug/Trace trigger register select. |
| `0x7A1` | MRW       | `tdata1`      | First Debug/Trace trigger data register. |
| `0x7A2` | MRW       | `tdata2`      | Second Debug/Trace trigger data register. |
| `0x7A3` | MRW       | `tdata3`      | Third Debug/Trace trigger data register. |
| `0x7A8` | MRW       | `mcontext`    | Machine-mode context register. |
| **Debug Mode Registers** | | | |
| `0x7B0` | DRW       | `dcsr`        | Debug control and status register. |
| `0x7B1` | DRW       | `dpc`         | Debug program counter. |
| `0x7B2` | DRW       | `dscratch0`   | Debug scratch register 0. |
| `0x7B3` | DRW       | `dscratch1`   | Debug scratch register 1. |

