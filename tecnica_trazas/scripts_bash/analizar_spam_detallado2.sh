#!/bin/bash

# ==============================================================================
# Script de Análisis Profundo de Mensajes de Spam
# ==============================================================================
# Este script realiza un análisis exhaustivo de un dataset de mensajes SMS,
# clasificándolos en "spam" y "ham" (no-spam) y extrayendo diversas métricas
# y patrones característicos de cada categoría utilizando herramientas de
# línea de comandos como grep, awk, sort y uniq.
#
# Características:
# - Identificación de palabras clave comunes.
# - Análisis de N-gramas (bigramas y trigramas).
# - Detección de posibles remitentes y identificadores.
# - Extracción y análisis de URLs y dominios.
# - Detección de direcciones de correo electrónico y números de teléfono.
# - Análisis de longitud de palabras y patrones de capitalización.
# - Cálculo de entropía aproximada del texto.
# - Métricas detalladas de texto y legibilidad (longitud promedio, distribución de caracteres).
# - Generación de reportes en formato de texto, CSV y JSON para resumen.
# - **NUEVO: Generación de CSVs adicionales para análisis detallado en Power BI.**
#
# Uso: ./analyze_sms.sh [ruta/al/SMSSpamCollection.txt]
# Ejemplo: ./analyze_sms.sh /mnt/c/data/SMSSpamCollection.txt
# Si no se proporciona un archivo, se usará la ruta por defecto.
#
# Autor: [Tu Nombre/Organización]
# Fecha: 2025-06-06 (Fecha de última revisión)
# Licencia: MIT (O la que corresponda)
# ==============================================================================

set -e # Termina el script si un comando falla

# --- Configuración de Archivos y Rutas --------------------------------------
# Ruta por defecto para el archivo de entrada en el entorno WSL
DEFAULT_DATA_FILE="/mnt/c/Me/School/ADT/proyecto_sms_spam/tecnica_ia/datos_raw/SMSSpamCollection.txt"
SPAM_ONLY_FILE="temp_spam_messages_only.txt"
HAM_ONLY_FILE="temp_ham_messages_only.txt"

# Ruta de salida para los archivos de reporte en el entorno WSL
REPORT_DIR="/mnt/c/Me/School/ADT/proyecto_sms_spam/tecnica_trazas/resultados"
REPORT_TIMESTAMP=$(date +%Y%m%d_%H%M%S) # Para nombres de archivo únicos

# Archivos de reporte de resumen (para visualización directa)
REPORT_TEXT_FILE="$REPORT_DIR/spam_analysis_report_$REPORT_TIMESTAMP.txt"
REPORT_CSV_FILE="$REPORT_DIR/spam_analysis_summary_$REPORT_TIMESTAMP.csv"
REPORT_JSON_FILE="$REPORT_DIR/spam_analysis_summary_$REPORT_TIMESTAMP.json"

# NUEVOS Archivos CSV para Power BI (datos más granulares)
PB_KEYWORDS_CSV="$REPORT_DIR/powerbi_keywords_$REPORT_TIMESTAMP.csv"
PB_NGRAMS_CSV="$REPORT_DIR/powerbi_ngrams_spam_$REPORT_TIMESTAMP.csv"
PB_SENDERS_CSV="$REPORT_DIR/powerbi_senders_spam_$REPORT_TIMESTAMP.csv"
PB_URLS_DOMAINS_CSV="$REPORT_DIR/powerbi_urls_domains_spam_$REPORT_TIMESTAMP.csv"


TOP_N_RESULTS=10 # Número de resultados principales a mostrar para listas.

# --- Variables para almacenar métricas (para CSV/JSON) ----------------------
declare -A METRICS # Usa un diccionario asociativo para almacenar métricas

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
    echo "Error: El archivo '$DATA_FILE' no se encontró." >&2
    echo "Por favor, asegúrese de que el archivo exista en la ruta especificada." >&2
    echo "Si lo ejecutas en WSL, verifica que la ruta de Windows esté correctamente" >&2
    echo "traducida (ej. 'C:\\ruta\\archivo.txt' -> '/mnt/c/ruta/archivo.txt')." >&2
    exit 1
fi

# --- Funciones de Análisis ----------------------------------------------------

