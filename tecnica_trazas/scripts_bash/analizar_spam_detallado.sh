#!/bin/bash

# ==============================================================================
# Script de Análisis Profundo de Mensajes de Spam
# ==============================================================================
# Este script realiza un análisis exhaustivo de un conjunto de datos de mensajes
# (spam y ham), extrayendo patrones, métricas y comparaciones, utilizando
# herramientas de línea de comandos como grep, awk, sort, uniq, wc, etc.
#
# Genera un reporte detallado en un archivo de texto plano, y resúmenes
# estadísticos en formato CSV y JSON.
#
# Uso: ./analizar_spam_profesional.sh [archivo_entrada]
# Si no se especifica archivo_entrada, se usará la ruta por defecto para WSL.
#
# Funcionalidades Incluidas:
# - Filtrado de mensajes de spam y ham.
# - Conteo de mensajes de spam y ham.
# - Análisis de n-gramas (bigramas, trigramas).
# - Análisis de palabras clave comunes (con filtrado de stop words).
# - Detección de posibles shortcodes/identificadores de remitente.
# - Extracción y conteo de URLs sospechosas.
# - Detección y extracción de direcciones de correo electrónico.
# - Extracción de dominios (hostnames) de las URLs encontradas.
# - Identificación de patrones de números de teléfono.
# - Análisis de palabras muy largas o muy cortas.
# - Cálculo de entropía aproximada del texto (basada en caracteres).
# - Análisis de capitalización y "shouting" (palabras en MAYÚSCULAS).
# - Detección de emoticonos o emojis (versión ASCII).
# - Métricas de legibilidad simples (longitud media de palabra).
# - Comparación de métricas clave entre mensajes spam y ham.
# - Manejo de errores para archivos inexistentes.
# - Parámetros configurables (ej. número de resultados principales a mostrar).
# - Exportación de resultados a un archivo de reporte con formato atractivo.
# - Exportación de un resumen de estadísticas en formato CSV y JSON.
# ==============================================================================

# --- Configuración de Archivos y Rutas --------------------------------------
# Ruta por defecto para el archivo de entrada en el entorno WSL
DEFAULT_DATA_FILE="/mnt/c/Me/School/ADT/proyecto_sms_spam/tecnica_ia/datos_raw/SMSSpamCollection.txt"
SPAM_ONLY_FILE="temp_spam_messages_only.txt"
HAM_ONLY_FILE="temp_ham_messages_only.txt"

# Ruta de salida para los archivos de reporte en el entorno WSL
REPORT_DIR="/mnt/c/Me/School/ADT/proyecto_sms_spam/tecnica_ia/resultados"
REPORT_TIMESTAMP=$(date +%Y%m%d_%H%M%S) # Para nombres de archivo únicos

REPORT_TEXT_FILE="$REPORT_DIR/spam_analysis_report_$REPORT_TIMESTAMP.txt"
REPORT_CSV_FILE="$REPORT_DIR/spam_analysis_summary_$REPORT_TIMESTAMP.csv"
REPORT_JSON_FILE="$REPORT_DIR/spam_analysis_summary_$REPORT_TIMESTAMP.json"

TOP_N_RESULTS=15 # Número de resultados principales a mostrar para listas.

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
    echo "Error: El archivo '$DATA_FILE' no se encontró."
    echo "Por favor, asegúrese de que el archivo exista en la ruta especificada."
    echo "Si lo ejecutas en WSL, verifica que la ruta de Windows esté correctamente"
    echo "traducida (ej. 'C:\\ruta\\archivo.txt' -> '/mnt/c/ruta/archivo.txt')."
    exit 1
fi

# --- Funciones de Análisis ----------------------------------------------------

# Función para extraer y preparar los mensajes de spam y ham
prepare_data() {
    echo "======================================================================"
    echo "                         INICIANDO ANÁLISIS DE SPAM/HAM             "
    echo "======================================================================"
    echo "Fecha y Hora del Reporte: $(date)"
    echo "Archivo de Datos Analizado: $DATA_FILE"
    echo "----------------------------------------------------------------------"
    echo "Preparando datos: Filtrando mensajes de spam y ham..."
    grep "^spam" "$DATA_FILE" | cut -f2- > "$SPAM_ONLY_FILE"
    grep "^ham" "$DATA_FILE" | cut -f2- > "$HAM_ONLY_FILE"

    METRICS["total_spam_messages"]=$(wc -l < "$SPAM_ONLY_FILE")
    METRICS["total_ham_messages"]=$(wc -l < "$HAM_ONLY_FILE")
    METRICS["total_messages"]=$((METRICS["total_spam_messages"] + METRICS["total_ham_messages"]))

    echo "Número total de mensajes en el dataset: ${METRICS["total_messages"]}"
    echo "Número total de mensajes de spam: ${METRICS["total_spam_messages"]}"
    echo "Número total de mensajes ham: ${METRICS["total_ham_messages"]}"
    echo ""
}

