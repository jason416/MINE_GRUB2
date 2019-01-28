#include "assembler.h"
#include "linkage.h"

#define IA32_EFER_MSR 0xC0000080

.section .phys.text
.code32

BEGIN_FUNC(_simple_loop)
1:
	nop
	jmp 1b
	ret
END_FUNC(_simple_loop)

BEGIN_FUNC(hang)
1:
	hlt
	jmp 1b
END_FUNC(hang)

BEGIN_FUNC(_start)
	cli 
	nop

    movl %eax, %edi /* multiboot_magic    */
    movl %ebx, %esi /* multiboot_info_ptr */

    /* Load kernel boot stack pointer */
    leal boot_stack_top, %esp

    /* Reset EFLAGS register (also disables interrupts etc.) */
    pushl $0
    popf

    /* Already push parameters for calling grub_test later. Push
     * them as 8 byte values so we can easily pop later. */
    pushl $0
    pushl %esi /* 2nd parameter: multiboot_info_ptr */
    pushl $0
    pushl %edi /* 1st parameter: multiboot_magic    */

    /* Disable paging. */
    movl %cr0, %eax
    andl $0x7fffffff, %eax
    movl %eax, %cr0

    /* Put base pointer in cr3. */
    movl $__PML4E, %eax
    movl %eax, %cr3

	/* Set PAE (bit 5) */
	movl $0x00000020, %eax
    movl %eax, %cr4

    /* Set LME (bit 8) in the extended feature MSR. */
    movl $IA32_EFER_MSR, %ecx
    rdmsr
	bt $11, %eax
	jc hang
    orl $0x100, %eax
    wrmsr

#if 1
    /* Set PG (bit 31) of cr0 to enable paging. */
	movl %cr0, %eax
    orl $0x80000000, %eax
    movl %eax, %cr0
#endif

	call _simple_loop

	lgdt _gdt64_ptr
    /* Reload CS with long bit to enable long mode. */
    ljmp $8, $_start64

END_FUNC(_start)


.code64
/*.align 4096*/
BEGIN_FUNC(_start64)
     /* Leave phys code behind and jump to the high kernel virtual address. */
    movabs $_entry_64, %rax
    jmp *%rax
END_FUNC(_start64)


.comm temp_buf,20,4
/* OS important data structure */
.section .phys.data
/* PG structure */
.align 8
.globl __PML4E
    
__PML4E:                     /* level 1 */
	.quad	0x102007
	.fill	255,8,0
	.quad	0x102007
	.fill	255,8,0

/* level 2 */
__PDPTE:
	.quad	0x103007		/* set user accessible */
	.fill	511,8,0

/* level 3 */
__PDE:
	.quad	0x000087		/* set user accessible */
	.quad	0x200087
	.quad	0x400087
	.quad	0x600087
	.quad	0x800087
	.quad	0x80000087		/* 0x a00000, physic addr: 0x8000,0000 */
	.quad	0x80200087
	.quad	0x80400087
	.quad	0x80600087		/* 0x1000000 */
	.quad	0x80800087		
	.quad	0x80a00087
	.quad	0x80c00087
	.quad	0x80e00087
	.fill	499,8,0
	
.align 16
_gdt64_ptr:
GDT_LIMIT:	.word	GDT_END - GDT_Table - 1
GDT_BASE:	.long	GDT_Table

.globl GDT_Table
GDT_Table:
	.quad	0x0000000000000000			/*0	NULL descriptor		       	00*/
	.quad	0x0020980000000000			/*1	KERNEL	Code	64-bit	Segment	08*/
	.quad	0x0000920000000000			/*2	KERNEL	Data	64-bit	Segment	10*/
	.quad	0x0000000000000000			/*3	USER	Code	32-bit	Segment 18*/
	.quad	0x0000000000000000			/*4	USER	Data	32-bit	Segment 20*/
	.quad	0x0020f80000000000			/*5	USER	Code	64-bit	Segment	28*/
	.quad	0x0000f20000000000			/*6	USER	Data	64-bit	Segment	30*/
	.quad	0x00cf9a000000ffff			/*7	KERNEL	Code	32-bit	Segment	38*/
	.quad	0x00cf92000000ffff			/*8	KERNEL	Data	32-bit	Segment	40*/
	.fill	10,8,0						/*10 ~ 11 TSS (jmp one segment <9>) in long-mode 128-bit 50*/
GDT_END:

_idt64_ptr:
IDT_LIMIT:	.word	IDT_END - IDT_Table - 1
IDT_BASE:	.long	IDT_Table

/* OS IDT_Table */
.globl IDT_Table
IDT_Table:                              /*  each discriptor is 128-bits, 256 * 16B */
	.fill  512,8,0
IDT_END:



/* OS TSS64_Table */

.globl	TSS64_Table
TSS64_Table:
	.fill  13,8,0                       /* 13 * 8 = 26 * 4, Rspn and ISTn */
TSS64_END:

TSS64_POINTER:
TSS64_LIMIT:	.word	TSS64_END - TSS64_Table - 1
TSS64_BASE:		.quad	TSS64_Table