# Función para extraer y preparar los mensajes de spam y ham
prepare_data() {
    echo "======================================================================"
    echo "                       INICIANDO ANÁLISIS DE SPAM/HAM                 "
    echo "======================================================================"
    echo "Fecha y Hora del Reporte: $(date)"
    echo "Archivo de Datos Analizado: $DATA_FILE"
    echo "----------------------------------------------------------------------"
    echo "Preparando datos: Filtrando mensajes de spam y ham..."
    grep "^spam" "$DATA_FILE" | cut -f2- > "$SPAM_ONLY_FILE"
    grep "^ham" "$DATA_FILE" | cut -f2- > "<span class="math-inline">HAM\_ONLY\_FILE"
METRICS\["total\_spam\_messages"\]\=</span>(wc -l < "<span class="math-inline">SPAM\_ONLY\_FILE"\)
METRICS\["total\_ham\_messages"\]\=</span>(wc -l < "<span class="math-inline">HAM\_ONLY\_FILE"\)
METRICS\["total\_messages"\]\=</span>((METRICS["total_spam_messages"] + METRICS["total_ham_messages"]))

    echo "Número total de mensajes en el dataset: ${METRICS["total_messages"]}"
    echo "Número total de mensajes de spam: ${METRICS["total_spam_messages"]}"
    echo "Número total de mensajes ham: ${METRICS["total_ham_messages"]}"
    echo ""
}

# Función para analizar palabras clave comunes (para el reporte de texto)
# Parámetro 1: Archivo a analizar
# Parámetro 2: Prefijo para el título (ej. "SPAM" o "HAM")
analyze_common_keywords() {
    local file_to_analyze="$1"
    local prefix="$2"
    
    echo "----------------------------------------------------------------------"
    echo "1. ANÁLISIS DE PALABRAS CLAVE COMUNES ($prefix)"
    echo "----------------------------------------------------------------------"
    echo "Las $TOP_N_RESULTS palabras más comunes en el $prefix (excluyendo stop words básicas y palabras de una letra):"
    awk -v top_n="$TOP_N_RESULTS" '
    BEGIN { RS="[^a-zA-Z]+" } # Record Separator: cualquier secuencia que no sea una letra
    {
        word = tolower($0)
        # Lista de stop words más completa y filtrado de palabras de una letra
        if (word != "" && length(word) > 1 && \
            !(word in {"a":1, "an":1, "the":1, "and":1, "or":1, "but":1, \
                       "is":1, "are":1, "was":1, "were":1, "for":1, "in":1, \
                       "on":1, "at":1, "to":1, "of":1, "with":1, "from":1, \
                       "you":1, "an":1, "your":1, "it":1, "i":1, "me":1, "my":1, \
                       "we":1, "our":1, "us":1, "he":1, "she":1, "they":1, \
                       "his":1, "her":1, "its":1, "their":1, "this":1, "that":1, \
                       "these":1, "those":1, "be":1, "have":1, "has":1, "had":1, \
                       "do":1, "does":1, "did":1, "not":1, "no":1, "yes":1, \
                       "can":1, "will":1, "would":1, "should":1, "could":1, "get":1, \
                       "just":1, "go":1, "know":1, "see":1, "new":1, "now":1, \
                       "only":1, "up":1, "out":1, "if":1, "as":1, "by":1, \
                       "so":1, "then":1, "when":1, "where":1, "why":1, \
                       "how":1, "much":1, "more":1, "most":1, "very":1, "than":1, \
                       "don":1, "t":1, "what":1, "there":1, "time":1, "call":1, \
                       "free":1, "txt":1, "mobile":1, "u":1, "ur":1, "im":1, "lol":1, \
                       "gt":1, "lt":1, "ok":1, "ll":1})) { # Improved stop words
            count[word]++
        }
    }
    END {
        for (word in count) {
            print count[word], word
        }
    }' "$file_to_analyze" | sort -nr | head -n "$TOP_N_RESULTS" | awk '{printf "%-5s %s\n", $1, $2}'
    echo ""
}

