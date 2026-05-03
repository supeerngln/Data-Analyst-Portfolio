# Philippine Typhoon Risk Analysis (2014-2024)
An investigation into the atmospheric drivers of tropical cyclone frequency in the Philippine Area of Responsibility (PAR).

## Project Link
https://upsystem-my.sharepoint.com/:x:/g/personal/emanuran_outlook_up_edu_ph/IQC4Mpl76THgTqVJqCRp7uTbATeiwT-dYLcpdLpNDku81wI?e=hRqe79

## Project Overview
This project analyzes 10 years of meteorological data to identify the primary drivers of typhoon frequency in the Philippines. Moving beyond simple descriptive statistics, the project explores the correlation between localized atmospheric variables (Pressure, Humidity, SST) and global climate indices (ONI).

## Key Findings
Contrary to common assumptions that Sea Surface Temperature (SST) is the sole predictor of storm frequency, this data-driven study revealed:
* A significant **inverse correlation (-0.50)** was found between Sea Level Pressure and typhoon frequency. Lower barometric pressure is a more reliable predictor of storm counts than temperature alone.
* Midlevel Humidity showed a **moderate positive correlation (+0.42)**, showing that it acts as a necessary "fuel" for storm maintenance.
* While El Niño years averaged slightly higher typhoon counts **(1.57)** compared to Neutral years **(1.31)**, the risk remains high across all phases, indicating that the Philippines maintains a "ready-state" regardless of the ENSO cycle.
* Historical data confirms **October** to be the peak month of risk, characterized by the lowest annual average pressure readings.

## Technical Implementation
* Conducted correlational matrices using the *CORREL* function to compare **ONI,SST, and atmospheric variables**
* Built an interactive Excel dashboard featuring:
    *  Using secondary axes to visualize the relationship between Typhoon Count (*1.5* scale) and Sea Level Pressure (*1000+* scale).
    *  Filtering by **Year, Month, and ONI Category**     

