#!/bin/bash
# Copyright 2026 Univ. Grenoble Alpes, Inria, TIMA Laboratory
#
# SPDX-License-Identifier: Apaches-2.0 WITH SHL-2.1
#
# Authors       : Vincent Verdillon
# Creation Date : June, 2026
# Description   : Run unit tests in RISC-V 128 bits architecture.

# check where are the tools
if ! [ -n "$RISCV" ]; then
  echo "Error: RISCV variable undefined"
  return
fi

# Test lists for RV128I and RV128M

# I
test_list_i_path="verif/tests/custom/rv128-unit-tests-src/unit_tests_i"
test_list_i=(
test_add.S
test_addd.S
test_addi.S
test_addid.S
test_addiw.S
test_addw.S
test_and.S
test_andi.S
test_auipc.S
test_beq.S
test_beqz.S
test_bge.S
test_bgeu.S
test_bgez.S
test_blt.S
test_bltu.S
test_bltz.S
test_bne.S
test_bnez.S
test_lb.S
test_lbu.S
test_ld.S
# test_ld_misaligned.S
test_ldu.S
# test_ldu_misaligned.S
test_lh.S
# test_lh_misaligned.S
test_lhu.S
# test_lhu_misaligned.S
test_lq.S
# test_lq_misaligned.S
test_lui.S
test_lw.S
# test_lw_misaligned.S
test_lwu.S
# test_lwu_misaligned.S
test_or.S
test_ori.S
test_sll.S
test_slld.S
test_slli.S
test_sllid.S
test_slliw.S
test_sllw.S
test_slt.S
test_slti.S
test_sltiu.S
test_sltu.S
test_sq.S
# test_sq_unaligned.S
test_sra.S
test_srad.S
test_srai.S
test_sraid.S
test_sraiw.S
test_sraw.S
test_srl.S
test_srld.S
test_srli.S
test_srlid.S
test_srliw.S
test_srlw.S
test_sub.S
test_subd.S
test_subw.S
test_xor.S
test_xori.S
)

# M
test_list_m_path="verif/tests/custom/rv128-unit-tests-src/unit_tests_m"
test_list_m=(
test_div.S
test_divd.S
test_divu.S
test_divud.S
test_divuw.S
test_divw.S
test_mul.S
test_muld.S
test_mulh.S
test_mulhsu.S
test_mulhu.S
test_mulw.S
test_rem.S
test_remd.S
test_remu.S
test_remud.S
test_remuw.S
test_remw.S
)

missing_tests=0

# If test files are not found, exit with error
for test in "${test_list_i[@]}"; do
    if [ ! -f "$test_list_i_path/$test" ]; then
        echo "Error: Test file $test_list_i_path/$test not found"

        missing_tests=1
    fi
done

for test in "${test_list_m[@]}"; do
    if [ ! -f "$test_list_m_path/$test" ]; then
        echo "Error: Test file $test_list_m_path/$test not found"

        missing_tests=1
    fi
done

# genrate missing tests if any were missing
if [ $missing_tests -eq 1 ]; then
    echo "Some test files were missing. Generating them now..."
    cd verif/tests/custom/
    python3 gen-rv128-test.py
    cd ../../../
fi

# print where the script is running from
echo "Running script from $(pwd)"

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
    -march=rv128gc_zba_zbb_zbs_zbc \
    -mabi=llp128
)

# array to store the status of each test (name -> PASS/FAIL)
declare -A test_status
# keep track of the order of tests to report results in the same order
test_order=()

# Iterate over the test lists and run each test
# I
echo "Running tests for RV128I"
for test in "${test_list_i[@]}"; do
    echo "===================== Running test: $test"

    # convert the relative path to an absolute path
    src0=$(realpath "$test_list_i_path/$test")

    cd verif/sim

    # Run the CVA6 simulation with the specified parameters.
    # It works only if the script is executed from the root of the project.
    python3 cva6.py \
            --target cv128a6_im_sv39_hpdcache_wb \
            --hwconfig_opts="$DV_HWCONFIG_OPTS" \
            --iss="$DV_SIMULATORS" \
            --iss_yaml=cva6.yaml \
            --steps=gen,gcc_compile,iss_sim \
            --c_tests "$src0" \
            --sv_seed 1 \
            --gcc_opts "${srcA[*]} ${cflags[*]}" \
            $DV_OPTS

    ret=$?

    cd ../../

    # get the return code of the last command
    test_order+=("$test")
    if [ $ret -eq 0 ]; then
        test_status["$test"]="PASS"
    else
        test_status["$test"]="FAIL"
    fi

    # wait 100 milliseconds before running the next test
    # This is to avoid overwhelming the system with too many processes at once.
    sleep 0.2
done

# M
echo "Running tests for RV128M"

for test in "${test_list_m[@]}"; do
    echo "===================== Running test: $test"

    # convert the relative path to an absolute path
    src0=$(realpath "$test_list_m_path/$test")

    cd verif/sim

    # Run the CVA6 simulation with the specified parameters.
    # It works only if the script is executed from the root of the project.
    python3 cva6.py \
            --target cv128a6_im_sv39_hpdcache_wb \
            --hwconfig_opts="$DV_HWCONFIG_OPTS" \
            --iss="$DV_SIMULATORS" \
            --iss_yaml=cva6.yaml \
            --steps=gen,gcc_compile,iss_sim \
            --c_tests "$src0" \
            --sv_seed 1 \
            --gcc_opts "${srcA[*]} ${cflags[*]}" \
            $DV_OPTS

    ret=$?

    cd ../../

    # get the return code of the last command
    test_order+=("$test")
    if [ $ret -eq 0 ]; then
        test_status["$test"]="PASS"
    else
        test_status["$test"]="FAIL"
    fi

    # wait 100 milliseconds before running the next test
    # This is to avoid overwhelming the system with too many processes at once.
    sleep 0.2
done

# ------------------------- Final recap of the tests --------------------------

echo ""
echo "===================== TEST RECAP ====================="
nb_fail=0
for test in "${test_order[@]}"; do
    status="${test_status[$test]}"
    if [ "$status" == "FAIL" ]; then
        printf "%-35s %s\n" "$test" "$status"
        nb_fail=$((nb_fail + 1))
    else
        printf "%-30s %s\n" "$test" "$status"
    fi
done
echo "========================================================"
echo "Total: ${#test_order[@]} test(s), $nb_fail fail(s)"
echo ""

if [ $nb_fail -gt 0 ]; then
    echo "At least one test has failed."
    exit 1
fi

exit 0
