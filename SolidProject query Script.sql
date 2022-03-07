/* 

Queries to be used for presentation in Tableau

*/


--- 1. Death rate in the world
select location, SUM(cast(new_cases as float)) as "total cases", sum(cast(new_deaths as float)) as "total death", (sum(cast(new_deaths as float))/sum(cast(new_cases as float)))*100 as "Death Rate"
from SolidProject..CovidDeaths 
--Where location like '%south africa%'
Where continent is not null and population is not null
group by location
order by "Death Rate" desc

--- 2. Death rate locally
select location, SUM(cast(new_cases as float)) as "total cases", sum(cast(new_deaths as float)) as "total death", (sum(cast(new_deaths as float))/sum(cast(new_cases as float)))*100 as "Death Rate"
from SolidProject..CovidDeaths 
Where location like '%south africa%' 
--where continent is not null and population is not null
group by location
--order by 1,2


-- 3. Total number of deaths by Continents
select continent, SUM(cast(new_deaths as float)) as "Death Count"
from SolidProject..CovidDeaths 
Where continent is not null and population is not null
group by continent
ORDER BY "Death Count"

-- 4. Total numer of deaths Globally
select location, SUM(cast(new_deaths as float)) as "Death Count"
from SolidProject..CovidDeaths 
Where continent is null and location like '%World%'
group by location
ORDER BY "Death Count"

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