import struct
import string
import unicodedata

class tokenizer:
    def __init__(self, texto):
        self.texti = texto
        self.contenido = None
        self.palabras = None

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
            # Crear una tabla de traducción para eliminar caracteres no alfabéticos
            contenido = contenido.lower()  # Convertir todo a minúsculas
            contenido = self.eliminar_acento(contenido)
            # Eliminar cualquier carácter que no sea una letra (a-z)
            contenido = ''.join(c for c in contenido if c.isalpha() or c.isspace())
            contenido = ''.join(c if c.isalpha() else '0' for c in contenido)
             # Ahora los espacios han sido reemplazados por '0'
            self.palabras = contenido.split()  # Obtener las palabras como una lista

    def guardar_en_binario(self):
        # Abre el archivo en modo binario para escritura
        with open('archivo_nuevo.bin', 'wb') as f:
            for palabra in self.palabras:
                # Codificar la palabra en utf-8 y escribir solo la palabra codificada
                palabra_codificada = palabra.encode('utf-8')
                f.write(palabra_codificada)

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
        token.guardar_en_binario()  # Guarda las palabras en formato binario
        print(f"Archivo {archivo_txt} procesado y guardado como archivoo_nuevo.bin")
    else:
        print("No se seleccionó ningún archivo.")
