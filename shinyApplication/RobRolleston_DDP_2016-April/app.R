# Rob Rolleston
# Load required libraries
library(ggplot2)
library(dplyr)
library(gcookbook)
library(shiny)

# Get original data, and create a 'grade' value
data <- gcookbook::heightweight
data$grade <- as.factor(round(data$ageYear) - 6)

ui <- shinyUI(fluidPage( 
  
  #Header
  h1("Comparing Height/Weight of Grade School Children"), 
  h3("Rob Rolleston, Developing Data Products, 2016-April"),
  br(),

  # Main Panel
  fluidRow(
    # side panel
    column(4,
      wellPanel(
           numericInput("grade", "Select a Grade (6-10):", 6, min=6, max=10),
           
           radioButtons("meas", "Select Height or Weight", 
                        choices = list("Weight" = "weightLb","Height" = "heightIn"),
                        selected = "weightLb"),
           
           helpText("The chart at the right showes the distibution and means of Height or Weight",
                    "for 'M' and 'F' for the selected grade"),
           helpText("The p-value for the t.test comparing the means is also shown")#,
      ),
      wellPanel(
           HTML("<span class='help-block'; style='font-style:italic'>Dataset from  gcookbook::heightweight</span>")
      )),
    #Chart & Text Panel
    column(8, 
           plotOutput('densPlot'),
           htmlOutput('textSummary')
           )
  )
))



server<- shinyServer(function(input, output) { 

    # Select the grade,and copy the measure to 'Value' column  
    dataGrade <- reactive({
      dataGrade <- data %>% filter(grade == input$grade)
      dataGrade$Value <- dataGrade[,input$meas]
      dataGrade
      })
    
    # Plot
    output$densPlot <- renderPlot({ 
      dataMeans <- dataGrade() %>% group_by(sex) %>% summarise(avg = mean(Value))
      g<- ggplot(data=dataGrade(), aes(x=Value, fill=sex)) +
        geom_density(alpha=0.3) +
        geom_vline(data=dataMeans, aes(xintercept=avg, color=sex), linetype="dashed", size=1) +
        xlab(input$meas)
      print(g)
    })
   

    # Text summary
    output$textSummary <- renderUI ({
      meanF <- mean(filter(dataGrade(), sex=="f")$Value)
      meanM <- mean(filter(dataGrade(), sex=="m")$Value)
      tTestResults <- t.test(filter(dataGrade(), sex=="f")$Value, filter(dataGrade(), sex=="m")$Value)
      str1 <- paste("mean Female ", input$meas, " is ", round(meanF, 1))
      str2 <- paste("mean Male   ", input$meas, " is ", round(meanM, 1))
      str3 <- paste("P-value for difference of means is: ", round(tTestResults$p.value, 3))
      HTML(paste(str1, str2, str3, sep='<br/>'))
    })
      
})

shinyApp(ui=ui, server=server)

