#! /usr/bin/env Rscript

##################################################
## Project: 
## Date: 
## Author: Chao Wange [cre] and Mengda (Albert) Yu [aut cre]
## Script purpose: The scripts of Mental Health Programs Effectiveness App
##
##################################################


##################################################
## Section: libraries
##################################################
suppressPackageStartupMessages(library(shiny))
suppressPackageStartupMessages(library(shinydashboard))
suppressPackageStartupMessages(library(shinyalert))
suppressPackageStartupMessages(library(DT))
suppressPackageStartupMessages(library(plotly))
suppressPackageStartupMessages(library(shinyWidgets))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(summarytools))
suppressPackageStartupMessages(library(RColorBrewer))
# suppressPackageStartupMessages(library(shinyBS))


##################################################
## Section: Data 
##################################################
demo_info <- read_csv("./data/01_demo_info.csv")
mental_cond <- read_csv("./data/02_mh_condition.csv")
work_info <- read_csv("./data/03_workplace_info.csv")
mental_support <- read_csv("./data/04_org_support.csv")
Openness <- read_csv("./data/05_openness_about_mh.csv")
all_tidy_data <- read_csv("./data/06_data_tidy.csv")
unique_country <- sort(unique(demo_info$Country))
min_age <- min(demo_info$Age)
max_age <- max(demo_info$Age)


##################################################
## Section: UI layout
##################################################
ui <- dashboardPage( 
  
  dashboardHeader(title = "C&A Inc."
  ),
  
  # dashboardsidebar contains graph, data, and about page
  dashboardSidebar(
    tags$h3("Mental Health Programs Effectiveness in Tech Companies"),
    hr(),
    sidebarMenu(
      menuItem("Graph", tabName = "graph", icon = icon("bar-chart-o")
      ),
      menuItem("Raw data", tabName = "rawdata", icon = icon("th")
      ),
      menuItem("About", tabName = "about", icon = icon("info-circle")
      ),
      br(),
      br(),
      # Help button 
      actionLink(inputId='', 
                 label="Project Home",
                 icon = icon("github"),
                 onclick = "window.open('https://github.com/UBC-MDS/Mental-Health-Analysis_Vis-App', '_blank')"
                 )
      
    )
    
  ),
  
  
  dashboardBody(
  
    useShinyalert(),
    
    tabItems(
      # the main graph panel contains valuebox, grpah and graph filter 
      tabItem("graph",
              fluidRow(
                column(8,
                       fluidRow(
                         valueBoxOutput("observationBox", width = 6),
                         valueBoxOutput("countryBox", width = 6)
                       ),
                       box(
                         width = 13, status = "primary", solidHeader = TRUE, 
                         title = "Graphs",
                         plotlyOutput("myPlotOutput"),
                         br(),
                         br(),
                         br(),
                         br(),
                         br(),
                         br(),
                         br(),
                         br(),
                         br()
                       )
                       
                ),
                
                column(4,
                       box(
                         width = 13, 
                         status = "primary", 
                         solidHeader = TRUE, 
                         collapsible = TRUE,
                         title = "Graph Filter",
                         selectInput("selectTopic", label = "Topic", 
                                     choices = list("1. Does your employer provide mental health benefits?" = "benefits",
                                                    "2. Do you know the options for mental health care your employer provides?" = "care_options",
                                                    "3. Has your employer ever discussed mental health as part of an employee wellness program?" = "wellness_program",
                                                    "4. How easy is it for you to take medical leave for a mental health condition?" = "leave"), 
                                     selected = "benefits"),
                         hr(),
                         pickerInput('selectCountry', 'Select Country', unique_country,  
                                     selected = unique_country, multiple = TRUE,
                                     options = list("actions-box" = TRUE,
                                                    "dropdownAlignRight" = TRUE,
                                                    "liveSearch" = TRUE,
                                                    "dropupAuto" = FALSE,
                                                    "none-selected-text" = "None")),
                         sliderInput("sliderAge", label = "Age range", 
                                     min = min_age,  max = max_age, 
                                     value = c(min_age, max_age)),
                         plotOutput("histAge", height = 100),
                         hr(),
                         radioButtons("radioGraphType", 
                                      label = "Graph type",
                                      choices = list("Bar graph" = "bar", 
                                                     "Pie graph" = "pie"), 
                                      selected = "bar", inline = TRUE),
                         uiOutput("uiVariable"),
                         uiOutput("uiBarPosition")
                       )
                )
              )
      ),
      
      # The data table page that contains datatable and data filter 
      tabItem("rawdata",
              fluidRow(height = 100,
                       column(8,
                              box(width = 13, 
                                  status = "primary",
                                  title = "Raw data",
                                  solidHeader = TRUE,
                                  dataTableOutput("data_table"),
                                  wellPanel(id = "tPanel", 
                                            style = "overflow-y:scroll; max-height: 700px",
                                            uiOutput("summaryTable")
                                            )
                              )
                       ),
                       column(4, 
                              fluidRow(
                                box(
                                  width = 13, 
                                  status = "primary",
                                  title = "Data Filter",
                                  solidHeader = TRUE,
                                  collapsible = TRUE,
                                  # Select reports
                                  selectInput("selectReport", "Reports: ", 
                                              choices = c("Demographic information",
                                                          "Mental health condition",
                                                          "Workplace information",
                                                          "Organizational mental health supports",
                                                          "Openness about mental health",
                                                          "All")
                                  ),
                                  radioButtons("display_button", "Display style:",
                                               list("Datatable", "Summary"),
                                               selected = "Datatable", inline = TRUE, width='100%'),
                                  
                                  downloadButton("downloadCsv", "Download Raw Data as CSV")
                                )),
                              fluidRow(
                                  box(
                                    width = 13, 
                                    title = "Description",
                                    collapsible = TRUE,
                                    collapsed = TRUE,
                                    dataTableOutput("descriptionTable")
                                )
                              )
                       )
              )
              
      ),
      
      # The about page includes the overview of our app
      tabItem("about",
                includeMarkdown("./README.md")
      )
      
    )
  )
)


