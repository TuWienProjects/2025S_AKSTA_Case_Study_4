library(shiny)
library(jsonlite)
library(dplyr)
library(DT)
library(shiny)
library(jsonlite)
library(dplyr)
library(ggplot2)
library(viridis)
library(plotly)
library(DT)
library(countrycode)
library(maps)   

ui <- fluidPage(
  
  # App title and subtitle as shown in screenshot
  titlePanel("CIA World Factbook 2020"),
  
  tags$p(
    em("Welcome to my shiny app, which allows you to visualize variables from the CIA 2020 factbook on the world map, generate descriptive statistics and statistical graphics.")
  ),
  
  # Tab structure (empty tabs for now)
  tabsetPanel(
    tabPanel("Univariate analysis",
             sidebarLayout(
               sidebarPanel(
                 selectInput("uni_var", "Select a variable:",
                             choices = c(
                               "Expenditure on education" = "expenditure",
                               "Youth unemployment rate" = "youth_unempl_rate",
                               "Net migration rate" = "net_migr_rate",
                               "Population growth rate" = "pop_growth_rate",
                               "Electricity (fossil fuel)" = "electricity_fossil_fuel",
                               "Life expectancy" = "life_expectancy"
                             )),
                 actionButton("view_data", "View raw data"),
                 br(),
                 DTOutput("raw_data_table")
                 
               ),
               mainPanel(
                 tabsetPanel(
                   tabPanel("Map", 
                            p("The map contains values of the selected variables. The countries with gray areas have a missing value for the visualized variable."),
                            plotlyOutput("map_plot")),
                   tabPanel("Global analysis",
                            h5("Boxplot"),
                            plotlyOutput("global_boxplot"),
                            br(),
                            h5("Histogram and density"),
                            plotlyOutput("global_density"))
                   ,
                   tabPanel("Analysis per continent",
                            h5("Boxplot by continent"),
                            plotlyOutput("continent_boxplot"),
                            br(),
                            h5("Density plot by continent"),
                            plotlyOutput("continent_density"))
                   
                 )
               )
               
             )
    )
    ,
    tabPanel("Multivariate analysis",
             sidebarLayout(
               sidebarPanel(
                 selectInput("var_x", "Select X variable:",
                             choices = c(
                               "Expenditure on education" = "expenditure",
                               "Youth unemployment rate" = "youth_unempl_rate",
                               "Net migration rate" = "net_migr_rate",
                               "Population growth rate" = "pop_growth_rate",
                               "Electricity (fossil fuel)" = "electricity_fossil_fuel",
                               "Life expectancy" = "life_expectancy"
                             )),
                 selectInput("var_y", "Select Y variable:",
                             choices = c(
                               "Expenditure on education" = "expenditure",
                               "Youth unemployment rate" = "youth_unempl_rate",
                               "Net migration rate" = "net_migr_rate",
                               "Population growth rate" = "pop_growth_rate",
                               "Electricity (fossil fuel)" = "electricity_fossil_fuel",
                               "Life expectancy" = "life_expectancy"
                             )),
                 selectInput("point_size", "Size points by:",
                             choices = c("Population" = "population", "Area" = "area"))
               ),
               mainPanel(
                 plotlyOutput("scatter_plot")
               )
             )
    )
    
  )
)



# Load data once when app starts
cia_data <- fromJSON("data_cia2.json")

