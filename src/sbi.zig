// ⚫ An ECALL is used as the control transfer instruction between the supervisor and the SEE.
// ⚫ a7 encodes the SBI extension ID (EID),
// ⚫ a6 encodes the SBI function ID (FID) for a given extension ID encoded in a7 for any SBI extension defined in or after SBI v0.2.
// ⚫ All registers except a0 & a1 must be preserved across an SBI call by the callee.
// ⚫ SBI functions must return a pair of values in a0 and a1, with a0 returning an error code. This is

const SbiError = enum(c_long) {
    SBI_SUCCESS = 0,
    SBI_ERR_FAILED = -1,
    SBI_ERR_NOT_SUPPORTED = -2,
    SBI_ERR_INVALID_PARAM = -3,
    SBI_ERR_DENIED = -4,
    SBI_ERR_INVALID_ADDRESS = -5,
    SBI_ERR_ALREADY_AVAILABLE = -6,
    SBI_ERR_ALREADY_STARTED = -7,
    SBI_ERR_ALREADY_STOPPED = -8,
    SBI_ERR_NO_SHMEM = -9,
    SBI_ERR_INVALID_STATE = -10,
    SBI_ERR_BAD_RANGE = -11,
    SBI_ERR_TIMEOUT = -12,
    SBI_ERR_IO = -13,
};

const SbiRet = struct {
    err: SbiError,
    value: c_long,
};

pub fn put_char(chr: u8) SbiRet {
    return syscall_1(chr, 0x00, 0x01);
}

fn syscall_1(arg0: c_long, fid: c_long, eid: c_long) SbiRet {
    var err: SbiError = undefined;
    var value: c_long = undefined;

    asm volatile ("ecall"
        : [err] "={a0}" (err),
          [value] "={a1}" (value),
        : [arg0] "{a0}" (arg0),
          [fid] "{a6}" (fid),
          [eid] "{a7}" (eid),
        : "memory"
    );

    return .{
        .err = err,
        .value = value,
    };
}

/// Read the value of the CSR named `regname`
fn sbi_call(
    arg0: c_long,
    arg1: c_long,
    arg2: c_long,
    arg3: c_long,
    arg4: c_long,
    arg5: c_long,
    fid: c_long,
    eid: c_long,
) SbiRet {
    var err: SbiError = undefined;
    var value: c_long = undefined;

    asm volatile ("ecall"
        : [err] "={a0}" (err),
          [value] "={a1}" (value),
        : [arg0] "{a0}" (arg0),
          [arg1] "{a1}" (arg1),
          [arg2] "{a2}" (arg2),
          [arg3] "{a3}" (arg3),
          [arg4] "{a4}" (arg4),
          [arg5] "{a5}" (arg5),
          [fid] "{a6}" (fid),
          [eid] "{a7}" (eid),
    );

    return .{
        .err = err,
        .value = value,
    };
}
