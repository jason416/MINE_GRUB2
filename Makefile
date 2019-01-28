
CC=gcc

MARCH_FLAGS = -march=nehalem -mno-mmx -mno-sse -mno-sse2 -mno-3dnow
OTHER_FLAGS = -O2 -g -ggdb 
AS_FALGS = -Wa,--64 -nostdinc -nostdlib -mcmodel=kernel -fno-pic -fno-pie -fno-stack-protector -fno-asynchronous-unwind-tables \
-std=c99 -Wall -Werror -Wstrict-prototypes -Wmissing-prototypes -Wnested-externs -Wmissing-declarations -Wundef -Wpointer-arith -Wno-nonnull -ffreestanding


CC_FLAGS=-m64 -nostdinc -nostdlib -mcmodel=kernel -fno-pic -fno-pie -fno-stack-protector -fno-asynchronous-unwind-tables -std=c99 \
-Wall -Werror -Wstrict-prototypes -Wmissing-prototypes -Wnested-externs -Wmissing-declarations -Wundef -Wpointer-arith -Wno-nonnull -ffreestanding 

KERNEL_FLAGS=-m64 -Wl,-m -Wl,elf_x86_64 -nostdinc -nostdlib -mcmodel=kernel -fno-pic -fno-pie -ffreestanding -Wl,--build-id=none -static -Wl,-n

all: kernel.elf

#$@--OBJ，$^--ALL FILE NEEDED，$<--FIRST FILE NEEDED。

ASM_OBJ=multiboot.o head.o #entry.o
C_OBJ=grub_test.o main.o

multiboot.o: multiboot.S
	$(CC) $(AS_FALGS) -o $@ -c $<
head.o: head.S
	$(CC) $(AS_FALGS) -o $@ -c $< 
entry.o: entry.S
	$(CC) $(AS_FALGS) -o $@ -c $^ 

grub_test.o: grub_test.c
	$(CC) $(CC_FLAGS) -o $@ -c $<
main.o: main.c
	$(CC) $(CC_FLAGS) -o $@ -c $<

kernel.elf: $(ASM_OBJ) $(C_OBJ) 
	$(CC) $(KERNEL_FLAGS) -T linker.lds $^ -o $@64
	objcopy -O elf32-i386 $@64 $@ 
	@#rm -rf $@64

.PHONY:
	clean

clean:
	rm -rf kernel.elf* *.o 


#objcopy -O elf32-i386 kernel.elf kernel-x86_64-pc99
#cp capdl-loader capdl-loader-image-x86_64-pc99

# .S compile flags
# gcc -Wa,--64  -march=nehalem -O2 -g -ggdb -nostdinc -nostdlib -mcmodel=kernel -fno-pic -fno-pie -fno-stack-protector -fno-asynchronous-unwind-tables \
-std=c99 -Wall -Werror -Wstrict-prototypes -Wmissing-prototypes -Wnested-externs -Wmissing-declarations -Wundef -Wpointer-arith -Wno-nonnull -ffreestanding \
-mno-mmx -mno-sse -mno-sse2 -mno-3dnow -o head.S.obj -c head.S

# kernel.c compile flags
# gcc -m64 -march=nehalem -O2 -g -ggdb -nostdinc -nostdlib -mcmodel=kernel -fno-pic -fno-pie -fno-stack-protector -fno-asynchronous-unwind-tables -std=c99 \
-Wall -Werror -Wstrict-prototypes -Wmissing-prototypes -Wnested-externs -Wmissing-declarations -Wundef -Wpointer-arith -Wno-nonnull -ffreestanding \
-mno-mmx -mno-sse -mno-sse2 -mno-3dnow -o kernel_all.i.obj -c kernel_all.i

# for kernel.elf, compile .c and .s
# gcc -m64  -march=nehalem -O2 -g -march=nehalem  -Wl,-m -Wl,elf_x86_64 -nostdinc -nostdlib -O2 -g -ggdb -mcmodel=kernel -fno-pic -fno-pie -ffreestanding -Wl,--build-id=none \
-static -Wl,-n  -T linker.lds_pp multiboot.S.obj machine_asm.S.obj traps.S.obj head.S.obj kernel_all.i.obj  -o kernel/kernel.elf 