# Función para analizar bigramas y trigramas (para el reporte de texto)
analyze_ngrams() {
    echo "----------------------------------------------------------------------"
    echo "2. ANÁLISIS DE N-GRAMAS (SPAM)"
    echo "----------------------------------------------------------------------"
    echo "Top $TOP_N_RESULTS Bigramas (pares de palabras) en spam:"
    awk '
    {
        # Mantener solo letras, números y espacios para evitar n-gramas con puntuación
        # y luego convertir a minúsculas
        clean_line = tolower($0);
        gsub(/[^a-zA-Z0-9 ]/, "", clean_line); 
        split(clean_line, words, " "); # Divide la línea en palabras

        for (i=1; i<length(words); i++) {
            # Asegura que las palabras no estén vacías después de la limpieza
            if (words[i] != "" && words[i+1] != "") { 
                bigram = words[i] " " words[i+1];
                bigram_count[bigram]++;
            }
        }
    }
    END {
        for (b in bigram_count) {
            print bigram_count[b], b;
        }
    }' "$SPAM_ONLY_FILE" | sort -nr | head -n "$TOP_N_RESULTS" | awk '{printf "%-5s %s\n", $1, substr($0, index($0,$2))}'
    echo ""

    echo "Top $TOP_N_RESULTS Trigramas (triples de palabras) en spam:"
    awk '
    {
        clean_line = tolower($0);
        gsub(/[^a-zA-Z0-9 ]/, "", clean_line);
        split(clean_line, words, " ");
        for (i=1; i<=(length(words)-2); i++) {
            if (words[i] != "" && words[i+1] != "" && words[i+2] != "") {
                trigram = words[i] " " words[i+1] " " words[i+2];
                trigram_count[trigram]++;
            }
        }
    }
    END {
        for (t in trigram_count) {
            print trigram_count[t], t;
        }
    }' "$SPAM_ONLY_FILE" | sort -nr | head -n "$TOP_N_RESULTS" | awk '{printf "%-5s %s\n", $1, substr($0, index($0,$2))}'
    echo ""
}

# Función para analizar posibles remitentes (shortcodes o nombres de servicios para el reporte de texto)
analyze_senders() {
    echo "----------------------------------------------------------------------"
    echo "3. ANÁLISIS DE POSIBLES REMITENTES/IDENTIFICADORES (SPAM)"
    echo "----------------------------------------------------------------------"
    echo "Shortcodes o números de remitente comunes (5-6 dígitos - Top $TOP_N_RESULTS):"
    grep -oP '\b\d{5,6}\b' "$SPAM_ONLY_FILE" | sort | uniq -c | sort -nr | head -n "$TOP_N_RESULTS" | awk '{printf "%-5s %s\n", $1, $2}'
    echo ""
    echo "Nombres de empresas o servicios comunes (identificados en el texto - Top $TOP_N_RESULTS):"
    grep -ioP '\b(O2|Vodafone|Nokia|Orange|Mobile|Service|Network|Account|Claim|Award|Winner|Prize)\b' "$SPAM_ONLY_FILE" | sort | uniq -c | sort -nr | head -n "$TOP_N_RESULTS" | awk '{printf "%-5s %s\n", $1, $2}'
    echo ""
}

# Función para analizar URLs sospechosas (para el reporte de texto)
analyze_urls() {
    echo "----------------------------------------------------------------------"
    echo "4. ANÁLISIS DE URLs SOSPECHOSAS (SPAM)"
    echo "----------------------------------------------------------------------"
    echo "URLs encontradas en mensajes de spam (Top $TOP_N_RESULTS):"
    grep -oP 'https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}(/[a-zA-Z0-9._~?#%&=-]*)?' "$SPAM_ONLY_FILE" | sort | uniq -c | sort -nr | head -n "$TOP_N_RESULTS" | awk '{printf "%-5s %s\n", $1, $2}'
    echo ""
}

# Función para detectar direcciones de correo electrónico (para el reporte de texto)
detect_emails() {
    echo "----------------------------------------------------------------------"
    echo "5. DETECCIÓN DE DIRECCIONES DE CORREO ELECTRÓNICO (SPAM)"
    echo "----------------------------------------------------------------------"
    echo "Direcciones de correo electrónico encontradas en mensajes de spam (Top $TOP_N_RESULTS):"
    grep -oP '\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b' "$SPAM_ONLY_FILE" | sort | uniq -c | sort -nr | head -n "$TOP_N_RESULTS" | awk '{printf "%-5s %s\n", $1, $2}'
    echo ""
}

