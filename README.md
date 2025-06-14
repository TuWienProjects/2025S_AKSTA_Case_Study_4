# Global Indicators Explorer – A Shiny App

This Shiny web application provides an interactive platform to explore and analyze global development indicators derived from the 2020 CIA World Factbook. Built for the **AKSTA Statistical Computing** course (Case Study 4), the app allows users to visualize, compare, and interpret country-level data in both univariate and multivariate contexts.



## Project Structure

---
├── app.R # Main Shiny app file

├── data_cia2.json # Dataset file

├── www/ # (Optional) Folder for custom CSS or images

└── README.md # Project description

---

## Features

### 🔹 Univariate Analysis

- **Sidebar Inputs**:
  - Variable selector (e.g., education expenditure, youth unemployment)
  - View raw data (max 15 rows) with country and continent

- **Main Panel Tabs**:
  - **Map**: Interactive choropleth with tooltips using `ggplotly()`
  - **Global Analysis**: Histogram, density plot, and boxplot
  - **Analysis per Continent**: Grouped boxplot and density plot by continent

### 🔹 Multivariate Analysis

- **Sidebar Inputs**:
  - Select two numeric variables for scatterplot axes
  - Choose point size variable: `population` or `area`

- **Main Panel**:
  - Interactive scatterplot colored by continent
  - LOESS trend lines per continent
  - Point size scaled appropriately

---

## 📁 Dataset

Data source: `data_cia2.json` (CIA World Factbook, 2020)

**Variables include**:
- `expenditure`: Public education expenditure (% of GDP)
- `youth_unempl_rate`: Youth unemployment rate (15–24 years)
- `net_migr_rate`: Net migration rate (per 1000)
- `electricity_fossil_fuel`: Fossil fuel electricity share (%)
- `pop_growth_rate`: Population growth rate (%)
- `life_expectancy`: Life expectancy at birth
- `area`, `population`, `continent`, `subcontinent`, `status`

---

## Installation

```r
# Install required packages
install.packages(c("shiny", "ggplot2", "plotly", "dplyr", "DT", "countrycode"))

# Run the app
shiny::runApp("path_to_folder_containing_app.R")
