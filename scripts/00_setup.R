# ============================================================
# 00_setup.R — Instalación y configuración del entorno
# political-thought-mining | Supervisado por Claude (Anthropic)
# ============================================================

required_packages <- c(
  # Core tidyverse
  "tidyverse", "tibble", "dplyr", "stringr", "purrr", "readr",
  # Texto y NLP
  "tidytext", "quanteda", "quanteda.textstats", "quanteda.textmodels",
  "udpipe", "cld3",
  # Ingestión
  "gutenbergr", "readtext", "pdftools", "rvest", "httr2",
  # Topic modeling
  "topicmodels", "ldatuning",
  # Embeddings
  "reticulate",
  # Visualización
  "ggplot2", "plotly", "ggraph", "igraph", "DT",
  # Shiny
  "shiny", "bslib", "shinyWidgets",
  # Utils
  "here", "glue", "furrr", "logger"
)

new_packages <- required_packages[
  !(required_packages %in% installed.packages()[, "Package"])
]

if (length(new_packages) > 0) {
  message("Instalando: ", paste(new_packages, collapse = ", "))
  install.packages(new_packages, dependencies = TRUE)
}

stopifnot("R >= 4.3 requerido" = getRversion() >= "4.3.0")

dirs <- c(
  here::here("data", "raw", "gutenberg"),
  here::here("data", "raw", "pdfs"),
  here::here("data", "processed"),
  here::here("data", "translations")
)
purrr::walk(dirs, dir.create, recursive = TRUE, showWarnings = FALSE)

message("✅ Entorno configurado correctamente.")

