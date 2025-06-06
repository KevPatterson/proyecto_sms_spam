#!/bin/bash

# ==============================================================================
# Script de Análisis Avanzado de Mensajes de Spam
# ==============================================================================
# Este script analiza un conjunto de datos de mensajes (spam y ham) para
# extraer información relevante sobre los mensajes de spam, utilizando
# herramientas de línea de comandos como grep, awk, sort, uniq, wc, etc.
#
# Genera un reporte detallado en un archivo de texto plano.
#
# Uso: ./analizar_spam_profesional.sh [archivo_entrada]
# Si no se especifica archivo_entrada, se usará la ruta por defecto para WSL.
#
# Funcionalidades Incluidas:
# - Filtrado de mensajes de spam.
# - Conteo de mensajes de spam.
# - Análisis de palabras clave comunes (con filtrado básico de stop words).
# - Detección de posibles shortcodes/identificadores de remitente.
# - Extracción y conteo de URLs sospechosas.
# - Identificación de patrones de números de teléfono.
# - Cálculo del tamaño promedio de los mensajes de spam.
# - Conteo de palabras únicas en los mensajes de spam.
# - Análisis de la distribución de tipos de caracteres (mayúsculas, dígitos, etc.).
# - Manejo de errores para archivos inexistentes.
# - Parámetros configurables (ej. número de resultados principales a mostrar).
# - Exportación de resultados a un archivo de reporte con formato atractivo.
# ==============================================================================

# --- Configuración ----------------------------------------------------------
# Ruta por defecto para el archivo de entrada en el entorno WSL
DEFAULT_DATA_FILE="/mnt/c/Me/School/ADT/proyecto_sms_spam/tecnica_ia/datos_raw/SMSSpamCollection.txt"
SPAM_ONLY_FILE="temp_spam_messages_only.txt"

# Ruta de salida para el archivo de reporte en el entorno WSL
REPORT_DIR="/mnt/c/Me/School/ADT/proyecto_sms_spam/tecnica_ia/resultados"
REPORT_FILE="$REPORT_DIR/spam_analysis_report_$(date +%Y%m%d_%H%M%S).txt" # Nombre de archivo único con fecha y hora

TOP_N_RESULTS=15 # Número de resultados principales a mostrar para listas.

# --- Manejo de Argumentos y Error Handling ------------------------------------
if [ -z "$1" ]; then
    DATA_FILE="$DEFAULT_DATA_FILE"
    echo "Usando archivo de entrada por defecto (ruta WSL): '$DATA_FILE'"
else
    DATA_FILE="$1"
    echo "Usando archivo de entrada proporcionado: '$DATA_FILE'"
fi

# Asegurarse de que la ruta proporcionada o por defecto exista
if [ ! -f "$DATA_FILE" ]; then
    echo "Error: El archivo '$DATA_FILE' no se encontró."
    echo "Por favor, asegúrese de que el archivo exista en la ruta especificada."
    echo "Si lo ejecutas en WSL, verifica que la ruta de Windows esté correctamente"
    echo "traducida (ej. 'C:\\ruta\\archivo.txt' -> '/mnt/c/ruta/archivo.txt')."
    exit 1
fi

# --- Funciones de Análisis (Modificadas para imprimir en el reporte) ---------

# Función para extraer y preparar los mensajes de spam
prepare_spam_data() {
    echo "======================================================================"
    echo "                         INICIANDO ANÁLISIS DE SPAM                 "
    echo "======================================================================"
    echo "Fecha y Hora del Reporte: $(date)"
    echo "Archivo de Datos Analizado: $DATA_FILE"
    echo "----------------------------------------------------------------------"
    echo "Preparando datos: Filtrando mensajes de spam..."
    grep "^spam" "$DATA_FILE" | cut -f2- > "$SPAM_ONLY_FILE"

    NUM_SPAM_MESSAGES=$(wc -l < "$SPAM_ONLY_FILE")
    echo "Número total de mensajes de spam extraídos: $NUM_SPAM_MESSAGES"
    echo ""
}

