if (!requireNamespace("rsconnect", quietly = TRUE)) {
  install.packages("rsconnect")
}

app_dir <- if (file.exists("app.R")) {
  normalizePath(".", mustWork = TRUE)
} else if (file.exists(file.path("app", "app.R"))) {
  normalizePath("app", mustWork = TRUE)
} else {
  stop("Run this from the app folder or the RWorld3-03 project root.", call. = FALSE)
}
old_wd <- setwd(app_dir)
on.exit(setwd(old_wd), add = TRUE)

rsconnect::writeManifest(appDir = app_dir)
message("Wrote manifest.json in ", app_dir)
