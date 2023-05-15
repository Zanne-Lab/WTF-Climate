# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline # nolint

# Load packages required to define the pipeline:
library(targets)
library(tarchetypes) # Load other packages as needed. # nolint

# Set target options:
tar_option_set(
  packages = c("tibble","lubridate", "tidyverse","openxlsx", "rio", "readxl",
               "modelr", "scattermore", "anomalize"), # packages that your targets need to run
  format = "rds",
  error = "null"# default storage format
  # Set other options as needed.
)

# tar_make_clustermq() configuration (okay to leave alone):
options(clustermq.scheduler = "multicore")

# tar_make_future() configuration (okay to leave alone):
# Install packages {{future}}, {{future.callr}}, and {{future.batchtools}} to allow use_targets() to configure tar_make_future() options.

# Run the R scripts in the R/ folder with your custom functions:
tar_source("R/process-data.R")
# source("other_functions.R") # Source other scripts as needed. # nolint

# Replace the target list below with your own:
list(
  tar_target(wthr_dro_station3,format = "file",
             command = get_dro_vaisala_wxt520("data/dro_data/DRO_Jib_WeatherStation_18-22.xls")),
  tar_target(dro_met3, format= "file", 
             command = get_dro_vaisala_hmp60("data/dro_data/DRO_Crane_Met_2020_cleaned.xlsx",
                                             "data/dro_data/DRO_Crane_Met_2021_cleaned.xlsx",
                                             "data/dro_data/DRO_Crane_Met_2022_cleaned.xlsx")),
  tar_target(dro_soil_all, format = "file",
             get_dro_soil("data/dro_data/DRO_soil_pit/DRO_Soil Pit_19.xls",
                          "data/dro_data/DRO_soil_pit/DROsoil_Start-2020-01_Stop-2021-01_y2022m06d16h17m05s57.xls",
                          "data/dro_data/DRO_soil_pit/DROsoil_Start-2021-01_Stop-2022-01_y2022m06d16h17m06s05.xls",
                          "data/dro_data/DRO_soil_pit/DROsoil_Start-2022-01_Stop-2023-01_y2022m06d16h17m06s14.xls")),
  tar_target(wthr_dat, read_weather_stations("data/weather_stations")),
  tar_target(wthr_dat6, process_weather_stations(wthr_dat))
  
)