server <- function(input, output, session) {
  
  # Reactive selection of variable
  selected_data <- reactive({
    req(input$uni_var)
    label <- switch(input$uni_var,
                    "expenditure" = "Expenditure on education",
                    "youth_unempl_rate" = "Youth unemployment rate",
                    "net_migr_rate" = "Net migration rate",
                    "pop_growth_rate" = "Population growth rate",
                    "electricity_fossil_fuel" = "Electricity (fossil fuel)",
                    "life_expectancy" = "Life expectancy")
    
    cia_data %>%
      select(country, continent, value = all_of(input$uni_var)) %>%
      rename(Country = country, Continent = continent, !!label := value)
  })
  
  
  
  # Show table when button clicked
  observeEvent(input$view_data, {
    output$raw_data_table <- renderDT({
      datatable(selected_data(), options = list(pageLength = 15))
    })
  })
  
  
  # Load world map and attach ISO3 codes
  world_map <- map_data("world")
  world_map$ISO3 <- countrycode(sourcevar = world_map$region,
                                origin = "country.name",
                                destination = "iso3c")
  
  # Join map with data
  map_data_joined <- reactive({
    req(input$uni_var)
    
    left_join(world_map, 
              cia_data %>% select(ISO3, value = all_of(input$uni_var), country),
              by = "ISO3")
  })
  
  output$map_plot <- renderPlotly({
    req(map_data_joined())
    
    gg <- ggplot(map_data_joined(), aes(x = long, y = lat, group = group)) +
      geom_polygon(aes(fill = value, text = paste("Country:", country, "<br>Value:", round(value, 2))),
                   color = "white") +
      scale_fill_viridis_c(na.value = "gray80") +
      theme_void()
    
    ggplotly(gg, tooltip = "text")
  })
  
  # Global boxplot
  output$global_boxplot <- renderPlotly({
    req(input$uni_var)
    label <- names(selected_data())[3]  # Get clean variable label
    
    gg <- ggplot(selected_data(), aes(x = "", y = .data[[label]])) +
      geom_boxplot(fill = "#2196F3") +
      labs(x = NULL, y = label) +
      theme_minimal()
    
    ggplotly(gg)
  })
  
  # Global histogram + density
  output$global_density <- renderPlotly({
    req(input$uni_var)
    label <- names(selected_data())[3]
    
    gg <- ggplot(selected_data(), aes(x = .data[[label]])) +
      geom_histogram(aes(y = ..density..), fill = "#90CAF9", bins = 30, color = "white") +
      geom_density(color = "#0D47A1", linewidth = 1) +
      labs(x = label, y = "Density") +
      theme_minimal()
    
    ggplotly(gg)
  })
  
  # Continent-wise boxplot
  output$continent_boxplot <- renderPlotly({
    req(input$uni_var)
    label <- names(selected_data())[3]
    
    gg <- ggplot(selected_data(), aes(x = Continent, y = .data[[label]], fill = Continent)) +
      geom_boxplot() +
      labs(x = "Continent", y = label) +
      theme_minimal()
    
    ggplotly(gg)
  })
  
  # Continent-wise density plot
  output$continent_density <- renderPlotly({
    req(input$uni_var)
    label <- names(selected_data())[3]
    
    gg <- ggplot(selected_data(), aes(x = .data[[label]], fill = Continent, color = Continent)) +
      geom_density(alpha = 0.4) +
      labs(x = label, y = "Density") +
      theme_minimal()
    
    ggplotly(gg)
  })
  
  output$scatter_plot <- renderPlotly({
    req(input$var_x, input$var_y, input$point_size)
    
    # Clean axis labels
    label_x <- switch(input$var_x,
                      "expenditure" = "Expenditure on education",
                      "youth_unempl_rate" = "Youth unemployment rate",
                      "net_migr_rate" = "Net migration rate",
                      "pop_growth_rate" = "Population growth rate",
                      "electricity_fossil_fuel" = "Electricity (fossil fuel)",
                      "life_expectancy" = "Life expectancy")
    
    label_y <- switch(input$var_y,
                      "expenditure" = "Expenditure on education",
                      "youth_unempl_rate" = "Youth unemployment rate",
                      "net_migr_rate" = "Net migration rate",
                      "pop_growth_rate" = "Population growth rate",
                      "electricity_fossil_fuel" = "Electricity (fossil fuel)",
                      "life_expectancy" = "Life expectancy")
    
    gg <- ggplot(cia_data, aes_string(
      x = input$var_x,
      y = input$var_y,
      color = "continent",
      size = input$point_size)) +
      geom_point(alpha = 0.7) +
      geom_smooth(method = "loess", aes(group = continent), se = FALSE, color = "black", linewidth = 0.5, inherit.aes = FALSE) +
      labs(x = label_x, y = label_y) +
      theme_minimal()
    
    ggplotly(gg)
  })
  
  
  
}

shinyApp(ui, server)
