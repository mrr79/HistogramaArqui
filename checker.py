import tkinter as tk
from tkinter import filedialog, messagebox
import os

# Función para procesar el archivo .bin y contar las palabras separadas por '0'
def count_words_in_bin_file(file_path):
    try:
        with open(file_path, 'rb') as file:
            # Leer el contenido del archivo como bytes
            content = file.read()
            # Decodificar los bytes a una cadena de texto
            text = content.decode('utf-8')

            # Verificar si el último carácter es '#', y eliminarlo si es así
            if text.endswith('#'):
                text = text[:-1]

            # Separar las palabras utilizando '0' como delimitador
            words = text.split('0')
            # Filtrar palabras vacías (en caso de que haya múltiples ceros consecutivos)
            words = [word for word in words if word]
            return len(words), words
    except Exception as e:
        messagebox.showerror("Error", f"Error al procesar el archivo: {e}")
        return 0, []

# Función que se llama cuando se selecciona un archivo
def select_file():
    file_path = filedialog.askopenfilename(filetypes=[("Bin Files", "*.bin")])
    if file_path:
        word_count, words = count_words_in_bin_file(file_path)
        messagebox.showinfo("Resultado", f"Palabras encontradas: {word_count}\n\n{words}")

# Crear la interfaz gráfica
root = tk.Tk()
root.title("Contador de Palabras en Archivo .bin")
root.geometry("400x200")

# Botón para seleccionar el archivo
select_button = tk.Button(root, text="Seleccionar Archivo .bin", command=select_file)
select_button.pack(pady=50)

# Ejecutar la aplicación
root.mainloop()
