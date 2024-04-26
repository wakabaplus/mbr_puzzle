bits 16
org 0x7c00

%define MAX_X 8
%define MAX_Y 8
%define EMPTY '.'
%define PLAYER 'O'
%define GOAL 'G'
%define WALL 'X'
%define STONE '*'
%define NEWLINE_0D 0x0d
%define NEWLINE_0A 0x0a

%macro DEBUG 0
    xchg bx, bx
%endmacro

init:
    mov ax, 3
    int 0x10
    .loop:
        .draw:
            xor bx, bx
            mov al, "L"
            call putchar
            mov al, "V"
            call putchar
            mov al, byte [lv]
            add al, "0"
            call putchar
            .y:
                call print_0d0a
                cmp bl, MAX_Y
                jz .main
                xor cx, cx
                .x:
                    cmp cl, MAX_X
                    jz .end_x
                    cmp cl, [player_x]
                    jz .check_player_y
                .normal1:
                    cmp cl, [goal_x]
                    jz .check_goal_y
                .normal2:
                    cmp cl, [stone_x]
                    jz .check_stone_y
                .normal:
                    or byte [map+bx], 0b10000001
                    bt [map+bx], cx
                    jnc .print_empty
                    mov al, WALL
                    jmp .putchar
                    .check_player_y:
                        cmp bl, [player_y]
                        jnz .normal1
                        mov al, PLAYER
                        jmp .putchar
                    .check_goal_y:
                        cmp bl, [goal_y]
                        jnz .normal2
                        mov al, GOAL
                        jmp .putchar
                    .check_stone_y:
                        cmp bl, [stone_y]
                        jnz .normal
                        mov al, STONE
                        jmp .putchar
                    .print_empty:
                        mov al, EMPTY
                    .putchar:
                        call putchar
                        inc cx
                        jmp .x
                .end_x:
                    inc bx
                    jmp .y
    .main:
        call main
        cmp byte [lv], 1
        jz .next
        pusha
        mov ah, 2
        int 0x1a
        xor ax, ax
        add ax, cx
        mul dh
        mov [map+1], ax
        mul cx
        mov [map+3], ax
        mul cx
        mov [map+5], ax
        popa
        .next:
        mov bl, [stone_x]
        cmp bl, [goal_x]
        jnz .loop
        mov bl, [stone_y]
        cmp bl, [goal_y]
        jnz .loop
        mov al, [lv]
        inc al
        mov byte [lv], al
        mov byte [player_x], 1
        mov byte [player_y], 1
        mov byte [goal_x], 6
        mov byte [goal_y], 6
        mov byte [stone_x], 2
        mov byte [stone_y], 2
        jmp init


print_0d0a:
    mov al, NEWLINE_0D
    call putchar
    mov al, NEWLINE_0A
    call putchar
    ret

main:
    call wait_key
    movzx bx, byte [player_y]
    movzx cx, byte [player_x]
    cmp ax, 0x4800 ; UP
    jz .dec_y
    cmp ax, 0x5000 ; DOWN
    jz .inc_y
    cmp ax, 0x4b00 ; LEFT
    jz .dec_x
    cmp ax, 0x4d00 ; RIGHT
    jz .inc_x
    jmp .end
    .dec_y:
        dec bx
        bt [map+bx], cx
        jnc .check_stone
        inc bx
        jmp .end
        .check_stone:
        cmp bl, [stone_y]
        jnz .end
        cmp cl, [stone_x]
        jnz .end
        test bx, bx
        jz .end
        push bx
        dec bx
        bt [map+bx], cx
        jc .end_a
        mov [stone_y], bl-1
        jmp .o_end
        .end_a:
        pop bx
        inc bx
        jmp .end
        .o_end:
        pop bx
        jmp .end
    .inc_y:
        inc bx
        bt [map+bx], cx
        jnc .check_stone3
        dec bx
        jmp .end
        .check_stone3:
        cmp bl, [stone_y]
        jnz .end
        cmp cl, [stone_x]
        jnz .end
        cmp bx, 7
        ja .end
        push bx
        inc bx
        bt [map+bx], cx
        jc .end_a3
        mov [stone_y], bl
        jmp .o_end
        .end_a3:
        pop bx
        dec bx
        jmp .end
    .dec_x:
        dec cx
        bt [map+bx], cx
        jnc .check_stone2
        inc cx
        jmp .end
        .check_stone2:
        cmp bl, [stone_y]
        jnz .end
        cmp cl, [stone_x]
        jnz .end
        test cx, cx
        jz .end
        push cx
        dec cx
        bt [map+bx], cx
        jc .end_a2
        mov [stone_x], cl-1
        jmp .o_end2
        .end_a2:
        pop cx
        inc cx
        jmp .end
    .inc_x:
        inc cx
        bt [map+bx], cx
        jnc .check_stone4
        dec cx
        jmp .end
        .check_stone4:
        cmp bl, [stone_y]
        jnz .end
        cmp cl, [stone_x]
        jnz .end
        cmp cx, 7
        ja .end
        push cx
        inc cx
        bt [map+bx], cx
        jc .end_a4
        mov [stone_x], cl
        jmp .o_end2
        .end_a4:
        pop cx
        dec cx
        jmp .end
        .o_end2:
        pop cx
    .end:
        mov byte [player_x], cl
        mov byte [player_y], bl
        mov ah, 2
        mov bh, 0
        xor dx, dx
        int 0x10
        ret

wait_key:
    xor ax, ax
    int 0x16
    ret

putchar:
    pusha
    mov ah, 0xe
    xor bx, bx
    int 0x10
    popa
    ret

player_x db 1
player_y db 1
goal_x db 6
goal_y db 6
stone_x db 2
stone_y db 2

lv db 1

map db 0b11111111,
    db 0b10000001,
    db 0b10101001,
    db 0b10111001,
    db 0b10011001,
    db 0b10000001,
    db 0b10000001,
    db 0b11111111

times 510-($-$$) db 0
db 0x55, 0xaa
