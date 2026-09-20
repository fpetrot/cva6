#!/bin/bash
for i in *.S; do
	o32=$(basename $i .S)_rv32.elf
	o64=$(basename $i .S)_rv64.elf
	riscv128-unknown-elf-gcc -static -mcmodel=medany -fvisibility=hidden -nostdlib -g syscalls.c -lgcc -Tlink.ld -march=rv32imf_zcmp_zicsr -mabi=ilp32 -I ../env -o $o32 $i
	riscv128-unknown-elf-gcc -static -mcmodel=medany -fvisibility=hidden -nostdlib -g syscalls.c -lgcc -Tlink.ld -march=rv64imd_zcmp_zicsr -mabi=lp64d -I ../env -o $o64 $i
done
