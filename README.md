# CVA6 128 RISC-V CPU

CVA6 128 is a 6-stage, single-issue, in-order CPU which implements the 128-bit RISC-V instruction set. It is implemented on the 64-bits CVA6 version.

<img src="docs/03_cva6_design/_static/ariane_overview.drawio.png"/>

# Quick setup

This guide describes the steps required to set up the environment, compile the 128-bit CVA6 core, choose a program to run, and launch the simulation.

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

We assume that the 128 bits RISC-V toolchain is in `/path/to/cva6/tools/toolchain`.
In the future the toolchain compilation will be directly integrated in the 128 bits project.

## 3. Docker initialization

To run properly the CVA6 we choose to use a docker environment, it needs to be initialized properly.
To do so you can use `make` :

```bash
make dk-create-image
```

This command creates the docker image and installs an environment to run the CVA6.
But for convenience the docker container do not clone the CVA6 128 and use directly the project
files right here, so there are still work to be done in the docker before launch any simulation.

## 4. Docker container environment setup

Launch the docker container with `make` :

```bash
make dk-run
```

Normally all environment variables and python environment are sourced by the `/.bashrc` by default.
So you can skip the section 4.1 if all work correctly.
However, section 4.1 describes how to setup python environment and environment variables.

## 4.1 Setup environment variables and python environment

By default, `RISCV` and `CVA6_REPO_DIR` variables are defined in the `/.bashrc`.
Those variables are very important because they defined where the toolchain is installed and where is the project root respectively.

Before proceeding, source the environment setup scripts:

```bash
source verif/sim/setup-env-toolchain.sh
source verif/sim/setup-env.sh
source verif/sim/simulation-parameters.sh
```

NB: `verif/sim/setup-env-toolchain.sh` must come before `verif/sim/setup-env.sh` because
`setup-env.sh` use paths defined in `verif/sim/setup-env-toolchain.sh`.

Or use the script that do all these commands:

```bash
source verif/sim/setup-env-all.sh
```

Those scripts create environment variables needed by the CVA6 such as `RISCV` that indicate where
the RISC-V toolchain is installed.

CVA6 project use Python to execute multiple tests. We use a specific Python environment to do so in
`/.venv` and you need to activate it:

```bash
source /.venv/bin/activate
```

## 5. Verilator, Spike installations and stack size

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

## 6. Build the Core

Run the following command to generate the CVA6 core using Verilator:

```bash
make -C /cva6_128/ verilate verilator="verilator --no-timing" target=cv128
```

## 7. Run a program on the CVA6 128 bits

Because we use a 128 bits version of the CVA6 the original compilation pipeline does not work by
default. So we must for now use our proper compilation tools.
To run a program on the CVA6 128 bits you can use this script:

```bash
bash verif/tests/custom/run_cva_128.sh /absolute/path/to/you/code
```

This script compiles and use the `cva6.py` python script to run your program.
If you want to manually run your program you can read section 7.1.

## 7.1 Run a program

Because the ELF file format does not support 128 bits program (for now) we have to convert and load
manually the ELF file into binary raw data.

To do so manually you have to compile your program into a `ELF` file and convert it into binary with
`objcopy` and set the `ELF_BIN_DATA` environment variable with the path to this file.

```bash
export ELF_BIN_DATA=/binary/prog/to/run
```

## 7.1.1 Launch the Simulation

To be able to receive message/error from your program you must specify correctly the `tohost`
address. It can be determined by using `nm`.

Run the simulation with the following command:

```bash
./work-ver/Variane_testharness $ELF_BIN_DATA ++$ELF_BIN_DATA +elf_file=$ELF_BIN_DATA +debug_disable=1 +core_name=cv128 +tohost_addr=<your_tohost>
```

> ⚠️ **Important:** The `+tohost_addr` value must be set correctly. If it is incorrect, the simulation will not complete properly. In a matter of fact, the CPU simulator will not stop in case of infinite loop.

# Debug

## GDB

We assume that you have QEMU and GDB installed with your 128 bits toolchain.
In this case there are a bash script to launch a program with GDB and a `.gdbinit` at the project
root:

```bash
bash gdb.sh <you_program>
```

NB. Because in most test programm there is no obvious entry point you can begin to display and
execute the assembly code with:

```bash
display /i $pc
```

And go to the next instruction with:

