ENTRY(_start)
/*
PADDR_BASE = 0x00000000;
PADDR_LOAD = 0x00100000;
KERNEL_BASE  = 0xe0000000;
OUTPUT_ARCH(i386)
OUTPUT_FORMAT(elf32-i386)
*/

/* for amd64, long mode */
PADDR_BASE = 0x00000000;
PADDR_LOAD = 0x00100000;
KERNEL_BASE = 0xffffffff80000000;
OUTPUT_FORMAT(elf64-x86-64)

KERNEL_OFFSET = KERNEL_BASE - PADDR_BASE;

SECTIONS
{
    /* load kernel to 1M to avoid the famous IA-32 memory holes below */
    . = PADDR_LOAD;

    /* code/data only needed during bootstrapping, linked to physical addresses */

    .phys . :
    {
        *(.mbh)
        *(.phys.text)
        *(.phys.data)
        . = ALIGN(4K);
    }
    .phys.bss ADDR(.phys) + SIZEOF(.phys) (NOLOAD) :
    {
        boot_stack_bottom = .;
        . = . + 2K;
        . = ALIGN(4K);
        boot_stack_top = .;
        *(.phys.bss)
    }
    /* --------------enter kernel ----------------*/

	. = . + KERNEL_OFFSET;

    .boot . : AT(ADDR(.boot) - KERNEL_OFFSET)
    {
        *(.boot.text)
        *(.boot.data)
    }

    .boot.bss . (NOLOAD) : AT(ADDR(.boot.bss) - KERNEL_OFFSET)
    {
        *(.boot.bss)
        . = ALIGN(4K);
    }
    
	ki_boot_end = .;	/* record the end address of sgement for boot */
 
    .text . : AT(ADDR(.text) - KERNEL_OFFSET)
    {
		_text = .;
		*(.text)
		_etext = .;
    }

	. = ALIGN(8);

    .data . : AT(ADDR(.data) - KERNEL_OFFSET)
    {
		_data = .;
		*(.data)
		_edata = .;
    }

    .rodata . : AT(ADDR(.rodata) - KERNEL_OFFSET)
    {
        *(.rodata)
        *(.rodata.*)
    }

	/* 32KB space for init_task_union */
	. = ALIGN(32768);
	.data.init_task : AT(ADDR(.data.init_task) - KERNEL_OFFSET)
	{ 
		*(.data.init_task) 
	}

    .bss . : AT(ADDR(.bss) - KERNEL_OFFSET)
    {
		_bss = .;
		*(.bss)
        *(COMMON)
		_ebss = .;
    }

    .ehframe : AT(ADDR(.ehframe) - KERNEL_OFFSET)
    {
        _ehframe = .;
        *(.eh_frame)
        . = ALIGN(4K);
    }

    . = ALIGN(4K);
    ki_end = .;
	_end = .;

}
