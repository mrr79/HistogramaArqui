section .data
    input_file db "/home/mrr79/Documents/HistogramaArqui/prueba.txt", 0
    output_file db "word_counts.txt", 0
    buffer_size equ 1024
    max_word_size equ 256  ; Tamaño máximo para una palabra
    max_words equ 100      ; Máximo de palabras permitidas
    word_count dd 0
    error_message db "Error al escribir en el archivo.", 0xA
    error_message_len equ $ - error_message
    error_open_msg db "Error al abrir archivo.", 0xA
    error_open_msg_len equ $ - error_open_msg
    error_generic_msg db "Error inesperado.", 0xA
    error_generic_msg_len equ $ - error_generic_msg
    debug_message_read db "Archivo leído correctamente", 0xA
    debug_message_read_len equ $ - debug_message_read
    debug_message_write db "Escribiendo archivo de salida", 0xA
    debug_message_write_len equ $ - debug_message_write
    new_line db 0xA  ; Salto de línea (newline)

section .bss
    buffer resb buffer_size
    words resb max_word_size * max_words  ; Buffer para hasta 100 palabras, 256 bytes cada una
    counts resd max_words                 ; Contadores para cada palabra
    salida_fd resd 1                      ; Descriptor de archivo de salida

section .text
    global _start

_start:
    ; Abrir el archivo de entrada
    mov eax, 5                ; sys_open
    mov ebx, input_file
    mov ecx, 0                ; O_RDONLY
    int 0x80
    test eax, eax
    js error_open_file         ; Si hay error al abrir el archivo, ir a la etiqueta error_open_file
    mov ebx, eax              ; Guardar el descriptor de archivo

    ; Leer el contenido del archivo
    mov eax, 3                ; sys_read
    mov ecx, buffer
    mov edx, buffer_size
    int 0x80
    test eax, eax
    js error                  ; Si hay error al leer el archivo
    test eax, eax
    jz end_of_text            ; Si no hay más datos para leer

    ; Mensaje de depuración para confirmar que el archivo se ha leído
    mov eax, 4                ; sys_write
    mov ebx, 1                ; Salida estándar
    mov ecx, debug_message_read
    mov edx, debug_message_read_len
    int 0x80

    ; Procesar el contenido del buffer
    mov esi, buffer       ; Puntero de lectura
    xor ecx, ecx          ; Contador de palabras

    ; Inicialización de words (después de leer el archivo)
    mov edi, words
    mov ecx, max_word_size * max_words
    xor eax, eax
    rep stosb              ; Inicializar el buffer de palabras con ceros

next_char:
    ; Leer el siguiente carácter
    mov al, [esi]
    cmp al, '#'
    je end_of_text         ; Si es '#', fin del texto
    cmp al, ' '
    je end_word            ; Si es un espacio, termina la palabra actual
    test al, al
    jz end_of_text         ; Si llegamos al final del buffer, detener

    ; Almacenar carácter si no es un delimitador
    cmp edi, words + max_word_size * max_words  ; Verificar que no se exceda el buffer de palabras
    jae end_word          ; Si excede, termina la palabra actual
    stosb                 ; Almacenar el carácter en la palabra actual
    inc esi               ; Avanza al siguiente carácter
    jmp next_char

end_word:
    cmp edi, words        ; Verificar si hay una palabra vacía
    je skip_empty_word    ; Si no se almacenó nada, saltar
    cmp edi, words + max_word_size * max_words  ; Verificar límite de buffer de palabras
    jae skip_empty_word   ; Si excede el tamaño, saltar
    mov byte [edi], 0     ; Terminar la palabra actual con un null byte
    call check_word       ; Revisar si la palabra ya existe

    ; Reinicialización correcta de EDI y ECX
    mov edi, words
    xor ecx, ecx          ; Reiniciar el contador de palabras
    jmp continue

skip_empty_word:
    inc esi               ; Si la palabra está vacía, solo avanzar al siguiente carácter
    jmp next_char

continue:
    mov edi, words        ; Reiniciar puntero para la próxima palabra
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
    xor ebx, ebx              ; Índice de palabras
    mov edx, ecx              ; Guardar el contador de palabras

compare_loop:
    cmp ebx, dword [word_count] ; Comprobar si hemos alcanzado el número total de palabras
    je new_word               ; Si no se encuentra, es una nueva palabra

    ; Comparar palabra actual con palabras almacenadas
    mov esi, edi              ; Cargar puntero a la palabra actual
    repe cmpsb                ; Comparar bytes de palabras
    je word_found             ; Si las palabras coinciden, se encontró

    add edi, max_word_size    ; Mover al siguiente slot de palabra
    inc ebx
    jmp compare_loop

