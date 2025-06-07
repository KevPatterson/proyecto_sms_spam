import datetime

def convert_sms_to_w3c_log(input_file_path, output_file_path):
    """
    Convierte un archivo de colección de SMS (formato TSV) a un archivo de log
    en formato W3C Extended para su análisis.

    Args:
        input_file_path (str): La ruta al archivo SMSSpamCollection.txt.
        output_file_path (str): La ruta donde se guardará el archivo .log de salida.
    """
    try:
        with open(input_file_path, 'r', encoding='utf-8') as infile, \
             open(output_file_path, 'w', encoding='utf-8') as outfile:

            # Escribir la cabecera del formato W3C Extended
            outfile.write("#Software: SMS Log Converter\n")
            outfile.write("#Version: 1.0\n")
            # El timestamp de la fecha de generación se establecerá en la hora actual
            outfile.write(f"#Date: {datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%d %H:%M:%S')}\n")
            outfile.write("#Fields: date time cs-username c-ip cs-method cs-uri-stem sc-status sc-bytes x-sms-text\n")

            # Establecer una fecha de inicio para los logs
            current_timestamp = datetime.datetime.now()

            # Leer el archivo de entrada línea por línea
            for line in infile:
                if not line.strip():
                    continue

                # Separar la etiqueta (ham/spam) del contenido del mensaje
                parts = line.strip().split('\t', 1)
                if len(parts) != 2:
                    continue
                
                label, message = parts
                
                # Limpiar el mensaje para el log (remover saltos de línea y escapar comillas)
                # El formato W3C usa comillas dobles para encerrar campos con espacios.
                # Cualquier comilla doble dentro del campo debe ser escapada duplicándola.
                log_message = message.replace('"', '""')

                # Generar datos para los campos del log
                log_date = current_timestamp.strftime('%Y-%m-%d')
                log_time = current_timestamp.strftime('%H:%M:%S')
                ip_address = "10.0.0.1" if label == "ham" else "10.0.0.2"
                method = "SMS"
                uri = "/messages/"
                status = 200
                message_bytes = len(message.encode('utf-8'))

                # Formatear la línea de log
                log_entry = (
                    f'{log_date} {log_time} {label} {ip_address} {method} {uri} '
                    f'{status} {message_bytes} "{log_message}"\n'
                )

                outfile.write(log_entry)

                # Decrementar el timestamp para el siguiente registro
                current_timestamp -= datetime.timedelta(minutes=1)

        print(f"¡Conversión exitosa! El archivo de log ha sido guardado en: {output_file_path}")

    except FileNotFoundError:
        print(f"Error: El archivo de entrada no fue encontrado en '{input_file_path}'")
    except Exception as e:
        print(f"Ocurrió un error inesperado: {e}")

# --- Instrucciones de uso ---
# 1. Asegúrese de que el archivo 'SMSSpamCollection.txt' esté en el mismo
#    directorio que este script, o proporcione la ruta completa.
# 2. Ejecute el script.
# 3. Se generará un archivo 'sms_analysis.log' en el mismo directorio.

# Nombre del archivo de entrada
input_filename = 'SMSSpamCollection.txt'

# Nombre del archivo de salida
output_filename = 'sms_analysis.log'

# Llamar a la función para realizar la conversión
convert_sms_to_w3c_log(input_filename, output_filename)