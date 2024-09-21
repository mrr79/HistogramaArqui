section .data
    input_file db "/home/mrr79/Documents/HistogramaArqui/prueba.txt", 0
    output_file db "word_counts.txt", 0
    debug_open_input db "Error al abrir el archivo de entrada", 0xA, 0
    debug_read_input db "Error al leer el archivo de entrada", 0xA, 0
    debug_no_words_found db "No se encontraron palabras", 0xA, 0
    debug_open_output db "Error al abrir el archivo de salida", 0xA, 0
    debug_write_output db "Error al escribir en el archivo de salida", 0xA, 0
    debug_success db "Palabras procesadas y escritas exitosamente", 0xA, 0
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
    mov eax, 5                ; sys_open
    mov ebx, input_file
    mov ecx, 0                ; O_RDONLY
    int 0x80
    test eax, eax
    js debug_open_input_error  ; Si hay error al abrir el archivo, ir a la etiqueta de depuración
    mov ebx, eax              ; Guardar el descriptor de archivo

    ; Leer el contenido del archivo
    mov eax, 3                ; sys_read
    mov ecx, buffer
    mov edx, buffer_size
    int 0x80
    test eax, eax
    js debug_read_input_error  ; Si hay error al leer el archivo
    test eax, eax
    jz no_words_found_label    ; Si no hay más datos para leer

    ; Procesar el contenido del buffer
    mov esi, buffer       ; Puntero de lectura
    xor ecx, ecx          ; Contador de palabras
    mov edi, words        ; Puntero para almacenar palabras

next_char:
    ; Leer el siguiente carácter
    mov al, [esi]
    cmp esi, buffer + buffer_size
    jae end_of_text           ; Si ESI está fuera de los límites del buffer, terminar

    cmp al, '#'            ; Fin del texto
    je end_of_text
    cmp al, ' '            ; Delimitador de palabra (espacio)
    je end_word
    cmp al, 10             ; Delimitador de palabra (salto de línea)
    je end_word
    cmp al, 'a'            ; Solo letras minúsculas permitidas
    jb skip_char           ; Saltar caracteres que no sean letras minúsculas
    cmp al, 'z'
    ja skip_char
    test al, al
    jz end_of_text         ; Si llegamos al final del buffer, detener

    ; Almacenar carácter si es válido
    cmp edi, words + max_word_size * 20  ; Verificar límite de buffer de palabras
    jae end_word            ; Si excede el tamaño, terminar la palabra
    stosb                   ; Almacenar el carácter en el buffer de la palabra actual
    inc esi
    jmp next_char           ; Continuar al siguiente carácter

end_word:
    cmp edi, words        ; Verificar si hay una palabra vacía
    je skip_empty_word    ; Si no se almacenó nada, saltar
    cmp edi, words + max_word_size * 20  ; Verificar límite de buffer de palabras
    jae skip_empty_word   ; Si excede el tamaño, saltar
    mov byte [edi], 0     ; Terminar la palabra actual con un null byte
    call check_word       ; Revisar si la palabra ya existe
    xor edi, edi          ; Reiniciar edi para la próxima palabra
    jmp continue          ; Continuar al siguiente carácter

skip_char:
    inc esi
    jmp next_char

skip_empty_word:
    inc esi               ; Si la palabra está vacía, solo avanzar al siguiente carácter
    jmp next_char

continue:
    mov edi, words        ; Reiniciar puntero para la próxima palabra
    add edi, ecx          ; Avanzar el puntero para la próxima palabra
    inc ecx               ; Incrementar el contador de palabras
    jmp next_char         ; Continuar al siguiente carácter

check_word:
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

    ; Imprimir la palabra nueva encontrada
    push ecx                  ; Guardar ecx (contador de palabras)
    push ebx                  ; Guardar ebx (índice de palabra)

    ; Cargar puntero de la palabra en esi
    mov esi, edi              ; EDI ya apunta a la nueva palabra
    call print_word

    ; Restaurar registros
    pop ebx
    pop ecx
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


print_word:
    ; Almacenar el salto de línea para después de la palabra
    push byte 10           ; 10 es '\n'

    ; Determinar la longitud de la palabra
    mov ecx, esi           ; Puntero a la palabra
print_char:
    cmp byte [ecx], 0      ; Ver si llegamos al fin de la palabra (byte nulo)
    je print_done          ; Si es el fin, saltar
    inc ecx                ; Avanzar al siguiente carácter
    jmp print_char

