// Copyright (c) 2025 Thales Research and Technology
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
/**
 * \file bootrom_types.h
 * \brief Contains custom types which show their size.
 * \author Julien Mallet
 *
*/
// Copyright 2026 Univ. Grenoble Alpes, Inria, TIMA Laboratory
// SPDX-License-Identifier: Apaches-2.0 WITH SHL-2.1
// Contributor: Vincent Verdillon


#ifndef BOOTROM_TYPES_H
#define BOOTROM_TYPES_H

#include <stdint.h>

typedef int8_t s8_t;
typedef uint8_t u8_t;

typedef int16_t s16_t;
typedef unsigned short u16_t;

typedef int32_t s32_t;
typedef uint32_t u32_t;

typedef int64_t s64_t;
typedef uint64_t u64_t;

typedef __int128_t s128_t;
typedef __uint128_t u128_t;

typedef uintptr_t uptr_t;

#endif
