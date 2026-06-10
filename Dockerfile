# Copyright 2026 Univ. Grenoble Alpes, Inria, TIMA Laboratory
#
# SPDX-License-Identifier: Apaches-2.0 WITH SHL-2.1
#
# Authors       : Vincent Verdillon
# Creation Date : June, 2026
# Description   : Dockerfile for CVA6 128 bits environment
# History       :

# OS
FROM debian:stable-slim

# Labels
LABEL maintainer="Frédéric Pétrot <frederic.petrot@univ-grenoble-alpes.fr>"
LABEL Description="Image to build and run cva6 128 processor"

#
# Set environment
#
# Working directory
WORKDIR /cva6_128

#
# /root/src -> compile stuff
# /opt/tools -> install non packaged dependencies
# /cva6_128/bin -> built binaries
# /cva6_128/tmp -> tmp directory for verilator
#
ENV ROOTSRCS=/root/src
ENV INSTPATH=/opt/tools
ENV BINBUILD=/cva6_128/bin
ENV VERILATOR_TMP=/cva6_128/tmp

# Set path environment
ENV PATH=$INSTPATH/bin:$PATH
ENV PATH=$BINBUILD:$PATH

# Create directories
RUN mkdir -p $INSTPATH $ROOTSRCS $BINBUILD $VERILATOR_TMP
RUN mkdir /.venv && chmod 777 /.venv

#
# Dependencies
#
RUN apt-get update

# basic tools
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --no-install-suggests \
    apt-utils \
    bash-completion \
    file \
    grep \
    less \
    help2man \
    nano \
    vim

# network dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --no-install-suggests \
    curl \
    wget \
    git \
    openssh-client \
    openssl

# programming languages
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --no-install-suggests \
    python3 \
    python3-pip \
    python3-venv

# create the python environment
WORKDIR /tmp
RUN git clone https://github.com/fpetrot/cva6.git
WORKDIR /tmp/cva6
RUN git submodule update --init --recursive
RUN python3 -m venv /.venv
RUN /.venv/bin/pip3 install -r verif/sim/dv/requirements.txt
RUN rm -rf /tmp/cva6
RUN echo "source /.venv/bin/activate" >> /.bashrc
WORKDIR /cva6_128

# CVA6 dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --no-install-suggests \
    autoconf \
    automake \
    autotools-dev \
    bc \
    bison \
    build-essential \
    cmake \
    device-tree-compiler \
    flex \
    gawk \
    gdb \
    gperf \
    libfl-dev \
    libmpc-dev \
    libmpfr-dev \
    libgmp-dev \
    libtool \
    libdebuginfod1 \
    libcapstone-dev \
    libpixman-1-dev \
    libglib2.0-0 \
    texinfo \
    zlib1g-dev

# clean the last installs
RUN apt-get clean

# activate bash-completion and alias
RUN echo "source /usr/share/bash-completion/bash_completion" >> /.bashrc
RUN echo "alias nvim=vim" >> /.bashrc

# add environment variables to work with the CVA6
RUN echo "export CVA6_REPO_DIR=/cva6_128" >> /.bashrc
RUN echo "export RISCV=/cva6_128/tools/toolchain" >> /.bashrc
RUN echo "source /cva6_128/verif/sim/setup-env-all.sh" >> /.bashrc

# config gdb
RUN mkdir -p /.config/gdb
RUN echo "set auto-load safe-path /" >> /.config/gdb/gdbinit

# increase the size of the stack
RUN ulimit -s unlimited

