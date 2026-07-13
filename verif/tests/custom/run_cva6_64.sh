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
    /cva6_128/verif/tests/custom/common/crt0.S
)
cflags=(
    -fno-tree-loop-distribute-patterns
    -static
    -mcmodel=medany
    -fvisibility=hidden
    -nostdlib
    -nostartfiles
    -lgcc
    -O0 --no-inline
    -Wno-implicit-function-declaration
    -Wno-implicit-int
    -I /cva6_128/verif/tests/custom/env/
    -I /cva6_128/verif/tests/custom/common/
    -DNOPRINT
)
carch=(
    -march=rv64gc_zba_zbb_zbs_zbc_zbkb_zbkx_zkne_zknd_zknh \
    -mabi=lp64d
)

# Generate the output name
basename_with_ext=$(basename "$src0")
name="${basename_with_ext%.*}"

# create the output directory
current_date=$(date +%Y-%m-%d)
output_dir="/cva6_128/verif/sim/out_${current_date}/directed_tests/"
mkdir -p "$output_dir"

echo "Compile to ELF..."

# set -x

# Compile program the programme
$RISCV_CC "$src0" \
    -I /cva6_128/verif/sim/dv/user_extension \
    -T/cva6_128/verif/sim/../../config/gen_from_riscv_config/linker/link.ld \
    "${srcA[@]}" \
    "${cflags[@]}" \
    -o $output_dir$name \
    "${carch[@]}"

# set +x

echo "Convert ELF to BIN to be used by the RTL simulation..."

# get the thost addr to discuss with the host and cut it to avoid 128 bits addr
# tohost_addr=$($RISCV/bin/${CV_SW_PREFIX}nm -B $output_dir$name | grep -w tohost | cut -d' ' -f1 | cut -c17-32)
# echo "tohost address: $tohost_addr"

python3 cva6.py \
        --target cv64a6_imafdc_sv39_hpdcache_wb \
        --hwconfig_opts="$DV_HWCONFIG_OPTS" \
        --iss="$DV_SIMULATORS" \
        --iss_yaml=cva6.yaml \
        --steps=gen,gcc_compile,iss_sim \
        --c_tests "$src0" \
        --sv_seed 1 \
        --gcc_opts "${srcA[*]} ${cflags[*]}" \
        $DV_OPTS

# run verilator
# $ROOT_PROJECT/work-ver/Variane_testharness $ELF_BIN_DATA \
#                                            ++$ELF_BIN_DATA \
#                                            +elf_file=$ELF_BIN_DATA \
#                                            +debug_disable=1 \
#                                            +core_name=cv64 \
#                                            +tohost_addr=$tohost_addr

