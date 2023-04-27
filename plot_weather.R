# Visualize weather data

# Load packages
library(tidyverse)
library(lubridate)
library(ggh4x)
library(forcats)
library(zoo)

########## Load in data ##########

wthr_final <- read_csv("wthr_1hr_final.csv")
SILO <- read_csv("data/external_data/SILO_processed.csv") 


########## Set color palettes and common aesthetics ##########

# Colors for weather plots
p_WTF <- "#7870C8"
p_POWER <- "#A84890"
p_CHRS <- "#680850"
p_SILO <- "#333333"
p_calc <- "#303088"

# Common aesthetics
fig_aes <- theme_bw() +
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        strip.background =element_rect(fill="gray95"))


########## Plots ##########
#..Air temp/rainfall for each site ####
png("figures/temp_rain.png",width=2000,height=2500,res=250)
ggplot() + 
  geom_line(data=wthr_final,aes(date,AirTC_Avg),
            stat="identity",color="red",alpha=0.5) + 
  geom_bar(data=filter(wthr_final,Rain_mm_Tot>0),aes(date,Rain_mm_Tot),
           stat="identity",color="blue") + 
  facet_grid2(fct_relevel(site,"DRO","MLRF","MLES","STCK","HQ_AWC","PNW")~.) +
  xlab(label = "Date") + 
  scale_y_continuous(name="Air Temperature (C)",
                     sec.axis=sec_axis(~.,name="Rainfall (mm/hr)")) +
  fig_aes
dev.off()


#..Table of annual rainfall and precipitation across experiment ####
wthr_rain_avg <- wthr_final %>%
  mutate(year = year(date),
         month = month(date),
         Rain_mm_f = ifelse(is.na(Rain_mm),PRECTOTCORR,Rain_mm)) %>%
  mutate(year_half = case_when(month%in%c(6:12) ~ "second",
                               TRUE ~ "first")) %>%
  group_by(site, year, year_half) %>%
  summarize(Rain_tot = sum(Rain_mm_Tot),
            Rain_tot_CCS = sum(Rain_mm_f)) %>%
  ungroup() %>%
  mutate(Rain_tot_yr = Rain_tot + dplyr::lag(Rain_tot),
         Rain_tot_yr_CCS = Rain_tot_CCS + dplyr::lag(Rain_tot_CCS)) %>%
  filter(year_half=="first") %>%
  group_by(site) %>%
  summarize(Rain_avg = mean(Rain_tot_yr),
            Rain_avg_CCS = mean(Rain_tot_yr_CCS))
write_csv(wthr_rain_avg,"figures/wthr_rain_avg.csv")

wthr_TC_avg <- wthr_final %>%
  mutate(year = year(date)) %>%
  group_by(site,year) %>%
  summarize(AirTC_mean = mean(AirTC_Avg),
            AirTC_max = max(AirTC_Avg),
            AirTC_min = min(AirTC_Avg),
            ibTC_mean = mean(ib_AirTC_Avg),
            ibTC_max = max(ib_AirTC_Avg),
            ibTC_min = min(ib_AirTC_Avg))
write_csv(wthr_TC_avg,"figures/wthr_TC_avg.csv")


#......Rainfall gap-filling comparison with SILO data ####
SILO_rain_f <- SILO %>%
  filter(day > as.POSIXlt("2018-06-04")) %>%
  filter(day < as.POSIXlt("2022-06-14")) %>%
  mutate(year_mon = as.yearmon(day)) %>%
  group_by(site,year_mon) %>%
  summarize(SILO = sum(daily_rain, na.rm = TRUE))

wthr_rain_val <- wthr_final %>%
  mutate(Rain_CP = ifelse(is.na(Rain_mm),PRECTOTCORR,Rain_mm)) %>%
  mutate(day = date(date),
         year_mon = as.yearmon(day)) %>%
  group_by(site,year_mon) %>%
  summarize(CHRS_filled = sum(Rain_mm_Tot),
            POWER_filled = sum(Rain_mm_Tot_P),
            CP_only = sum(Rain_CP))

wthr_rain <- wthr_final %>%
  mutate(day = date(date),
         year_mon = as.yearmon(day)) %>%
  group_by(site,year_mon) %>%
  count(Rain_source) %>%
  top_n(1) %>%
  select(-n) %>%
  left_join(wthr_rain_val,by=c("site","year_mon"))

png("figures/wthr_rain_comparison.png",width=2000,height=2500,res=250)
ggplot() + 
  geom_point(data=SILO_rain_f,aes(year_mon,SILO),
             color=p_SILO,alpha=0.8) + 
  geom_line(data=SILO_rain_f,aes(year_mon,SILO),
            color=p_SILO,linetype="dashed",alpha=0.8) + 
  geom_point(data=wthr_rain,aes(year_mon,CHRS_filled,color=Rain_source),
             alpha=0.8) +
  geom_line(data=wthr_rain,aes(year_mon,CHRS_filled),
            color=p_WTF,alpha=0.8) + 
  scale_color_manual(name="Rainfall source",values =c(p_CHRS,p_WTF),
                     labels=c("CHRS CCS", "WTF Stations")) + 
  facet_grid(fct_relevel(site,"DRO","MLRF","MLES","STCK","HQ_AWC","PNW")~.) + 
  xlab("Month") + ylab("Rainfall (mm/month)") +
  fig_aes
dev.off()
