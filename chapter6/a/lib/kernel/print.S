TI_GDT equ 0 
RPL0 equ 0 
SELECTOR_VIDEO equ (0x0003<<3) + TI_GDT + RPL0 
                                        
[bits 32] 
section .text 
                                        ; ------------------------ put_char ----------------------------- 
                                        ; 功能描述：把栈中的 1 个字符写入光标所在处
                                        ; ------------------------------------------------------------------- 
global put_char 
put_char: 
    pushad                              ; 备份 32 位寄存器环境
                                        ; 需要保证 gs 中为正确的视频段选择子
                                        ; 为保险起见，每次打印时都为 gs 赋值
    mov ax, SELECTOR_VIDEO              ; 不能直接把立即数送入段寄存器
    mov gs, ax 

                                        ; ------ 获取当前光标位置 ------
                                        ; 先获得高 8 位
    mov dx, 0x03d4                      ; 索引寄存器
    mov al, 0x0e                        ; 用于提供光标位置的高 8 位
    out dx, al 
    mov dx, 0x03d5                      ; 通过读写数据端口 0x3d5 来获得或设置光标位置
    in al, dx                           ; 得到了光标位置的高 8 位
    mov ah, al 

                                        ; 再获取低 8 位
    mov dx, 0x03d4 
    mov al, 0x0f 
    out dx, al 
    mov dx, 0x03d5 
    in al, dx 

                                        ; 将光标存入 bx 
    mov bx, ax 
                                        ; 下面这行是在栈中获取待打印的字符
    mov ecx, [esp + 36]                 ; pushad 压入 4×8＝32 字节，
                                        ; 加上主调函数 4 字节的返回地址，故 esp+36 字节
    cmp cl, 0xd                         ; CR 是 0x0d，LF 是 0x0a 
    jz .is_carriage_return 
    cmp cl, 0xa 
    jz .is_line_feed 

    cmp cl, 0x8                         ; BS(backspace)的 asc 码是 8 
    jz .is_backspace 
    jmp .put_other 

.is_backspace: 
                                        ; ------ backspace 的一点说明 ------
                                        ; 当为 backspace 时，本质上只要将光标移向前一个显存位置即可.后面再输入的字符自然会覆盖此处的字符
                                        ; 但有可能在键入backspace 后并不再键入新的字符，这时光标已经向前移动到待删除的字符位置，但字符还在原处
                                        ; 这就显得好怪异，所以此处添加了空格或空字符 0 
    dec bx 
    shl bx,1                            ; 光标左移 1 位等于乘 2 
                                        ; 表示光标对应显存中的偏移字节
    mov byte [gs:bx], 0x20              ; 将待删除的字节补为 0 或空格皆可
    inc bx 
    mov byte [gs:bx], 0x07 
    shr bx,1 
    jmp .set_cursor 

.put_other: 
    shl bx, 1                           ; 光标位置用 2 字节表示，将光标值乘 2 
                                        ; 表示对应显存中的偏移字节
    mov [gs:bx], cl                     ; ASCII 字符本身
    inc bx 
    mov byte [gs:bx],0x07               ; 字符属性
    shr bx, 1                           ; 恢复老的光标值
    inc bx                              ; 下一个光标值
    cmp bx, 2000 
    jl .set_cursor                      ; 若光标值小于 2000，表示未写到
                                        ; 显存的最后，则去设置新的光标值
                                        ; 若超出屏幕字符数大小（2000）
                                        ; 则换行处理
.is_line_feed:                          ; 是换行符 LF(\n) 
.is_carriage_return:                    ; 是回车符 CR(\r) 
                                        ; 如果是 CR(\r)，只要把光标移到行首就行了
    xor dx, dx                          ; dx 是被除数的高 16 位，清 0 
    mov ax, bx                          ; ax 是被除数的低 16 位
    mov si, 80                          ; 由于是效仿 Linux，Linux 中\n 表示
                                        ; 下一行的行首，所以本系统中
    div si                              ; 把\n 和\r 都处理为 Linux 中\n 的意思
                                        ; 也就是下一行的行首
    sub bx, dx                          ; 光标值减去除 80 的余数便是取整
                                        ; 以上 4 行处理\r 的代码

.is_carriage_return_end:                ; 回车符 CR 处理结束
    add bx, 80 
    cmp bx, 2000 
.is_line_feed_end:                      ; 若是 LF(\n),将光标移+80 便可
    jl .set_cursor 
                                        ; 屏幕行范围是 0～24，滚屏的原理是将屏幕的第 1～24 行搬运到第 0～23 行
                                        ; 再将第 24 行用空格填充
.roll_screen:                           ; 若超出屏幕大小，开始滚屏
    cld 
    mov ecx, 960                        ; 2000-80=1920 个字符要搬运，共 1920*2=3840 字节
                                        ; 一次搬 4 字节，共 3840/4=960 次
    mov esi, 0xc00b80a0                 ; 第 1 行行首
    mov edi, 0xc00b8000                 ; 第 0 行行首
    rep movsd 

                                        ; 将最后一行填充为空白
    mov ebx, 3840                       ; 最后一行首字符的第一个字节偏移= 1920 * 2 
    mov ecx, 80                         ; 一行是 80 字符（160 字节），每次清空 1 字符
                                        ; （2 字节），一行需要移动 80 次
.cls: 
    mov word [gs:ebx], 0x0720           ; 0x0720 是黑底白字的空格键
    add ebx, 2 
    loop .cls 
    mov bx,1920                         ; 将光标值重置为 1920，最后一行的首字符

.set_cursor: 
                                        ; 将光标设为 bx 值
                                        ; ------ 1 先设置高 8 位 ------
    mov dx, 0x03d4                      ; 索引寄存器
    mov al, 0x0e                        ; 用于提供光标位置的高 8 位
    out dx, al 
    mov dx, 0x03d5                      ; 通过读写数据端口 0x3d5 来获得或设置光标位置
    mov al, bh 
    out dx, al 

                                        ; ------ 2 再设置低 8 位 ------
    mov dx, 0x03d4 
    mov al, 0x0f 
    out dx, al 
    mov dx, 0x03d5 
    mov al, bl 
    out dx, al 
.put_char_done: 
    popad 
    ret 