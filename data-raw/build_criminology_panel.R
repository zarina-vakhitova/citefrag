# =============================================================================
# data-raw/build_criminology_panel.R
# =============================================================================
# Rebuilds the `criminology_panel` and `criminology_alternatives` datasets
# shipped with the package, by calling the replication pipeline's building
# blocks directly (rather than running its full main() function).
# =============================================================================

replication_script <- "/Users/zvak0001/Documents/RESEARCH/20_problems/Fragmentation_Criminology/replication_23_output_R/replication_23.R"

if (!file.exists(replication_script))
  stop("Replication script not found at ", replication_script, call. = FALSE)

# Override path variables so the replication script finds its data regardless
# of the current working directory.
BASE_DIR <- "/Users/zvak0001/Documents/RESEARCH/20_problems/Fragmentation_Criminology"
WOS_DIR  <- file.path(BASE_DIR, "NEW_DATA_WOS")
OUT      <- tempfile("replication_out_")  # throwaway output directory
dir.create(file.path(OUT, "tables"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(OUT, "data"),   recursive = TRUE, showWarnings = FALSE)
tbl_dir  <- file.path(OUT, "tables")
dat_dir  <- file.path(OUT, "data")
YEAR_END <- 2025L

# Null-coalescing operator
`%||%` <- function(a, b) if (!is.null(a)) a else b

# Source the replication script WITHOUT running main().
# We do this by temporarily redefining main() to a no-op before sourcing,
# so all the function definitions load but main() does not execute.
source(replication_script, local = FALSE)

message("\nBuilding matrices from scratch...")
records <- load_data()
mats    <- build_matrices(records)
art_counts <- count_articles(records)

message("\nWrapping into citefrag format...")

# ---- Build matrices keyed by year, restricted to active journals ----------
matrices <- lapply(names(mats), function(yr_str) {
  yr <- as.integer(yr_str)
  active <- KEYS[AVAIL[KEYS] <= yr]
  if (length(active) < 2L) return(NULL)
  M <- mats[[yr_str]][KEY2IDX[active], KEY2IDX[active], drop = FALSE]
  rownames(M) <- SHORT[active]
  colnames(M) <- SHORT[active]
  M
})
names(matrices) <- names(mats)
matrices <- matrices[!vapply(matrices, is.null, logical(1L))]

# ---- Build groups vector --------------------------------------------------
groups <- setNames(JOURNALS$cluster, JOURNALS$short)

# ---- Build sizes list (time-varying, keyed by year) -----------------------
sizes <- lapply(names(matrices), function(yr_str) {
  yr <- as.integer(yr_str)
  active_short <- rownames(matrices[[yr_str]])
  active_key <- JOURNALS$key[match(active_short, JOURNALS$short)]
  s <- vapply(active_key,
              function(k) as.numeric(art_counts[[paste(k, yr, sep = "_")]] %||% 0),
              numeric(1L))
  setNames(s, active_short)
})
names(sizes) <- names(matrices)

# ---- Construct the citation_panel object ----------------------------------
library(citefrag)
criminology_panel <- citation_panel(matrices, groups, sizes)

# ---- Build the alternative-specification list -----------------------------
criminology_alternatives <- list(
  merge_cd_to_quant = local({
    g <- groups
    g["Crime & Delinq"] <- "Quant/Empirical"
    g
  }),
  merge_ps_to_applied = local({
    g <- groups
    g["Punish & Soc"] <- "Applied/Practice"
    g
  }),
  merge_cjc_to_applied = local({
    g <- groups
    g["Criminol Crim Justice"] <- "Applied/Practice"
    g
  })
)

# ---- Save -----------------------------------------------------------------
usethis::use_data(criminology_panel, overwrite = TRUE)
usethis::use_data(criminology_alternatives, overwrite = TRUE)

message("\nDatasets rebuilt. Run devtools::document() and devtools::install().")
