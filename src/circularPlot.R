library(tidyr)

plotCircularChart <- function(grouped_df, model_name = 'seqtransformer') {
  group_name <- ''
  if ("actual_opu" %in% names(grouped_df)) {
    group_name <- 'DischargeOpioid'
    data <- data.frame(
      individual = as.factor(grouped_df$sub_cat),
      group= as.factor(grouped_df$actual_opu),
      value=grouped_df$avg_optimal_value #* 100
    )
  } else if ("SurgeryTypeCat" %in% names(grouped_df)){
    group_name <- 'SurgeryTypeCat'
    data <- data.frame(
      individual = as.factor(grouped_df$sub_cat),
      group= as.factor(grouped_df$SurgeryTypeCat),
      value=grouped_df$avg_optimal_value #* 100
    )
  } else if ("SurgeryTypeCode" %in% names(grouped_df)){
    group_name <- 'SurgeryTypeCode'
    data <- data.frame(
      individual = as.factor(grouped_df$sub_cat),
      group= as.factor(grouped_df$SurgeryTypeCode),
      value=grouped_df$avg_optimal_value #* 100
    )
  } else {
    stop("Invalid group name!")
  }
  
  zoom_min <- floor(min(data$value))
  zoom_max <- ceiling(max(data$value))
  zoom_second <- round((zoom_max - zoom_min) * 0.333 + zoom_min)
  zoom_third <- round((zoom_max - zoom_min) * 0.666 + zoom_min)
  
  data <- data %>%
    mutate(value = (value - zoom_min) / (zoom_max - zoom_min) * 100)
  
  
  min_value <- min(data$value)
  max_value <- max(data$value)
  second_value <- round((max_value - min_value) * 0.333 + min_value)
  third_value <- round((max_value - min_value) * 0.666 + min_value)
  
  # Set a number of 'empty bar' to add at the end of each group
  empty_bar <- 3
  to_add <- data.frame( matrix(NA, empty_bar*nlevels(data$group), ncol(data)) )
  colnames(to_add) <- colnames(data)
  to_add$group <- rep(levels(data$group), each=empty_bar)
  data <- rbind(data, to_add)
  data <- data %>% arrange(group)
  data$id <- seq(1, nrow(data))
  
  # Get the name and the y position of each label
  label_data <- data
  number_of_bar <- nrow(label_data)
  angle <- 90 - 360 * (label_data$id-0.5) /number_of_bar     # I substract 0.5 because the letter must have the angle of the center of the bars. Not extreme right(1) or extreme left (0)
  label_data$hjust <- ifelse( angle < -90, 1, 0)
  label_data$angle <- ifelse(angle < -90, angle+180, angle)
  
  # prepare a data frame for base lines
  base_data <- data %>% 
    group_by(group) %>% 
    summarize(start=min(id), end=max(id) - empty_bar) %>% 
    rowwise() %>% 
    mutate(title=mean(c(start, end)))
  
  # prepare a data frame for grid (scales)
  grid_data <- base_data
  grid_data$end <- grid_data$end[ c( nrow(grid_data), 1:nrow(grid_data)-1)] + 1
  grid_data$start <- grid_data$start - 1
  grid_data <- grid_data[-1,]
  
  # Make the plot
  p <- ggplot(data, aes(x=as.factor(id), y=value, fill=group)) +       # Note that id is a factor. If x is numeric, there is some space between the first bar
    
    geom_bar(aes(x=as.factor(id), y=value, fill=group), stat="identity", alpha=0.5) +
    
    # Add a val=100/75/50/25 lines. I do it at the beginning to make sur barplots are OVER it.
    geom_segment(data=grid_data, aes(x = end, y = max_value, xend = start, yend = max_value), colour = "grey", alpha=1, size=0.3 , inherit.aes = FALSE ) +
    geom_segment(data=grid_data, aes(x = end, y = third_value, xend = start, yend = third_value), colour = "grey", alpha=1, size=0.3 , inherit.aes = FALSE ) +
    geom_segment(data=grid_data, aes(x = end, y = second_value, xend = start, yend = second_value), colour = "grey", alpha=1, size=0.3 , inherit.aes = FALSE ) +
    geom_segment(data=grid_data, aes(x = end, y = min_value, xend = start, yend = min_value), colour = "grey", alpha=1, size=0.3 , inherit.aes = FALSE ) +
    
    # Add text showing the value of each 100/75/50/25 lines
    #annotate("text", x = rep(max(data$id),4), y = c(20, 40, 60, 80), label = c("20", "40", "60", "80") , color="grey", size=3 , angle=0, fontface="bold", hjust=1) +
    annotate("text", x = rep(max(data$id),4), y = c(min_value, second_value, third_value, max_value), label = as.character(c(zoom_min, zoom_second, zoom_third, zoom_max)) , color="grey", size=3 , angle=0, fontface="bold", hjust=1) +
    
    geom_bar(aes(x=as.factor(id), y=value, fill=group), stat="identity", alpha=0.5) +
    ylim(-100,120) +
    theme_minimal() +
    theme(
      legend.position = "none",
      axis.text = element_blank(),
      axis.title = element_blank(),
      panel.grid = element_blank(),
      plot.margin = unit(rep(-1,4), "cm") 
    ) +
    coord_polar() + 
    geom_text(data=label_data, aes(x=id, y=value+10, label=individual, hjust=hjust), color="black", fontface="bold",alpha=0.6, size=3.8, angle= label_data$angle, inherit.aes = FALSE ) +
    
    # Add base line information
    geom_segment(data=base_data, aes(x = start, y = -5, xend = end, yend = -5), colour = "black", alpha=0.8, size=0.6 , inherit.aes = FALSE )  +
    geom_text(data=base_data, aes(x = title, y = -34, label=group), colour = "black", alpha=0.8, size=4.2, fontface="bold", inherit.aes = FALSE)
  
  plot(p)
  ggsave(paste('./results/V2/plot/DischargeOpioid_vs_Others', group_name, model_name, '.pdf',sep = "_"), units="in", width=10, height=10, dpi=300)
  #dev.off()
}



