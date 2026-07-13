# Copyright 2026 Univ. Grenoble Alpes, Inria, TIMA Laboratory
#
# SPDX-License-Identifier: Apaches-2.0 WITH SHL-2.1
#
# Authors       : Vincent Verdillon
# Creation Date : July, 2026
# Description   : Compose file for CVA6 128 bits docker environment
# History       :

#*****************************************************************************
# add.S
#-----------------------------------------------------------------------------
#
  .text
  .globl main
main:
  lq t4, mem_var

  li a0, 0x0

  j _exit

.data

.balign 4
mem_var:
    .octa 0xdeadbeefdeadbeefcafebabecafebabe
