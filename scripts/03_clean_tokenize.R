# ============================================================
# 03_clean_tokenize.R — Limpieza, detección idioma, tokenización
# ============================================================
library(tidyverse)
library(tidytext)
library(cld3)
library(here)
library(glue)

corpus_raw <- readRDS(here("data", "processed", "corpus_raw.rds"))

# --- 1. Limpieza básica ---
corpus_clean <- corpus_raw |>
  mutate(
    texto_cadena = texto_cadena |>
      str_remove_all("\\[.*?\\]") |>
      str_remove_all("(?i)project gutenberg.*") |>
      str_replace_all("[\\r\\n]+", " ") |>
      str_squish()
  ) |>
  filter(nchar(texto_cadena) > 100)

# --- 2. Detección de idioma ---
corpus_clean <- corpus_clean |>
  mutate(
    idioma_detectado = cld3::detect_language(texto_cadena)
  )

# --- 3. Tokenización ---
tokens <- corpus_clean |>
  unnest_tokens(
    output   = word,
    input    = texto_cadena,
    token    = "words",
    to_lower = TRUE
  ) |>
  anti_join(stop_words, by = "word") |>
  filter(str_detect(word, "^[a-záéíóúàèìòùäöüñ]{3,}$"))

# --- 4. Top palabras por pensador ---
tokens |>
  count(pensador_id, word, sort = TRUE) |>
  group_by(pensador_id) |>
  slice_max(n, n = 10) |>
  print(n = 50)

# Guardar
saveRDS(corpus_clean, here("data", "processed", "corpus_clean.rds"))
saveRDS(tokens,       here("data", "processed", "tokens.rds"))

message(glue("✅ Limpieza completa. Segmentos: {nrow(corpus_clean)} | Tokens: {nrow(tokens)}"))

