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
    quarto_there <- file.exists("_quarto.yml")
    ## <Hacky
    if (!quarto_there) {
        tempd <- .gen_empty_dir()
        x <- quarto::quarto_create_project(name = Package, dir = tempd, quiet = TRUE, no_prompt = TRUE)
        quarto_proj_basepath <- file.path(tempd, Package)
        system(paste0("cd ", quarto_proj_basepath, "; quarto use binder --no-prompt"))
        ## needed files
        usethis::use_template("quarto.yaml", "_quarto.yml", data = list("Package" = Package), package = "usemh")        
        x <- file.copy(file.path(tempd, Package, "postBuild"), ".")
        x <- file.copy(file.path(tempd, Package, "apt.txt"), ".")
        x <- file.copy(file.path(tempd, Package, ".jupyter"), ".", recursive = TRUE)
        usethis::use_build_ignore(c("postBuild", "_quarto.yml", "apt.txt", ".jupyter"))
    }
    ## Hacky>
    usethis::use_build_ignore("^methodshub", escape = FALSE)
    usethis::use_template("methodshub.qmd",
                          data = list("Package" = Package,
                                      "Title" = .get_field(desc, "Title"),
                                      "Description" = .get_field(desc, "Description")),
                          ignore = FALSE, package = "usemh",
                          open = open)
}

#' @export
zap_mh <- function() {
    ## TODO: Clean .Rbuildignore
    usethis:::check_is_package("zap_mh()")
    .zap("CITATION.cff")
    .zap("_quarto.yml")
    .zap("apt.txt")
    .zap("install.R")
    .zap("postBuild")
    .zap("methodshub.qmd")
    .zap(".jupyter")    
}

.get_field <- function(x, field) {
    x[which(colnames(x) == field)]
}

.zap <- function(file) {
    if (file.exists(file)) {
        unlink(file, recursive = TRUE, force = TRUE)
    }
}

.gen_empty_dir <- function() {
    continue <- TRUE
    while (continue) {
        tempd <- file.path(tempdir(), sample(100000,1))
        if (!dir.exists(tempd)) {
            dir.create(tempd)
            continue <- FALSE
        }
    }
    return(tempd)   
}
