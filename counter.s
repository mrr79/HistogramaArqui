section .data
    input_file db "/home/mrr79/Documents/HistogramaArqui/prueba.txt", 0
    output_file db "word_counts.txt", 0
    buffer_size equ 1024
    delimiters db " ", 0
    word_count dd 0

section .bss
    buffer resb buffer_size
    words resb 256 * 200  ; Buffer para almacenar hasta 20 palabras de 256 bytes cada una
    counts resd 20       ; Contadores para cada palabra

section .text
    global _start

_start:
    ; Abrir el archivo de entrada
    mov eax, 5          ; sys_open
    mov ebx, input_file
    mov ecx, 0          ; O_RDONLY
    int 0x80
    test eax, eax
    js error            ; Si hay error al abrir el archivo
    mov ebx, eax        ; Guardar el descriptor de archivo

    ; Leer el contenido del archivo
    mov eax, 3          ; sys_read
    mov ecx, buffer
    mov edx, buffer_size
    int 0x80
    test eax, eax
    js error            ; Si hay error al leer el archivo

    ; Procesar el contenido del buffer
    mov esi, buffer
    mov edi, words
    xor ecx, ecx         ; Contador de palabras

next_char:
    ; Leer el siguiente carácter
    mov al, [esi]
    cmp al, '#'
    je end_of_text       ; Si es '#', fin del texto
    cmp al, ' '
    je end_word          ; Si es un espacio, termina la palabra actual
    stosb                ; Almacena el carácter en el buffer de la palabra actual
    inc esi
    jmp next_char        ; Continuar al siguiente carácter

end_word:
    cmp edi, words       ; Verificar si hay una palabra vacía
    je skip_empty_word   ; Si no se almacenó nada, saltar
    stosb                ; Añadir el null byte para terminar la palabra
    inc ecx              ; Incrementar el contador de palabras
    call check_word      ; Revisar si la palabra ya existe
    jmp continue         ; Continuar al siguiente carácter

skip_empty_word:
    inc esi              ; Si la palabra está vacía, solo avanzar al siguiente carácter
    jmp next_char

continue:
    xor edi, edi         ; Reiniciar el buffer para la siguiente palabra
    jmp next_char        ; Continuar al siguiente carácter

check_word:
    ; Guardar registros
    push ecx
    push edx
    push esi
    push edi
    push ebx

    ; Comparar la palabra actual con las palabras almacenadas
    mov edi, words
    xor ebx, ebx         ; Índice de palabras
    mov ecx, dword [word_count]

compare_loop:
    mov esi, edi
    add esi, ebx
    mov edi, words
    repe cmpsb
    je word_found
    add edi, 256
    inc ebx
    cmp ebx, dword [word_count]
    jne compare_loop

    ; Si no se encontró la palabra, agregarla al array
    mov edi, words
    add edi, ebx
    mov esi, edi
    mov edi, words
    rep movsb
    mov dword [counts + ebx * 4], 1
    inc dword [word_count]

    ; Restaurar registros
    pop ebx
    pop edi
    pop esi
    pop edx
    pop ecx
    ret

word_found:
    ; Si se encontró la palabra, incrementar su contador
    inc dword [counts + ebx * 4]

    ; Restaurar registros
    pop ebx
    pop edi
    pop esi
    pop edx
    pop ecx
    ret

end_of_text:
    ; Abrir el archivo de salida
    mov eax, 5          ; sys_open
    mov ebx, output_file
    mov ecx, 577        ; O_WRONLY | O_CREAT | O_TRUNC
    mov edx, 438        ; 0666 en octal
    int 0x80
    test eax, eax
    js error            ; Si hay error al abrir el archivo
    mov ebx, eax        ; Guardar el descriptor de archivo

    ; Escribir los resultados en el archivo de salida
    mov ecx, 0
write_loop:
    cmp ecx, dword [word_count]
    je done
    mov esi, words
    add esi, ecx
    mov edi, buffer
    rep movsb
    mov al, ':'
    stosb
    mov eax, [counts + ecx * 4]
    call int_to_str
    mov al, 10          ; ASCII de '\n'
    stosb
    mov eax, 4          ; sys_write
    mov edx, edi
    sub edx, buffer
    int 0x80
    inc ecx
    jmp write_loop

int_to_str:
    ; Convertir un entero a cadena (decimal)
    ; Guardar registros
    push eax
    push ebx
    push ecx
    push edx

    ; Inicializar punteros y variables
    mov ebx, 10         ; Divisor
    xor ecx, ecx        ; Contador de dígitos
    mov edx, 0          ; Clear edx for division

convert_loop:
    div ebx             ; eax / 10, resultado en eax, resto en edx
    add dl, '0'         ; Convertir dígito a carácter
    push dx             ; Guardar dígito en la pila
    inc ecx             ; Incrementar contador de dígitos
    test eax, eax       ; ¿Quedan más dígitos?
    jnz convert_loop

    ; Extraer dígitos de la pila
extract_loop:
    pop dx
    mov [edi], dl
    inc edi
    loop extract_loop

    ; Terminar la cadena con null byte
    mov byte [edi], 0

    ; Restaurar registros
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
