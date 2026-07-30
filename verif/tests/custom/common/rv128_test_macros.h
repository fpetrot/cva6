// Copyright 2026 Univ. Grenoble Alpes, Inria, TIMA Laboratory
//
// SPDX-License-Identifier: Apaches-2.0 WITH SHL-2.1
//
// Authors       : Vincent Verdillon
// Creation Date : July, 2026
// Description   : macros for the RV128I tests

// These macros are made to replace the prgchk directive, which is not
// supported. If the test is not successful, the macros will send a message to
// rise an error with the "tohost" variable with the specified error value.

#pragma once

#if __riscv_xlen == 128
#define LREG lq
#define SREG sq
#define LD ld
#define SD sd
#define REGBYTES 16
#elif __riscv_xlen == 64
#define LREG ld
#define SREG sd
#define REGBYTES 8
#else
#define LREG lw
#define SREG sw
#define REGBYTES 4
#endif

// To return a value to the host we must write the value to the "tohost"
// variable. The way it works is that the least significant bit is used to
// indicate if Verilator should stop the simulation or not.If the bit is set to
// 1, Verilator will stop the simulation and return the value of the other bits
// as the exit code.If the bit is set to 0, Verilator will continue the
// simulation.

// The macro will rise an error with the "tohost" variable with the specified
// error value.
#define RAISE_ERROR(error_val)                                                 \
  li t0, error_val;                                                            \
  slli t0, t0, 1;                                                              \
  ori t0, t0, 1;                                                               \
  43 : SREG t0, tohost, t1;                                                    \
  j 43b;

// The macro will print a message to the host with the "tohost" variable with
// the specified message value.
#define PRINT_MSG(msg_val)                                                     \
  li t0, msg_val;                                                              \
  slli t0, t0, 1;                                                              \
  ori t0, t0, 1;                                                               \
  43 : SREG t0, tohost, t1;                                                    \
  j 43b;

// The macro will print a register value to the host with the "tohost" variable
// with the specified message value.
#define PRINT_REG_VALUE(reg)                                                   \
  mv t0, reg;                                                                  \
  slli t0, t0, 1;                                                              \
  ori t0, t0, 1;                                                               \
  43 : SREG t0, tohost, t1;                                                    \
  j 43b;

// The macro will check the value of a register.
#define CHK_REG_EQ_VALUE(reg, expected, error_val)                             \
  addi sp, sp, -REGBYTES * 3;                                                  \
  SREG t0, 0(sp);                                                              \
  SREG t1, REGBYTES(sp);                                                       \
  SREG t2, REGBYTES * 2(sp);                                                   \
  mv t0, reg;                                                                  \
  li t1, expected;                                                             \
  beq t0, t1, 43f;                                                             \
  li t3, error_val;                                                            \
  slli t3, t3, 1;                                                              \
  ori t3, t3, 1;                                                               \
  17 : SREG t3, tohost, t2;                                                    \
  j 17b;                                                                       \
  43 : LREG t0, 0(sp);                                                         \
  LREG t1, REGBYTES(sp);                                                       \
  LREG t2, REGBYTES * 2(sp);                                                   \
  addi sp, sp, REGBYTES * 3;

// The macro will check the value of a register.
#define CHK_REG_NEQ_VALUE(reg, expected, error_val)                            \
  addi sp, sp, -REGBYTES * 3;                                                  \
  SREG t0, 0(sp);                                                              \
  SREG t1, REGBYTES(sp);                                                       \
  SREG t2, REGBYTES * 2(sp);                                                   \
  mv t0, reg;                                                                  \
  li t1, expected;                                                             \
  bne t0, t1, 43f;                                                             \
  li t3, error_val;                                                            \
  slli t3, t3, 1;                                                              \
  ori t3, t3, 1;                                                               \
  17 : SREG t3, tohost, t2;                                                    \
  j 17b;                                                                       \
  43 : LREG t0, 0(sp);                                                         \
  LREG t1, REGBYTES(sp);                                                       \
  LREG t2, REGBYTES * 2(sp);                                                   \
  addi sp, sp, REGBYTES * 3;

// The macro will check equality between two registers.
#define CHK_EQ_REG_REG(reg1, reg2, error_val)                                  \
  addi sp, sp, -REGBYTES * 2;                                                  \
  SREG t0, 0(sp);                                                              \
  SREG t1, REGBYTES(sp);                                                       \
  beq reg1, reg2, 43f;                                                         \
  li t1, error_val;                                                            \
  slli t1, t1, 1;                                                              \
  ori t1, t1, 1;                                                               \
  17 : SREG t1, tohost, t2;                                                    \
  j 17b;                                                                       \
  43 : LREG t0, 0(sp);                                                         \
  LREG t1, REGBYTES(sp);                                                       \
  addi sp, sp, REGBYTES * 2;

// The macro will check inequality between two registers.
#define CHK_NEQ_REG_REG(reg1, reg2, error_val)                                 \
  addi sp, sp, -REGBYTES * 2;                                                  \
  SREG t0, 0(sp);                                                              \
  SREG t1, REGBYTES(sp);                                                       \
  bne reg1, reg2, 43f;                                                         \
  li t1, error_val;                                                            \
  slli t1, t1, 1;                                                              \
  ori t1, t1, 1;                                                               \
  17 : SREG t1, tohost, t2;                                                    \
  j 17b;                                                                       \
  43 : LREG t0, 0(sp);                                                         \
  LREG t1, REGBYTES(sp);                                                       \
  addi sp, sp, REGBYTES * 2;

