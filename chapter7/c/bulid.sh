#!/bin/bash

cd /home/zhj/code
mkdir -p build  # 修正目录名，并添加 -p 以防止目录已存在的错误

# 编译 MBR
nasm -I boot/include -o build/mbr.bin boot/mbr.S
if [ $? -ne 0 ]; then
    echo "Error: Failed to compile MBR"
    exit 1
fi

# 将 MBR 写入硬盘映像
dd if=/home/zhj/code/build/mbr.bin of=/home/zhj/bochs/HD60.img bs=512 count=1 conv=notrunc
if [ $? -ne 0 ]; then
    echo "Error: Failed to write MBR to HD60.img"
    exit 1
fi

# 编译加载器
nasm -I boot/include -o build/loader.bin boot/loader.S
if [ $? -ne 0 ]; then
    echo "Error: Failed to compile loader"
    exit 1
fi

# 将加载器写入硬盘映像
dd if=/home/zhj/code/build/loader.bin of=/home/zhj/bochs/HD60.img bs=512 count=4 seek=2 conv=notrunc
if [ $? -ne 0 ]; then
    echo "Error: Failed to write loader to HD60.img"
    exit 1
fi

# 编译内核打印模块
nasm -f elf -o build/print.o lib/kernel/print.S
if [ $? -ne 0 ]; then
    echo "Error: Failed to compile kernel print module"
    exit 1
fi

# 编译内核模块
nasm -f elf -o build/kernel.o kernel/kernel.S
if [ $? -ne 0 ]; then
    echo "Error: Failed to compile kernel module"
    exit 1
fi

# 编译内核主模块
gcc -m32 -I lib/kernel/ -I lib/ -I kernel/ -c -fno-builtin -fno-stack-protector -o build/main.o kernel/main.c
if [ $? -ne 0 ]; then
    echo "Error: Failed to compile kernel main module"
    exit 1
fi

# 编译内核中断模块
gcc -m32 -I lib/kernel/ -I lib/ -I kernel/ -c -fno-builtin -fno-stack-protector -o build/interrupt.o kernel/interrupt.c
if [ $? -ne 0 ]; then
    echo "Error: Failed to compile kernel interrupt module"
    exit 1
fi

# 编译内核初始化模块
gcc -m32 -I lib/kernel/ -I lib/ -I kernel/ -c -fno-builtin -fno-stack-protector -o build/init.o kernel/init.c
if [ $? -ne 0 ]; then
    echo "Error: Failed to compile kernel init module"
    exit 1
fi

# 编译内核设备频率模块
gcc -m32 -I lib/kernel -c -o build/timer.o device/timer.c 
if [ $? -ne 0 ]; then
    echo "Error: Failed to compile kernel timer module"
    exit 1
fi

# 链接内核
ld -m elf_i386 -Ttext 0xc0001500 -e main -o build/kernel.bin build/main.o build/init.o build/interrupt.o build/print.o build/kernel.o build/timer.o
if [ $? -ne 0 ]; then
    echo "Error: Failed to link kernel"
    exit 1
fi

# 将内核写入硬盘映像
dd if=/home/zhj/code/build/kernel.bin of=/home/zhj/bochs/HD60.img bs=512 count=200 seek=9 conv=notrunc
if [ $? -ne 0 ]; then
    echo "Error: Failed to write kernel to HD60.img"
    exit 1
fi

rm -rf build

echo "Build and installation completed successfully."
