USE [Covid Vaccination-Death Analysis]

Select * from [covid-deaths] order by location, total_cases
select * from [covid-vaccinations]

---------Transforming data

--Changing column data types
ALTER TABLE [covid-deaths]
ALTER COLUMN total_deaths float

ALTER TABLE [covid-deaths]
ALTER COLUMN total_cases float

ALTER TABLE [covid-vaccinations]
ALTER COLUMN new_vaccinations bigint




--Performing analysis on covid-death table

--Analyzing total case vs total death in Canada and Bangladesh
SELECT location, date, population, total_cases, total_deaths, (total_deaths/total_cases)*100 as percent_died
FROM [covid-deaths] 
WHERE location='Canada' AND total_deaths > 0
ORDER BY location,date

SELECT location, date, population, total_cases, total_deaths, (total_deaths/total_cases)*100 as percent_died
FROM [covid-deaths] 
WHERE location='Bangladesh' AND total_deaths > 0
ORDER BY date

--Analyzing total cases vs population
SELECT location, date, population, total_cases, (total_cases/population)*100 as percent_infected
FROM [covid-deaths] 
WHERE location='Canada' AND total_cases > 0
ORDER BY date

--Analyzing total deaths vs population
SELECT location, date, population, total_deaths, (total_deaths/population)*100 as percent_died
FROM [covid-deaths] 
WHERE location='Canada' AND total_deaths > 0
ORDER BY date

--Country with highest infection rate per population, death rate per case, death rate per population
SELECT location, population, MAX(total_cases) as overall_cases, MAX(total_cases/population)*100 as percent_infected
FROM [covid-deaths] 
WHERE continent is not null
GROUP BY location, population
ORDER By percent_infected DESC

--Countried with highest death rate per case
SELECT location, MAX(total_cases) as overall_cases, MAX(total_deaths) as overall_deaths ,(MAX(total_deaths)/MAX(total_cases))*100 as percent_died_case
FROM [covid-deaths] 
WHERE continent is not null
GROUP BY location
ORDER By percent_died_case DESC

--Countries wtih highest death rate per population
SELECT location, population, MAX(total_deaths) as overall_deaths ,(MAX(total_deaths)/population)*100 as percent_died_per_population
FROM [covid-deaths] 
WHERE continent is not null
GROUP BY location, population
ORDER By percent_died_per_population DESC


--Overall cases and deaths by continents

SELECT continent, SUM(population) as total_population,SUM(cases) as total_cases, SUM(deaths) as total_deaths, 
	(SUM(cases)/SUM(population)) * 100 as percent_infected, (SUM(deaths)/SUM(population)) * 100 as percent_died_per_population,  
	(SUM(deaths)/SUM(cases)) * 100 as percent_died_per_case
FROM (
	-- All Country's total data
	SELECT continent, location, MAX(population) as population, MAX(total_cases) as cases, MAX(total_deaths) as deaths
	FROM [covid-deaths]
	WHERE continent is not null
	Group By continent, location
	) as Continents
Group BY continent
ORDER By continent

--Looking at the Sub-query data above, we can see that the continent data is put under locations where the continent is NULL, so we can use the following as well to grab the continental data

SELECT location, population,MAX(total_cases) as total_cases, MAX(total_deaths) as total_Deaths, MAX(population) as total_population
FROM [covid-deaths]
WHERE continent is null AND location NOT LIKE '%Income%' AND location NOT LIKE '%Union%' and location NOT LIKE '%WORLD%'
GROUP BY location, population
Order By location


--Analyzing Worldwide data by date
SELECT location, date, population, total_cases, total_deaths, (total_cases/population)*100 as percent_infected,
		(total_deaths/population)*100 as percent_died_population, (total_deaths/total_cases)*100 as percent_died_cases
FROM [covid-deaths] 
WHERE location='World'
ORDER BY date


--Overall worldwide statistic up to March 7th
SELECT location, MAX(total_cases) as total_cases, MAX(total_deaths) as total_deaths, (MAX(total_cases)/population)*100 as percent_infected,
		(MAX(total_deaths)/population)*100 as percent_died_population, (MAX(total_deaths)/MAX(total_cases))*100 as percent_died_cases
FROM [covid-deaths] 
WHERE location='World'
GROUP BY location, population



------Joining covid-deaths with covid-vaccination to view total population vs Vaccination--------

SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations
FROM [covid-deaths] deaths
JOIN [covid-vaccinations] vac 
	on deaths.location = vac.location
	AND deaths.date = vac.date
WHERE deaths.continent is not null
ORDER BY 1,2



--Using Common Table Expression (CTE)
With PopvsVac (Continent,Location, Date, Population, New_Vaccination, RollingVaccination)
as
(
 --Using sum of new vaccination instead of total vaccination
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (Partition by deaths.location ORDER BY deaths.location, deaths.date) as RollingVaccination

FROM [covid-deaths] deaths
JOIN [covid-vaccinations] vac 
	on deaths.location = vac.location
	AND deaths.date = vac.date
WHERE deaths.continent is not null
)
Select * , (RollingVaccination/Population)*100 as PercentVaccinated
FROM PopvsVac


--Using Temp table
DROP TABLE If exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(Continent nvarchar(255), Location nvarchar(255), Date datetime, Population numeric, New_vaccinations numeric, RollingVaccination numeric)

Insert Into #PercentPopulationVaccinated
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (Partition by deaths.location ORDER BY deaths.location, deaths.date) as RollingVaccination

FROM [covid-deaths] deaths
JOIN [covid-vaccinations] vac 
	on deaths.location = vac.location
	AND deaths.date = vac.date
--WHERE deaths.continent is not null
--order by 2,3

Select * , (RollingVaccination/Population)*100 as PercentVaccinated
FROM #PercentPopulationVaccinated


-------Creating Views to store data for Tableau visualization

--Worldwide data view
Create View WorldWideData as 
SELECT location, MAX(total_cases) as total_cases, MAX(total_deaths) as total_deaths, (MAX(total_cases)/population)*100 as percent_infected,
		(MAX(total_deaths)/population)*100 as percent_died_population, (MAX(total_deaths)/MAX(total_cases))*100 as percent_died_cases
FROM [covid-deaths] 
WHERE location='World'
GROUP BY location, population

--Continent data view
Create View ContinentData as
SELECT continent, SUM(population) as total_population,SUM(cases) as total_cases, SUM(deaths) as total_deaths, 
	(SUM(cases)/SUM(population)) * 100 as percent_infected, (SUM(deaths)/SUM(population)) * 100 as percent_died_per_population,  
	(SUM(deaths)/SUM(cases)) * 100 as percent_died_per_case
FROM (
	-- All Country's total data
	SELECT continent, location, MAX(population) as population, MAX(total_cases) as cases, MAX(total_deaths) as deaths
	FROM [covid-deaths]
	WHERE continent is not null
	Group By continent, location
	) as Continents
Group BY continent

--Country data view
Create View CountryData as 
SELECT location, population, MAX(total_cases) as overall_cases, MAX(total_cases/population)*100 as percent_infected, 
(MAX(total_deaths)/MAX(total_cases))*100 as percent_died_case,(MAX(total_deaths)/population)*100 as percent_died_per_population
FROM [covid-deaths] 
WHERE continent is not null
GROUP BY location, population

--Country's vaccination view
Create View CountryVacData as 
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (Partition by deaths.location ORDER BY deaths.location, deaths.date) as RollingVaccination

FROM [covid-deaths] deaths
JOIN [covid-vaccinations] vac 
	on deaths.location = vac.location
	AND deaths.date = vac.date
WHERE deaths.continent is not null
