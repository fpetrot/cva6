# Copyright 2022 Thales DIS design services SAS
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Guillaume Chauvon (guillaume.chauvon@thalesgroup.fr)

#*****************************************************************************
# add.S
#-----------------------------------------------------------------------------
#
  .text
  .globl main
main:
# core of the test
  li t0, 0x0
  li t1, 0x0
  add a0, t0, t1
  j _exit

