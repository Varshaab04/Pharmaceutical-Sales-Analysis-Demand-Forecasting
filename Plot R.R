
# STEP 1: Import the CSV file
pharma <- read.csv(
  file.choose(),
  check.names = FALSE,
  stringsAsFactors = FALSE
)

# STEP 2: Inspect the imported dataset
head(pharma)
names(pharma)
str(pharma)

# STEP 3: Convert the date column
# Assumes the date column is named "datum"
pharma$datum <- as.Date(pharma$datum)

# If your dates are in DD/MM/YYYY format instead, use:
# pharma$datum <- as.Date(pharma$datum, format = "%d/%m/%Y")

# Check for dates that failed to convert
if (anyNA(pharma$datum)) {
  stop("Some dates could not be converted. Check the date format.")
}

# STEP 4: Identify medicine-category columns
category_cols <- setdiff(
  names(pharma),
  "datum"
)

# Convert medicine-category columns to numeric
pharma[category_cols] <- lapply(
  pharma[category_cols],
  function(x) as.numeric(as.character(x))
)

# STEP 5: Calculate total sales volume for each month
pharma$Total_Sales_Volume <- rowSums(
  pharma[category_cols],
  na.rm = FALSE
)

# Check for missing or invalid sales values
if (anyNA(pharma$Total_Sales_Volume)) {
  stop("Missing or non-numeric sales values found. Check the CSV data.")
}

# Display monthly totals
head(pharma[, c("datum", "Total_Sales_Volume")])

# STEP 6: Calculate total sales by medicine category
category_totals <- data.frame(
  Category = category_cols,
  Total_Sales = colSums(
    pharma[category_cols],
    na.rm = FALSE
  )
)

# Sort from highest to lowest sales
category_totals <- category_totals[
  order(-category_totals$Total_Sales),
]

print(category_totals)

# STEP 7: Plot sales volume by medicine category
# Install ggplot2 only if it is not already installed
# install.packages("ggplot2")

library(ggplot2)

ggplot(
  category_totals,
  aes(
    x = reorder(Category, Total_Sales),
    y = Total_Sales
  )
) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Sales Volume by Medicine Category",
    x = "Medicine Category",
    y = "Total Sales Volume"
  ) +
  theme_minimal()

# STEP 8: Sort all monthly observations chronologically
pharma <- pharma[order(pharma$datum), ]

# STEP 9: Plot every monthly sales observation
ggplot(
  pharma,
  aes(
    x = datum,
    y = Total_Sales_Volume,
    group = 1
  )
) +
  geom_line(linewidth = 0.6) +
  geom_point(size = 1.5) +
  labs(
    title = "Monthly Pharmaceutical Sales Volume",
    x = "Month",
    y = "Total Sales Volume"
  ) +
  theme_minimal()

# STEP 10: Prepare the moving-average forecast
sales <- pharma$Total_Sales_Volume

# Check that sufficient complete data is available
if (length(sales) <= 6 || anyNA(sales)) {
  stop("At least 7 complete monthly observations are required.")
}

# Reserve the last 6 months for testing
test_size <- 6
n <- length(sales)

actual <- tail(sales, test_size)
forecast <- numeric(test_size)

# STEP 11: Forecast each test month using the previous 3 actual months
for (i in seq_len(test_size)) {
  pos <- n - test_size + i
  
  forecast[i] <- mean(
    sales[(pos - 3):(pos - 1)]
  )
}

# STEP 12: Compare actual and forecast sales
comparison <- data.frame(
  Month = tail(pharma$datum, test_size),
  Actual = actual,
  Forecast = forecast
)

comparison$Absolute_Error <- abs(
  comparison$Actual - comparison$Forecast
)

print(comparison)

# STEP 13: Calculate Mean Absolute Error (MAE)
MAE <- mean(comparison$Absolute_Error)

cat("Mean Absolute Error (MAE):", MAE, "\n")

# STEP 14: Forecast the next month's sales volume
next_month_forecast <- mean(tail(sales, 3))

next_month_date <- seq(
  max(pharma$datum),
  by = "month",
  length.out = 2
)[2]

cat(
  "Forecast month:",
  format(next_month_date, "%Y-%m"),
  "\n"
)

cat(
  "Next-month sales-volume forecast:",
  round(next_month_forecast, 2),
  "\n"
)

# STEP 15: Plot actual vs forecast sales for the test period
ggplot(comparison, aes(x = Month)) +
  geom_line(
    aes(y = Actual, color = "Actual"),
    linewidth = 0.8
  ) +
  geom_line(
    aes(y = Forecast, color = "Forecast"),
    linewidth = 0.8,
    linetype = "dashed"
  ) +
  geom_point(aes(y = Actual, color = "Actual")) +
  geom_point(aes(y = Forecast, color = "Forecast")) +
  labs(
    title = "Actual vs Forecast Pharmaceutical Sales",
    x = "Month",
    y = "Sales Volume",
    color = "Series"
  ) +
  theme_minimal()

