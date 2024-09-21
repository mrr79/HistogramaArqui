section .data
    input_file db "/home/mrr79/Documents/HistogramaArqui/prueba.txt", 0
    output_file db "word_counts.txt", 0
    buffer_size equ 1024
    max_word_size equ 256  ; Tamaño máximo para una palabra
    word_count dd 0

section .bss
    buffer resb buffer_size
    words resb max_word_size * 20  ; Buffer para hasta 20 palabras, 256 bytes cada una
    counts resd 20                 ; Contadores para cada palabra

section .text
    global _start

_start:
    ; Abrir el archivo de entrada
    mov eax, 5            ; sys_open
    mov ebx, input_file
    mov ecx, 0            ; O_RDONLY
    int 0x80
    test eax, eax
    js error              ; Si hay error al abrir el archivo
    mov ebx, eax          ; Guardar el descriptor de archivo

    ; Leer el contenido del archivo
    mov eax, 3            ; sys_read
    mov ecx, buffer
    mov edx, buffer_size
    int 0x80
    test eax, eax
    js error              ; Si hay error al leer el archivo

    ; Procesar el contenido del buffer
    mov esi, buffer       ; Puntero de lectura
    xor ecx, ecx          ; Contador de palabras
    mov edi, words        ; Puntero para almacenar palabras

next_char:
    ; Leer el siguiente carácter
    mov al, [esi]
    cmp al, '#'
    je end_of_text        ; Si es '#', fin del texto
    cmp al, ' '
    je end_word           ; Si es un espacio, termina la palabra actual
    test al, al
    jz end_of_text        ; Si llegamos al final del buffer, detener

    ; Almacenar carácter si no es un delimitador
    cmp edi, words + max_word_size * 20  ; Verificar límite de buffer de palabras
    jae end_word           ; Si excede el tamaño, terminar la palabra
    stosb                 ; Almacena el carácter en el buffer de la palabra actual
    inc esi
    jmp next_char         ; Continuar al siguiente carácter

end_word:
    cmp edi, words        ; Verificar si hay una palabra vacía
    je skip_empty_word    ; Si no se almacenó nada, saltar
    cmp edi, words + max_word_size * 20  ; Verificar límite de buffer de palabras
    jae skip_empty_word   ; Si excede el tamaño, saltar
    mov byte [edi], 0     ; Terminar la palabra actual con un null byte
    call check_word       ; Revisar si la palabra ya existe
    xor edi, edi          ; Reiniciar edi para la próxima palabra
    jmp continue          ; Continuar al siguiente carácter


skip_empty_word:
    inc esi               ; Si la palabra está vacía, solo avanzar al siguiente carácter
    jmp next_char

continue:
    mov edi, words        ; Reiniciar puntero para la próxima palabra
    add edi, ecx          ; Avanzar el puntero para la próxima palabra
    inc ecx               ; Incrementar el contador de palabras
    jmp next_char         ; Continuar al siguiente carácter

check_word:
    ; Guardar registros
    push ecx
    push edx
    push esi
    push edi
    push ebx

    ; Comparar la palabra actual con las palabras almacenadas
    mov edi, words
    xor ebx, ebx          ; Índice de palabras
    mov edx, ecx          ; Guardar el contador de palabras

compare_loop:
    cmp ebx, dword [word_count] ; Comprobar si hemos alcanzado el número total de palabras
    je new_word           ; Si no se encuentra, es una nueva palabra

    ; Comparar palabra actual con palabras almacenadas
    mov esi, edi          ; Cargar puntero a la palabra actual
    repe cmpsb            ; Comparar bytes de palabras
    je word_found         ; Si las palabras coinciden, se encontró

    add edi, max_word_size  ; Mover al siguiente slot de palabra
    inc ebx
    jmp compare_loop

new_word:
    ; Si no se encontró la palabra, agregarla al array
    mov edi, words
    add edi, ebx
    mov esi, words
    rep movsb             ; Copiar la nueva palabra
    mov dword [counts + ebx * 4], 1
    inc dword [word_count]
    jmp restore_registers

word_found:
    ; Si se encontró la palabra, incrementar su contador
    inc dword [counts + ebx * 4]

restore_registers:
    ; Restaurar registros
    pop ebx
    pop edi
    pop esi
    pop edx
    pop ecx
    ret

end_of_text:
    ; Abrir el archivo de salida
    mov eax, 5            ; sys_open
    mov ebx, output_file
    mov ecx, 577          ; O_WRONLY | O_CREAT | O_TRUNC
    mov edx, 438          ; 0666 en octal
    int 0x80
    test eax, eax
    js error              ; Si hay error al abrir el archivo
    mov ebx, eax          ; Guardar el descriptor de archivo

    ; Escribir los resultados en el archivo de salida
    xor ecx, ecx          ; Reiniciar el contador de palabras
write_loop:
    cmp ecx, dword [word_count]
    je done
    mov esi, words
    add esi, ecx
    mov edi, buffer       ; Puntero para el buffer de salida
    rep movsb             ; Copiar la palabra al buffer de salida
    mov al, ':'
    stosb                 ; Añadir ':' después de la palabra
    mov eax, [counts + ecx * 4]
    call int_to_str       ; Convertir el número en cadena
    mov al, 10            ; Añadir '\n'
    stosb
    mov eax, 4            ; sys_write
    mov edx, edi
    sub edx, buffer
    int 0x80
    inc ecx
    jmp write_loop

int_to_str:
    ; Convertir un entero a cadena (decimal)
    push eax
    push ebx
    push ecx
    push edx

    ; Inicializar punteros y variables
    mov ebx, 10
    xor ecx, ecx
    xor edx, edx

convert_loop:
    div ebx
    add dl, '0'
    push dx
    inc ecx
    test eax, eax
    jnz convert_loop

extract_loop:
    pop dx
    mov [edi], dl
    inc edi
    loop extract_loop

    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

done:
    ; Salir del programa
    mov eax, 1
    xor ebx, ebx
    int 0x80

error:
    ; Manejo de errores
    mov eax, 1
    mov ebx, -1
    int 0x80
