This is a custom x86 operating system being built entirely from scratch. The project focuses on low-level bare-metal development, moving past legacy limitations to build a modern system using modern EFI booting.

Development Environment

Assembler: NASM compiles the raw assembly into machine code.
Automation: GNU Make manages the compilation pipeline and image layout.
Emulator: QEMU simulates bare-metal hardware to test the EFI program files.

Technical Overview

Booting: The system uses modern EFI booting. The motherboard firmware looks into a special dedicated EFI system partition and loads the operating system directly as a compiled EFI program.
Memory and Architecture: Features include manual memory management using pointer segments, dedicated register configurations, and custom stack pointer setup.
Screen Output: Uses low-level video interrupts and output functions to handle character rendering directly to the screen.