# Función para extraer dominios (hostnames) (para el reporte de texto)
extract_domains() {
    echo "----------------------------------------------------------------------"
    echo "6. EXTRACCIÓN DE DOMINIOS (HOSTNAMES) DE URLs (SPAM)"
    echo "----------------------------------------------------------------------"
    echo "Dominios más frecuentes en URLs de spam (Top $TOP_N_RESULTS):"
    grep -oP 'https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}' "$SPAM_ONLY_FILE" | \
    sed -E 's|https?://(www\.)?([^/]+).*|\2|' | sort | uniq -c | sort -nr | head -n "$TOP_N_RESULTS" | awk '{printf "%-5s %s\n", $1, $2}'
    echo ""
}

# Función para analizar patrones de números de teléfono (para el reporte de texto)
analyze_phone_numbers() {
    echo "----------------------------------------------------------------------"
    echo "7. ANÁLISIS DE PATRONES DE NÚMEROS DE TELÉFONO (SPAM)"
    echo "----------------------------------------------------------------------"
    echo "Números de teléfono encontrados en mensajes de spam (Patrones comunes UK/general - Top $TOP_N_RESULTS):"
    grep -oP '\b(?:(?:\+?\d{1,3}[-.\s]?)?\(?\d{2,5}\)?[-.\s]?\d{3,4}[-.\s]?\d{4,6}|\b\d{4}[-.\s]?\d{3}[-.\s]?\d{3}\b|\b\d{10,11}\b)\b' "$SPAM_ONLY_FILE" | sort | uniq -c | sort -nr | head -n "$TOP_N_RESULTS" | awk '{printf "%-5s %s\n", $1, $2}'
    echo ""
}

# Función para analizar palabras muy largas o muy cortas (para el reporte de texto)
analyze_word_lengths() {
    echo "----------------------------------------------------------------------"
    echo "8. ANÁLISIS DE LONGITUD DE PALABRAS (SPAM)"
    echo "----------------------------------------------------------------------"
    echo "Palabras muy cortas (<= 3 caracteres) en spam (Top $TOP_N_RESULTS):"
    awk '
    {
        gsub(/[^a-zA-Z]/, " ", $0); # Reemplaza no-letras con espacios
        $0 = tolower($0);
        n = split($0, words, " ");
        for (i=1; i<=n; i++) {
            if (length(words[i]) <= 3 && length(words[i]) > 0) {
                count[words[i]]++;
            }
        }
    }
    END {
        for (word in count) {
            print count[word], word;
        }
    }' "$SPAM_ONLY_FILE" | sort -nr | head -n "$TOP_N_RESULTS" | awk '{printf "%-5s %s\n", $1, $2}'
    echo ""

    echo "Palabras muy largas (> 15 caracteres) en spam (Top $TOP_N_RESULTS):"
    awk '
    {
        gsub(/[^a-zA-Z]/, " ", $0);
        $0 = tolower($0);
        n = split($0, words, " ");
        for (i=1; i<=n; i++) {
            if (length(words[i]) > 15) {
                count[words[i]]++;
            }
        }
    }
    END {
        for (word in count) {
            print count[word], word;
        }
    }' "$SPAM_ONLY_FILE" | sort -nr | head -n "$TOP_N_RESULTS" | awk '{printf "%-5s %s\n", $1, $2}'
    echo ""
}

