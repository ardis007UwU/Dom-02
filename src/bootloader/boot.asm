org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

;
; FAT12 header
; 
jmp short start
nop

bdb_oem:                    db 'MSWIN4.1'           
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0E0h
bdb_total_sectors:          dw 2880                 
bdb_media_descriptor_type:  db 0F0h                 
bdb_sectors_per_fat:        dw 9                    
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sector_count:     dd 0

; extended boot record
ebr_drive_number:           db 0                    
                            db 0                    
ebr_signature:              db 29h
ebr_volume_id:              db 12h, 34h, 56h, 78h   
ebr_volume_label:           db 'NANOBYTE OS'        
ebr_system_id:              db 'FAT12   '           

start:
    jmp main

; Prints a string to the screen
puts:
    push si
    push ax
    push bx

.loop:
    lodsb               
    or al, al           
    jz .done

    mov ah, 0x0E        
    mov bh, 0           
    int 0x10

    jmp .loop

.done:
    pop bx
    pop ax
    pop si    
    ret

main:
    ; setup data segments
    mov ax, 0                   
    mov ds, ax
    mov es, ax
    
    ; setup stack
    mov ss, ax
    mov sp, 0x7C00              

    ; Save the boot drive number given by BIOS
    mov [ebr_drive_number], dl

    ; Read the kernel sectors from the disk safely
    mov ax, 1                   ; Start at LBA 1 (right after boot sector)
    mov cl, 4                   ; Read 4 sectors (plenty of room for kernel expansion)
    mov bx, 0x7E00              ; Load the kernel data right to memory location 0x7E00
    call disk_read

    ; Pass boot drive to kernel in DL and execute the jump
    mov dl, [ebr_drive_number]
    jmp 0x0000:0x7E00

    cli                         
    hlt

; Error handlers
floppy_error:
    mov si, msg_read_failed
    call puts
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 16h                     
    jmp 0FFFFh:0                

; Converts an LBA address to a CHS address
lba_to_chs:
    push ax
    push dx

    xor dx, dx                          
    div word [bdb_sectors_per_track]    

    inc dx                              
    mov cx, dx                          

    xor dx, dx                          
    div word [bdb_heads]                
    mov dh, dl                          
    mov ch, al                          
    shl ah, 6
    or cl, ah                           

    pop ax
    mov dl, al                          
    pop ax
    ret

; Reads sectors from a disk
disk_read:
    push ax                             
    push bx
    push cx
    push dx
    push di

    push cx                             
    call lba_to_chs                     
    pop ax                              
    
    mov ah, 02h
    mov di, 3                           

.retry:
    pusha                               
    stc                                 
    int 13h                             
    jnc .done                           

    popa
    call disk_reset

    dec di
    test di, di
    jnz .retry

.fail:
    jmp floppy_error

.done:
    popa

    pop di
    pop dx
    pop cx
    pop bx
    pop ax                             
    ret

disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret

msg_read_failed:        db 'Disk Error!', ENDL, 0

times 510-($-$$) db 0
dw 0AA55h