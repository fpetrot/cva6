# CVA6 128 RISC-V CPU

CVA6 128 is a 6-stage, single-issue, in-order CPU which implements the RV128I and RV128M. It is implemented on the 32/64-bits CVA6 version.

<img src="docs/03_cva6_design/_static/ariane_overview.drawio.png"/>

# Quick setup

This guide describes the steps required to set up the environment, compile the 128-bit CVA6 core, choose a program to run, and launch a simulation.

Throughout all build and simulations scripts executions, you can use the environment variable `NUM_JOBS` to set the number of concurrent jobs launched by `make`:

- if left undefined, `NUM_JOBS` will default to 1, resulting in a sequential execution
  of `make` jobs;
- when setting `NUM_JOBS` to an explicit value, it is recommended not to exceed 2/3 of
  the total number of virtual cores available on your system.

## 1. Get the CVA6 128

Checkout the repository and initialize all submodules.

```bash
git clone https://github.com/fpetrot/cva6.git
cd cva6
git submodule update --init --recursive
```

## 2. Get the 128 bits toolchain

We assume that you have the 32/64/128 bits RISC-V toolchain is in `/path/to/cva6/tools/toolchain`.
You should also specified it to the CVA6 with `export RISCV=/path/to/cva6/tools/toolchain`.
If you want to use the CVA6 in 128 bits you can get it from the here: [128-bit-riscv-devs](https://github.com/fpetrot/128-bit-riscv-devs).
If you want to use the CVA6 in 32 or 64 bits you can follow these instructions to install the
toolchain required by default : [toolchain](util/toolchain-builder/README.md#Getting-started).

## 3. Docker container environment setup

To run properly the CVA6 we choose to use a docker environment, it needs to be initialized properly.
To do so you can use `make` :

```bash
# create docker image
make dk-create-image
# run the docker container
make dk-run
```

But for convenience the docker container do not clone the CVA6 128 and use directly the project
files right here. This docker image is only made for running simulation.

Normally all environment variables and python environment are sourced by the `/.bashrc` by default
in the docker so you do not have to do anything.
Thus, you can skip the section 3.1 if all work correctly.
However, if it not works, or you want more information about it, section 3.1
describes how to set up the python environment and environment variables.

## 3.1 Setup environment variables and python environment

By default, `RISCV` and `CVA6_REPO_DIR` variables are defined in the docker container `/.bashrc`.
Those variables are very important because they defined where the toolchain is installed and where is the project root respectively.
`CVA6_REPO_DIR` is defined automatically but not `RISCV` so make sure that it is well-defined.

### Environment variables

In the docker container you can source the environment setup script:

```bash
# Setup all environment variables
source verif/sim/setup-env-all.sh
```

Or source manually these scripts:

```bash
# Setup default RISCV and NUM_JOBS variables
source verif/sim/setup-env-toolchain.sh
# Setup all CVA6 environment variables
source verif/sim/setup-env.sh
# Setup variables for simulations
source verif/sim/simulation-parameters.sh
```

NB: `verif/sim/setup-env-toolchain.sh` must come before `verif/sim/setup-env.sh` because
`setup-env.sh` use paths defined in `verif/sim/setup-env-toolchain.sh`.

### Python environment

CVA6 project use Python to execute multiple tests. We use a specific Python environment to do so in
`.venv/` and you need to activate it:

```bash
source /.venv/bin/activate
```

## 4. Verilator, Spike installations and stack size

Before starting, please ensure the following and in this order:

- **Stack size limit:** You must increase the limit with:
  ```bash
  ulimit -s unlimited
  ```
- **Verilator installation:** Make sure Verilator is installed correctly. You can install it using:
  ```bash
  bash verif/regress/install-verilator.sh
  ```
- **Spike installation:** You can install it using:
  ```bash
  bash verif/regress/install-spike.sh
  ```

## 5. Run a program on the CVA6 128 bits

Because we use a 128 bits version of the CVA6 the original compilation pipeline does not work by
default. So we must for now use our proper compilation tools.
To run a program on the CVA6 128 bits you can use this script:

```bash
export DV_SIMULATORS=veri-testharness
bash verif/tests/custom/run_cva_128.sh path/to/you/code
```

This script compiles and use the `cva6.py` python script to run your program.
If you want to manually run your program you can read section 7.1.

Currently, only rv32 and rv64 are supported by Spike so you can only use `veri-testharness` with 128
bits programs.

N.B. If you want to reproduce code execution in 64 bits you can run a similar script:

```bash
export DV_SIMULATORS=veri-testharness,spike
bash verif/tests/custom/run_cva_64.sh path/to/you/code
```

## 5.1 Run a program manually

If you want not use `cva6.py` script you can run it manually with Verilator.

## 5.1.1. Build the Core

Run the following command to generate the CVA6 core using Verilator:

```bash
make -C /cva6_128/ verilate verilator="verilator --no-timing" target=cv128
```

## 5.1.2. Use the Core

Because the ELF file format does not support 128 bits program (for now) we have to convert and load
manually the ELF file into binary raw data. Verilator do it itself and creates a binary file using
objcopy in the same directory of ELF.

To be able to receive message/error from your program you must specify correctly the `tohost`
address. It can be determined by using `nm`.

Run the simulation with the following command:

```bash
export ELF_BIN_DATA="path/to/the/program"
./work-ver/Variane_testharness $ELF_BIN_DATA ++$ELF_BIN_DATA +elf_file=$ELF_BIN_DATA +debug_disable=1 +core_name=cv128 +tohost_addr=<your_tohost>
```

> ⚠️ **Important:** The `+tohost_addr` value must be set correctly. If it is incorrect, the simulation will not complete properly. In a matter of fact, the CPU simulator will not stop in case of infinite loop.

## 6 Tests

To validate CVA6 you can run:

```bash
export DV_TARGET=you_cva6_version # e.g. cv64a6_imafdc_sv39_hpdcache_wb
bash verif/regress/dv-riscv-arch-test.sh
```

This script only works for 32 and 64 bits CVA6 version.

To test CVA6 128 bits you can run:

```bash
bash verif/tests/custom/run-rv128-unit-tests.sh
```

# Debug

## Logs

When you run a simulation Verilator generate an execution trace with executed opcode.
Normally on rv64 architecture Spike translate these opcodes into assembly. However, there is no rv128
instructions support in Spike so rv128 instructions are poorly translated (without arguments). So
there is an additional translation layer for rv128 that use `objdump` to get the disassembly.
The `rv128.spike.log` and `rv128.objdump.log` are logs that pas through the additional translation layer:

- `rv128.spike.log` -> Spike translation with a translation pass on rv128 instructions
- `rv128.objdump.log` -> objdump only translation,

## GDB

We assume that you have QEMU and GDB installed with your 128 bits toolchain.
In this case there are a bash script to launch a program with GDB and a `.gdbinit` at the project
root:

```bash
bash gdb_<32/64/128>.sh <you_program>
```

NB. Because in most test programm there is no obvious entry point you can begin to display and
execute the assembly code with:

```bash
display /i $pc
# go to the next instruction
si
```

## Error code

When you run a program on the CV6 there is a system to return error code or other message to the host.
This system works with a global variable named `tohost`, this variable is read by Verilator to check
if there is a problem. The memory address is specified by the `tohost_addr` parameter of
`Variane_testharness` program that we can see in the section 8 of the Quick Start.

The RTL simulator read continuously the `tohsot` variable and interpret it like this:

- The Less Significant Bit (LSB) indicate to the RTL simulator to stop or continue. (0 => continue, 1 =>
  stop).
- Other bit than the LSB are read by the RTL simulator or other program. If the RTL simulator stop
  these bites indicate if the CPU encounter an error. So if you write 1 in `tohost` that while stop
  the simulator BUT because other bits are at zero Verilator while not see any error and say that
  all are all right.

# Troubleshooting

## Segmentation fault (core dumped)

If you have a sgmentation fault when you run the CVA6 128, verify if `ulimit` is setup with
unlimited.

# Main CVA6 project

The original project can be found here: [CVA6](https://github.com/openhwgroup/cva6)
