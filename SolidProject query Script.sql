/* 

COVID-19 Data Analysis SQL Script

Overview

This document presents a collection of SQL queries designed for analyzing global COVID-19 data, with a specific focus on South Africa. 
The queries are intended for use in Tableau for data visualization and presentation purposes. The dataset comprises two tables:

	CovidDeaths — Contains COVID-19 case, death, and population data by location and date.

	CovidVaccinations — Contains vaccination data by location and date.

The script is organized into the following analytical themes:

1.	Death rate analysis (global and local)

2.	Death counts by continent and globally

3.	Infection rate analysis

4.	Population vs. vaccination analysis (using Joins, CTEs, and Temp Tables)


*/

--- 1. Death rate in the world
SELECT 
    location,
    SUM(CAST(new_cases AS FLOAT)) AS "total cases",
    SUM(CAST(new_deaths AS FLOAT)) AS "total death",
    (SUM(CAST(new_deaths AS FLOAT)) / SUM(CAST(new_cases AS FLOAT))) * 100 AS "Death Rate"
FROM SolidProject..CovidDeaths
WHERE continent IS NOT NULL 
  AND population IS NOT NULL
GROUP BY location
ORDER BY "Death Rate" DESC;

/* 
Purpose: 
Calculates the death rate for each country (location) by dividing total deaths by total cases and multiplying by 100. 
Filters out aggregate rows (where continent is NULL) and rows without population data to ensure country-level accuracy.
*/

--Death Rate Locally (South Africa)
SELECT 
    location,
    SUM(CAST(new_cases AS FLOAT)) AS "total cases",
    SUM(CAST(new_deaths AS FLOAT)) AS "total death",
    (SUM(CAST(new_deaths AS FLOAT)) / SUM(CAST(new_cases AS FLOAT))) * 100 AS "Death Rate"
FROM SolidProject..CovidDeaths
WHERE location LIKE '%South Africa%'
GROUP BY location;

/*
Purpose: Focuses on South Africa specifically, calculating the same death rate metric for local analysis.
*/

-- 3. Total number of deaths by Continents
SELECT 
    continent,
    SUM(CAST(new_deaths AS FLOAT)) AS "Death Count"
FROM SolidProject..CovidDeaths
WHERE continent IS NOT NULL 
  AND population IS NOT NULL
GROUP BY continent
ORDER BY "Death Count";
/*
Purpose: Aggregates total deaths by continent, providing a continental-level view of COVID-19 mortality.
*/

-- 4. Total numer of deaths Globally
SELECT 
    location,
    SUM(CAST(new_deaths AS FLOAT)) AS "Death Count"
FROM SolidProject..CovidDeaths
WHERE continent IS NULL 
  AND location LIKE '%World%'
GROUP BY location
ORDER BY "Death Count";

/*
Purpose: Retrieves the global death count using the aggregated "World" row in the dataset.
*/

-- 5. Countries with the highest infection rate 
SELECT 
    location,
    date,
    MAX(CAST(new_cases AS FLOAT)) AS "Highest number of new cases",
    MAX(CAST(total_cases AS FLOAT)) AS "Highest number of cases",
    (MAX(CAST(new_cases AS FLOAT)) / MAX(CAST(total_cases AS FLOAT))) * 100 AS "Infection Rate"
FROM SolidProject..CovidDeaths
WHERE continent IS NOT NULL 
  AND population IS NOT NULL
GROUP BY location, date
ORDER BY date, [Infection Rate];

/*
Purpose: Retrieves the global death count using the aggregated "World" row in the dataset.
*/

-- 6. joining the two tables

SELECT *
FROM SolidProject..CovidDeaths cd
JOIN SolidProject..CovidVaccinations cv
    ON cd.date = cv.date
    AND cd.location = cv.location;

/*
Purpose: Demonstrates the join between deaths and vaccinations tables on date and location, forming the foundation for combined analysis.
*/
	
-- 7. looking at total Population vs total number of Vaccination per day in South Africa
SELECT 
    cv.continent,
    cv.location,
    cv.date,
    population,
    new_vaccinations,
    SUM(CONVERT(FLOAT, new_vaccinations)) 
        OVER (PARTITION BY cd.location 
              ORDER BY cd.location, cd.date) AS "total vaccinations"
FROM SolidProject..CovidDeaths cd
JOIN SolidProject..CovidVaccinations cv
    ON cd.date = cv.date
    AND cd.location = cv.location
WHERE cd.continent IS NOT NULL 
  AND cd.population IS NOT NULL 
  AND cd.location LIKE '%South Africa%'
ORDER BY 2, 3;

/*
Purpose: Uses a window function to compute a running total of vaccinations over time for South Africa, alongside population data.
*/

-- 8. Using CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, total_vaccinations) AS (
    SELECT 
        cv.continent,
        cv.location,
        cv.date,
        population,
        new_vaccinations,
        SUM(CONVERT(FLOAT, new_vaccinations)) 
            OVER (PARTITION BY cd.location 
                  ORDER BY cd.location, cd.date) AS "total vaccinations"
    FROM SolidProject..CovidDeaths cd
    JOIN SolidProject..CovidVaccinations cv
        ON cd.date = cv.date
        AND cd.location = cv.location
    WHERE cd.continent IS NOT NULL 
      AND cd.population IS NOT NULL 
      AND cd.location LIKE '%South Africa%'
)
SELECT *, (total_vaccinations / population) * 100 AS "rate of the vaccinated"
FROM PopvsVac;

/*
Purpose: Encapsulates the running vaccination total in a CTE and then calculates the percentage of the population vaccinated.
*/
	
-- 9. Using CTE to add a Percentage of vaccinated population Column
DROP TABLE IF EXISTS #PopulationvsVaccinations;

CREATE TABLE #PopulationvsVaccinations (
    continent NVARCHAR(255),
    location NVARCHAR(255),
    date DATETIME,
    population NUMERIC,
    new_vaccinations NUMERIC,
    total_vaccinations NUMERIC
);

INSERT INTO #PopulationvsVaccinations
SELECT 
    cv.continent,
    cv.location,
    cv.date,
    population,
    new_vaccinations,
    SUM(CONVERT(FLOAT, new_vaccinations)) 
        OVER (PARTITION BY cd.location 
              ORDER BY cd.location, cd.date) AS "total vaccinations"
FROM SolidProject..CovidDeaths cd
JOIN SolidProject..CovidVaccinations cv
    ON cd.date = cv.date
    AND cd.location = cv.location
WHERE cd.continent IS NOT NULL 
  AND cd.population IS NOT NULL 
  AND cd.location LIKE '%South Africa%';

SELECT *, (total_vaccinations / population) * 100 AS "rate of the vaccinated"
FROM #PopulationvsVaccinations;

/*
Purpose: Achieves the same result as the CTE approach but persists the intermediate results in a temporary table, 
which can be useful for performance optimization or multi-step analyses.
*/


--------------------------------------------------------------------THE END---------------------------------------------------------------------------------------------------------------------------
