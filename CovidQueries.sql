USE CovidProject	

-- DATA EXPLORATION

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--QUERIES REGARDING COUNTRIES



--Total Cases vs Total deaths per day for a single country
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS NUMERIC)/CAST(total_cases AS NUMERIC))*100 AS DeathPercentage 
	FROM dbo.CovidDeaths$
	WHERE location = 'South Korea' AND continent IS NOT NULL
	ORDER BY 1,2 ASC

--Total Cases vs population per day for a single country
SELECT location, date, population, total_cases, (CAST(total_cases AS NUMERIC)/CAST(population AS NUMERIC))*100 AS PercentPopulationInfected 
	FROM dbo.CovidDeaths$
	WHERE location = 'South Korea' AND continent IS NOT NULL
	ORDER BY 1,2

-- Percent of Population Infected, grouped by country
SELECT location, population, MAX(CAST(total_cases AS NUMERIC)) AS HighestInfectionCount, MAX((total_cases/population)*100) AS PercentPopulationInfected 
	FROM dbo.CovidDeaths$
	WHERE continent IS NOT NULL
	GROUP BY location, population
	ORDER BY PercentPopulationInfected DESC



--QUERIES REGARDING CONTINENTS



-- Death count, grouped by continent
SELECT location, MAX(CAST(total_deaths as int)) AS TotalDeathCount 
	FROM dbo.CovidDeaths$
	WHERE continent IS NULL
	GROUP BY location
	ORDER BY TotalDeathCount DESC

-- Total Cases vs Total Deaths per day, partitioned by continent
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS NUMERIC)/CAST(total_cases AS NUMERIC))*100 AS DeathPercentage 
	FROM dbo.CovidDeaths$
	WHERE continent IS NULL
	ORDER BY 1,2

-- Total Cases vs Population per day, partitioned by continent
SELECT location, date, population, total_cases, (CAST(total_cases AS NUMERIC)/CAST(population AS NUMERIC))*100 AS PercentPopulationInfected 
	FROM dbo.CovidDeaths$
	WHERE continent IS NULL
	ORDER BY 1,2

-- Percent of Population Infected, grouped by continent
SELECT location, population, MAX(CAST(total_cases AS NUMERIC)) AS HighestInfectionCount, MAX((CAST(total_cases AS NUMERIC)/CAST(population AS NUMERIC))*100) AS HighestCovidCasePercentage 
	FROM dbo.CovidDeaths$
	WHERE continent IS NULL
	GROUP BY location, population
	ORDER BY HighestCovidCasePercentage DESC



--QUERIES REGARDING GLOBAL NUMBERS



-- Total Cases vs Total Deaths per day globally
SELECT date, TotalCases, TotalDeaths, TotalDeaths/TotalCases*100 AS DeathPercentage FROM
(SELECT date, SUM(CAST(new_cases AS NUMERIC)) AS TotalCases, SUM(CAST(new_deaths AS NUMERIC)) AS TotalDeaths
	FROM dbo.CovidDeaths$
	WHERE continent IS NOT NULL 
	GROUP BY date) AS subquery
	WHERE TotalCases != 0
	ORDER BY date ASC

-- Total Cases vs Total Deaths All Time
SELECT SUM(CAST(new_cases AS NUMERIC)) AS TotalCases, SUM(CAST(new_deaths AS NUMERIC)) AS TotalDeaths, SUM(CAST(new_deaths AS NUMERIC))/SUM(CAST(new_cases AS NUMERIC))*100 AS DeathPercentage
	FROM dbo.CovidDeaths$
	WHERE continent IS NOT NULL 


-- Percent of Population vaccinated per day, partitioned by country
WITH POPvsVAC AS

(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.people_vaccinated AS RollingNumberOfPeopleVaccinated
	FROM dbo.CovidDeaths$ AS dea
	JOIN dbo.CovidVaccinations$ AS vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL 
)

SELECT *, ROUND((RollingNumberOfPeopleVaccinated/population)*100,8) AS PercentPopulationVaccinated
	FROM POPvsVAC
	ORDER BY location, date ASC
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--QUERIES USED FOR TABLEAU VISUALIZATION



-- Total Cases vs Total Deaths All Time
SELECT SUM(CAST(new_cases AS NUMERIC)) AS TotalCases, SUM(CAST(new_deaths AS NUMERIC)) AS TotalDeaths, SUM(CAST(new_deaths AS NUMERIC))/SUM(CAST(new_cases AS NUMERIC))*100 AS DeathPercentage
	FROM dbo.CovidDeaths$
	WHERE continent IS NOT NULL 

-- Total death count, grouped by continent
SELECT location AS continent, SUM(CAST(new_deaths AS INT)) AS TotalDeathCount
	FROM dbo.CovidDeaths$
	WHERE continent IS NULL AND location NOT IN ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
	GROUP BY location
	ORDER BY TotalDeathCount DESC


-- Percentage of Population that is infected, grouped by location
SELECT location AS country, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)*100) AS PercentPopulationInfected 
	FROM dbo.CovidDeaths$
	WHERE continent IS NOT NULL
	GROUP BY location, population
	ORDER BY PercentPopulationInfected DESC


-- Rolling Percentage of Population that is infected, partitioned by country
WITH CTE AS
(
SELECT location, date, population, new_cases, SUM(new_cases) OVER (PARTITION BY location ORDER BY date ASC) AS NewCasesRollingSum
	FROM dbo.CovidDeaths$
	WHERE continent IS NOT NULL
)

SELECT *, CAST(NewCasesRollingSum AS NUMERIC)/CAST(population AS NUMERIC) * 100 AS PopulationPercentInfected 
	FROM CTE
	ORDER BY location,date ASC


-- Percent of Population vaccinated per day, partitioned by country
WITH POPvsVAC AS

(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.people_vaccinated AS RollingNumberOfPeopleVaccinated
	FROM dbo.CovidDeaths$ AS dea
	JOIN dbo.CovidVaccinations$ AS vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL 
)

SELECT location, date, ISNULL(PercentPopulationVaccinated,0) AS PercentPopulationVaccinated
	FROM (SELECT *, ROUND((RollingNumberOfPeopleVaccinated/population)*100,8) AS PercentPopulationVaccinated FROM POPvsVAC) AS subquery
	WHERE PercentPopulationVaccinated != 0
	ORDER BY location, date ASC