```bash
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

# CVA6 Original README

# CVA6 RISC-V CPU [![Build Status](https://github.com/openhwgroup/cva6/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/openhwgroup/cva6/actions/workflows/ci.yml) [![CVA6 dashboard](https://riscv-ci.pages.thales-invia.fr/dashboard/badge_master.svg)](https://riscv-ci.pages.thales-invia.fr/dashboard/dashboard_cva6.html) [![Documentation Status](https://readthedocs.com/projects/openhw-group-cva6-user-manual/badge/?version=latest)](https://docs.openhwgroup.org/projects/cva6-user-manual/?badge=latest) [![GitHub release](https://img.shields.io/github/release/openhwgroup/cva6?include_prereleases=&sort=semver&color=blue)](https://github.com/openhwgroup/cva6/releases/)

CVA6 is a 6-stage, single-issue, in-order CPU which implements the 64-bit RISC-V instruction set. It fully implements I, M, A and C extensions as specified in Volume I: User-Level ISA V 2.3 as well as the draft privilege extension 1.10. It implements three privilege levels M, S, U to fully support a Unix-like operating system. Furthermore, it is compliant to the draft external debug spec 0.13.

It has a configurable size, separate TLBs, a hardware PTW and branch-prediction (branch target buffer and branch history table). The primary design goal was on reducing critical path length.

The CVA6 core is part of a vivid ecosystem. In [this document](RESOURCES.md), we gather pointers to this ecosystem (building blocks, designs, partners...).

A performance model of CVA6 is available in the `perf-model/` folder of this repository.
It can be used to investigate performance-related micro-architecture changes.

<img src="docs/03_cva6_design/_static/ariane_overview.drawio.png"/>

# Quick setup

The following instructions will allow you to compile and run a Verilator model of the CVA6 APU (which instantiates the CVA6 core) within the CVA6 APU testbench (corev_apu/tb).

Throughout all build and simulations scripts executions, you can use the environment variable `NUM_JOBS` to set the number of concurrent jobs launched by `make`:

- if left undefined, `NUM_JOBS` will default to 1, resulting in a sequential execution
  of `make` jobs;
- when setting `NUM_JOBS` to an explicit value, it is recommended not to exceed 2/3 of
  <<<<<<< HEAD
  the total number of virtual cores available on your system.
  =======
  the total number of virtual cores available on your system.
  > > > > > > > 1ece3d5f (Separate env setups)

1. Checkout the repository and initialize all submodules.

```sh
git clone https://github.com/openhwgroup/cva6.git
cd cva6
git submodule update --init --recursive
```

2. Install the GCC Toolchain [build prerequisites](util/toolchain-builder/README.md#Prerequisites) then [the toolchain itself](util/toolchain-builder/README.md#Getting-started).

:warning: It is **strongly recommended** to use the toolchain built with the provided scripts.

3. Install `cmake`, version 3.14 or higher.

4. Set the RISCV environment variable.

```sh
export RISCV=/path/to/toolchain/installation/directory
```

5. Install `help2man` and `device-tree-compiler` packages.

For Debian-based Linux distributions, run :

```sh
sudo apt-get install help2man device-tree-compiler
```

6. Install the riscv-dv requirements:

```sh
pip3 install -r verif/sim/dv/requirements.txt
```

7. Run these commands to install a custom Spike and Verilator (i.e. these versions must be used to simulate the CVA6) and [these](#running-regression-tests-simulations) tests suites.

```sh
# DV_SIMULATORS is detailed in the next section
export DV_SIMULATORS=veri-testharness,spike
bash verif/regress/smoke-tests.sh
```

# Tutorials

- **[Running Simulations](tutorials/running_sim.md)**
- **[ASIC Implementation](tutorials/asic.md)**
- **[FPGA Implementation and running an OS](tutorials/fpga.md)**

# Directory Structure

The directory structure separates the [CVA6 RISC-V CPU](#cva6-risc-v-cpu) core from the [CORE-V-APU FPGA Emulation Platform](#corev-apu-fpga-emulation).
Files, directories and submodules under `cva6` are for the core _only_ and should not have any dependencies on the APU.
Files, directories and submodules under `corev_apu` are for the FPGA Emulation platform.
The CVA6 core can be compiled stand-alone, and obviously the APU is dependent on the core.

The top-level directories of this repo:

- **ci**: Scriptware for CI.
- **common**: Source code used by both the CVA6 Core and the COREV APU. Subdirectories from here are `local` for common files that are hosted in this repo and `submodules` that are hosted in other repos.
- **core**: Source code for the CVA6 Core only. There should be no sources in this directory used to build anything other than the CVA6 core.
- **corev_apu**: Source code for the CVA6 APU, exclusive of the CVA6 core. There should be no sources in this directory used to build the CVA6 core.
- **docs**: Documentation.
- **pd**: Example and CI scripts to synthesis CVA6.
- **util**: General utility scriptware.
- **vendor**: Third-party IP maintained outside the repository.
- **verif**: Verification environment for the CVA6. The verification files shared with other cores are in the [core-v-verif](https://github.com/openhwgroup/core-v-verif) repository on GitHub. core-v-verif is defined as a cva6 submodule.

## verif Directories

- **bsp**: board support package for test-programs compiled/assembled/linked for the CVA6.
  This BSP is used by both `core` testbench and `uvmt_cva6` UVM verification environment.
- **regress**: scripts to install tools, test suites, CVA6 code and to execute tests
- **sim**: simulation environment (e.g. riscv-dv)
- **tb**: testbench module instancing the core
- **tests**: source of test cases and test lists

# Contributing

We highly appreciate community contributions.
To ease the work of reviewing contributions, please review [CONTRIBUTING](CONTRIBUTING.md).

Contributions to the documentation (`docs/` and `tutorials/` directories) are very welcome as well.

If you find any problems or issues with CVA6 or the documentation, please check out the [issue tracker](https://github.com/openhwgroup/cva6/issues)
and create a new issue if your problem is not yet tracked. \
[The CVA6 Kanban Board](https://github.com/orgs/openhwgroup/project/3/view/7) loosely tracks planned improvements.

# Publication

If you use CVA6 in your academic work you can cite us:

<details>
<summary>CVA6 Publication</summary>

```
@article{zaruba2019cost,
   author={F. {Zaruba} and L. {Benini}},
   journal={IEEE Transactions on Very Large Scale Integration (VLSI) Systems},
   title={The Cost of Application-Class Processing: Energy and Performance Analysis of a Linux-Ready 1.7-GHz 64-Bit RISC-V Core in 22-nm FDSOI Technology},
   year={2019},
   volume={27},
   number={11},
   pages={2629-2640},
   doi={10.1109/TVLSI.2019.2926114},
   ISSN={1557-9999},
   month={Nov},
}
```

</details>

# Acknowledgements

Check out the [acknowledgements](ACKNOWLEDGEMENTS.md).
