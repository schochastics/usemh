#' @export
use_mh <- function(open = rlang::is_interactive()) {
    usethis:::check_is_package("use_mh()")
    ## Generate cff
    cffr::cff_write(cffr::cff_create()) ## auto add to .Rbuildignore
    ## install.R
    desc <- usethis:::proj_desc()
    Package <- desc$get("Package")
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
    bug_reports <- desc$get("BugReports")
    if (is.na(bug_reports)) {
        bug_reports <- ""
    } else {
        bug_reports <- paste0("Issue Tracker: [", bug_reports, "](", bug_reports, ")")
    }
    usethis::use_template("methodshub.qmd",
                          data = list("Package" = Package,
                                      "Title" = desc$get("Title"),
                                      "Description" = .fix_dois(desc$get("Description")),
                                      "Maintainer" = desc$get_maintainer(),
                                      "BugReports" = bug_reports),
                          ignore = FALSE, package = "usemh",
                          open = open)
}

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

.convert_doi_md <- function(doi) {
    doi <- stringr::str_replace(doi, "^\\<doi:", "")
    doi <- stringr::str_replace(doi, "\\>$", "")
    paste0("[<doi:", doi, ">](https://doi.org/", doi, ")")
}

.fix_dois <- function(description) {
    dois <- as.character(stringr::str_extract_all(description, "\\<doi:[0-9a-zA-Z\\./]+\\>", simplify = TRUE))

    for (doi in dois) {
        description <- stringr::str_replace(description, stringr::fixed(doi), .convert_doi_md(doi))
    }
    return(description)
}

