library(shiny)

source(file.path("R", "world3_03.R"))
world3_tables_file <- file.path("data", "functions_table_world3.json")

scenario_presets <- list(
  "Default Python run" = list(
    description = "PyWorld3-03 defaults: policy year 1975; resource, pollution, yield, and resource tech policy years left inactive at 4000.",
    pyear = 1975, pyear_res_tech = 4000, pyear_pp_tech = 4000,
    pyear_fcaor = 4000, pyear_y_tech = 4000, nri = 1e12, dfr = 2
  ),
  "2004 reference run" = list(
    description = "Reference-style run from the included Python scenario script: broad policy switches deferred to 4000.",
    pyear = 4000, pyear_res_tech = 4000, pyear_pp_tech = 4000,
    pyear_fcaor = 4000, pyear_y_tech = 4000, nri = 1e12, dfr = 2
  ),
  "More resources" = list(
    description = "Doubles initial nonrenewable resources, matching the local Python example scenario.",
    pyear = 4000, pyear_res_tech = 4000, pyear_pp_tech = 4000,
    pyear_fcaor = 4000, pyear_y_tech = 4000, nri = 2e12, dfr = 2
  ),
  "More resources + pollution control" = list(
    description = "Doubles resources and starts pollution technology in 2002, matching the local Python example scenario.",
    pyear = 1975, pyear_res_tech = 4000, pyear_pp_tech = 2002,
    pyear_fcaor = 4000, pyear_y_tech = 4000, nri = 2e12, dfr = 2
  )
)

fmt_year <- function(x) ifelse(x >= 3000, "off", as.character(x))

scaled_headlines <- function(series) {
  data.frame(
    time = series$time,
    Population = series$pop / 1.6e10,
    Resources = series$nrfr,
    Food = series$fpc / 1000,
    Industrial_output = series$iopc / 1000,
    Pollution = series$ppolx / 40,
    Human_welfare = series$hwi
  )
}

plot_lines <- function(df, vars, title, ylab = NULL, scale = 1) {
  if (nrow(df) == 1) {
    df <- rbind(df, df)
    df$time[2] <- df$time[1] + 0.01
  }
  cols <- c("#2f6f73", "#b04a5a", "#7856a8", "#c27a2c", "#3867a6", "#5d7830")
  matplot(df$time, df[, vars, drop = FALSE] / scale, type = "o", pch = 16,
          cex = 0.35, lty = 1,
          lwd = 2.3, col = cols[seq_along(vars)], xlab = "Year",
          ylab = ylab %||% "", main = title)
  grid(col = "#dddddd")
  legend("topright", legend = vars, col = cols[seq_along(vars)], lty = 1,
         lwd = 2.3, bty = "n", cex = 0.85)
}

`%||%` <- function(x, y) if (is.null(x)) y else x

ui <- fluidPage(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "app.css"),
    tags$link(rel = "icon", type = "image/svg+xml", href = "logo.svg")
  ),
  div(
    class = "app-header",
    tags$img(src = "logo.svg", class = "app-logo", alt = ""),
    h2("World3-03 Simulation Cockpit", class = "app-title")
  ),
  fluidRow(
    column(
      width = 3,
      div(
        class = "sidebar-panel",
        selectInput("preset", "Scenario preset", names(scenario_presets)),
        helpText(textOutput("preset_description")),
        sliderInput("pyear", "General policy year", min = 1900, max = 4000,
                    value = 1975, step = 1, sep = ""),
        sliderInput("pyear_pp_tech", "Pollution technology year", min = 1900,
                    max = 4000, value = 4000, step = 1, sep = ""),
        sliderInput("pyear_res_tech", "Resource technology year", min = 1900,
                    max = 4000, value = 4000, step = 1, sep = ""),
        sliderInput("pyear_y_tech", "Agricultural yield technology year",
                    min = 1900, max = 4000, value = 4000, step = 1, sep = ""),
        sliderInput("pyear_fcaor", "Resource extraction allocation year",
                    min = 1900, max = 4000, value = 4000, step = 1, sep = ""),
        sliderInput("nri", "Initial nonrenewable resources", min = 0.5,
                    max = 3, value = 1, step = 0.1, post = "x"),
        sliderInput("dfr", "Desired food ratio", min = 1, max = 4,
                    value = 2, step = 0.1),
        actionButton("run", "Run simulation", class = "btn-primary"),
        tags$hr(),
        div(
          class = "presentation-controls",
          h4("Presentation timeline"),
          actionButton("play", "Play", class = "btn-success"),
          actionButton("pause", "Pause"),
          actionButton("reset_year", "Reset"),
          sliderInput("year", "Current year", min = 1900, max = 2100,
                      value = 1900, step = 1, sep = ""),
          sliderInput("speed", "Animation speed", min = 50, max = 1000,
                      value = 250, step = 50, post = " ms")
        )
      )
    ),
    column(
      width = 9,
      uiOutput("metrics"),
      tabsetPanel(
        tabPanel("Overview", plotOutput("overview_plot", height = 520)),
        tabPanel("Population", plotOutput("population_plot", height = 460)),
        tabPanel("Capital", plotOutput("capital_plot", height = 460)),
        tabPanel("Agriculture", plotOutput("agriculture_plot", height = 460)),
        tabPanel("Pollution", plotOutput("pollution_plot", height = 460)),
        tabPanel("Resources", plotOutput("resource_plot", height = 460)),
        tabPanel("Data", tableOutput("tail_table"))
      )
    )
  )
)

