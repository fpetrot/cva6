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
# /root/src -> compile stuff
# /opt/tools -> install non packaged dependencies
# /work/bin -> built binaries
#
ENV ROOTSRCS=/root/src
ENV INSTPATH=/opt/tools
ENV BINBUILD=/work/bin

# Set path environment
ENV PATH=$INSTPATH/bin:$PATH
ENV PATH=$BINBUILD:$PATH

# Working directory
WORKDIR /work

# Create directories
RUN mkdir -p $INSTPATH $ROOTSRCS

#
# Dependencies
#
RUN apt-get update

# basic tools
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --no-install-suggests \
    apt-utils \
    nano \
    less \
    file \
    grep \
    help2man

# network dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --no-install-suggests \
    curl \
    wget \
    git \
    openssh-client

# programming languages
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --no-install-suggests \
    python3

# CVA6 dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --no-install-suggests \
    autoconf \
    automake \
    autotools-dev \
    bc \
    bison \
    build-essential \
    device-tree-compiler \
    flex \
    gawk \
    gperf \
    libmpc-dev \
    libmpfr-dev \
    libgmp-dev \
    libtool \
    texinfo \
    zlib1g-dev

# clean the last installs
RUN apt-get clean

