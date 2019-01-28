/***************************************************
*		版权声明
*
*	本操作系统名为：MINE
*	该操作系统未经授权不得以盈利或非盈利为目的进行开发，
*	只允许个人学习以及公开交流使用
*
*	代码最终所有权及解释权归田宇所有；
*
*	本模块作者：	田宇
*	EMail:		345538255@qq.com
*
*
***************************************************/

/* 
 * exception and interrupt handler entry, writen in assembly
*/

#include "linkage.h"

R15	=	0x00
R14	=	0x08
R13	=	0x10
R12	=	0x18
R11	=	0x20
R10	=	0x28
R9	=	0x30
R8	=	0x38
RBX	=	0x40
RCX	=	0x48
RDX	=	0x50
RSI	=	0x58
RDI	=	0x60
RBP	=	0x68
DS	=	0x70
ES	=	0x78
RAX	=	0x80
FUNC	=	0x88
ERRCODE	=	0x90
RIP	=	0x98
CS	=	0xa0
RFLAGS	=	0xa8
OLDRSP	=	0xb0
OLDSS	=	0xb8

RESTORE_ALL:
	popq	%r15;		
	popq	%r14;		
	popq	%r13;		
	popq	%r12;		
	popq	%r11;		
	popq	%r10;		
	popq	%r9;		
	popq	%r8;		
	popq	%rbx;		
	popq	%rcx;		
	popq	%rdx;		
	popq	%rsi;		
	popq	%rdi;		
	popq	%rbp;		
	popq	%rax;		
	movq	%rax,	%ds;	/* pop ds, GAS not surppot pop ds in 64-bits*/
	popq	%rax;		
	movq	%rax,	%es;	/* pop es */
	popq	%rax;			/* pop real rax */
	addq	$0x10,	%rsp;	/* pop error code and handler */
	iretq;					/* if IOPL change, auto pop OLDSS OLDRSP*/

#define GET_CURRENT(reg)	\
	movq	$-32768,reg		\
	andq	%rsp,	reg

ret_from_exception:
	/*GET_CURRENT(%ebx)	need rewrite*/
ENTRY(ret_from_intr)
	jmp	RESTORE_ALL	/*need rewrite*/

ENTRY(system_call)
	sti							/* must enable interrupt */
	subq	$0x38,	%rsp		/* fake stack operation */		 
	cld;					 

	pushq	%rax;				 /* save vector, for raw system call func */
	movq	%es,	%rax;			 	
	pushq	%rax;				 	
	movq	%ds,	%rax;			 	
	pushq	%rax;				 	
	xorq	%rax,	%rax;			 	
	pushq	%rbp;				 	
	pushq	%rdi;				 	
	pushq	%rsi;				 	
	pushq	%rdx;				 /* pop value store at ring 3 code */	
	pushq	%rcx;				 /* the same as rdx, prepare for sysexit */
	pushq	%rbx;				 	
	pushq	%r8;				 	
	pushq	%r9;				 	
	pushq	%r10;				 
	pushq	%r11;				 
	pushq	%r12;				 	
	pushq	%r13;				 
	pushq	%r14;				 	
	pushq	%r15;				 	
	movq	$0x10,	%rdx;		/* KERNEL_CODE */	 	
	movq	%rdx,	%ds;			 	
	movq	%rdx,	%es;			 
	movq	%rsp,	%rdi		/* rsp, args1 for system_call_function */		 	
			
	callq	system_call_function /* raw system call function */


ENTRY(ret_system_call)		
	movq	%rax,	0x80(%rsp)	/* update return value for syscall */
	popq	%r15				 
	popq	%r14				 	
	popq	%r13				 	
	popq	%r12				 	
	popq	%r11				 	
	popq	%r10				 	
	popq	%r9				 	
	popq	%r8				 	
	popq	%rbx				 	
	popq	%rcx				 	
	popq	%rdx				 	
	popq	%rsi				 	
	popq	%rdi				 	
	popq	%rbp				 	
	popq	%rax				 	
	movq	%rax,	%ds			 
	popq	%rax				 
	movq	%rax,	%es			 
	popq	%rax				 
	addq	$0x38,	%rsp	/* fake stack operation */
	.byte	0x48		 	/* prefix for 64bits*/
	sysexit	

ENTRY(divide_error)
	pushq	$0				/* fake error code */
	pushq	%rax
	leaq	do_divide_error(%rip),	%rax
	xchgq	%rax,	(%rsp)	/* push handler do_divide_error */