.code64
.section .boot.text

BEGIN_FUNC(_entry_64)
	mov	$0x10,	%ax         /* reflush ds,es,... */
	mov	%ax,	%ds
	mov	%ax,	%es
	mov	%ax,	%fs
	mov	%ax,	%gs
	mov	%ax,	%ss
    movq   $0x7E00,	%rsp    /* update rsp */

/* load	cr3, -> PML4 base */
	movq	$__PML4E,	%rax
	movq	%rax,		%cr3

/*-------------------- 64 bits code ---------------------*/
switch_seg:
    .quad	entry64

entry64:
    movq	$0x10,	%rax
	movq	%rax,	%ds
	movq	%rax,	%es
	movq	%rax,	%gs
	movq	%rax,	%ss

	pop %rdi
	pop %rsi

#if 0
loop:   
    jmp     loop
#endif
	call grub_test


#	movq	_stack_start(%rip),	%rsp	/* rsp address , kernel stack base */

/* initialize basic IDT, each save ignore_int address */
setup_IDT:							
	leaq	ignore_int(%rip),	%rdx
	movq	$(0x08 << 16),	%rax
	movw	%dx,	%ax
	movq	$(0x8E00 << 32),	%rcx		
	addq	%rcx,	%rax
	movl	%edx,	%ecx
	shrl	$16,	%ecx
	shlq	$48,	%rcx
	addq	%rcx,	%rax
	shrq	$32,	%rdx
	leaq	IDT_Table(%rip),	%rdi
	mov		$256,	%rcx
rp_sidt:
	movq	%rax,	(%rdi)
	movq	%rdx,	8(%rdi)
	addq	$0x10,	%rdi
	dec	%rcx
	jne	rp_sidt

/* initialize basic TSS64 */
setup_TSS64:
	leaq	TSS64_Table(%rip),	%rdx
	xorq	%rax,	%rax
	xorq	%rcx,	%rcx
	movq	$0x89,	%rax
	shlq	$40,	%rax
	movl	%edx,	%ecx
	shrl	$24,	%ecx
	shlq	$56,	%rcx
	addq	%rcx,	%rax
	xorq	%rcx,	%rcx
	movl	%edx,	%ecx
	andl	$0xffffff,	%ecx
	shlq	$16,	%rcx
	addq	%rcx,	%rax
	addq	$103,	%rax
	leaq	GDT_Table(%rip),	%rdi
	movq	%rax,	80(%rdi)			/* 8th -> 10th, in GDT */
	shrq	$32,	%rdx
	movq	%rdx,	88(%rdi)

/* TO DO: */
#if 0										/* update with GDT */
	mov	$0x50,	%ax							/* jump 9, 10-11 is TSS64*/
	ltr	%ax									/* load TSS64 discriptor to TR*/
#endif

/* jump to go_to kernel */
    movq	go_to_kernel(%rip),	%rax		/* movq address */
	pushq	$0x08
	pushq	%rax
	lretq

go_to_kernel:
	/* Pop the multiboot parameters off. */
    pop %rdi
    pop %rsi
	.quad	Start_Kernel

/* all vector(0-255) default handler */
ignore_int:
	cld
	pushq	%rax
	pushq	%rbx
	pushq	%rcx
	pushq	%rdx
	pushq	%rbp
	pushq	%rdi
	pushq	%rsi

	pushq	%r8
	pushq	%r9
	pushq	%r10
	pushq	%r11
	pushq	%r12
	pushq	%r13
	pushq	%r14
	pushq	%r15

	movq	%es,	%rax
	pushq	%rax
	movq	%ds,	%rax
	pushq	%rax

	movq	$0x10,	%rax
	movq	%rax,	%ds						/* load kernel_64 data sector*/
	movq	%rax,	%es

/* rax func(rdi, rsi, rdx, rcx, r8, r9) 
 * here, rax = color_printk(0x00ff0000 RED, 0x00000000 BLACK, int_msg)
*/
	leaq	int_msg(%rip),	%rax			/* leaq get address */
	pushq	%rax							/* save string base addr*/
	movq	%rax,	%rdx
	movq	$0x00000000,	%rsi
	movq	$0x00ff0000,	%rdi
	movq	$0,	%rax
#	callq	color_printk
	addq	$0x8,	%rsp					/* caller banlance stack*/

Loop:
	jmp	Loop	

	popq	%rax
	movq	%rax,	%ds
	popq	%rax
	movq	%rax,	%es

	popq	%r15
	popq	%r14
	popq	%r13
	popq	%r12
	popq	%r11
	popq	%r10
	popq	%r9
	popq	%r8

	popq	%rsi
	popq	%rdi
	popq	%rbp
	popq	%rdx
	popq	%rcx
	popq	%rbx
	popq	%rax
	iretq

int_msg:
	.asciz "Unknown interrupt or fault at RIP\n"

#ENTRY(_stack_start)
# 	.quad	init_task_union + 32768


END_FUNC(_entry_64)