server <- function(input, output, session) {
  playing <- reactiveVal(FALSE)

  observeEvent(input$preset, {
    preset <- scenario_presets[[input$preset]]
    updateSliderInput(session, "pyear", value = preset$pyear)
    updateSliderInput(session, "pyear_pp_tech", value = preset$pyear_pp_tech)
    updateSliderInput(session, "pyear_res_tech", value = preset$pyear_res_tech)
    updateSliderInput(session, "pyear_y_tech", value = preset$pyear_y_tech)
    updateSliderInput(session, "pyear_fcaor", value = preset$pyear_fcaor)
    updateSliderInput(session, "nri", value = preset$nri / 1e12)
    updateSliderInput(session, "dfr", value = preset$dfr)
  }, ignoreInit = FALSE)

  output$preset_description <- renderText({
    scenario_presets[[input$preset]]$description
  })

  sim <- eventReactive(input$run, {
    run_world3_03(
      pyear = input$pyear,
      pyear_res_tech = input$pyear_res_tech,
      pyear_pp_tech = input$pyear_pp_tech,
      pyear_fcaor = input$pyear_fcaor,
      pyear_y_tech = input$pyear_y_tech,
      constants = list(nri = input$nri * 1e12, dfr = input$dfr),
      tables_file = world3_tables_file
    )
  }, ignoreInit = FALSE)

  observeEvent(input$run, {
    playing(FALSE)
    updateSliderInput(session, "year", value = 1900)
  })

  observeEvent(input$play, playing(TRUE))
  observeEvent(input$pause, playing(FALSE))
  observeEvent(input$reset_year, {
    playing(FALSE)
    updateSliderInput(session, "year", value = 1900)
  })

  observe({
    invalidateLater(input$speed)
    if (isTRUE(playing())) {
      next_year <- input$year + 1
      if (next_year > 2100) {
        playing(FALSE)
      } else {
        updateSliderInput(session, "year", value = next_year)
      }
    }
  })

  series <- reactive(world3_key_series(sim()))
  full <- reactive(as.data.frame(sim()))
  visible_series <- reactive(series()[series()$time <= input$year, , drop = FALSE])
  visible_full <- reactive(full()[full()$time <= input$year, , drop = FALSE])

  output$metrics <- renderUI({
    s <- visible_series()
    if (nrow(s) == 0) s <- series()[1, , drop = FALSE]
    peak_pop <- max(s$pop, na.rm = TRUE) / 1e9
    peak_pop_year <- s$time[which.max(s$pop)]
    min_resources <- tail(s$nrfr, 1)
    peak_pollution <- max(s$ppolx, na.rm = TRUE)
    final_hwi <- tail(s$hwi, 1)
    tags$div(
      class = "metric-row",
      tags$div(class = "metric", tags$div(class = "label", "Peak population"),
               tags$div(class = "value", sprintf("%.2fB", peak_pop)),
               tags$div(class = "label", paste("in", peak_pop_year))),
      tags$div(class = "metric", tags$div(class = "label", paste("Resources in", input$year)),
               tags$div(class = "value", sprintf("%.1f%%", 100 * min_resources))),
      tags$div(class = "metric", tags$div(class = "label", "Peak pollution index"),
               tags$div(class = "value", sprintf("%.2f", peak_pollution))),
      tags$div(class = "metric", tags$div(class = "label", paste("Human welfare in", input$year)),
               tags$div(class = "value", sprintf("%.2f", final_hwi)))
    )
  })

  output$overview_plot <- renderPlot({
    df <- scaled_headlines(visible_series())
    plot_lines(df, names(df)[-1], "Headline indicators, scaled to fit one chart", "Scaled index")
  })

  output$population_plot <- renderPlot({
    df <- visible_full()
    plot_lines(df, c("pop", "p1", "p2", "p3", "p4"), "Population sector", "Billion people", 1e9)
  })

  output$capital_plot <- renderPlot({
    df <- visible_full()
    plot_lines(df, c("iopc", "sopc", "ciopc"), "Capital and output per capita", "Dollars/person-year")
  })

  output$agriculture_plot <- renderPlot({
    df <- visible_full()
    plot_lines(df, c("fpc", "ly", "lfert"), "Agriculture sector", "Model units")
  })

  output$pollution_plot <- renderPlot({
    df <- visible_full()
    plot_lines(df, c("ppolx", "ppgf", "ppt", "ef"), "Pollution and footprint", "Index")
  })

  output$resource_plot <- renderPlot({
    df <- visible_full()
    plot_lines(df, c("nrfr", "fcaor", "nruf", "rt"), "Nonrenewable resources", "Fraction/index")
  })

  output$tail_table <- renderTable({
    tail(round(visible_series(), 4), 12)
  })
}

shinyApp(ui, server)
