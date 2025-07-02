library(dplyr)
library(ggplot2)


getSummaryStats <- function(dataset, colName){
  col <- sym(colName)
  summary_stats <- dataset %>% summarise(
    variable = colName,
    mean = mean(!!col, na.rm = TRUE),
    sd = sd(!!col, na.rm = TRUE),
    min = min(!!col, na.rm = TRUE),
    max = max(!!col, na.rm = TRUE),
    q10 = quantile(!!col, 0.10, na.rm = TRUE),
    q25 = quantile(!!col, 0.25, na.rm = TRUE),
    median = median(!!col, na.rm = TRUE),
    q75 = quantile(!!col, 0.75, na.rm = TRUE),
    q90 = quantile(!!col, 0.90, na.rm = TRUE)
  )
  return (summary_stats)
}


plotDensity <- function(df, covariate='A1C', outcome='POU', bins = 30, output='./results'){
  #df <- df[df[covariate] >= 3.5 & df[covariate] <= 13.5,]
  df <- df[df[covariate] <= 3,]
  p <- ggplot(df, aes(x=eval(parse(text = covariate)), fill = factor(eval(parse(text = outcome))))) +
       geom_histogram(aes(y=..density..), position = "dodge", bins= bins) + 
       geom_density(alpha = 0.1) + 
       labs(x= covariate, y="Density", fill=outcome) + 
       theme_classic() + 
       #ggtitle(paste("POU distribution over ", covariate , " values")) +
       scale_x_continuous(breaks = seq(floor(min(df[covariate])), ceiling(max(df[covariate])), by = 0.5))
  
  plot(p)
  ggsave(output, dpi=300)
  dev.off()
  
  return(p)
}


plotHistogram <- function(df, covariate='A1C', outcome='POU', bins = 30, output='./results'){
  #df <- df[df[covariate] >= 3.5 & df[covariate] <= 13.5,]
  df <- df[df[covariate] <= 3,]
  p <- ggplot(df, aes(x=eval(parse(text = covariate)), fill = factor(eval(parse(text = outcome))))) +
    geom_histogram(position = "dodge", bins= bins) + 
    labs(x= covariate, fill=outcome) + 
    theme_classic() + 
    #ggtitle(paste("POU distribution over ", covariate , " values")) +
    scale_x_continuous(breaks = seq(floor(min(df[covariate])), ceiling(max(df[covariate])), by = 0.5))
  
  plot(p)
  ggsave(output, dpi=300)
  dev.off()
    
  return(p)
}




plotCovariateSetDensity <- function(df, outcome='POU', model='RF'){
  df_melt <- data.frame(
    outcome = rep(df[,outcome], times=ncol(df)-1),
    variable = rep(names(df)[-which(names(df)==outcome)], each=nrow(df)),
    value = unlist(df[,-which(names(df)==outcome)])
  )
  
  ratio <- df_melt %>%
    group_by(variable) %>%
    summarise(count = n(), 
              occurrence = sum(value)) %>%
    arrange(occurrence) %>%
    mutate(variable_perc = paste0(variable, " (", round(occurrence / count * 100, 2), "%)"))
  
  df_melt <- df_melt %>%
    left_join(ratio, by="variable")
  
  df_melt <- df_melt[df_melt$value == 1,]
  
  df_melt$variable_perc <- factor(df_melt$variable_perc, levels = ratio$variable_perc)
  
  p <- ggplot(df_melt, aes(x=outcome, fill = factor(variable_perc))) +
    geom_histogram(aes(y=after_stat(density)), bins= 30, color = 'black') +
    geom_density(alpha = 0.3) + # (alpha = 0.9, position = "dodge")
    facet_wrap(~ variable_perc) + #, scales = "free_y"
    labs(x= paste(outcome, "Estimated Probability"), y="Density", fill=outcome) + 
    theme_classic() +
    theme(legend.position = "none")
  
  plot(p)
  ggsave(paste0('./results/plots/opioidDensityFacet_', outcome, "_", model, '.pdf'), dpi=300)
  dev.off()
  
  return(p)
}








sqlQuery <- SqlRender::readSql("./src/covariateSql/firstPriorA1C.sql")

renderedSql <- SqlRender::render(
  sql = sqlQuery,
  cdm_database_schema = cdmDatabaseSchema,
  target_database_schema = targetDatabaseSchema,
  cohort_table = cohortTable,
  cohort_id = cohortId
)



anaylyzeA1c <- function(){
  sql <- SqlRender::translate(renderedSql, targetDialect = dbms)
  connection <- DatabaseConnector::connect(connectionDetails)
  a1cData <- DatabaseConnector::querySql(connection, sql)
  DatabaseConnector::disconnect(connection = connection)
  
  # a1cData <- data.frame(
  #   day_from_cohort = rnorm(100),
  #   a1c_dcct_percent = rnorm(100)
  # )
  
  summartStats <-  rbind(getSummaryStats(a1cData, toupper('day_from_cohort')), 
                         getSummaryStats(a1cData, toupper('a1c_dcct_percent')))
  
  
  write.csv(summartStats, file = "./a1c-summary-stats.csv", row.names = F)
}