# Función para calcular la entropía aproximada del texto
# Parámetro 1: Archivo a analizar
# Parámetro 2: Nombre de la métrica para METRICS array
calculate_approx_entropy() {
    local file_to_analyze="$1"
    local metric_name="<span class="math-inline">2"
local entropy\_val
entropy\_val\=</span>(awk '
    BEGIN {
        LOG2 = log(2);
        total_chars = 0;
    }
    {
        for (i=1; i<=length($0); i++) {
            char = substr($0, i, 1);
            char_freq[char]++;
            total_chars++;
        }
    }
    END {
        if (total_chars == 0) {
            print 0;
            exit;
        }
        entropy = 0;
        for (char in char_freq) {
            p = char_freq[char] / total_chars;
            if (p > 0) {
                entropy -= p * (log(p) / LOG2);
            }
        }
        printf "%.4f", entropy;
    }' "$file_to_analyze")

    echo "----------------------------------------------------------------------"
    echo "9. CÁLCULO DE ENTROPÍA APROXIMADA ($metric_name)"
    echo "----------------------------------------------------------------------"
    echo "Entropía aproximada (basada en caracteres): <span class="math-inline">entropy\_val bits/carácter"
METRICS\["</span>{metric_name}_entropy"]="$entropy_val"
    echo ""
}

# Función para analizar capitalización y "shouting" (para el reporte de texto)
analyze_capitalization_shouting() {
    echo "----------------------------------------------------------------------"
    echo "10. ANÁLISIS DE CAPITALIZACIÓN Y 'SHOUTING' (SPAM)"
    echo "----------------------------------------------------------------------"
    echo "Palabras en MAYÚSCULAS (>1 carácter) en spam (Top $TOP_N_RESULTS):"
    grep -oP '\b[A-Z]{2,}\b' "$SPAM_ONLY_FILE" | sort | uniq -c | sort -nr | head -n "$TOP_N_RESULTS" | awk '{printf "%-5s %s\n", $1, $2}'
    echo ""

    # Conteo de mensajes con un alto porcentaje de mayúsculas
    echo "Mensajes de spam con alta capitalización (ej. >50% de letras en mayúsculas):"
    awk '
    BEGIN {
        messages_shouting = 0;
    }
    {
        upper_chars = 0;
        total_alpha_chars = 0;
        # Recorrer cada caracter de la línea original
        for (i=1; i<=length($0); i++) {
            char = substr($0, i, 1);
            if (char ~ /[A-Z]/) {
                upper_chars++;
                total_alpha_chars++;
            } else if (char ~ /[a-z]/) {
                total_alpha_chars++;
            }
        }
        if (total_alpha_chars > 0 && (upper_chars / total_alpha_chars) > 0.5) {
            messages_shouting++;
        }
    }
    END {
        print "Número total de mensajes de spam con alta capitalización: " messages_shouting;
    }' "$SPAM_ONLY_FILE"
    echo ""
}

# Función para detectar emoticonos o emojis (versión ASCII) (para el reporte de texto)
detect_emoticons() {
    echo "----------------------------------------------------------------------"
    echo "11. DETECCIÓN DE EMOTICONOS/EMOJIS (ASCII) (SPAM)"
    echo "----------------------------------------------------------------------"
    local EMOTICONS_REGEX='(\s:-\)|\s:-\(|\s:D|\s:P|\s;\)|\s:\)|\s:\(|:\'\(|XD|:o|:O|:\*|<3|-_-|:\/|\\(>_<)//|>=o|-_-)'
    echo "Emoticonos ASCII comunes encontrados en spam (Top $TOP_N_RESULTS):"
    grep -oP "$EMOTICONS_REGEX" "$SPAM_ONLY_FILE" | sort | uniq -c | sort -nr | head -n "$TOP_N_RESULTS" | awk '{printf "%-5s %s\n", $1, $2}'
    echo ""
}

# Función para calcular el tamaño promedio de los mensajes y longitud media de palabra
# Parámetro 1: Archivo a analizar
# Parámetro 2: Prefijo para las métricas (ej. "spam" o "ham")
calculate_text_metrics() {
    local file_to_analyze="$1"
    local prefix="<span class="math-inline">2"
local results
results\=</span>(awk '
    BEGIN {
        # Inicializar contadores para la distribución de caracteres por mensaje
        total_upper_count = 0;
        total_lower_count = 0;
        total_digit_count = 0;
        total_space_count = 0;
        total_punct_count = 0;
        total_chars_overall = 0; # Caracteres totales para los porcentajes finales

        total_line_length = 0;
        line_count = 0;
        total_word_length = 0;
        word_count = 0;
    }
    {
        line_length = length($0);
        total_line_length += line_length;
        line_count++;

        # Contar la distribución de caracteres ANTES de modificar la línea
        for (i=1; i<=line_length; i++) {
            char = substr($0, i, 1);
            if (char ~ /[A-Z]/) total_upper_count++;
            else if (char ~ /[a-z]/) total_lower_count++;
            else if (char ~ /[0-9]/) total_digit_count++;
            else if (char ~ /[[:space:]]/) total_space_count++;
            else total_punct_count++;
            total_chars_overall++;
        }

        # Procesar para longitud de palabras y palabras únicas
        # Crear una copia limpia para el procesamiento de palabras
        clean_line = $0;
        gsub(/[^a-zA-Z]/, " ", clean_line); # Reemplaza no-letras con espacios
        clean_line = tolower(clean_line); # Convierte a minúsculas
        
        n = split(clean_line, words, " ");
        for (i=1; i<=n; i++) {
            if (length(words[i]) > 0) {
                total_word_length += length(words[i]);
                word
