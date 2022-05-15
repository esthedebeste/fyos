nasm ./kernel/kernel_entry.asm -f elf -o bin/kernel_entry.o
fy com ./kernel/kernel.fy bin/kernel.ll
clang -target i386 -ffreestanding -c bin/kernel.ll -o bin/kernel.o
ld.lld -o bin/kernel.bin -Ttext 0x1000 bin/kernel_entry.o bin/kernel.o --oformat binary
cd boot
nasm bootsect.asm -f bin -o ../bin/bootsect.bin
cd ..
cat bin/bootsect.bin bin/kernel.bin > bin/os-image.bin
qemu-system-i386 -fda bin/os-image.bin