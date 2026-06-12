This is my own OS (operating system) that im building from scrach 

Assembler:`nasm` (compiles my raw assembly into machine code)

Automation:`GNU Make` (manages the compilation and floppy drive layout)

Emulator:`QEMU` (simulates bare-metal hardware so I can test my boot sectors)

_______How do BIOS start up__________________
1. BIOS is copied from ROM to RAM
2. BIOS starts executing codes
    -Initializes hardwear
    -Runs some tests POST (power-on self test)
3. BIOS searches from OS to start
4. BIOS loads and starts the OS

_______Operating System________________________
Legacy Booting
    - BIOS loads first sector of each bootable device into memory (0x7C00)
    - BIOS checks for signature (0xAA55h).
    -If found starts executing.
EFI Booting
    - BIOS looks into special EFI partition
    - OS must be compiled as an EFI program.

________Directive________________________________
    -Gives a clue to the assembler that that will how the program gets compiled.NOT translated to machine code!.
    -Assembler specific
    -Different assemblers might  have different directives.

________Instructions______________________________
    -Translates to a machine code instructions that the CPU will execute.

--BITS--
    -tells assembler to emit 16/32/64-bit code. (Directive)
--HTL--
    -stops CPU from executing. (it can be resumed by an interrupt)
--DB--
    -byte 1, byte 2, byte 3... (Directive)
    -stands for "define byte(s)". Writes given byte(s) to assembly
    -also there is DW for "define word(s)
--TIMES--
    -number instructions/data
    -Repeats given instructions or piece of data a number  of times
--$--
    -special symbol which is equal to the memory offset of the current line.
--$$--
    -special symbol which is equal to the memory offset of the current section (in our case, program)
--$-$$--
    -Gives the size of our program

________Memory Segmentation_________________________

segment:offset
0x1234:0x5678

real_address = segment * 16 + offset

segment:offset     real address
0x0000:0x7C00      0x7C00  
0x0001:0x7BF0      0x7C00
0x0010:0x7B00      0x7C00
0x000C:0x7000      0x7C00
0x07C0:0x0000      0x7C00

These registers are used to specify currently active segments:

CS - currently running code segment
DS - data segment
SS - stack segment
ES, FS, GS - extra (data) segments

segment: [base + index * scale + displacement]

All fields are optional:
segment: CS, DS, ES, FS, GS, SS (DS if unspecified)
base: (16 bits) BP/BX
    (32/64 bits) any general purpose register
index: (16 bits) SI/DI
    (32/64 bits) any general purpose register
scale: (32/64 bits only) 1, 2, 4 or 8
displacement: a (signed) constant value

________Stack______________________________________

    -memory accessed in a FIFO (first in, first out) manner using -push- and -pop-
    -used to save  the return address when caling functions
    -sp always goes downwards you always set sp to the start of the the operating system becouze else way it would just over write it and not  work.

________CODE________________________________________

LODSB, LODSW, LODSD

These instructions load a byte/word/double-word from DS:SI into AL/AX/EAX, then increment SI by the number of bytes loaded.

OR destination, source  
Performs bitwise OR between source and destination, stores result in destination.  

JZ destination
Jumps to destination if zero flag is set.

________Interrupt___________________________________

A signal which makes the processor stop what it's doing, in order to handle that signal.

Can be triggered by:
1. An exception (e.g. dividing by zero, segmentation fault, page fault)
2. Hardware (e.g. keyboard key pressed or released, timer tick, disk controller finished an operation)
3. Software, through the INT instruction

_______Examples of BIOS interrupts__________________

INT 10h -- Video  
INT 11h -- Equipment Check  
INT 12h -- Memory Size  
INT 13h -- Disk I/O  
INT 14h -- Serial communications  
INT 15h -- Cassette  
INT 16h -- Keyboard I/O

________BIOS INT 10h________________________________

AH = 00h --- Set Video Mode  
AH = 01h --- Set Cursor Shape  
AH = 02h --- Set Cursor Position  
AH = 03h --- Get Cursor Position And Shape  

...  
AH = 0Eh --- Write Character in TTY Mode

________BIOS INT 10h, AH = 0Eh______________________

Prints a character to the screen in TTY mode.

AH = 0E  
AL = ASCII character to write  
BH = page number (text modes)  
BL = foreground pixel color (graphics modes)  

returns nothing  

-cursor advances after write  
-characters BEL (7), BS (8), LF (A), and CR (D) are treated as control codes

-ardis
