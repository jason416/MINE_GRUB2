/*
 * Copyright 2014, General Dynamics C4 Systems
 *
 * This software may be distributed and modified according to the terms of
 * the GNU General Public License version 2. Note that NO WARRANTY is provided.
 * See "LICENSE_GPLv2.txt" for details.
 *
 * @TAG(GD_GPL)
 */
 
#include "assembler.h"

#define CONFIG_MULTIBOOT1_HEADER

#define MULTIBOOT_HEADER_MAGIC 0x1BADB002
#define MULTIBOOT_HEADER_FLAGS 0x7

#define MULTIBOOT_GRAPHICS     0x0
#define CONFIG_MULTIBOOT_GRAPHICS_MODE_HEIGHT 1280
#define CONFIG_MULTIBOOT_GRAPHICS_MODE_WIDTH  768
#define CONFIG_MULTIBOOT_GRAPHICS_MODE_DEPTH  32

.code32
.section .mbh
#ifdef CONFIG_MULTIBOOT1_HEADER
    /* MultiBoot header */
    .align  4
    .long   MULTIBOOT_HEADER_MAGIC; /*magic*/
    .long   MULTIBOOT_HEADER_FLAGS; /*flags*/
    .long   - MULTIBOOT_HEADER_FLAGS - MULTIBOOT_HEADER_MAGIC; /*checksum*/
    .long   0 /*header_addr*/
    .long   0 /*load_addr*/
    .long   0 /*load_end_addr*/
    .long   0 /*bss_end_addr*/
    .long   0 /*entry_addr*/
    .long   MULTIBOOT_GRAPHICS /*mode_type*/
    .long   CONFIG_MULTIBOOT_GRAPHICS_MODE_WIDTH /*width*/
    .long   CONFIG_MULTIBOOT_GRAPHICS_MODE_HEIGHT /*height*/
    .long   CONFIG_MULTIBOOT_GRAPHICS_MODE_DEPTH /*depth*/
#endif

#ifdef CONFIG_MULTIBOOT2_HEADER
    .align  8
__mbi2_start:
    /* magic multi-boot 2 header */
    .long   0xe85250d6
    .long   0x0
    .long   (__mbi2_end - __mbi2_start)
    .long  -(0xe85250d6 + (__mbi2_end - __mbi2_start))
    /* end tag - type, flags, size */
    .word   0x0
    .word   0x0
    .long   0x8
__mbi2_end:
#endif