# Función para analizar palabras clave comunes
analyze_common_keywords() {
    echo "----------------------------------------------------------------------"
    echo "1. ANÁLISIS DE PALABRAS CLAVE COMUNES"
    echo "----------------------------------------------------------------------"
    echo "Las $TOP_N_RESULTS palabras más comunes en el spam (excluyendo stop words básicas y palabras de una letra):"
    awk -v top_n="$TOP_N_RESULTS" '
    BEGIN { RS="[^a-zA-Z]+" }
    {
        word = tolower($0)
        if (word != "" && \
            word != "a" && word != "an" && word != "the" && \
            word != "and" && word != "or" && word != "but" && \
            word != "is" && word != "are" && word != "was" && \
            word != "were" && word != "for" && word != "in" && \
            word != "on" && word != "at" && word != "to" && \
            word != "of" && word != "with" && word != "from" && \
            word != "you" && word != "your" && word != "it" && \
            word != "i" && word != "me" && word != "my" && \
            word != "we" && word != "our" && word != "us" && \
            word != "he" && word != "she" && word != "they" && \
            word != "his" && word != "her" && word != "its" && \
            word != "their" && word != "this" && word != "that" && \
            word != "these" && word != "those" && word != "be" && \
            word != "have" && word != "has" && word != "had" && \
            word != "do" && word != "does" && word != "did" && \
            word != "not" && word != "no" && word != "yes" && \
            word != "can" && word != "will" && word != "would" && \
            word != "should" && word != "could" && word != "get" && \
            word != "just" && word != "go" && word != "know" && \
            word != "see" && word != "new" && word != "now" && \
            word != "only" && word != "up" && word != "out" && \
            word != "if" && word != "as" && word != "by" && \
            word != "we" && word != "so" && word != "then" && \
            word != "when" && word != "where" && word != "why" && \
            word != "how" && word != "much" && word != "more" && \
            word != "most" && word != "very" && word != "than" && \
            word != "don" && word != "t" && word != "what" && \
            word != "there" && word != "time" && word != "call" && \
            word != "free" && word != "txt" && word != "mobile" && \
            word != "u" && word != "ur" && word != "im" && word != "lol" && \
            length(word) > 1) {
            count[word]++
        }
    }
    END {
        for (word in count) {
            print count[word], word
        }
    }' "$SPAM_ONLY_FILE" | sort -nr | head -n "$TOP_N_RESULTS" | awk '{printf "%-5s %s\n", $1, $2}' # Formato de salida
    echo ""
}

# Función para analizar posibles remitentes (shortcodes o nombres de servicios)
analyze_senders() {
    echo "----------------------------------------------------------------------"
    echo "2. ANÁLISIS DE POSIBLES REMITENTES/IDENTIFICADORES"
    echo "----------------------------------------------------------------------"
    echo "Shortcodes o números de remitente comunes (5-6 dígitos - Top $TOP_N_RESULTS):"
    grep -oP '\b\d{5,6}\b' "$SPAM_ONLY_FILE" | sort | uniq -c | sort -nr | head -n "$TOP_N_RESULTS" | awk '{printf "%-5s %s\n", $1, $2}'
    echo ""
    echo "Nombres de empresas o servicios comunes (identificados en el texto - Top $TOP_N_RESULTS):"
    grep -ioP '(o2|vodafone|prize|claim|etecsa|award|winner|txt|free|urgent|offer|nokia|orange|mobile|service|network|uk|msg|optin|stop|reply|call|phone|£|p|min|account|cash|credit|won|t&cs|terms|conditions)' "$SPAM_ONLY_FILE" | sort | uniq -c | sort -nr | head -n "$TOP_N_RESULTS" | awk '{printf "%-5s %s\n", $1, $2}'
    echo ""
}

# Función para analizar URLs sospechosas
analyze_urls() {
    echo "----------------------------------------------------------------------"
    echo "3. ANÁLISIS DE URLs SOSPECHOSAS"
    echo "----------------------------------------------------------------------"
    echo "URLs encontradas en mensajes de spam (Top $TOP_N_RESULTS):"
    grep -oP 'https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}(/[a-zA-Z0-9._~/?#%&=-]*)?' "$SPAM_ONLY_FILE" | sort | uniq -c | sort -nr | head -n "$TOP_N_RESULTS" | awk '{printf "%-5s %s\n", $1, $2}'
    echo ""
}

# Función para analizar patrones de números de teléfono
analyze_phone_numbers() {
    echo "----------------------------------------------------------------------"
    echo "4. ANÁLISIS DE PATRONES DE NÚMEROS DE TELÉFONO"
    echo "----------------------------------------------------------------------"
    echo "Números de teléfono encontrados en mensajes de spam (Patrones comunes UK/general - Top $TOP_N_RESULTS):"
    grep -oP '\b(?:(?:\+?\d{1,3}[-.\s]?)?\(?\d{2,5}\)?[-.\s]?\d{3,4}[-.\s]?\d{4,6}|\b\d{4}[-.\s]?\d{3}[-.\s]?\d{3}\b|\b\d{10,11}\b)\b' "$SPAM_ONLY_FILE" | sort | uniq -c | sort -nr | head -n "$TOP_N_RESULTS" | awk '{printf "%-5s %s\n", $1, $2}'
    echo ""
}

