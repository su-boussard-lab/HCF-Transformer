calculate_log_anova <- function(group_data, cov_name){
  
  group_data$value <- log(group_data$value)
  # group_data <- group_data[group_data$value != 0,]
  
  stats <- group_data %>% 
    group_by(group) %>% 
    summarize (
      mean_log = mean(value),
      ci_log = sd(value) / sqrt(n()) * 1.96,
      N = n()
    ) %>%
    mutate(
      mean_ci = paste0(round(exp(mean_log), digits = 2), '(+/- ', round(exp(ci_log), digits = 2), ')'),
      N = n()
    )
  
  model <- aov(value ~ group, data = group_data)
  anova <- summary(model)
  p_value <- anova[[1]][["Pr(>F)"]][1]
  
  # calculate the effect size (eta squared)
  eta_sq <- rstatix::eta_squared(model)
  
  # calculate the effect size (Cohen's F)
  Cohen_f <- sqrt(eta_sq / (1 - eta_sq))
  
  # 0.10 ~ small; 0.25 ~ medium, 0.40 ~ large
  anova_effect_size <- 'small'
  if(Cohen_f > 0.175){
    anova_effect_size <- 'medium'
  }
  
  if(Cohen_f > 0.325){
    anova_effect_size <- 'large'
  }
  
  return(data.frame(list(covariateName = cov_name, 
                         N = stats$N[1],
                         Oxycodone = stats[stats$group=='Oxycodone',2],
                         Hydrocodone = stats[stats$group=='Hydrocodone',2],
                         Morphine = stats[stats$group=='Morphine',2],
                         Tramadol = stats[stats$group=='Tramadol',2],
                         Hydromorphone = stats[stats$group=='Hydromorphone',2],
                         Codeine = stats[stats$group=='Codeine',2],
                         Non_opioid = stats[stats$group=='Non-opioid',2],
                         p_value = round(p_value, digits = 5),
                         eta_squared = eta_sq,
                         Cohen_f = Cohen_f,
                         effect_size = anova_effect_size)))
  
}


calculate_anova <- function(group_data, cov_name){
  group_data <- na.omit(group_data)
  stats <- group_data %>% 
    group_by(group) %>% 
    summarize (
    #mean_sd = paste0(round(mean(value), digits = 2), '(', round(sd(value), digits = 2), ')'),
    mean_ci = paste0(round(mean(value), digits = 2), '(+/- ', round(sd(value) / sqrt(n()) * 1.96, digits = 2), ')'),
    N = n()
  )
  
  model <- aov(value ~ group, data = group_data)
  # model <- kruskal.test(value ~ group, data = group_data)
  
  anova <- summary(model)
  p_value <- anova[[1]][["Pr(>F)"]][1]
  
  # calculate the effect size (eta squared)
  eta_sq <- rstatix::eta_squared(model)
  
  # calculate the effect size (Cohen's F)
  Cohen_f <- sqrt(eta_sq / (1 - eta_sq))
  
  # 0.10 ~ small; 0.25 ~ medium, 0.40 ~ large
  anova_effect_size <- 'small'
  if(Cohen_f > 0.175){
    anova_effect_size <- 'medium'
  }
  
  if(Cohen_f > 0.325){
    anova_effect_size <- 'large'
  }
  
  return(data.frame(list(covariateName = cov_name, 
                         N = stats$N[1],
                         Oxycodone = stats[stats$group=='Oxycodone',2],
                         Hydrocodone = stats[stats$group=='Hydrocodone',2],
                         Morphine = stats[stats$group=='Morphine',2],
                         Tramadol = stats[stats$group=='Tramadol',2],
                         Hydromorphone = stats[stats$group=='Hydromorphone',2],
                         Codeine = stats[stats$group=='Codeine',2],
                         Non_opioid = stats[stats$group=='Non-opioid',2],
                         p_value = round(p_value, digits = 5),
                         eta_squared = eta_sq,
                         Cohen_f = Cohen_f,
                         effect_size = anova_effect_size)))
  
}

runAnova <- function(x_y_test, main_groups_col="actual_opu", model_name = ""){
    
  main_groups <- levels(as.factor(x_y_test[[main_groups_col]]))
  
  anova_results <- data.frame(covariateName = character(),
                              N = numeric(),
                              Oxycodone = character(),
                              Hydrocodone = character(),
                              Morphine = character(),
                              Tramadol = character(),
                              Hydromorphone = character(),
                              Codeine = character(),
                              Non_opioid = character(),
                              p_vale = double(),
                              eta_squared = double(),
                              Cohen_f = double(),
                              effect_size = character())
  
  for (mg in main_groups){
    group_data = x_y_test[x_y_test[main_groups_col]==mg,][c("sub_cat", "Optimal_Value")]
    colnames(group_data) <- c("group", "value")
    
    anova_results[nrow(anova_results) + 1, ] <- calculate_anova(
      group_data, cov_name = mg
    )
  }
  
  write.csv(anova_results, paste("./results/V2/csv/anova_effect_size", main_groups_col, model_name, ".csv", sep = "_"), row.names = F)
}



