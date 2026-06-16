org 0x7E00
bits 16

%define ENDL 0x0D, 0x0A

start:
    jmp main

; --- 16-BIT REAL MODE RENDERING ENGINE ---
draw_art:
    push si
    push ax
    push bx
.loop:
    lodsb               
    or al, al           
    jz .done            

    cmp al, 0x0D
    je .print_raw
    cmp al, 0x0A
    je .print_raw

    cmp al, '.'
    je .light_shade
    cmp al, '#'
    je .dark_shade
    cmp al, 'X'
    je .solid_block
    jmp .print_raw

.light_shade:
    mov al, 0xB0        
    jmp .print_raw
.dark_shade:
    mov al, 0xB2        
    jmp .print_raw
.solid_block:
    mov al, 0xDB        
    jmp .print_raw

.print_raw:
    mov ah, 0x0E        
    mov bh, 0           
    int 0x10
    jmp .loop
.done:
    pop bx
    pop ax
    pop si    
    ret

move_cursor:
    push ax
    push bx
    mov ah, 0x02
    mov bh, 0
    int 0x10
    pop bx
    pop ax
    ret

main:
    ; Clean segment bounds setup
    xor ax, ax                   
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7E00              

refresh_screen:
    ; 1. Clear Screen to Pitch Black with Bright White Text
    mov ah, 0x06        
    mov al, 0           
    mov cx, 0x0000      
    mov dx, 0x184F      
    mov bh, 0x0F        
    int 0x10

    ; 2. Render your layout logo
    mov dh, 0
    mov dl, 0
    call move_cursor
    mov si, art_matrix
    call draw_art

    ; 3. Print the interactive selection line
    mov dh, 22
    mov dl, 2
    call move_cursor
    mov si, msg_selection
    call draw_art

wait_for_gate:
    mov ah, 0x00
    int 0x16            
    cmp al, 0x0D        ; Wait for user to hit ENTER to trigger the 64-bit initialization
    jne wait_for_gate

prepare_64bit:
    ; Clear screen completely before breaking out of BIOS mode
    mov ah, 0x06
    mov al, 0
    mov cx, 0x0000
    mov dx, 0x184F
    mov bh, 0x0F
    int 0x10

    ; --- SETUP 4-LEVEL HARDWARE PAGING TABLES ---
    ; Clear memory location from 0x1000 to 0x5000 for clean allocation tables
    mov edi, 0x1000     ; Using 32-bit register destination
    mov cr3, edi        ; CR3 requires a 32-bit source register footprint
    xor eax, eax
    mov cx, 4096
    rep stosd

    ; Link Level 4 (PML4) entry to Level 3 (PDPT)
    mov dword [0x1000], 0x2003      ; 0x3 flags = Present + Read/Write
    
    ; Link Level 3 (PDPT) entry to Level 2 (PD)
    mov dword [0x2000], 0x3003

    ; Link Level 2 (PD) entry to identity-map first 2MB block using huge pages
    mov dword [0x3000], 0x0083      ; 0x83 flags = Present + Read/Write + Huge Page (2MB)

    ; --- ENABLE EXTENDED CONTROLS ---
    ; Enable PAE (Physical Address Extension) bit 5 in CR4
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; Flip Long Mode Enable (LME) inside the Extended Feature Enable Register (EFER MSR)
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    ; Toggle Paging bit 31 in CR0 to make the system live
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    ; Load 64-bit Global Descriptor Table
    lgdt [gdt64_pointer]

    ; THE LONG JUMP: Break into 64-bit code segment
    jmp 0x08:init_long_mode


; --- 64-BIT LONG MODE EXECUTION LAYER ---
bits 64
init_long_mode:
    ; Reset segment registers to null descriptor
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Welcome to 64-bit CPU pipeline! Let's display the terminal prompt
    mov rsi, msg_64bit_active
    call puts_64

terminal_64bit_loop:
    ; Custom polling hardware keystroke loop (BIOS is dead now!)
.wait_key:
    in al, 0x64         ; Read PS/2 keyboard controller status
    test al, 0x01       ; Check if output buffer is full
    jz .wait_key
    
    in al, 0x60         ; Read scan code from keyboard data register
    test al, 0x80       ; Ignore key-release events
    jnz terminal_64bit_loop

    ; Minimal demo key mapping for character feedback loop
    cmp al, 0x1C        ; Enter key scan code
    je .handle_enter

    ; Default response loop to verify execution
    mov rsi, msg_key_press
    call puts_64
    jmp terminal_64bit_loop

.handle_enter:
    mov rsi, msg_newline
    call puts_64
    jmp terminal_64bit_loop

; Pure 64-bit direct Video Memory text printer
puts_64:
    push rbx
    push rax
    mov rbx, 0xB80000   ; Hardcoded VGA text mode memory pointer
.loop:
    lodsb
    or al, al
    jz .done
    mov [rbx], al       ; Write character ascii byte directly to monitor ram
    mov byte [rbx+1], 0x0A ; Green text attribute color flag
    add rbx, 2
    jmp .loop
.done:
    pop rax
    pop rbx
    ret


; --- STRUCTURAL DATA BLOCKS ---
align 8
gdt64:
    dq 0x0000000000000000           ; Null Descriptor
    dq 0x00209A0000000000           ; 64-Bit Code Segment Descriptor (Long mode flag set)
    dq 0x0000920000000000           ; 64-Bit Data Segment Descriptor
gdt64_pointer:
    dw $ - gdt64 - 1
    dq gdt64

; --- THE ART CANVAS CANVAS MATRIX ---
art_matrix:
    db "...............................................................................", ENDL
    db "...............................................................................", ENDL
    db "......................................XXXXXXXX.................................", ENDL
    db "..............................XXXXXXXXXX......XXX..............................", ENDL
    db "..............................XXXXXXX............X.............................", ENDL
    db "..............................XXXXX..............X.............................", ENDL
    db "..............................XXX.....XXXX........X............................", ENDL
    db "..............................X.......X...#.......X............................", ENDL
    db ".............................X........XXXX.....XXX.............................", ENDL
    db "............................X................XXXXX.............................", ENDL
    db "...........................X................XXXXXX.............................", ENDL
    db "...........................X..............XXXXXXXX.............................", ENDL
    db "............................X.......XXXXXX.....................................", ENDL
    db ".............................XXXXXXX...........................................", ENDL
    db ".......................................X.......................................", ENDL
    db "......................XXX...XXX..X...X...X..X.X..XXX..X..X.....................", ENDL
    db "......................X..X.X...X.XX.XX.X.XX.X.X.X...X.XX.X.....................", ENDL
    db "......................XXX...XXX..X.X.X.X.X.XX.X..XXX..X.XX.....................", ENDL
    db "...............................................................................", ENDL
    db "...............................................................................", ENDL
    db "...............................................................................", ENDL, 0

msg_selection:        db "DOMINION OS UNLOCKED. PRESS [ENTER] TO INITIALIZE 64-BIT CORE...", 0
msg_64bit_active:     db "KERNEL SWITCH SUCCESS: 64-BIT LONG MODE IS ONLINE. > ", 0
msg_key_press:        db "*", 0
msg_newline:          db " ", 0