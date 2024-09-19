section .data
    filename db "/home/mrr79/Documents/HistogramaArqui/archivo_nuevo.bin", 0 ; Ruta al archivo, termina en null
    msg db 'Numero de palabras: ', 0xA  ; Mensaje a mostrar

section .bss
    buffer resb 1024       ; Buffer para almacenar el contenido leído

section .text
global _start

_start:
    ; Abrir el archivo
    mov eax, 5             ; syscall sys_open
    mov ebx, filename      ; dirección del nombre del archivo
    mov ecx, 0             ; modo lectura (read-only)
    int 0x80               ; llamada al sistema

    ; Guardar el descriptor del archivo en edi
    mov edi, eax           ; Guardar el descriptor de archivo en edi

    ; Leer el contenido del archivo en el buffer
    mov eax, 3             ; syscall sys_read
    mov ebx, edi           ; descriptor de archivo en ebx (cargado desde edi)
    mov ecx, buffer        ; buffer donde se almacenan los datos
    mov edx, 1024          ; leer hasta 1024 bytes
    int 0x80               ; llamada al sistema

    ; Guardar el número de bytes leídos
    mov esi, eax           ; Guardar el número de bytes leídos en esi

    ; Inicializar el contador de palabras a 0
    xor ebx, ebx           ; usar ebx como contador de palabras
    mov ecx, buffer        ; puntero al inicio del buffer

_count_loop:
    ; Leer el carácter actual
    mov al, [ecx]
    cmp al, 0              ; Verificar si llegamos al final del archivo (byte nulo)
    je _done               ; Si es 0, saltar al final

    cmp al, 0              ; Separador nulo (0x00)
    je _next_word          ; Si encontramos un separador, contar la palabra

    ; Incrementar el puntero para el siguiente carácter
    inc ecx
    jmp _count_loop

_next_word:
    inc ebx                ; Incrementar el contador de palabras
    inc ecx                ; Saltar al siguiente carácter
    jmp _count_loop

_done:
    ; Mostrar el mensaje de resultado
    mov eax, 4             ; syscall sys_write
    mov ebx, 1             ; descriptor de archivo 1 (stdout)
    mov ecx, msg           ; mensaje
    mov edx, 19            ; longitud del mensaje
    int 0x80               ; llamada al sistema

    ; Convertir el contador de palabras (ebx) a cadena de texto y mostrarlo
    call print_number

    ; Salir del programa
    mov eax, 1             ; syscall sys_exit
    xor ebx, ebx           ; código de salida 0
    int 0x80               ; llamada al sistema

print_number:
    ; Convertir el valor en ebx a ASCII (en formato decimal)
    ; Aquí se utiliza un procedimiento simple para convertir el número en el registro ebx a una cadena
    ; y luego escribir esa cadena en stdout
    ; En este ejemplo simple, asumimos que el número es pequeño (menor a 1000)

    mov ecx, 10            ; Divisor para obtener los dígitos
    xor edx, edx           ; Limpiar edx (para la división)
    div ecx                ; Dividir ebx entre 10 (divisor en ecx)

    add edx, '0'           ; Convertir el residuo a ASCII
    mov [buffer], dl       ; Guardar el dígito en el buffer

    mov eax, 4             ; syscall sys_write
    mov ebx, 1             ; stdout
    mov ecx, buffer        ; Dirección del dígito convertido
    mov edx, 1             ; Longitud (1 carácter)
    int 0x80               ; Imprimir el número

    ret
