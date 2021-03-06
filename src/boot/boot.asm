[org 0x7c00]            ; Set the origin of the bootloader

loop:
  call fast_a20         ; Fast-enable the A20 line
  cli                   ; Clear BIOS interrupts

  ; We need to first initialise the <ds> register before loading the GDT
  xor ax, ax            ; Basically the same as <mov ax, 0> but preferred for some reason
  mov ds, ax            ; Initialise <ds> register with a null value
  lgdt [gdt_desc]       ; Load the GDT descriptor table

  ; Set PE (Protection Enable) bit in <cr0> (Control Register 0)
  mov eax, cr0          ; We cannot directly modify the value of <cr0>, so first load it in the <eax> register
  or eax, 1             ; Then, set the first bit in the <eax> register
  mov cr0, eax          ; Finally, move the <eax> with the PE bit set back into <cr0>

  jmp codeseg:clear_pipe    ; Perform a far-jump to clear the garbage 16-bit instructions and ready code for 32-bit architecture

[BITS 32]
clear_pipe:
  ; Store the correct address in the segment registers
  ; Refer here for the tutorial: http://www.osdever.net/tutorials/view/the-world-of-protected-mode
  mov ax, dataseg   ; Store the proper segment value in the <ax> register
  mov ds, ax        ; Store proper value in the <ds> register (<ds> register stores variables)
  mov ss, ax        ; Store proper value in the <ss> regsiter (<ss> register is the stack segment)
  mov esp, 0x90000  ; Start the stack at memory address 0x90000 (refer to the memory address table in the aforementioned site)

  mov [0xb8000], byte "P"         ; Move 'P' into the VGA video memory
  mov [0xb8001], byte 00001111b   ; Move the text formatting for the character into the next memory address

  ; Start using C code from this point onwards
  jmp $

; The code here will not be executed, but include statements will still work
%include "src/boot/protected_mode.asm"

; Pad the entire bootloader with zeroes because the bootloader must be exactly 512 bytes in size
times 510-($-$$) db 0

; The magic signature which tells the computer that this file is bootable
dw 0xaa55