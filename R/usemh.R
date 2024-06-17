#' @export
use_mh <- function(open = rlang::is_interactive()) {
    usethis:::check_is_package("use_mh()")
    ## Generate cff
    cffr::cff_write(cffr::cff_create()) ## auto add to .Rbuildignore
    ## install.R
    desc <- read.dcf("DESCRIPTION")
    Package <- .get_field(desc, "Package")
    usethis::use_template("install.R", data = list("Package" = Package), ignore = TRUE, package = "usemh")
    ## Capture the current postBuild in a temp. directory
    ## Not until this is fixed: quarto-dev/quarto-cli#9313
    ## <Hacky
    tempd <- tempdir()
    x <- quarto::quarto_create_project(name = Package, dir = tempd, quiet = TRUE, no_prompt = TRUE)
    quarto_proj_basepath <- file.path(tempd, Package)
    system(paste0("cd ", quarto_proj_basepath, "; quarto use binder --no-prompt"))
    ## needed files    
    x <- file.copy(file.path(tempd, Package, "postBuild"), ".")
    x <- file.copy(file.path(tempd, Package, "_quarto.yml"), ".")
    x <- file.copy(file.path(tempd, Package, "apt.txt"), ".")
    x <- file.copy(file.path(tempd, Package, ".jupyter"), ".", recursive = TRUE)
    usethis::use_build_ignore(c("postBuild", "_quarto.yml", "apt.txt", ".jupyter"))
    ## Hacky>
    
}

.get_field <- function(x, field) {
    x[which(colnames(x) == field)]
}
