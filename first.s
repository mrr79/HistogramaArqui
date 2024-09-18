section .data
    pathname DD "/home/mrr79/Documents/HistogramaArqui/archivo_nuevo.bin", 0  ; Ruta al archivo de texto, debe terminar en 0 (null)


section .bss
    buffer resb 1024       ; Buffer para almacenar el contenido leído

section .text
global main

main:
    ; Abrir el archivo
    mov eax, 5             ; syscall sys_open
    mov ebx, pathname      ; dirección del archivo
    mov ecx, 0             ; modo lectura (0 = read-only)
    int 80h               ; llamada al sistema

    MOV ebx,eax
    MOV eax,3
    MOV ecx,buffer
    MOV edx,1024
    int 80h





