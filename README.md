# Ollama en Railway — Guía de despliegue

## Modelos incluidos

| Modelo | Tag Ollama | RAM aprox. (Q4) | Ideal para |
|---|---|---|---|
| Gemma 4 27B | `gemma3:27b` | ~16 GB | Calidad máxima, razonamiento |
| Gemma 4 E4B (INT4) | `gemma3:4b-it-qat` | ~3 GB | Respuestas ultrarrápidas |
| Qwen 2.5 7B | `qwen2.5:7b` | ~5 GB | Multilingüe, código |
| Llama 4 Scout | `llama4:scout` | ~10 GB | Contexto largo (10M tokens) |
| Mistral 7B Q4 | `mistral:7b-instruct-q4_K_M` | ~4.5 GB | Instrucciones, velocidad |
| Phi-4 14B Q4 | `phi4:14b-q4_K_M` | ~9 GB | Razonamiento, matemáticas |

> Con carga bajo demanda y `OLLAMA_MAX_LOADED_MODELS=1`, solo un modelo
> ocupa RAM a la vez. Los 32 GB de Railway son suficientes para cualquiera.

---

## Despliegue en Railway

### 1. Crear el servicio
```bash
# Desde la Railway CLI
railway up
```
O conecta tu repo de GitHub desde el dashboard de Railway.

### 2. Añadir un Volume (IMPORTANTE)
Sin un Volume los modelos se re-descargan en cada deploy.

1. Dashboard → tu proyecto → **New** → **Volume**
2. Monta el volumen en el servicio Ollama con path `/models`

### 3. Variables de entorno (opcionales)
Puedes sobreescribir cualquier valor desde Railway → Variables:

| Variable | Default | Descripción |
|---|---|---|
| `OLLAMA_KEEP_ALIVE` | `5m` | Tiempo antes de descargar modelo de RAM |
| `OLLAMA_NUM_PARALLEL` | `4` | Requests paralelas por modelo |
| `OLLAMA_MAX_LOADED_MODELS` | `1` | Modelos en RAM simultáneamente |

Para descargar el modelo de RAM inmediatamente tras cada request:
```
OLLAMA_KEEP_ALIVE=0
```

### 4. Healthcheck
Railway usará `GET /api/tags` para verificar que el servicio está listo.
El timeout es de 300 s para dar tiempo al primer pull de modelos.

---

## Uso de la API

```bash
# Listar modelos disponibles
curl http://<tu-servicio>.railway.app/api/tags

# Generar texto (Gemma 4)
curl http://<tu-servicio>.railway.app/api/generate \
  -d '{
    "model": "gemma3:27b",
    "prompt": "Explícame la relatividad en 3 líneas",
    "stream": false
  }'

# Chat completion (compatible OpenAI)
curl http://<tu-servicio>.railway.app/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5:7b",
    "messages": [{"role": "user", "content": "Hola!"}]
  }'
```

---

## Desarrollo local

```bash
# Construir y arrancar
docker compose up --build

# Ver logs
docker compose logs -f ollama

# Probar la API local
curl http://localhost:11434/api/tags
```

---

## Ajuste de modelos

Para añadir o quitar modelos edita el array `MODELS` en `entrypoint.sh`:

```bash
MODELS=(
  "gemma3:27b"
  "llama4:scout"
  # añade aquí más modelos de https://ollama.com/library
)
```

Los modelos se descargan **una sola vez** y quedan en el Volume de Railway.
