context("use_rstudio")

test_that("use_rstudio() creates .Rproj file, named after directory", {
  dir <- scoped_temporary_package(rstudio = FALSE)
  capture_output(use_rstudio())
  rproj <- list.files(proj_get(), pattern = "\\.Rproj$")
  expect_identical(rproj, paste0(basename(dir), ".Rproj"))
})

test_that("a non-RStudio project is not recognized", {
  scoped_temporary_package(rstudio = FALSE)
  expect_false(is_rstudio_project())
  expect_identical(rproj_path(), NA_character_)
})

test_that("an RStudio project is recognized", {
  scoped_temporary_package(rstudio = TRUE)
  expect_true(is_rstudio_project())
  expect_match(rproj_path(), "\\.Rproj$")
})

test_that("we error for multiple Rproj files", {
  scoped_temporary_package(rstudio = TRUE)
  file.copy(
    proj_path(rproj_path()),
    proj_path("copy.Rproj")
  )
  expect_error(rproj_path(), "Multiple .Rproj files found", fixed = TRUE)
})

test_that("Rproj is parsed (actually, only colon-containing lines)", {
  tmp <- tempfile()
  writeLines(c("a: a", "", "b: b", "I have no colon"), tmp)
  expect_identical(
    parse_rproj(tmp),
    list(a = "a", "", b = "b", "I have no colon")
  )
})

test_that("Existing field(s) in Rproj can be modified", {
  tmp <- tempfile()
  writeLines(
    c(
      "Version: 1.0",
      "",
      "RestoreWorkspace: Default",
      "SaveWorkspace: Yes",
      "AlwaysSaveHistory: Default"
    ),
    tmp
  )
  before <- parse_rproj(tmp)
  delta <- list(RestoreWorkspace = "No", SaveWorkspace = "No")
  after <- modify_rproj(tmp, delta)
  expect_identical(before[c(1, 2, 5)], after[c(1, 2, 5)])
  expect_identical(after[3:4], delta)
})

test_that("we can roundtrip an Rproj file", {
  scoped_temporary_package(rstudio = TRUE)
  rproj_file <- proj_path(rproj_path())
  before <- readLines(rproj_file)
  rproj <- modify_rproj(rproj_file, list())
  writeLines(serialize_rproj(rproj), rproj_file)
  after <- readLines(rproj_file)
  expect_identical(before, after)
})

test_that("use_blank_state() modifies Rproj", {
  scoped_temporary_package(rstudio = TRUE)
  use_blank_slate("project")
  rproj <- parse_rproj(proj_path(rproj_path()))
  expect_equal(rproj$RestoreWorkspace, "No")
  expect_equal(rproj$SaveWorkspace, "No")
})
