/* 

Queries to be used for presentation in Tableau

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
select location,date,  MAX(cast(new_cases as float)) as "Highest number of new cases", MAX(cast(total_cases as float)) as "Highest number of cases", (MAX(cast(new_cases as float))/MAX(cast(total_cases as float)))*100 as "Infection Rate"
from SolidProject..CovidDeaths
where continent is not null and population is not null
group by location, date
order by date, [Infection rate]

--joining the two tables

Select *
from SolidProject..CovidDeaths cd
join SolidProject..CovidVaccinations cv
	on cd.date=cv.date
	and cd.location=cv.location

--looking at total Population vs total number of Vaccination per day in South Africa
Select cv.continent, cv.location, cv.date, population, new_vaccinations, SUM(CONVERT(float, new_vaccinations))
														over(PARTITION by cd.location
														order by cd.location, cd.date)
														as "total vaccinations"
from SolidProject..CovidDeaths cd
join SolidProject..CovidVaccinations cv
	on cd.date=cv.date
	and cd.location=cv.location
where cd.continent is not NULL and cd.population is not null and cd.location like '%south africa%'
order by 2,3


--Using CTE
with PopvsVac (continent, location, date, population, new_vaccinations, total_vaccinations) as (
Select cv.continent, cv.location, cv.date, population, new_vaccinations, SUM(CONVERT(float, new_vaccinations))
														over(PARTITION by cd.location
														order by cd.location, cd.date)
														as "total vaccinations"
from SolidProject..CovidDeaths cd
join SolidProject..CovidVaccinations cv
	on cd.date=cv.date
	and cd.location=cv.location
where cd.continent is not NULL and cd.population is not null and cd.location like '%south africa%'
--order by 2,3 (the 'order by' clause is invalide in a CTE)
)


-- Using CTE to add a Percentage of vaccinated population Column
select *, (total_vaccinations/population)*100 as "rate of the vaccinated" 
from PopvsVac


--Using a TEMP TABLE
Drop table if exists #PopulationvsVaccinations
Create table #PopulationvsVaccinations
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
total_vaccinations numeric,
)
Insert into #PopulationvsVaccinations
Select cv.continent, cv.location, cv.date, population, new_vaccinations, SUM(CONVERT(float, new_vaccinations))
														over(PARTITION by cd.location
														order by cd.location, cd.date)
														as "total vaccinations"
from SolidProject..CovidDeaths cd
join SolidProject..CovidVaccinations cv
	on cd.date=cv.date
	and cd.location=cv.location
where cd.continent is not NULL and cd.population is not null and cd.location like '%south africa%'

-- Using TEMP TABLE to add a Percentage of vaccinated population Column
select *, (total_vaccinations/population)*100 as "rate of the vaccinated" 
from #PopulationvsVaccinations


--------------------------------------------------------------------THE END---------------------------------------------------------------------------------------------------------------------------
