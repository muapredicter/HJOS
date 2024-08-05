#!/bin/bash

cd /home/zhj/code/boot

# 编译 MBR
nasm -I include -o mbr.bin mbr.S
if [ $? -ne 0 ]; then
    echo "Error: Failed to compile MBR"
    exit 1
fi

# 将 MBR 写入硬盘映像
dd if=/home/zhj/code/boot/mbr.bin of=/home/zhj/bochs/HD60.img bs=512 count=1 conv=notrunc
if [ $? -ne 0 ]; then
    echo "Error: Failed to write MBR to HD60.img"
    exit 1
fi

# 编译加载器
nasm -I include -o loader.bin loader.S
if [ $? -ne 0 ]; then
    echo "Error: Failed to compile loader"
    exit 1
fi

# 将加载器写入硬盘映像
dd if=/home/zhj/code/boot/loader.bin of=/home/zhj/bochs/HD60.img bs=512 count=4 seek=2 conv=notrunc
if [ $? -ne 0 ]; then
    echo "Error: Failed to write loader to HD60.img"
    exit 1
fi

cd ..

# 编译内核打印模块
nasm -f elf -o lib/kernel/print.o lib/kernel/print.S
if [ $? -ne 0 ]; then
    echo "Error: Failed to compile kernel print module"
    exit 1
fi

# 编译内核主模块
gcc -m32 -I lib/kernel/ -c -o kernel/main.o kernel/main.c
if [ $? -ne 0 ]; then
    echo "Error: Failed to compile kernel main module"
    exit 1
fi

# 链接内核
ld -m elf_i386 -Ttext 0xc0001500 -e main -o kernel/kernel.bin  kernel/main.o lib/kernel/print.o
if [ $? -ne 0 ]; then
    echo "Error: Failed to link kernel"
    exit 1
fi

# 将内核写入硬盘映像
dd if=/home/zhj/code/kernel/kernel.bin of=/home/zhj/bochs/HD60.img bs=512 count=200 seek=9 conv=notrunc
if [ $? -ne 0 ]; then
    echo "Error: Failed to write kernel to HD60.img"
    exit 1
fi

echo "Build and installation completed successfully."