print_done:
    sub ecx, esi           ; Longitud de la palabra = ecx - esi
    mov edx, ecx           ; Mover longitud a edx (para syscall)

    ; Syscall para escribir en la consola
    mov eax, 4             ; syscall sys_write
    mov ebx, 1             ; Descriptor de archivo 1 (salida estándar)
    mov ecx, esi           ; Puntero a la palabra
    int 0x80               ; Interrupción de sistema

    ; Escribir salto de línea
    mov eax, 4             ; syscall sys_write
    mov ebx, 1             ; Descriptor de archivo 1 (salida estándar)
    mov ecx, esp           ; Puntero al salto de línea
    mov edx, 1             ; Longitud 1 (solo el '\n')
    int 0x80               ; Interrupción de sistema

    ; No se necesita el pop porque el salto de línea ya se ha consumido
    ret





end_of_text:
    ; Abrir el archivo de salida
    mov eax, 5                ; sys_open
    mov ebx, output_file
    mov ecx, 577              ; O_WRONLY | O_CREAT | O_TRUNC
    mov edx, 438              ; 0666 en octal
    int 0x80
    test eax, eax
    js debug_open_output_error ; Si hay error al abrir el archivo
    mov ebx, eax              ; Guardar el descriptor de archivo

    ; Escribir los resultados en el archivo de salida
    xor ecx, ecx              ; Reiniciar el contador de palabras

write_loop:
    cmp ecx, dword [word_count]
    je done
    mov esi, words

    ; Multiplicar ecx por max_word_size
    mov eax, ecx              ; Guardar ecx en eax para hacer la multiplicación
    imul eax, max_word_size   ; eax = ecx * max_word_size

    ; Sumar el resultado a esi
    add esi, eax              ; Ahora esi tiene la dirección correcta de la palabra

    mov edi, buffer           ; Puntero para el buffer de salida
    rep movsb                 ; Copiar la palabra al buffer de salida
    mov al, ':'
    stosb                     ; Añadir ':' después de la palabra
    mov eax, [counts + ecx * 4]
    call int_to_str           ; Convertir el número en cadena
    mov al, 10                ; Añadir '\n'
    stosb

    ; Ajustar edi para que apunte al final del buffer
    lea edi, [edi + 1]

    ; Calcular la longitud de los datos en el buffer
    mov eax, 4                ; sys_write
    mov edx, edi
    sub edx, buffer
    int 0x80
    test eax, eax
    js debug_write_output_error ; Si hay error al escribir

    inc ecx
    jmp write_loop

int_to_str:
    ; Convertir un entero a cadena (decimal)
    push eax
    push ebx
    push ecx
    push edx

    ; Inicializar punteros y variables
    mov ebx, 10             ; Asegúrate de que el divisor es 10
    xor ecx, ecx            ; Contador de dígitos

convert_loop:
    xor edx, edx            ; Limpia edx antes de la división

    test eax, eax           ; Verifica si eax es 0
    jz done_convert_loop    ; Si eax es 0, sal del bucle

    div ebx                 ; Divide edx:eax por 10 (ebx contiene 10)
    add dl, '0'             ; Convertir el resto en carácter
    push dx                 ; Almacenar el carácter en la pila
    inc ecx                 ; Incrementar el contador de dígitos
    jmp convert_loop        ; Repetir hasta que eax sea 0

done_convert_loop:
    ; Extraer los caracteres de la pila

extract_loop:
    pop dx
    mov [edi], dl           ; Almacenar el carácter en la cadena
    inc edi
    loop extract_loop

    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

done:
    ; Mostrar mensaje de éxito
    mov eax, 4
    mov ebx, 1
    mov ecx, debug_success
    mov edx, 36
    int 0x80
    ; Salir del programa
    mov eax, 1
    xor ebx, ebx
    int 0x80

debug_open_input_error:
    mov eax, 4
    mov ebx, 1
    mov ecx, debug_open_input
    mov edx, 34
    int 0x80
    jmp done

debug_read_input_error:
    mov eax, 4
    mov ebx, 1
    mov ecx, debug_read_input
    mov edx, 33
    int 0x80
    jmp done

no_words_found_label:
    mov eax, 4
    mov ebx, 1
    mov ecx, debug_no_words_found
    mov edx, 25
    int 0x80
    jmp done

debug_open_output_error:
    mov eax, 4
    mov ebx, 1
    mov ecx, debug_open_output
    mov edx, 34
    int 0x80
    jmp done

debug_write_output_error:
    mov eax, 4
    mov ebx, 1
    mov ecx, debug_write_output
    mov edx, 34
    int 0x80
    jmp done