plotPredictionDistribution <- function(pred_df, model_name = 'seqtransformer', actual_outcome_col = 'POU_Outcome', pred_col='POU'){
  
  plotDf <- pred_df[c(actual_outcome_col, pred_col)]
  colnames(plotDf) <- c("outcomeCount","value")
  
  plotDf$outcomeCount <- as.factor(plotDf$outcomeCount)
  
  violinPlot <- ggplot2::ggplot(
    data = plotDf, 
    ggplot2::aes(
      x = .data$outcomeCount, 
      y = .data$value
    )
  ) +
    ggplot2::geom_violin(
      ggplot2::aes(fill = outcomeCount),
      show.legend = FALSE
    )  + 
    ggplot2::labs(
      x = "Outcome",
      y = "Estimated probability"
    ) +
    ggplot2::geom_boxplot(width=0.1) +
    theme(legend.position = "none", 
          axis.title = element_text(size=20),
          text = element_text(size=19))
  
  plot(violinPlot)
  ggsave(paste('./results/V2/plot/predDistrubution', pred_col, model_name, '.pdf',sep = "_"), units="in", width=6, height=6, dpi=300)
  #dev.off()
  return(violinPlot)
}



plotTrrDistribution <- function(pred_df, model_name = 'seqtransformer', actual_outcome_col = 'POU_Outcome', pred_col='POU'){

  plotDf <- pred_df[c(actual_outcome_col, pred_col)]
  colnames(plotDf) <- c("outcomeCount","value")
  
  plotDf$outcomeCount <- as.factor(plotDf$outcomeCount)
  
  violinPlot <- ggplot2::ggplot(
    data = plotDf, 
    ggplot2::aes(
      x = .data$outcomeCount, 
      y = .data$value
    )
  ) +
    ggplot2::geom_violin(
      ggplot2::aes(fill = outcomeCount),
      show.legend = FALSE
    )  + 
    ggplot2::labs(
      x = "Discharge Opioid",
      y = "Total Relative Risk"
    ) +
    ggplot2::geom_boxplot(width=0.1) + 
    #scale_y_continuous(limits = c(0, 10))
    theme(legend.position = "none", 
          axis.title = element_text(size=20),
          text = element_text(size=19))
  
  plot(violinPlot)
  ggsave(paste('./results/V2/plot/TRR_Distrubution', pred_col, model_name, '.pdf',sep = "_"), units="in", width=6, height=6, dpi=300)
  #dev.off()
  return(violinPlot)
}




plotBarChart <- function(grouped_df, model_name = 'seqtransformer') {
  group_name <- ''
  if ("actual_opu" %in% names(grouped_df)) {
    group_name <- 'DischargeOpioid'
    data <- data.frame(
      individual = grouped_df$sub_cat,
      group= as.factor(grouped_df$actual_opu),
      value=grouped_df$avg_optimal_value
    )
  } else if ("SurgeryTypeCat" %in% names(grouped_df)){
    group_name <- 'SurgeryTypeCat'
    data <- data.frame(
      individual = as.factor(grouped_df$sub_cat),
      group= as.factor(grouped_df$SurgeryTypeCat),
      value=grouped_df$avg_optimal_value 
    )
  } else if ("SurgeryTypeCode" %in% names(grouped_df)){
    group_name <- 'SurgeryTypeCode'
    data <- data.frame(
      individual = as.factor(grouped_df$sub_cat),
      group= as.factor(grouped_df$SurgeryTypeCode),
      value=grouped_df$avg_optimal_value
    )
  } else {
    stop("Invalid group name!")
  }
  
  empty_bar <- 1
  to_add <- data.frame( matrix(NA, empty_bar*nlevels(data$group), ncol(data)) )
  colnames(to_add) <- colnames(data)
  to_add$group <- rep(levels(data$group), each=empty_bar)
  data <- rbind(data, to_add)
  data <- data %>% arrange(group)
  data$id <- seq(1, nrow(data))
  data$id2 <- paste(data$individual, data$id, sep = ".")
  
  p <- ggplot(data, aes(x=as.factor(id), y=value, fill=group)) +
    geom_bar(stat="identity", alpha=0.5)
  

  plot(p)
  ggsave(paste('./results/V2/plot/barchart', group_name, model_name, '.pdf',sep = "_"), units="in", width=10, height=10, dpi=300)
  #dev.off()
}