new_word:
    ; Si no se encontró la palabra, agregarla al array
    mov edi, words
    add edi, ebx              ; Mover al siguiente slot de palabra
    mov esi, words
    rep movsb                 ; Copiar la nueva palabra
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
    mov eax, 5                ; sys_open
    mov ebx, output_file
    mov ecx, 577              ; O_WRONLY | O_CREAT | O_TRUNC
    mov edx, 438              ; 0666 en octal
    int 0x80
    test eax, eax
    js error_open_file        ; Si hay error al abrir el archivo
    mov dword [salida_fd], eax  ; Guardar el descriptor de archivo

    ; Mensaje de depuración para confirmar que vamos a escribir en el archivo
    mov eax, 4                ; sys_write
    mov ebx, 1                ; Salida estándar
    mov ecx, debug_message_write
    mov edx, debug_message_write_len
    int 0x80

    ; Escribir los resultados en el archivo de salida
    xor ecx, ecx              ; Reiniciar el contador de palabras

write_loop:
    cmp ecx, dword [word_count]
    je done                    ; Si todas las palabras han sido escritas, termina
    mov esi, words             ; Establecer puntero al inicio de words
    mov eax, ecx
    imul eax, max_word_size     ; Calcular el desplazamiento basado en el índice de la palabra
    add esi, eax               ; Apuntar a la palabra correcta

    ; Escribir la palabra actual
    mov edi, buffer            ; Puntero al buffer de salida
    call write_word_to_buffer  ; Escribir la palabra al buffer de salida

    ; Escribir ':'
    mov al, ':'
    stosb

    ; Escribir el número de repeticiones
    mov eax, [counts + ecx * 4]
    call int_to_str            ; Convertir el número de la palabra a una cadena
    mov al, 10                 ; Añadir un salto de línea
    stosb                      ; Añadirlo al buffer

    ; Escribir el buffer al archivo
    mov eax, 4                 ; sys_write
    mov ebx, [salida_fd]       ; Descriptor de archivo de salida
    mov ecx, buffer            ; Puntero al buffer
    sub edi, buffer            ; Calcula el número de bytes en edi - buffer
    mov edx, edi               ; Número de bytes a escribir
    int 0x80
    test eax, eax              ; Verifica si sys_write fue exitoso
    js error_write_file
    inc ecx
    jmp write_loop

error_open_file:
    ; Imprimir mensaje de error al abrir archivo
    mov eax, 4                 ; sys_write
    mov ebx, 1                 ; Salida estándar
    mov ecx, error_open_msg
    mov edx, error_open_msg_len
    int 0x80
    jmp done

error_write_file:
    ; Imprimir mensaje de error al escribir archivo
    mov eax, 4                 ; sys_write
    mov ebx, 1                 ; Salida estándar
    mov ecx, error_message
    mov edx, error_message_len
    int 0x80
    jmp done

error:
    ; Imprimir mensaje de error genérico
    mov eax, 4                 ; sys_write
    mov ebx, 1                 ; Salida estándar
    mov ecx, error_generic_msg
    mov edx, error_generic_msg_len
    int 0x80
    jmp done

done:
    ; Terminar la ejecución
    mov eax, 1                 ; sys_exit
    xor ebx, ebx
    int 0x80

write_word_to_buffer:
    ; Copiar palabra desde ESI a EDI (buffer)
    push esi
    push edi
    xor eax, eax
    xor ecx, ecx
    mov ecx, max_word_size     ; Máximo tamaño de la palabra
    rep movsb                  ; Copiar palabra desde [esi] a [edi]
    pop edi
    pop esi
    ret

int_to_str:
    ; Convertir un número entero a una cadena de caracteres
    ; Guardar registros
    push eax
    push ebx
    push ecx
    push edx

    ; Implementación simple para convertir el número en `eax` a string en `edi`
    mov ebx, 10               ; Divisor para obtener los dígitos
    xor ecx, ecx              ; Contador de dígitos

convert_loop:
    xor edx, edx              ; Limpiar edx para div
    div ebx                   ; eax = eax / 10, edx = resto (el dígito)
    add dl, '0'               ; Convertir el dígito a ASCII
    dec edi                   ; Mover el puntero al siguiente byte (en reversa)
    mov [edi], dl             ; Almacenar el carácter en la cadena
    inc ecx                   ; Incrementar contador de caracteres
    test eax, eax
    jnz convert_loop          ; Repetir si eax no es cero

    ; Restaurar registros
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