// The macro will check the value of a memory location of 128 bits.
#define CHK_EQ_MEM_VALUE_Q(mem_addr, expected, error_val)                      \
  addi sp, sp, -REGBYTES * 2;                                                  \
  SREG t0, 0(sp);                                                              \
  SREG t1, REGBYTES(sp);                                                       \
  LREG t0, mem_addr;                                                           \
  li t1, expected;                                                             \
  beq t0, t1, 43f;                                                             \
  li t1, error_val;                                                            \
  slli t1, t1, 1;                                                              \
  ori t1, t1, 1;                                                               \
  17 : SREG t1, tohost, t2;                                                    \
  j 17b;                                                                       \
  43 : LREG t0, 0(sp);                                                         \
  LREG t1, REGBYTES(sp);                                                       \
  addi sp, sp, REGBYTES * 2;

// The macro will check the value of a memory location of 128 bits.
#define CHK_NEQ_MEM_VALUE_Q(mem_addr, expected, error_val)                     \
  addi sp, sp, -REGBYTES * 2;                                                  \
  SREG t0, 0(sp);                                                              \
  SREG t1, REGBYTES(sp);                                                       \
  LREG t0, mem_addr;                                                           \
  li t1, expected;                                                             \
  bne t0, t1, 43f;                                                             \
  li t1, error_val;                                                            \
  slli t1, t1, 1;                                                              \
  ori t1, t1, 1;                                                               \
  17 : SREG t1, tohost, t2;                                                    \
  j 17b;                                                                       \
  43 : LREG t0, 0(sp);                                                         \
  LREG t1, REGBYTES(sp);                                                       \
  addi sp, sp, REGBYTES * 2;

// The macro will check the value of a memory location of 64 bits.
#define CHK_EQ_MEM_VALUE_D(mem_addr, expected, error_val)                      \
  addi sp, sp, -REGBYTES * 2;                                                  \
  SREG t0, 0(sp);                                                              \
  SREG t1, REGBYTES(sp);                                                       \
  LD t0, mem_addr;                                                             \
  li t1, expected;                                                             \
  beq t0, t1, 43f;                                                             \
  li t1, error_val;                                                            \
  slli t1, t1, 1;                                                              \
  ori t1, t1, 1;                                                               \
  17 : SREG t1, tohost, t2;                                                    \
  j 17b;                                                                       \
  43 : LREG t0, 0(sp);                                                         \
  LREG t1, REGBYTES(sp);                                                       \
  addi sp, sp, REGBYTES * 2;

// The macro will check the value of a memory location of 64 bits by checking
// for inequality.
#define CHK_NEQ_MEM_VALUE_D(mem_addr, not_expected, error_val)                 \
  addi sp, sp, -REGBYTES * 2;                                                  \
  SREG t0, 0(sp);                                                              \
  SREG t1, REGBYTES(sp);                                                       \
  ld t0, mem_addr;                                                             \
  li t1, not_expected;                                                         \
  bne t0, t1, 43f;                                                             \
  li t1, error_val;                                                            \
  slli t1, t1, 1;                                                              \
  ori t1, t1, 1;                                                               \
  17 : SREG t1, tohost, t2;                                                    \
  j 17b;                                                                       \
  43 : LREG t0, 0(sp);                                                         \
  LREG t1, REGBYTES(sp);                                                       \
  addi sp, sp, REGBYTES * 2;

// The macro will check the value of a memory location of 32 bits.
#define CHK_EQ_MEM_VALUE_W(mem_addr, expected, error_val)                      \
  addi sp, sp, -REGBYTES * 2;                                                  \
  SREG t0, 0(sp);                                                              \
  SREG t1, REGBYTES(sp);                                                       \
  lw t0, mem_addr;                                                             \
  li t1, expected;                                                             \
  beq t0, t1, 43f;                                                             \
  li t1, error_val;                                                            \
  slli t1, t1, 1;                                                              \
  ori t1, t1, 1;                                                               \
  17 : SREG t1, tohost, t2;                                                    \
  j 17b;                                                                       \
  43 : LREG t0, 0(sp);                                                         \
  LREG t1, REGBYTES(sp);                                                       \
  addi sp, sp, REGBYTES * 2;

// The macro will check the value of a memory location of 16 bits.
#define CHK_EQ_MEM_VALUE_H(mem_addr, expected, error_val)                      \
  addi sp, sp, -REGBYTES * 2;                                                  \
  SREG t0, 0(sp);                                                              \
  SREG t1, REGBYTES(sp);                                                       \
  lh t0, mem_addr;                                                             \
  li t1, expected;                                                             \
  beq t0, t1, 43f;                                                             \
  li t1, error_val;                                                            \
  slli t1, t1, 1;                                                              \
  ori t1, t1, 1;                                                               \
  17 : SREG t1, tohost, t2;                                                    \
  j 17b;                                                                       \
  43 : LREG t0, 0(sp);                                                         \
  LREG t1, REGBYTES(sp);                                                       \
  addi sp, sp, REGBYTES * 2;

// The macro will check the value of a memory location of 8 bits.
#define CHK_EQ_MEM_VALUE_B(mem_addr, expected, error_val)                      \
  addi sp, sp, -REGBYTES * 2;                                                  \
  SREG t0, 0(sp);                                                              \
  SREG t1, REGBYTES(sp);                                                       \
  lb t0, mem_addr;                                                             \
  li t1, expected;                                                             \
  beq t0, t1, 43f;                                                             \
  li t1, error_val;                                                            \
  slli t1, t1, 1;                                                              \
  ori t1, t1, 1;                                                               \
  17 : SREG t1, tohost, t2;                                                    \
  j 17b;                                                                       \
  43 : LREG t0, 0(sp);                                                         \
  LREG t1, REGBYTES(sp);                                                       \
  addi sp, sp, REGBYTES * 2;
