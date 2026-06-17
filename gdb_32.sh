#!/bin/bash
# Copyright 2026 Univ. Grenoble Alpes, Inria, TIMA Laboratory
#
# SPDX-License-Identifier: Apaches-2.0 WITH SHL-2.1
#
# Authors       : Vincent Verdillon
# Creation Date : June, 2026
# Description   : Run a 128 bits program on QEMU with GDB
# History       :

qemu-system-riscv32 -machine virt -bios none -nographic -m 128M -s -S -kernel $1 &
pid=$!
$RISCV/bin/${CV_SW_PREFIX}gdb $1
kill $pid
