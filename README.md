# World3-03 Shiny App

This folder is the publishable Shiny application root.

## Structure

- `app.R`: Shiny UI/server entry point.
- `R/world3_03.R`: native R World3-03 model code.
- `data/functions_table_world3.json`: World3 table functions copied from the
  local PyWorld3-03 source.
- `data/python_standard_reference.csv`: Python reference run for parity checks.
- `www/app.css`: app styling.
- `www/logo.svg`: app icon.
- `docs/World3-03_Shiny_App_User_Manual.docx`: user-facing manual.
- `tools/write_manifest.R`: helper for generating `manifest.json`.

## Presentation Mode

The app includes a presentation timeline in the left control panel. Click
`Run simulation`, then use `Play`, `Pause`, `Reset`, `Current year`, and
`Animation speed` to reveal the simulation one year at a time.

## Run Locally

Open this folder or the parent RStudio project, then run:

```r
install.packages(c("shiny", "jsonlite"))
shiny::runApp("app")
```

If your working directory is already this folder, use:

```r
shiny::runApp()
```

## Generate Posit Manifest

From this folder in RStudio:

```r
source("tools/write_manifest.R")
```

That writes `manifest.json` using `rsconnect::writeManifest()`.