plotOptimalOpioidCharacteristic <- function(data, model_name = 'seqtransformer'){
  
  data_long1 <- data[c("Optimal_Opioid", names(data)[endsWith(names(data), "_Mean")])] %>%
    pivot_longer(cols = -Optimal_Opioid, names_to = "Characteristic", values_to = "Mean")
  
  data_long2 <- data[c("Optimal_Opioid", names(data)[endsWith(names(data), "_CI")])] %>%
    pivot_longer(cols = -Optimal_Opioid, names_to = "Characteristic2", values_to = "CI")
  
  data_long <- bind_cols(data_long1, data_long2)
  data_long <- data_long[-4]
  colnames(data_long)[1] <- "Optimal_Opioid"
  
  data_long$Characteristic <- gsub("_Mean", "", data_long$Characteristic)
  
  p <- ggplot(data_long, aes(x = Optimal_Opioid, y = Mean, group = Characteristic, color = Characteristic )) +
    geom_line(aes(group = Characteristic), size = 1) +
    geom_point(size = 3) +
    geom_errorbar(aes(ymin = Mean - CI, ymax = Mean + CI), width = 0.2, size = 1) +
    facet_wrap(~Characteristic, scales = "free_y") + 
    theme_minimal() +
    labs(x = "Optimal Opioid", y = "Mean") +
    theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "none", 
          axis.title = element_text(size=20),
          text = element_text(size=17))
  
  plot(p)
  ggsave(paste('./results/V2/plot/OptimalOpioidCharacteristic', model_name, '.pdf',sep = "_"), units="in", width=6, height=6, dpi=300)
  dev.off()
  
}


plotRiskLftScatter <- function(data, model_name = 'seqtransformer'){
  data <- data[order(data$Total_Risk), ]
  max_trr <- max(data$Total_Risk)
  p <- ggplot(data, aes(x = AST_ALT_Ratio, y = Total_Risk)) +
    #geom_line(color = "blue", size = 1) +
    geom_point(alpha = 0.5, color = "blue", size=0.5) +
    geom_smooth(method = "lm", color = "red", se=FALSE) +
    labs(x = "AST/ALT Ratio", y = "Total Relevant Risk") +
    scale_x_continuous(limits = c(0, 4)) +
    scale_y_continuous(limits = c(0, max_trr)) +
    theme_minimal() +
    theme(
      legend.position = "none",
      axis.title = element_text(size = 17),
      text = element_text(size=15))
    
  plot(p)
  ggsave(paste('./results/V2/plot/riskVsAstAltRatio', model_name, '.pdf',sep = "_"), units="in", width=5, height=5, dpi=600)
  dev.off()
}


plotHydrocodoneDiffVsOthers <- function(data, model_name = 'seqtransformer'){
  #data <- read.csv('/Users/behzadn/BoussardLab/NLM-pain/RemainingDeliverables(DL)/opioid-treatment/results/VA-V2/V2-RR-Optimal/csv/optimalDifference_overall_seqtransforme_.csv')
  data <- data[data$min_optimal_op == 'Hydrocodone' & data$min_optimal_op != data$actual_opu, ]
  data <- data[c('min_optimal_op', 'actual_opu', 'avg_diff', 'ci')]
  data <- data[order(data$avg_diff), ]
  
  data$actual_opu <- factor(data$actual_opu, levels = data$actual_opu) 
  
  p <- ggplot(data, aes(x = actual_opu, y = avg_diff, group = 1)) +
    geom_line(size = .5, color = "blue") + 
    geom_point(size = 2, color = "red") +
    geom_errorbar(aes(ymin = avg_diff - ci, ymax = avg_diff + ci), width = 0.2, size = .5, color = "red") +
    theme_minimal() +
    labs(x = "Actual Discharge Opioid", y = "Total Risk Difference with Hydrocodone") +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          legend.position = "none",
          axis.title = element_text(size = 12),
          text = element_text(size=11))
  
  plot(p)
  ggsave(paste('./results/V2/plot/HydrocodoneVsOthers', model_name, '.pdf',sep = "_"), units="in", width=4, height=4, dpi=600)
  dev.off()
}