error_code:
	pushq	%rax			/* push rax */
	movq	%es,	%rax
	pushq	%rax			/* push es */
	movq	%ds,	%rax
	pushq	%rax			/* push ds */
	xorq	%rax,	%rax	/* clear rax */

	pushq	%rbp
	pushq	%rdi
	pushq	%rsi
	pushq	%rdx
	pushq	%rcx
	pushq	%rbx
	pushq	%r8
	pushq	%r9
	pushq	%r10
	pushq	%r11
	pushq	%r12
	pushq	%r13
	pushq	%r14
	pushq	%r15	
	
	cld
	movq	ERRCODE(%rsp),	%rsi /* 2nd arg, offset of error code */
	movq	FUNC(%rsp),	%rdx	

	movq	$0x10,	%rdi	/* change to kernel_64 data segment */
	movq	%rdi,	%ds
	movq	%rdi,	%es

	movq	%rsp,	%rdi	/* 1st arg */
	////GET_CURRENT(%ebx)

	callq 	*%rdx			/* func(dri, rsi), here func(rsp, error code offset*/

	jmp	ret_from_exception	

ENTRY(debug)
	pushq	$0
	pushq	%rax
	leaq	do_debug(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code

ENTRY(nmi)
	pushq	%rax			/* non-maskable/maskable interrupt, no error code */
	cld;			
	pushq	%rax;	
	
	pushq	%rax
	movq	%es,	%rax
	pushq	%rax
	movq	%ds,	%rax
	pushq	%rax
	xorq	%rax,	%rax
	
	pushq	%rbp;		
	pushq	%rdi;		
	pushq	%rsi;		
	pushq	%rdx;		
	pushq	%rcx;		
	pushq	%rbx;		
	pushq	%r8;		
	pushq	%r9;		
	pushq	%r10;		
	pushq	%r11;		
	pushq	%r12;		
	pushq	%r13;		
	pushq	%r14;		
	pushq	%r15;
	
	movq	$0x10,	%rdx;	
	movq	%rdx,	%ds;	
	movq	%rdx,	%es;
	
	movq	$0,	%rsi
	movq	%rsp,	%rdi

	callq	do_nmi

	jmp	RESTORE_ALL

ENTRY(int3)
	pushq	$0
	pushq	%rax
	leaq	do_int3(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code

ENTRY(overflow)
	pushq	$0
	pushq	%rax
	leaq	do_overflow(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code

ENTRY(bounds)
	pushq	$0
	pushq	%rax
	leaq	do_bounds(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code

ENTRY(undefined_opcode)
	pushq	$0
	pushq	%rax
	leaq	do_undefined_opcode(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code

ENTRY(dev_not_available)	/* need rewrite */
	pushq	$0
	pushq	%rax
	leaq	do_dev_not_available(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code


ENTRY(double_fault)
	pushq	%rax
	leaq	do_double_fault(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code

ENTRY(coprocessor_segment_overrun)
	pushq	$0
	pushq	%rax
	leaq	do_coprocessor_segment_overrun(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code

ENTRY(invalid_TSS)			/* auto push error code by CPU, but iret won't auto pop*/
	pushq	%rax
	leaq	do_invalid_TSS(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code

ENTRY(segment_not_present)
	pushq	%rax
	leaq	do_segment_not_present(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code

ENTRY(stack_segment_fault)
	pushq	%rax
	leaq	do_stack_segment_fault(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code

ENTRY(general_protection)
	pushq	%rax
	leaq	do_general_protection(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code

ENTRY(page_fault)		/* auto push error code */
	pushq	%rax
	leaq	do_page_fault(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code

ENTRY(x87_FPU_error)
	pushq	$0
	pushq	%rax
	leaq	do_x87_FPU_error(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code

ENTRY(alignment_check)
	pushq	%rax
	leaq	do_alignment_check(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code

ENTRY(machine_check)
	pushq	$0
	pushq	%rax
	leaq	do_machine_check(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code

ENTRY(SIMD_exception)
	pushq	$0
	pushq	%rax
	leaq	do_SIMD_exception(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code

ENTRY(virtualization_exception)
	pushq	$0
	pushq	%rax
	leaq	do_virtualization_exception(%rip),	%rax
	xchgq	%rax,	(%rsp)
	jmp	error_code


