
#!/usr/bin/env python3
import pandas as pd
import re
from datetime import datetime
import sys

# Ruta al archivo de log (puede pasarse como argumento)
logfile = sys.argv[1] if len(sys.argv) > 1 else "access.log-20201205"

# Expresión regular para parsear las líneas de log
log_pattern = re.compile(
    r'(?P<ip>\d+\.\d+\.\d+\.\d+) - (?P<user>[^\[]*) \[(?P<datetime>.*?)\] "(?P<method>\S+) (?P<url>[^ ]+) (?P<protocol>[^"]+)" (?P<status>\d+) (?P<size>\d+) "-" "(?P<user_agent>[^"]*)" (?P<type>[^\[]+) \[.*?X-Forwarded-For: (?P<forwarded>[^,\n]+).*?Host: (?P<host>[^:\\n\]]+)'
)

entries = []
with open(logfile, 'r') as file:
    for line in file:
        match = log_pattern.search(line)
        if match:
            data = match.groupdict()
            data["datetime"] = datetime.strptime(data["datetime"], "%d/%b/%Y:%H:%M:%S %z")
            data["size"] = int(data["size"])
            data["status"] = int(data["status"])
            entries.append(data)

df = pd.DataFrame(entries)

# Filtrado de categorías sospechosas
keywords = {
    "pornografía": ["porn", "xxx", "sex", "adult"],
    "antigubernamental": ["gusano", "anticomunista", "revolución cubana", "anticastro", "anticastrista"],
    "desinformación": ["fake-news", "conspiracy", "hoax", "desinformacion"],
    "vpn": ["vpn", "openvpn", "nordvpn", "expressvpn"],
    "pentesting": ["nmap", "metasploit", "sqlmap", "hydra"],
}

def categorizar_url(url):
    for categoria, palabras in keywords.items():
        for palabra in palabras:
            if palabra.lower() in url.lower():
                return categoria
    return "normal"

df["categoria"] = df["url"].apply(categorizar_url)

# Intentos fallidos
df["fallo"] = df["status"].apply(lambda x: x in [403, 401, 503])

# Análisis resumen
resumen = {
    "visitas_por_categoria": df["categoria"].value_counts(),
    "ips_con_mas_fallos": df[df["fallo"]].groupby("ip").size().sort_values(ascending=False),
    "usuarios_con_mas_fallos": df[df["fallo"]].groupby("user").size().sort_values(ascending=False),
    "conexiones_posible_vpn": df[df["categoria"] == "vpn"],
}

# Guardar resultados
df.to_csv("analisis_completo.csv", index=False)
for key, value in resumen.items():
    if isinstance(value, pd.DataFrame) or isinstance(value, pd.Series):
        value.to_csv(f"{key}.csv")

print("Análisis completado. Archivos exportados:")
print("\n".join([f"{key}.csv" for key in resumen.keys()]))