##################################################
## Section: Server layout
##################################################
server <- function(input, output) {
  
  # ==================================================
  # Graph page
  # ==================================================
  
  # filter data used in graph
  graph_filter <- reactive ({
    
    output_graph_data <- all_tidy_data %>%
      filter(Country %in% input$selectCountry) %>%
      filter(Age >= input$sliderAge[1],  Age <= input$sliderAge[2])
    
  })
  
  # plot age distribution on the filter panel
  output$histAge <- renderPlot({
    if (nrow(graph_filter()) == 0)
      return(NULL)
    
    graph_filter() %>%
      ggplot(aes(Age)) +
      geom_histogram(binwidth = 2, color="white") +
      theme_classic() +
      theme(axis.title.y = element_blank())
  })
  
  # print the count box
  output$observationBox <- renderValueBox({
    valueBox(
      value = dim(graph_filter())[1],
      subtitle = h4("Current Observations"),
      icon = icon("user-alt"),
      color = if (dim(graph_filter())[1] >= 1000) "orange" else "yellow"
    )
  })
  
  # print the the number of countries used
  output$countryBox <- renderValueBox({
    valueBox(
      value = length(unique(graph_filter()$Country)),
      subtitle = h4("Current Countries"),
      icon = icon("globe-americas"),
      color = if (length(unique(graph_filter()$Country)) >= 30) "purple" else "navy"
    )
  })
  
  # output bar position radio buttion 
  output$uiBarPosition <- renderUI({
    if (is.null(input$radioGraphType))
      return()
    
    if (input$radioGraphType == "bar" ) {
      radioButtons("radioBarPosition", label = "Bar position",
                   choices = list("Dodge" = "dodge",
                                  "Stack" = "stack"),
                   selected = "dodge", inline = TRUE) 
    }
    
  })
  
  # output variable selector 
  output$uiVariable  <- renderUI({
    if (is.null(input$radioGraphType))
      return()
    
    if (input$radioGraphType == "bar" ) {
      selectInput("selectVariable", label = "Variable (Bar Chart Only)", 
                  choices = list("Gender" = "Gender",
                                 "Remote or In-office" = "remote_work",
                                 "Self-employed or Employed" = "self_employed", 
                                 "Tech or Non-tech company" = "tech_company"), 
                  selected = "Gender")
    }
  })
  
  # build the plot 
  build_plot <- reactive({
    if (is.null(input$radioBarPosition))
      return()
    
    if (input$selectTopic == "care_options"){
      mytitle <- "Whether employees know the options\n for mental health care"
    } else if (input$selectTopic == "wellness_program") {
      mytitle <- "Whether employers discussed mental health \n as part of an employee wellness program"
    } else if (input$selectTopic == "leave") {
      mytitle <- "How easy to take medical leave \n for a mental health condition"
    } else {
      mytitle <- "Does your employer provide mental health benefits?"
    }
    
    if (input$selectVariable == "remote_work"){
      my_xtitle <- "Remote or In-office"
    } else if (input$selectVariable == "self_employed"){
      my_xtitle <- "Self-employed or Employed"
    } else if (input$selectVariable == "tech_company"){
      my_xtitle <- "Tech or Non-tech company"
    } else {
      my_xtitle <- "Gender"
    }
    
    if (input$radioGraphType == "pie"){
      
      pie_data <- graph_filter() %>%
        group_by(!!sym(input$selectTopic)) %>%
        summarise (n = n()) %>%
        mutate(new_labels = as.factor(!!sym(input$selectTopic)))
      
      my_plot <- plot_ly(pie_data,  labels = ~new_labels, values = ~n, type = 'pie') %>%
        layout(title = mytitle,
               height = 560,
               font= list(family = "Arial", 
                          size = 17, 
                          color = 'black'),
               xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
               yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
               margin = list(l = 100, r = 2, b = 2, t = 85, pad = 4)
        )
      
    } else {
      
      my_plot <- graph_filter() %>%
        ggplot(aes(x=!!sym(input$selectTopic), fill = !!sym(input$selectVariable))) +
        geom_bar(width = 0.8,  position = input$radioBarPosition, colour="black", size=.1, alpha = 0.82) +
        scale_y_continuous(expand = c(0,0)) +
        theme_classic() +
        labs(x = my_xtitle,
             y = "Count",
             title = mytitle) +
        scale_colour_brewer(palette = "Set1",aesthetics = "fill") +
        theme(panel.grid.minor = element_blank(),
              plot.title = element_text(size = 19, 
                                        hjust = 0.5,  
                                        family="Arial", 
                                        lineheight=1.2),
              plot.margin = margin(45, 0, 0, 0),
              axis.text.x = element_text(size = 8, face = "bold"),
              axis.text.y = element_text(size = 10),
              axis.ticks.x = element_blank(),
              legend.title = element_blank(),
              legend.position = "top") +
        guides(fill=guide_legend(title=input$selectVariable))
      
    }
  })
  
  # render the plot 
  output$myPlotOutput <- renderPlotly({
    if (!is.null(input$radioBarPosition)){
      
      if(input$radioGraphType == "pie"){
        my_plot <- build_plot()
      } else {
        my_plot <- build_plot()
        ggplotly(my_plot, height = 560) %>% 
          layout(
            margin =  list(l = 0,r = 0,b = 40,t = 90, pad = 4)
            )
      }
      
    }
  })
  
  # notification system 
  observeEvent(input$selectVariable, {
    if (input$selectVariable == "Gender"){
      showNotification("Gender (categorical) that contains cis_female,  cis_male, trans_female, 
                       trans_male and Genderqueer", type = "message", duration = 4)
    } else if (input$selectVariable == "remote_work") {
      showNotification("Do they work remotely (outside of an office)
                       at least 50% of the time?", type = "message", duration = 3)
    } else if (input$selectVariable == "self_employed") {
      showNotification("Are they self-employed?", type = "message", duration = 3)
    } else if (input$selectVariable == "tech_company") {
      showNotification("Is their employer primarily a 
                       tech company/organization?", type = "message", duration = 3)
    }
    })
  
  # Give a message when there is no country selected
  observeEvent(input$selectCountry, {
    if (is.null(input$selectCountry)) { 
      shinyalert("Oops", "Please select more countries.", type = "warning", timer = 1500)
    }
  }, ignoreNULL = FALSE)
  
  # Give a message when invalid age range is selected 
  observeEvent(input$sliderAge, {
    if (nrow(graph_filter()) == 0 && input$radioGraphType == "bar"){
      shinyalert("Oops", "please try different age range.", type = "error", timer = 3000)
    }
  })
  
  
  # ==================================================
  # Data page
  # ==================================================
  
  # Data category filter
  data_filter <- reactive({
    if (input$selectReport == "Mental health condition") {
      output_data <- mental_cond 
    } else if (input$selectReport == "Workplace information") {
      output_data <- work_info 
    } else if (input$selectReport == "Organizational mental health supports"){
      output_data <- mental_support 
    } else if (input$selectReport == "Openness about mental health") {
      output_data <- Openness 
    } else if (input$selectReport == "All") {
      output_data <- all_tidy_data
    } else { # default 
      output_data <- demo_info 
    }
  
    output_data <- output_data %>%
      select(-X1)
  })
  
  # Download hander 
  output$downloadCsv <- downloadHandler(
    filename = "download.csv",
    content = function(file) {
      write.csv(data_filter(), file)
    },
    contentType = "text/csv"
  )
  
  # render the table
  output$data_table <- DT:: renderDataTable({
    if (input$display_button == "Datatable") {
      data_filter()
    }
  }, 
  filter = 'top', 
  options = list(pageLength = 10,
                 dom = 'lftipr', 
                 scrollY = 570,
                 scroller = TRUE,
                 scrollX = TRUE)
  )
  
  # render the summary 
  output$summaryTable <- renderUI({
    if (input$display_button == "Summary"){
      view(dfSummary(data_filter()), 
           method = 'render',
           bootstrap.css = FALSE)
    }
  })
  
  # render description table 
  output$descriptionTable <- DT::renderDataTable({
    
    if (input$selectReport == "Mental health condition") {
      output_data <- tribble(
        ~Factor,    ~Description,
        "family_history",    "Do you have a family history of mental illness?",
        "treatment", "Have you sought treatment for a mental health condition?",
        "work_interfere",    "If you have a mental health condition, do you feel that it interferes with your work?"
      )
    } else if (input$selectReport == "Workplace information") {
      output_data <- tribble(
        ~Factor,    ~Description,
        "self_employed",    "Are you self-employed?",
        "no_employees", "How many employees does your company or organization have?",
        "remote_work",    "Do you work remotely (outside of an office) at least 50% of the time?",
        "tech_company", "Is your employer primarily a tech company/organization?"
      )
    } else if (input$selectReport == "Organizational mental health supports"){
      output_data <- tribble(
        ~Factor,    ~Description,
        "benefits",    "Does your employer provide mental health benefits?",
        "care_options", "Do you know the options for mental health care your employer provides?",
        "wellness_program",    "Does your employer provide resources to learn more about mental health issues and how to seek help?",
        "anonymity", "Is your anonymity protected if you choose to take advantage of mental health or substance abuse treatment resources?",
        "leave", "How easy is it for you to take medical leave for a mental health condition?"
      )
    } else if (input$selectReport == "Openness about mental health") {
      output_data <- tribble(
        ~Factor,    ~Description,
        "mental_health_consequence",    "Do you think that discussing a mental health issue with your employer would have negative consequences?",
        "phys_health_consequence", "Do you think that discussing a physical health issue with your employer would have negative consequences?",
        "coworkers",    "Would you be willing to discuss a mental health issue with your coworkers?",
        "supervisor",    "Would you be willing to discuss a mental health issue with your direct supervisor(s)?",
        "mental_health_interview", "Would you bring up a mental health issue with a potential employer in an interview?",
        "phys_health_interview", "Would you bring up a physical health issue with a potential employer in an interview?",
        "mental_vs_physical", "Do you feel that your employer takes mental health as seriously as physical health?",
        "obs_consequence", "Have you heard of or observed negative consequences for coworkers with mental health conditions in your workplace?"
      )
    } else if (input$selectReport == "All") {
      output_data <- tribble(
         ~Description,
         "This dataset is from a 2014 survey that measures attitudes 
         towards mental health and frequency of mental health disorders in the tech workplace."
      )
    } else { # default
      output_data <- tribble(
        ~Factor,    ~Description,
        "Age",    "Age of participants",
        "Gender", "Gender of participants",
        "Country",    "Country of participants"
      )
    }
  }, 
  rownames= FALSE,
  options = list(pageLength = 5,
                 lengthMenu = c(3),
                 dom = 'tp',
                 searching = FALSE,
                 scrollY = 330,
                 scroller = TRUE)
  )
  
}

##################################################
## Section: run app
##################################################
shinyApp(ui = ui, server = server)

