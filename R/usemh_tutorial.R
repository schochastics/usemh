#' @export
use_mh_tutorial_template <- function(title = "tutorial", dir = NULL, file = "index.qmd") {
    active_dir <- getwd()
    if (is.null(dir)) {
        dir <- gsub(" ", "_", title)
    }
    if (dir.exists(dir)) {
        stop("a directory with the same name already exists.")
    }
    dir.create(dir)
    setwd(dir)
    yaml_proj <- readLines(system.file("templates", "quarto.yaml", package = "usemh"))
    writeLines(
        whisker::whisker.render(
            yaml_proj,
            data = list("Package" = title, "file" = file)
        ), "_quarto.yml"
    )
    file.copy(system.file("templates", "tutorial.qmd", package = "usemh"), file)
    write("/.quarto/", ".gitignore", append = TRUE)
    cli::cli_alert_info("basic tutorial files created in {dir}. After finishing writing the tutorial run use_mh_tutorial_utils()")
    on.exit(setwd(active_dir))
}

#' @export
use_mh_tutorial_utils <- function(title = "tutorial", file = "index.qmd", overwrite = TRUE) {
    if (!file.exists("_quarto.yml") || isTRUE(overwrite)) {
        usethis::use_template(
            "quarto.yaml", "_quarto.yml",
            data = list("Package" = title, "file" = file), package = "usemh"
        )
        usethis::use_git_ignore("/.quarto/")
    }
    notebook <- paste0(tools::file_path_sans_ext(file), ".ipynb")
    if (!file.exists(notebook) || isTRUE(overwrite)) {
        system(paste0("quarto convert ", file, " --output ", notebook)) # TODO: Error handling
    }
    quarto:::quarto_use(args = c("binder", "--no-prompt"))
    if (!file.exists("install.R") || isTRUE(overwrite)) {
        .create_install_R()
    }
}

.create_install_R <- function(path = ".") {
    deps <- unique(renv::dependencies(path)$Package)
    reqs <- remotes::system_requirements("ubuntu", "22.04", package = deps)
    writeLines(reqs, "apt.txt")
    writeLines(paste0('install.packages("', deps, '")'), "install.R")
}
