import string
import unicodedata
import struct


class tokenizer:
    def __init__(self, texto):
        self.texti = texto
        self.contenido = None

    def eliminar_acento(self, texto):
        # Normalizar el texto para descomponer caracteres acentuados
        texto_normalizado = unicodedata.normalize('NFD', texto)
        # Eliminar los caracteres diacríticos (acentos)
        texto_sin_acento = ''.join(c for c in texto_normalizado if unicodedata.category(c) != 'Mn')
        return texto_sin_acento

    def procesarTexto(self):
        # Procesar el texto eliminando puntuación y convirtiéndolo a minúsculas
        with open(self.texti, 'r', encoding='utf-8') as archivo:
            contenido = archivo.read()
            contenido = contenido.lower()  # Convertir todo a minúsculas
            contenido = self.eliminar_acento(contenido)
            
            # Crear una nueva cadena solo con letras y espacios, eliminando todo lo demás
            contenido = ''.join(c for c in contenido if c.isalpha() or c.isspace())
            
            # Reemplazar múltiples espacios por un solo espacio y luego cambiar los espacios por ceros
            contenido = ' '.join(contenido.split())  # Eliminar espacios múltiples
            contenido = contenido.replace(' ', '0')  # Reemplazar los espacios por ceros
            contenido += '#'  # Añadir el símbolo '#' al final del texto procesado
            self.contenido = contenido

    def guardar_en_binario(self):
        # Abre el archivo en modo binario para escritura
        with open('archivo_nuevo.bin', 'wb') as f:
            for palabra in self.contenido:
                for caracter in palabra:
                    # Convertir el carácter a su valor Unicode
                    valor_unicode = ord(caracter)
                    # Convertir el valor Unicode a binario (8 bits)
                    valor_binario = struct.pack('B', valor_unicode)
                    # Escribir el valor binario en el archivo
                    f.write(valor_binario)

# Función para abrir el cuadro de diálogo de selección de archivo
def seleccionar_archivo():
    import tkinter as tk
    from tkinter import filedialog

    root = tk.Tk()
    root.withdraw()  # Oculta la ventana principal de tkinter
    archivo_seleccionado = filedialog.askopenfilename(
        title="Selecciona un archivo de texto",
        filetypes=[("Archivos de texto", "*.txt")]
    )
    return archivo_seleccionado

# Uso del tokenizer con selección de archivo
if __name__ == "__main__":
    archivo_txt = seleccionar_archivo()  # Selección del archivo .txt
    if archivo_txt:
        token = tokenizer(archivo_txt)
        token.procesarTexto()  # Procesa el texto y guarda las palabras
        token.guardar_en_binario()  # Guarda el contenido en formato binario (ASCII)
        print(f"Archivo {archivo_txt} procesado y guardado como archivo_nuevo.bin")
    else:
        print("No se seleccionó ningún archivo.")
