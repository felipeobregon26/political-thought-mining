# ============================================================
# 01_ingest_gutenberg.R — Ingestión desde Project Gutenberg
# Primeros 5 pensadores: Marx, Mill, Rousseau, Smith, Nietzsche
# ============================================================
library(tidyverse)
library(gutenbergr)
library(tidytext)
library(here)
library(glue)

# Mapa de obras
obras_gutenberg <- tribble(
  ~pensador_id, ~nombre,           ~obra,                           ~gutenberg_id, ~idioma_original,
  "PT001",      "Karl Marx",       "The Communist Manifesto",       61,            "de",
  "PT001",      "Karl Marx",       "Das Kapital Vol. I",            35447,         "de",
  "PT002",      "John S. Mill",    "On Liberty",                    34901,         "en",
  "PT002",      "John S. Mill",    "Utilitarianism",                11224,         "en",
  "PT003",      "Rousseau",        "The Social Contract",           46333,         "fr",
  "PT003",      "Rousseau",        "Emile or Education",            5427,          "fr",
  "PT004",      "Adam Smith",      "Wealth of Nations",             3300,          "en",
  "PT005",      "Nietzsche",       "Thus Spoke Zarathustra",        1998,          "de",
  "PT005",      "Nietzsche",       "Beyond Good and Evil",          4363,          "de"
)

# Función de descarga
descargar_obra <- function(pensador_id, nombre, obra, gutenberg_id, idioma_original) {
  message(glue("Descargando: {obra} ({gutenberg_id})..."))

  tryCatch({
    texto_raw <- gutenberg_download(
      gutenberg_id,
      mirror = "http://mirrors.xmission.com/gutenberg/"
    )

    texto_cadena <- texto_raw |>
      pull(text) |>
      paste(collapse = " ") |>
      str_squish()

    palabras    <- str_split(texto_cadena, "\s+")[[1]]
    n_palabras  <- length(palabras)
    bloque_size <- 500
    n_bloques   <- ceiling(n_palabras / bloque_size)

    tibble(
      pensador_id     = pensador_id,
      obra            = obra,
      gutenberg_id    = gutenberg_id,
      segmento_id     = seq_len(n_bloques),
      texto_cadena    = map_chr(seq_len(n_bloques), ~{
        inicio <- (.x - 1) * bloque_size + 1
        fin    <- min(.x * bloque_size, n_palabras)
        paste(palabras[inicio:fin], collapse = " ")
      }),
      idioma_original = idioma_original,
      fecha_descarga  = Sys.Date(),
      fuente_url      = glue("https://www.gutenberg.org/ebooks/{gutenberg_id}")
    )

  }, error = function(e) {
    warning(glue("Error descargando {gutenberg_id}: {e$message}"))
    NULL
  })
}

# Ejecutar pipeline
corpus_raw <- obras_gutenberg |>
  pmap(descargar_obra) |>
  compact() |>
  bind_rows()

# Guardar
saveRDS(corpus_raw, here("data", "processed", "corpus_raw.rds"))
write_csv(
  corpus_raw |> select(-texto_cadena),
  here("data", "processed", "corpus_index.csv")
)

message(glue("✅ Corpus: {nrow(corpus_raw)} segmentos de {n_distinct(corpus_raw$pensador_id)} pensadores"))

