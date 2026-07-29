#!/bin/bash
# Copyright 2026 Univ. Grenoble Alpes, Inria, TIMA Laboratory
#
# SPDX-License-Identifier: Apaches-2.0 WITH SHL-2.1
#
# Authors       : Vincent Verdillon
# Creation Date : June, 2026
# Description   : Run a source file in RISC-V 64 bits architecture.     :

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

# convert the relative path to an absolute path
src0=$(realpath "$src0")

srcA=(
    $(realpath "verif/tests/custom/common/crt0.S")
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
    -I$(realpath "verif/tests/custom/env/")
    -I$(realpath "verif/tests/custom/common/")
    -DNOPRINT
)
carch=(
    -march=rv64gc_zba_zbb_zbs_zbc_zbkb_zbkx_zkne_zknd_zknh \
    -mabi=lp64d
)

cd verif/simS

# Run the CVA6 simulation with the specified parameters.
# It works only if the script is executed from the root of the project.
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

cd ../../
