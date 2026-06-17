#!/bin/bash
# Copyright 2026 Univ. Grenoble Alpes, Inria, TIMA Laboratory
#
# SPDX-License-Identifier: Apaches-2.0 WITH SHL-2.1
#
# Authors       : Vincent Verdillon, Frédéric Pétrot
# Creation Date : June, 2026
# Description   : Run an XLEN bits program on QEMU with GDB
# History       : Merge 32-64-128 and take XLEN as a parameter

if [[ $# != 2 || ($1 != 32 && $1 != 64 && $1 != 128) ]]; then
	echo "Usage: $0 <32|64|128> executable"
	echo '(Assume $RISCV is set to point to the appropriate toolchain)'
	exit 1
fi

XLEN=$1

if test $XLEN -eq 32 -o $XLEN -eq 64; then
	QEMU=qemu-system-riscv${XLEN}
	GDB=riscv${XLEN}-unknown-elf-gdb
else # XLEN == 128
	if test -z "$RISCV"; then
		echo 'Please set $RISCV when XLEN=128'
		exit 1
	fi
	QEMU="$RISCV/bin/qemu-system-riscv64 -cpu x-rv128"
	GDB=$RISCV/bin/riscv${XLEN}-unknown-elf-gdb
fi

$QEMU -machine virt -bios none -nographic -m 128M -s -S -kernel $2 &
pid=$!
$GDB $2
kill $pid
