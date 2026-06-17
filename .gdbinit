# Copyright 2026 Univ. Grenoble Alpes, Inria, TIMA Laboratory
#
# SPDX-License-Identifier: Apaches-2.0 WITH SHL-2.1
#
# Authors       : Vincent Verdillon
# Creation Date : June, 2026
# Description   : Sanitize Makefile
# History       :

# Connection automatique au stub GDB de QEMU
target remote :1234
# Modification du prompt gdb
set prompt \001\033[1;36m\002(gdb-cva6) \001\033[0m\002