# Función para calcular el tamaño promedio de los mensajes
calculate_average_length() {
    echo "----------------------------------------------------------------------"
    echo "5. CÁLCULO DEL TAMAÑO PROMEDIO DE LOS MENSAJES"
    echo "----------------------------------------------------------------------"
    awk '{ total_length += length($0); count++ } END { if (count > 0) printf "Longitud promedio de los mensajes de spam: %.2f caracteres\n", total_length/count; else print "No se encontraron mensajes de spam para calcular el promedio." }' "$SPAM_ONLY_FILE"
    echo ""
}

# Función para contar palabras únicas
count_unique_words() {
    echo "----------------------------------------------------------------------"
    echo "6. CONTEO DE PALABRAS ÚNICAS"
    echo "----------------------------------------------------------------------"
    TOTAL_UNIQUE_WORDS=$(awk '
    BEGIN { RS="[^a-zA-Z]+" }
    {
        word = tolower($0)
        if (word != "") {
            unique_words[word]++
        }
    }
    END {
        print length(unique_words)
    }' "$SPAM_ONLY_FILE")
    echo "Número total de palabras únicas en los mensajes de spam: $TOTAL_UNIQUE_WORDS"
    echo ""
}

# Función para analizar la distribución de caracteres
analyze_char_distribution() {
    echo "----------------------------------------------------------------------"
    echo "7. ANÁLISIS DE DISTRIBUCIÓN DE TIPOS DE CARACTERES"
    echo "----------------------------------------------------------------------"
    awk '
    {
        for (i=1; i<=length($0); i++) {
            char = substr($0, i, 1)
            if (char ~ /[A-Z]/) upper_count++
            else if (char ~ /[a-z]/) lower_count++
            else if (char ~ /[0-9]/) digit_count++
            else if (char ~ /[[:space:]]/) space_count++
            else punct_count++ # Considera puntuación y otros caracteres especiales
            total_chars++
        }
    }
    END {
        if (total_chars > 0) {
            printf "Total de caracteres analizados: %d\n", total_chars
            printf "  Mayúsculas:      %.2f%% (%d)\n", (upper_count / total_chars * 100), upper_count
            printf "  Minúsculas:      %.2f%% (%d)\n", (lower_count / total_chars * 100), lower_count
            printf "  Dígitos:         %.2f%% (%d)\n", (digit_count / total_chars * 100), digit_count
            printf "  Espacios:        %.2f%% (%d)\n", (space_count / total_chars * 100), space_count
            printf "  Puntuación/Otros: %.2f%% (%d)\n", (punct_count / total_chars * 100), punct_count
        } else {
            print "No se encontraron caracteres para analizar."
        }
    }' "$SPAM_ONLY_FILE"
    echo ""
}

# --- Ejecución Principal ------------------------------------------------------
main() {
    echo "Iniciando el script de análisis de spam..."
    echo "Generando reporte en: $REPORT_FILE"

    # 1. Crear el directorio de resultados si no existe
    mkdir -p "$REPORT_DIR"
    if [ $? -ne 0 ]; then
        echo "Error: No se pudo crear el directorio de resultados '$REPORT_DIR'."
        echo "Asegúrese de tener los permisos adecuados."
        exit 1
    fi

    # 2. Redirigir toda la salida de las funciones de análisis al archivo de reporte
    { # Abre un bloque para redirigir toda la salida dentro de él

        prepare_spam_data
        analyze_common_keywords
        analyze_senders
        analyze_urls
        analyze_phone_numbers
        calculate_average_length
        count_unique_words
        analyze_char_distribution

        echo "======================================================================"
        echo "                       FIN DEL REPORTE DE ANÁLISIS                  "
        echo "======================================================================"

    } > "$REPORT_FILE" # Redirige todo el bloque a REPORT_FILE (sobrescribe si existe)

    # Limpieza: Eliminar el archivo temporal
    echo "Análisis completado. Limpiando archivos temporales..."
    rm -f "$SPAM_ONLY_FILE"
    echo "Archivos temporales eliminados."
    echo "Reporte guardado exitosamente en: '$REPORT_FILE'"
    echo "¡Proceso finalizado!"
}

# Ejecutar la función principal
main
