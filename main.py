import tkinter as tk
from tkinter import filedialog
import re

def procesar_archivo():
    # Abrir el archivo .txt
    archivo = filedialog.askopenfilename(filetypes=[("Text files", "*.txt")])
    
    if archivo:
        with open(archivo, 'r', encoding='utf-8') as f:
            texto = f.read()
        
        # Eliminar espacios, comas, signos de exclamación, y convertir a minúsculas
        texto_procesado = re.sub(r'[!?]', '', texto).lower()
        
        # Reemplazar los puntos con un espacio para mantener la separación original
        texto_procesado = texto_procesado.replace('.', ' ')
        
        # Separar las palabras y unirlas con puntos
        palabras = re.findall(r'\b\w+\b', texto_procesado)
        resultado = '.'.join(palabras)
        
        # Agregar un punto al final
        resultado += '.'
        
        # Guardar el resultado en un nuevo archivo
        with open('resultado.txt', 'w', encoding='utf-8') as f:
            f.write(resultado)
        
        print("El archivo ha sido procesado y guardado como 'resultado.txt'.")

# Crear la interfaz de usuario
root = tk.Tk()
root.title("Procesador de Texto")

boton_procesar = tk.Button(root, text="Subir Archivo .txt", command=procesar_archivo)
boton_procesar.pack(pady=20)

root.mainloop()