# Función para analizar palabras clave comunes
# Parámetro 1: Archivo a analizar
# Parámetro 2: Prefijo para el título (ej. "SPAM" o "HAM")
analyze_common_keywords() {
    local file_to_analyze="$1"
    local prefix="$2"
    local output

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

# Función para analizar bigramas y trigramas
analyze_ngrams() {
    echo "----------------------------------------------------------------------"
    echo "2. ANÁLISIS DE N-GRAMAS (SPAM)"
    echo "----------------------------------------------------------------------"
    echo "Top $TOP_N_RESULTS Bigramas (pares de palabras) en spam:"
    # Tokeniza, limpia puntuación, convierte a minúsculas y genera bigramas
    awk '
    {
        gsub(/[^a-zA-Z0-9 ]/, "", $0); # Elimina puntuación, mantiene números y espacios
        tolower($0); # Convierte a minúsculas
        split($0, words, " "); # Divide la línea en palabras
        for (i=1; i<length(words); i++) {
            if (words[i] != "" && words[i+1] != "") { # Asegura que no sean palabras vacías
                bigram = words[i] " " words[i+1];
                bigram_count[bigram]++;
            }
        }
    }
    END {
        for (b in bigram_count) {
            print bigram_count[b], b;
        }
    }' "$SPAM_ONLY_FILE" | sort -nr | head -n "$TOP_N_RESULTS" | awk '{printf "%-5s %s\n", $1, $2}'
    echo ""

    echo "Top $TOP_N_RESULTS Trigramas (triples de palabras) en spam:"
    awk '
    {
        gsub(/[^a-zA-Z0-9 ]/, "", $0);
        tolower($0);
        split($0, words, " ");
        for (i=1; i<length(words)-1; i++) {
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
    }' "$SPAM_ONLY_FILE" | sort -nr | head -n "$TOP_N_RESULTS" | awk '{printf "%-5s %s\n", $1, $2}'
    echo ""
}


# Función para analizar posibles remitentes (shortcodes o nombres de servicios)
analyze_senders() {
    echo "----------------------------------------------------------------------"
    echo "3. ANÁLISIS DE POSIBLES REMITENTES/IDENTIFICADORES (SPAM)"
    echo "----------------------------------------------------------------------"
    echo "Shortcodes o números de remitente comunes (5-6 dígitos - Top $TOP_N_RESULTS):"
    grep -oP '\b\d{5,6}\b' "$SPAM_ONLY_FILE" | sort | uniq -c | sort -nr | head -n "$TOP_N_RESULTS" | awk '{printf "%-5s %s\n", $1, $2}'
    echo ""
    echo "Nombres de empresas o servicios comunes (identificados en el texto - Top $TOP_N_RESULTS):"
    grep -ioP '(o2|vodafone|prize|claim|award|winner|txt|free|urgent|offer|nokia|orange|mobile|service|network|uk|msg|optin|stop|reply|call|phone|£|p|min|account|cash|credit|won|t&cs|terms|conditions)' "$SPAM_ONLY_FILE" | sort | uniq -c | sort -nr | head -n "$TOP_N_RESULTS" | awk '{printf "%-5s %s\n", $1, $2}'
    echo ""
}

# Función para analizar URLs sospechosas
analyze_urls() {
    echo "----------------------------------------------------------------------"
    echo "4. ANÁLISIS DE URLs SOSPECHOSAS (SPAM)"
    echo "----------------------------------------------------------------------"
    echo "URLs encontradas en mensajes de spam (Top $TOP_N_RESULTS):"
    grep -oP 'https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}(/[a-zA-Z0-9._~/?#%&=-]*)?' "$SPAM_ONLY_FILE" | sort | uniq -c | sort -nr | head -n "$TOP_N_RESULTS" | awk '{printf "%-5s %s\n", $1, $2}'
    echo ""
}

# Función para detectar direcciones de correo electrónico
detect_emails() {
    echo "----------------------------------------------------------------------"
    echo "5. DETECCIÓN DE DIRECCIONES DE CORREO ELECTRÓNICO (SPAM)"
    echo "----------------------------------------------------------------------"
    echo "Direcciones de correo electrónico encontradas en mensajes de spam (Top $TOP_N_RESULTS):"
    grep -oP '\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b' "$SPAM_ONLY_FILE" | sort | uniq -c | sort -nr | head -n "$TOP_N_RESULTS" | awk '{printf "%-5s %s\n", $1, $2}'
    echo ""
}

# Función para extraer dominios (hostnames)
extract_domains() {
    echo "----------------------------------------------------------------------"
    echo "6. EXTRACCIÓN DE DOMINIOS (HOSTNAMES) DE URLs (SPAM)"
    echo "----------------------------------------------------------------------"
    echo "Dominios más frecuentes en URLs de spam (Top $TOP_N_RESULTS):"
    # Extrae URLs completas, luego usa sed para obtener solo el dominio
    grep -oP 'https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}' "$SPAM_ONLY_FILE" | \
    sed -E 's/https?:\/\/(www\.)?([^/]+).*/\2/' | sort | uniq -c | sort -nr | head -n "$TOP_N_RESULTS" | awk '{printf "%-5s %s\n", $1, $2}'
    echo ""
}

# Función para analizar patrones de números de teléfono
analyze_phone_numbers() {
    echo "----------------------------------------------------------------------"
    echo "7. ANÁLISIS DE PATRONES DE NÚMEROS DE TELÉFONO (SPAM)"
    echo "----------------------------------------------------------------------"
    echo "Números de teléfono encontrados en mensajes de spam (Patrones comunes UK/general - Top $TOP_N_RESULTS):"
    grep -oP '\b(?:(?:\+?\d{1,3}[-.\s]?)?\(?\d{2,5}\)?[-.\s]?\d{3,4}[-.\s]?\d{4,6}|\b\d{4}[-.\s]?\d{3}[-.\s]?\d{3}\b|\b\d{10,11}\b)\b' "$SPAM_ONLY_FILE" | sort | uniq -c | sort -nr | head -n "$TOP_N_RESULTS" | awk '{printf "%-5s %s\n", $1, $2}'
    echo ""
}

# Función para analizar palabras muy largas o muy cortas
analyze_word_lengths() {
    echo "----------------------------------------------------------------------"
    echo "8. ANÁLISIS DE LONGITUD DE PALABRAS (SPAM)"
    echo "----------------------------------------------------------------------"
    echo "Palabras muy cortas (<= 3 caracteres) en spam (Top $TOP_N_RESULTS):"
    awk '
    {
        gsub(/[^a-zA-Z]/, " ", $0); # Reemplaza no-letras con espacios
        tolower($0);
        split($0, words, " ");
        for (i=1; i<=length(words); i++) {
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
        tolower($0);
        split($0, words, " ");
        for (i=1; i<=length(words); i++) {
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
    local metric_name="$2"
    local entropy_val

    entropy_val=$(awk '
    BEGIN {
        # log_2(x) = log(x) / log(2)
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
            print 0; # No characters to analyze
            exit;
        }
        entropy = 0;
        for (char in char_freq) {
            p = char_freq[char] / total_chars;
            # Asegura que log no se aplique a cero o NaN si p es muy pequeño (aunque p > 0 por construcción)
            if (p > 0) {
                entropy -= p * (log(p) / LOG2);
            }
        }
        printf "%.4f", entropy;
    }' "$file_to_analyze")

    echo "----------------------------------------------------------------------"
    echo "9. CÁLCULO DE ENTROPÍA APROXIMADA ($metric_name)"
    echo "----------------------------------------------------------------------"
    echo "Entropía aproximada (basada en caracteres): $entropy_val bits/carácter"
    METRICS["${metric_name}_entropy"]="$entropy_val"
    echo ""
}

# Función para analizar capitalización y "shouting"
analyze_capitalization_shouting() {
    echo "----------------------------------------------------------------------"
    echo "10. ANÁLISIS DE CAPITALIZACIÓN Y 'SHOUTING' (SPAM)"
    echo "----------------------------------------------------------------------"
    echo "Palabras en MAYÚSCULAS (>1 carácter) en spam (Top $TOP_N_RESULTS):"
    # Busca palabras que consisten solo en mayúsculas (2 o más caracteres)
    grep -oP '\b[A-Z]{2,}\b' "$SPAM_ONLY_FILE" | sort | uniq -c | sort -nr | head -n "$TOP_N_RESULTS" | awk '{printf "%-5s %s\n", $1, $2}'
    echo ""

    # Conteo de mensajes con un alto porcentaje de mayúsculas (ej. más del 50% de caracteres alfabéticos son mayúsculas)
    echo "Mensajes de spam con alta capitalización (ej. >50% de letras en mayúsculas):"
    awk '
    {
        upper_chars = 0;
        total_alpha_chars = 0;
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
            print $0; # Imprime el mensaje completo si cumple la condición
            messages_shouting++;
        }
    }
    END {
        print "----------------------------------------------------------------------";
        print "Número total de mensajes de spam con alta capitalización: " messages_shouting;
    }' "$SPAM_ONLY_FILE"
    echo ""
}

# Función para detectar emoticonos o emojis (versión ASCII)
detect_emoticons() {
    echo "----------------------------------------------------------------------"
    echo "11. DETECCIÓN DE EMOTICONOS/EMOJIS (ASCII) (SPAM)"
    echo "----------------------------------------------------------------------"
    # Patrones comunes de emoticonos ASCII
    local EMOTICONS_REGEX='(:-\)|:-\(|:D|:P|;\)|\(:|:\'\(|XD|:o|:O|:\*|<3|\:\-?\s*[\(\)\|\]\[/DPSO<>C*])'
    echo "Emoticonos ASCII comunes encontrados en spam (Top $TOP_N_RESULTS):"
    grep -oP "$EMOTICONS_REGEX" "$SPAM_ONLY_FILE" | sort | uniq -c | sort -nr | head -n "$TOP_N_RESULTS" | awk '{printf "%-5s %s\n", $1, $2}'
    echo ""
}

# Función para calcular el tamaño promedio de los mensajes y longitud media de palabra
# Parámetro 1: Archivo a analizar
# Parámetro 2: Prefijo para las métricas (ej. "spam" o "ham")
calculate_text_metrics() {
    local file_to_analyze="$1"
    local prefix="$2"
    local results

    results=$(awk '
    {
        line_length = length($0);
        total_line_length += line_length;
        line_count++;

        gsub(/[^a-zA-Z]/, " ", $0); # Limpia puntuación para contar palabras
        tolower($0);
        split($0, words, " ");
        for (i=1; i<=length(words); i++) {
            if (length(words[i]) > 0) {
                total_word_length += length(words[i]);
                word_count++;
                unique_words[words[i]]++;
            }
        }

        # Caracteres para distribución
        for (i=1; i<=line_length; i++) {
            char = substr($0, i, 1);
            if (char ~ /[A-Z]/) upper_count++;
            else if (char ~ /[a-z]/) lower_count++;
            else if (char ~ /[0-9]/) digit_count++;
            else if (char ~ /[[:space:]]/) space_count++;
            else punct_count++;
            total_chars++;
        }
    }
    END {
        avg_msg_len = (line_count > 0) ? (total_line_length / line_count) : 0;
        avg_word_len = (word_count > 0) ? (total_word_length / word_count) : 0;
        num_unique_words = length(unique_words);

        upper_perc = (total_chars > 0) ? (upper_count / total_chars * 100) : 0;
        lower_perc = (total_chars > 0) ? (lower_count / total_chars * 100) : 0;
        digit_perc = (total_chars > 0) ? (digit_count / total_chars * 100) : 0;
        space_perc = (total_chars > 0) ? (space_count / total_chars * 100) : 0;
        punct_perc = (total_chars > 0) ? (punct_count / total_chars * 100) : 0;

        printf "avg_msg_len:%.2f\n", avg_msg_len;
        printf "avg_word_len:%.2f\n", avg_word_len;
        printf "num_unique_words:%d\n", num_unique_words;
        printf "upper_perc:%.2f\n", upper_perc;
        printf "lower_perc:%.2f\n", lower_perc;
        printf "digit_perc:%.2f\n", digit_perc;
        printf "space_perc:%.2f\n", space_perc;
        printf "punct_perc:%.2f\n", punct_perc;
    }' "$file_to_analyze")

    while IFS= read -r line; do
        key=$(echo "$line" | cut -d: -f1)
        value=$(echo "$line" | cut -d: -f2)
        METRICS["${prefix}_$key"]="$value"
    done <<< "$results"

    echo "----------------------------------------------------------------------"
    echo "12. MÉTRICAS DE TEXTO Y LEGIBILIDAD ($prefix)"
    echo "----------------------------------------------------------------------"
    echo "Longitud promedio de los mensajes: ${METRICS["${prefix}_avg_msg_len"]} caracteres"
    echo "Longitud promedio de palabra: ${METRICS["${prefix}_avg_word_len"]} caracteres"
    echo "Número total de palabras únicas: ${METRICS["${prefix}_num_unique_words"]}"
    echo ""
    echo "Distribución de caracteres:"
    printf "  Mayúsculas:      %.2f%%\n" "${METRICS["${prefix}_upper_perc"]}"
    printf "  Minúsculas:      %.2f%%\n" "${METRICS["${prefix}_lower_perc"]}"
    printf "  Dígitos:         %.2f%%\n" "${METRICS["${prefix}_digit_perc"]}"
    printf "  Espacios:        %.2f%%\n" "${METRICS["${prefix}_space_perc"]}"
    printf "  Puntuación/Otros: %.2f%%\n" "${METRICS["${prefix}_punct_perc"]}"
    echo ""
}

# Función para comparación spam vs. ham (usa métricas ya calculadas)
compare_spam_vs_ham() {
    echo "======================================================================"
    echo "                    COMPARACIÓN SPAM VS. HAM                        "
    echo "======================================================================"
    echo "Métrica                  | Spam                  | Ham"
    echo "-------------------------|-----------------------|-----------------------"
    printf "%-25s| %-21s | %-21s\n" "Total Mensajes" "${METRICS["total_spam_messages"]}" "${METRICS["total_ham_messages"]}"
    printf "%-25s| %-21s | %-21s\n" "Longitud Promedio Mensaje" "${METRICS["spam_avg_msg_len"]}" "${METRICS["ham_avg_msg_len"]}"
    printf "%-25s| %-21s | %-21s\n" "Longitud Promedio Palabra" "${METRICS["spam_avg_word_len"]}" "${METRICS["ham_avg_word_len"]}"
    printf "%-25s| %-21s | %-21s\n" "Palabras Únicas" "${METRICS["spam_num_unique_words"]}" "${METRICS["ham_num_unique_words"]}"
    printf "%-25s| %-21s | %-21s\n" "Entropía (bits/char)" "${METRICS["spam_entropy"]}" "${METRICS["ham_entropy"]}"
    printf "%-25s| %-21s | %-21s\n" "% Mayúsculas" "${METRICS["spam_upper_perc"]}%" "${METRICS["ham_upper_perc"]}%"
    printf "%-25s| %-21s | %-21s\n" "% Dígitos" "${METRICS["spam_digit_perc"]}%" "${METRICS["ham_digit_perc"]}%"
    echo "----------------------------------------------------------------------"
    echo ""
}

# Función para generar el reporte CSV
generate_csv_report() {
    echo "Generando reporte CSV en: $REPORT_CSV_FILE"
    {
        # Encabezados CSV
        echo "Metric,SpamValue,HamValue"
        echo "Total_Messages,${METRICS["total_spam_messages"]},${METRICS["total_ham_messages"]}"
        echo "Average_Message_Length,${METRICS["spam_avg_msg_len"]},${METRICS["ham_avg_msg_len"]}"
        echo "Average_Word_Length,${METRICS["spam_avg_word_len"]},${METRICS["ham_avg_word_len"]}"
        echo "Unique_Words_Count,${METRICS["spam_num_unique_words"]},${METRICS["ham_num_unique_words"]}"
        echo "Approx_Entropy,${METRICS["spam_entropy"]},${METRICS["ham_entropy"]}"
        echo "Uppercase_Percentage,${METRICS["spam_upper_perc"]},${METRICS["ham_upper_perc"]}"
        echo "Lowercase_Percentage,${METRICS["spam_lower_perc"]},${METRICS["ham_lower_perc"]}"
        echo "Digit_Percentage,${METRICS["spam_digit_perc"]},${METRICS["ham_digit_perc"]}"
        echo "Space_Percentage,${METRICS["spam_space_perc"]},${METRICS["ham_space_perc"]}"
        echo "Punctuation_Other_Percentage,${METRICS["spam_punct_perc"]},${METRICS["ham_punct_perc"]}"
    } > "$REPORT_CSV_FILE"
}

# Función para generar el reporte JSON
generate_json_report() {
    echo "Generando reporte JSON en: $REPORT_JSON_FILE"
    cat <<EOF > "$REPORT_JSON_FILE"
{
  "report_timestamp": "$REPORT_TIMESTAMP",
  "data_file": "$DATA_FILE",
  "summary": {
    "total_messages": ${METRICS["total_messages"]},
    "spam": {
      "total_messages": ${METRICS["total_spam_messages"]},
      "average_message_length": ${METRICS["spam_avg_msg_len"]},
      "average_word_length": ${METRICS["spam_avg_word_len"]},
      "unique_words_count": ${METRICS["spam_num_unique_words"]},
      "approx_entropy": ${METRICS["spam_entropy"]},
      "character_distribution": {
        "uppercase_percentage": ${METRICS["spam_upper_perc"]},
        "lowercase_percentage": ${METRICS["spam_lower_perc"]},
        "digit_percentage": ${METRICS["spam_digit_perc"]},
        "space_percentage": ${METRICS["spam_space_perc"]},
        "punctuation_other_percentage": ${METRICS["spam_punct_perc"]}
      }
    },
    "ham": {
      "total_messages": ${METRICS["total_ham_messages"]},
      "average_message_length": ${METRICS["ham_avg_msg_len"]},
      "average_word_length": ${METRICS["ham_avg_word_len"]},
      "unique_words_count": ${METRICS["ham_num_unique_words"]},
      "approx_entropy": ${METRICS["ham_entropy"]},
      "character_distribution": {
        "uppercase_percentage": ${METRICS["ham_upper_perc"]},
        "lowercase_percentage": ${METRICS["ham_lower_perc"]},
        "digit_percentage": ${METRICS["ham_digit_perc"]},
        "space_percentage": ${METRICS["ham_space_perc"]},
        "punctuation_other_percentage": ${METRICS["ham_punct_perc"]}
      }
    }
  }
}
EOF
}

# Función para limpiar archivos temporales
cleanup_temp_files() {
    echo "Limpiando archivos temporales..."
    rm -f "$SPAM_ONLY_FILE" "$HAM_ONLY_FILE"
    echo "Archivos temporales eliminados."
}

# --- Ejecución Principal ------------------------------------------------------
main() {
    echo "Iniciando el script de análisis de spam y ham..."
    echo "Reporte de texto detallado en: $REPORT_TEXT_FILE"
    echo "Resumen de estadísticas en CSV: $REPORT_CSV_FILE"
    echo "Resumen de estadísticas en JSON: $REPORT_JSON_FILE"

    # 1. Crear el directorio de resultados si no existe
    mkdir -p "$REPORT_DIR"
    if [ $? -ne 0 ]; then
        echo "Error: No se pudo crear el directorio de resultados '$REPORT_DIR'."
        echo "Asegúrese de tener los permisos adecuados."
        exit 1
    fi

    # 2. Redirigir toda la salida de las funciones de análisis al archivo de reporte de texto
    { # Abre un bloque para redirigir toda la salida dentro de él

        prepare_data # Prepara tanto spam como ham
        
        # Análisis para SPAM
        analyze_common_keywords "$SPAM_ONLY_FILE" "SPAM"
        analyze_ngrams
        analyze_senders
        analyze_urls
        detect_emails
        extract_domains
        analyze_phone_numbers
        analyze_word_lengths
        calculate_approx_entropy "$SPAM_ONLY_FILE" "spam"
        analyze_capitalization_shouting
        detect_emoticons
        calculate_text_metrics "$SPAM_ONLY_FILE" "spam" # Calcula AVG len y dist. caracteres para spam

        # Análisis para HAM (Solo las métricas clave para comparación)
        echo "======================================================================"
        echo "               ANÁLISIS DE MENSAJES HAM (NO-SPAM)                   "
        echo "======================================================================"
        analyze_common_keywords "$HAM_ONLY_FILE" "HAM"
        calculate_approx_entropy "$HAM_ONLY_FILE" "ham"
        calculate_text_metrics "$HAM_ONLY_FILE" "ham" # Calcula AVG len y dist. caracteres para ham

        # Comparación final
        compare_spam_vs_ham

        echo "======================================================================"
        echo "                       FIN DEL REPORTE DE ANÁLISIS                  "
        echo "======================================================================"

    } > "$REPORT_TEXT_FILE" # Redirige todo el bloque al archivo de reporte de texto

    # Generar reportes CSV y JSON (no redirigidos, ya que son su propio archivo)
    generate_csv_report
    generate_json_report

    cleanup_temp_files # Limpia archivos temporales

    echo "Reporte de texto guardado exitosamente en: '$REPORT_TEXT_FILE'"
    echo "Resumen CSV guardado exitosamente en: '$REPORT_CSV_FILE'"
    echo "Resumen JSON guardado exitosamente en: '$REPORT_JSON_FILE'"
    echo "¡Proceso finalizado!"
}

# Ejecutar la función principal
main
