#!/bin/bash
# Copyright 2026 Univ. Grenoble Alpes, Inria, TIMA Laboratory
#
# SPDX-License-Identifier: Apaches-2.0 WITH SHL-2.1
#
# Authors       : Vincent Verdillon
# Creation Date : June, 2026
# Description   : Sanitize Makefile
# History       :

# check where are the tools
if ! [ -n "$RISCV" ]; then
  echo "Error: RISCV variable undefined"
  return
fi

src0="${1}"
# if --help or no argument is provided, show usage
if [[ "$src0" == "--help" || -z "$src0" ]]; then
    echo "Compile a source file in RISC-V 128 bits architecture.\nThis script must be executed in common directory."
    echo "Usage: bash $0 <path-to-code>"
    exit 0
fi

cd verif/sim

srcA=(
    # /cva6_128/verif/tests/custom/common/syscalls.c
    /cva6_128/verif/tests/custom/common/crt.S
)
cflags=(
    -fno-tree-loop-distribute-patterns
    -static
    -mcmodel=medany
    -fvisibility=hidden
    -nostdlib
    -nostartfiles
    -lgcc
    -O3 --no-inline
    -Wno-implicit-function-declaration
    -Wno-implicit-int
    -I /cva6_128/verif/tests/custom/env/
    -I /cva6_128/verif/tests/custom/common/
    -DNOPRINT
)
carch=(
    -march=rv128gc_zba_zbb_zbs_zbc \
    -mabi=llp128
)

# Generate the output name
basename_with_ext=$(basename "$src0")
name="${basename_with_ext%.*}"

# create the output directory
current_date=$(date +%Y-%m-%d)
output_dir="/cva6_128/verif/sim/out_${current_date}/directed_tests/"
mkdir -p "$output_dir"

set -x

# Compile program the programme
$RISCV/bin/riscv128-unknown-elf-gcc "$src0" \
    -I /cva6_128/verif/sim/dv/user_extension \
    -T/cva6_128/verif/sim/../../config/gen_from_riscv_config/linker/link.ld \
    "${srcA[@]}" \
    "${cflags[@]}" \
    -o $output_dir$name \
    "${carch[@]}"

set +x
