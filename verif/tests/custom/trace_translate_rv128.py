# Copyright 2026 Univ. Grenoble Alpes, Inria, TIMA Laboratory
#
# SPDX-License-Identifier: Apaches-2.0 WITH SHL-2.1
#
# Authors       : Vincent Verdillon
# Creation Date : June, 2026
# Description   : Translate rv128 instructions in execution trace log.
# History       :

import subprocess
import os
import argparse
import re

parser = argparse.ArgumentParser(
    description="Script to translate RISC-V 128 bits opcode with \
                                 objdump in a Verilator simulator trace."
)

parser.add_argument("-e", "--elf", type=str, help="The ELF path")
parser.add_argument("-t", "--trace", type=str, help="Verilator trace path")
args = parser.parse_args()

input_file_path = args.elf
trace_path = args.trace

toolchain = os.environ.get("RISCV")
cmd = toolchain + "/bin/riscv128-unknown-elf-objdump -d " + input_file_path
objdump = subprocess.run(cmd, shell=True, capture_output=True, text=True).stdout

objdump_lines = objdump.split("\n")
objdump_addrs = [line.split(":") for line in objdump_lines]

# remove empty line and only addr line
addrs_clean = []
for addr in objdump_addrs:
    if len(addr) > 1 and addr[0] != "" and addr[1] != "":
        addrs_clean.append(addr)

# create addr instruction dictionnary
addr_to_instr = {}
for addr in addrs_clean:
    tmp = addr[1].split("\t")
    if len(tmp) >= 4:
        instr = tmp[2] + " " + tmp[3]

        addr_tmp = "0" * (16 - len(addr[0].strip())) + addr[0].strip()

        addr_to_instr[addr_tmp] = instr

# open trace file
with open(trace_path, "r") as f:
    trace_lines = f.readlines()

# for each line of the trace, extract the address and the opcode and replace DASM with the instruction from the objdump
for line in trace_lines:
    if "core" not in line:
        print(line, end="")
        continue

    # log from Spike
    if "args unknown" in line:
        words_line = line.split()
        addr = words_line[2][2:]
        if addr in addr_to_instr:
            instr = addr_to_instr[addr]

            # find the begining of the instruction in the line and replace it with the instruction from the objdump
            index = line.find(")") + 1
            line = line[:index] + " " + instr + " # rv128 only\n"

    # log from Verilator
    elif "DASM" in line:
        words_line = line.split()
        addr = words_line[2][2:]
        if addr in addr_to_instr:
            instr = addr_to_instr[addr]

            # find the begining of the instruction in the line and replace it with the instruction from the objdump
            index = line.find("DASM")
            line = line[:index] + " " + instr + "\n"

    print(line, end="")
