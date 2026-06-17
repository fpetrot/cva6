#!/bin/bash
# Copyright 2026 Univ. Grenoble Alpes, Inria, TIMA Laboratory
#
# SPDX-License-Identifier: Apaches-2.0 WITH SHL-2.1
#
# Authors       : Vincent Verdillon
# Creation Date : June, 2026
# Description   : Run a 128 bits program on QEMU with GDB
# History       :

/cva6_128/tools/toolchain/bin/qemu-system-riscv64 -machine virt -cpu x-rv128 -bios none -nographic -m 128M -s -S -kernel $1 &
pid=$!
/cva6_128/tools/toolchain/bin/riscv128-unknown-elf-gdb $1
kill $pid
