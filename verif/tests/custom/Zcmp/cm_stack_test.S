#include "riscv_test.h"
#include "load_store.h"

RVTEST_CODE_BEGIN
    la   sp, stack

    // First call, success
    mv   a7, sp
    lla  t0, 0f             # Load call return address
    jal popret_ra
0:  bne  t0, ra, failure    # Check that we came back here
    bne  a7, sp, failure
    li   a1, 0xdeadbeef
    bne  a0, a1, failure    # and that a0 was no clobbered

    // Exact same second call, failure
    mv   a7, sp
    lla  t0, 0f             # Load call return address
    jal popret_ra
0:  bne  t0, ra, failure    # Check that we came back here
    bne  a7, sp, failure
    li   a1, 0xdeadbeef
    bne  a0, a1, failure    # and that a0 was no clobbered
    j success

failure:
    li x1, 1
    j 1f
success:
    li x1, 0
1:
    slli x1, x1, 1
    addi x1, x1, 1
    sw x1, tohost, t5
1:  j 1b

popret_ra:
    cm.push {ra}, -align_16up((1) * xlen_bytes)
    li a0, 0xdeadbeef
    li ra, 0xbadc00de
    cm.popret {ra}, align_16up((1) * xlen_bytes)

RVTEST_CODE_END

.data

RVTEST_DATA_BEGIN

    .balign 16
    .space 64 * xlen_bytes
    stack:
    .space 64 * xlen_bytes

RVTEST_DATA_END
