# ============================================================
# 05_lda_topics.R — Topic modeling LDA por pensador
# ============================================================
library(tidyverse)
library(tidytext)
library(topicmodels)
library(here)
library(glue)

tokens <- readRDS(here("data", "processed", "tokens.rds"))

dtm <- tokens |>
  count(pensador_id, word) |>
  filter(n > 2) |>
  cast_dtm(document = pensador_id, term = word, value = n)

message(glue("DTM: {nrow(dtm)} documentos x {ncol(dtm)} terminos"))

set.seed(42)
lda_model <- LDA(
  dtm,
  k      = 6,
  method = "Gibbs",
  control = list(seed = 42, burnin = 500, thin = 100, iter = 2000)
)

temas_palabras <- tidy(lda_model, matrix = "beta") |>
  group_by(topic) |>
  slice_max(beta, n = 15) |>
  ungroup() |>
  arrange(topic, -beta)

temas_documentos <- tidy(lda_model, matrix = "gamma") |>
  rename(pensador_id = document, topico = topic)

etiquetas_topicos <- tibble(
  topico   = 1:6,
  etiqueta = c(
    "Estado y poder soberano",
    "Economia y trabajo",
    "Libertad individual y derechos",
    "Revolucion y cambio social",
    "Nacion e identidad",
    "Moral y filosofia politica"
  )
)

resultados_lda <- temas_documentos |>
  left_join(etiquetas_topicos, by = "topico") |>
  arrange(pensador_id, -gamma)

plot_lda <- temas_palabras |>
  left_join(etiquetas_topicos, by = c("topic" = "topico")) |>
  group_by(etiqueta) |>
  slice_max(beta, n = 8) |>
  ungroup() |>
  mutate(term = reorder_within(term, beta, etiqueta)) |>
  ggplot(aes(beta, term, fill = etiqueta)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~etiqueta, scales = "free_y") +
  scale_y_reordered() +
  labs(title = "Top palabras por topico (LDA)", x = "Beta", y = NULL) +
  theme_minimal()

ggsave(here("docs", "lda_topics_plot.png"), plot_lda, width = 12, height = 8, dpi = 150)

saveRDS(lda_model,      here("data", "processed", "lda_model.rds"))
saveRDS(resultados_lda, here("data", "processed", "resultados_lda.rds"))
write_csv(resultados_lda, here("data", "processed", "resultados_lda.csv"))

message(glue("✅ LDA completo. Topicos: 6 | Pensadores: {n_distinct(resultados_lda$pensador_id)}"))
