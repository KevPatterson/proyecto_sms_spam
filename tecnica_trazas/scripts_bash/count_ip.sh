#!/bin/bash
# count_ip.sh
# Uso: ./count_ip.sh <archivo_log> <ip_objetivo>
# Ejemplo: ./count_ip.sh ../datos_de_prueba/custom_trazas.log 10.0.0.5

if [ $# -ne 2 ]; then
  echo "Uso: $0 archivo_log ip_objetivo"
  exit 1
fi

ARCHIVO="$1"
IP="$2"

# Verificar que el archivo exista y sea legible
if [ ! -r "$ARCHIVO" ]; then
  echo "Error: no se puede leer el archivo '$ARCHIVO'"
  exit 1
fi

# Contar líneas que contienen exactamente la IP (puede coincidir como subcadena)
count=$(grep -F "$IP" "$ARCHIVO" | wc -l)

echo "La IP '$IP' aparece $count veces en '$ARCHIVO'."
