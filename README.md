# Proyecto SMS Spam (ADT-IA)

Este repositorio contiene un proyecto completo orientado al análisis y detección de mensajes SMS de tipo "spam" utilizando dos enfoques principales:

1. **Técnica de Inteligencia Artificial** (carpeta `tecnica_ia/`):

   * Preprocesamiento de datos y vectorización.
   * Entrenamiento y persistencia de un modelo de detección de spam (Isolation Forest).
2. **Técnica de Análisis de Trazas** (carpeta `tecnica_trazas/`):

   * Automatización con scripts Bash para procesar logs de mensajes etiquetados.
   * Generación de informes detallados y resúmenes en formatos CSV, JSON y TXT.

---

## 📂 Estructura del Proyecto

```
proyecto_sms_spam/
├── .gitattributes
├── .gitignore
├── README.md                 # (Este archivo)
├── tecnica_ia/               # Análisis con IA
│   ├── datos_raw/            # Datos de entrada en distintos formatos
│   │   ├── SMSSpamCollection
│   │   ├── SMSSpamCollection.csv
│   │   ├── SMSSpamCollection.ndjson
│   │   └── mensajes_convertido.csv
│   ├── modelos/              # Modelos y vectores entrenados
│   │   ├── features_vectorizer.txt
│   │   └── iso_forest_sms_spam.joblib
│   └── notebooks/            # Jupyter notebooks de exploración y entrenamiento
│       └── exploracion_modelado.ipynb
├── tecnica_trazas/           # Análisis de trazas con scripts Bash
│   ├── scripts_bash/         # Scripts para ejecutar procesamiento por lotes
│   │   ├── analizar_spam.sh
│   │   ├── analizar_spam_detallado.sh
│   │   └── analizar_spam_detallado2.sh
│   ├── resultados/           # Informes generados
│   │   ├── spam_analysis_report_YYYYMMDD_HHMMSS.txt
│   │   ├── spam_analysis_summary_*.csv
│   │   └── spam_analysis_summary_*.json
│   └── web_spy/              # (Opcional) Scripts de scraping/web spying
└── LICENSE                   # Licencia del proyecto
```

---

## 🚀 Requisitos Previos

* **Python 3.8+**
* **pip** (gestor de paquetes Python)
* **bash** y utilidades GNU para scripts (en Linux/macOS o WSL en Windows)

### Dependencias Python

Ejecutar en la raíz del proyecto:

```bash
pip install -r tecnica_ia/requirements.txt
```

> **Nota:** El archivo `requirements.txt` debe incluir bibliotecas como `scikit-learn`, `pandas`, `joblib`, `ndjson`, entre otras.

---

## 🧠 Técnica de Inteligencia Artificial

1. **Carga de datos**: Los archivos originales (`SMSSpamCollection`, CSV y NDJSON) se encuentran en `tecnica_ia/datos_raw/`.
2. **Preprocesamiento**:

   * Conversión de formatos a CSV y JSON.
   * Limpieza y normalización de texto (minusculas, eliminación de puntuación, stopwords).
3. **Vectorización**:

   * Uso de `CountVectorizer` o `TfidfVectorizer` para transformar texto en vectores.
   * Guardado del vectorizador en `tecnica_ia/modelos/features_vectorizer.txt`.
4. **Entrenamiento del modelo**:

   * Empleo de un `IsolationForest` entrenado sobre los datos limpios.
   * Serialización del modelo a `iso_forest_sms_spam.joblib`.
5. **Evaluación y predicción**:

   * Cálculo de métricas (precisión, recall, F1) y ejemplos de predicción.

### Cómo ejecutar

En la carpeta `tecnica_ia/`:

```bash
python run_pipeline.py --input datos_raw/SMSSpamCollection.csv \
                       --vectorizer modelos/features_vectorizer.txt \
                       --model modelos/iso_forest_sms_spam.joblib \
                       --output resultados/predicciones.csv
```

---

## 🛠️ Técnica de Análisis de Trazas (Bash)

Los scripts Bash automatizan el procesamiento de logs etiquetados para obtener reportes y resúmenes de la detección de spam.

### Scripts disponibles

* `analizar_spam.sh`: análisis básico con conteo de mensajes por etiqueta.
* `analizar_spam_detallado.sh`: detalle por usuario, fecha y categoría.
* `analizar_spam_detallado2.sh`: versiones complementarias con métricas adicionales.

### Resultados

Los informes se generan en `tecnica_trazas/resultados/`:

* `*.txt`: reporte legible tipo log.
* `*.csv` y `*.json`: resúmenes estructurados para visualización o carga en otras herramientas.

### Ejecución

```bash
cd tecnica_trazas/scripts_bash/
./analizar_spam_detallado.sh \
    ../../tecnica_ia/datos_raw/SMSSpamCollection.csv \
    ../resultados/
```

---

## 📊 Visualización y Monitorización (ELK Stack)

Elasticsearch: ingestión de NDJSON en índices diarios.

Logstash (tecnica_adt/logstash/kevin.conf): pipeline JSON → campos, timestamps.

Kibana: dashboards con conteo ham/​spam, series temporales, top emisores y heatmaps.

Alertas: Watcher para umbrales de spam (>20%).

## 🎨 Reporting con Power BI

Dashboards interactivos de métricas de IA (AUC, recall), análisis temporal y geográfico de spam.

KPI cards, series temporales, mapas y heatmaps.

Conexión directa a CSV generados por generar_reportes.py y refresco automático.

## 📓 Exploración y Análisis Visual

Jupyter Notebooks: notebooks para exploración, preprocesamiento, modelado y evaluación.

Orange Data Mining: flujo analisis_data_cruda.ows para clustering y visualización sin código.

## 🔧 Orquestación y CI/CD

Makefile: unifica conversión, análisis, entrenamiento y despliegue de dashboards.

GitHub Actions: lint, tests, entrenamiento de modelos y despliegue de configuraciones ELK.

---

## 🤝 Contribuciones

¡Se aceptan pull requests! Por favor, siga las siguientes pautas:

1. Haga un fork del repositorio.
2. Cree una rama (`git checkout -b feature/nueva-funcionalidad`).
3. Realice sus cambios y commitee.
4. Envíe un pull request describiendo el cambio.

---
