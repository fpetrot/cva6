#include "riscv_test.h"
#include "load_store.h"


RVTEST_CODE_BEGIN
    // Setup stack
    la   sp, stack

    // Check the ra-only case
    lla  t0, 0f             # Load call return address
    jal popret_ra
0:  bne  t0, ra, failure    # Check that we came back here
    li   a1, 0xdeadbeef
    bne  a0, a1, failure    # and that a0 was no clobbered

    // Load numbers into caller saved registers
    lx   s0, num1
    lx   s1, num2
    lx   a2, result
    lla  t0, 0f
    jal  popret_some
0:  bne  t0, ra, failure
    add  t2, s0, s1
    add  t2, t2, s2
    bne  t2, a2, failure   # Popped registers have a correct value
    li   a1, 0x8badf00d
    bne  a0, a1, failure   # a0 kept its value

    li   s1,  1
    li   s2,  2
    li   s3,  3
    li   s4,  4
    li   s5,  5
    li   s6,  6
    li   s7,  7
    li   s8,  8
    li   s9,  9
    li   s10, 10
    li   s11, 11
    lx   a2, result    # Let's make that 12 too
    lla  t0, 0f
    jal  popret_all
0:  bne  t0, ra, failure
    li   a1, 0xcafebabe
    bne  a0, a1, failure   # a0 kept its value
    j success
    add  t2, s1, s11
    bne  a2, t2, failure
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

popret_some:
    cm.push {ra, s0-s2}, -align_16up((4 + 1) * xlen_bytes)
    li a0, 0x8badf00d
    move s1, a0
    cm.popret {ra, s0-s2}, align_16up((4 + 1) * xlen_bytes)

popret_all:
    cm.push {ra, s0-s11}, -align_16up((16 + 1) * xlen_bytes)
    li a0, 0xcafebabe
    cm.popret {ra, s0-s11}, align_16up((16 + 1) * xlen_bytes)

RVTEST_CODE_END

.data

RVTEST_DATA_BEGIN

    num1:   xdata 5     // First number
    num2:   xdata 7     // Second number
    result: xdata 12    // Result

    .balign 16
    .space 64 * xlen_bytes
    stack:
    .space 64 * xlen_bytes

RVTEST_DATA_END
