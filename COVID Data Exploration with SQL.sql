-- COVID Data Exploration Project
-- This project was done on GCP BigQuery
-- Demonstrated Skills: 
-- Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, 
-- Creating View;


-- Verifying if import was successful

SELECT *
FROM portfolio234.covid.covid_deaths
WHERE continent is not null
ORDER BY 3,4

SELECT *
FROM portfolio234.covid.covid_vaccines
ORDER BY 3,4

-- Selecting data to be used

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM portfolio234.covid.covid_deaths
WHERE continent is not null
ORDER BY 1,2


-- COUNTRY NUMBERS

-- Comparing Total Cases with Total Deaths
-- Shows probability of dying after getting COVID
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
WHERE continent is not null
FROM portfolio234.covid.covid_deaths
ORDER BY 1,2

-- Viewing my country's death percentage

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM portfolio234.covid.covid_deaths
WHERE location = 'Philippines'
ORDER BY 1,2

-- Comparing Total Cases with Total Population (PH)
-- Shows what percentage of the population got COVID; infection rate

SELECT location, date, total_cases, population, (total_cases/population)*100 AS infected_percentage
FROM portfolio234.covid.covid_deaths
WHERE location = 'Philippines'
ORDER BY 1,2

-- Finding out when was the date that PH got the most deaths resulting from COVID

SELECT location, date, MAX(total_deaths) AS max_deaths
FROM portfolio234.covid.covid_deaths
WHERE location = 'Philippines'
GROUP BY 1,2
ORDER BY 3 DESC

-- Looking at Countries with Highest Infected Count Compared to Population
-- Cyprus had 73.76% of its population infected with COVID

SELECT location, MAX(total_cases) AS total_infection_count, population, MAX((total_cases/population))*100 AS infected_percentage
FROM portfolio234.covid.covid_deaths
WHERE continent is not null
GROUP BY location, population
ORDER BY 4 DESC

-- Showing Countries with Highest Death Count per Population

SELECT location, MAX(total_deaths) AS total_death_count, population, MAX((total_deaths/population))*100 AS death_percentage
FROM portfolio234.covid.covid_deaths
WHERE location != continent
GROUP BY location, population
ORDER BY 2 DESC



-- CONTINENTAL NUMBERS

-- Showing Continents with Highest Death Count

SELECT continent, MAX(total_deaths) AS total_death_count
FROM portfolio234.covid.covid_deaths
WHERE continent is not null
GROUP BY continent
ORDER BY 2 DESC

-- Showing Continents with Highest Death Count per Population

SELECT continent, MAX(total_deaths) AS total_death_count,population, MAX((total_deaths/population))*100 AS death_percentage
FROM portfolio234.covid.covid_deaths
WHERE continent is not null
GROUP BY continent, population
ORDER BY 2 DESC



-- GLOBAL NUMBERS

-- Viewing daily changes in the amount of reported cases and deaths

SELECT date, SUM(new_cases) AS total_reported_cases, SUM(new_deaths) AS total_reported_deaths, SUM(new_deaths)/NULLIF(SUM(new_cases), 0) AS death_percentage
FROM portfolio234.covid.covid_deaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

-- Viewing total amount of reported cases and deaths

SELECT SUM(new_cases) AS total_reported_cases, SUM(new_deaths) AS total_reported_deaths, SUM(new_deaths)/NULLIF(SUM(new_cases), 0) AS death_percentage
FROM portfolio234.covid.covid_deaths
WHERE continent is not null

-- Starting to JOIN covid_deaths and covid_vaccines table

SELECT *
FROM portfolio234.covid.covid_deaths AS dea
JOIN portfolio234.covid.covid_vaccines AS vac
ON dea.location = vac.location AND
   dea.date = vac.date

-- Looking at Total Vaccinations compared with Total Population  

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS latest_vaccination_amount
FROM portfolio234.covid.covid_deaths AS dea
JOIN portfolio234.covid.covid_vaccines AS vac
ON dea.location = vac.location AND
   dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- Using CTE to find out what percentage of the population is vaccinated

WITH PopvsVac AS
(
SELECT dea.continent, dea.location, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS latest_vaccination_amount
FROM portfolio234.covid.covid_deaths AS dea
JOIN portfolio234.covid.covid_vaccines AS vac
ON dea.location = vac.location AND
   dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3
)

SELECT *, (latest_vaccination_amount/population)*100 AS vaccinated_percentage
FROM PopvsVac
GROUP BY 1,2

-- Creating Temp Table to see what percentage of the population is vaccinated

DROP TABLE IF EXISTS portfolio234.covid.covid_vaccines2;
CREATE TABLE portfolio234.covid.covid_vaccines2
(
continent string, 
location string, 
population string, 
new_vaccinations int64, 
latest_vaccination_amount float64
);

INSERT INTO portfolio234.covid.covid_vaccines2 
(SELECT dea.continent, dea.location, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS latest_vaccination_amount
FROM portfolio234.covid.covid_deaths AS dea
JOIN portfolio234.covid.covid_vaccines AS vac
ON dea.location = vac.location AND
   dea.date = vac.date);

SELECT *, (latest_vaccination_amount/population)*100 AS vaccinated_percentage
FROM portfolio234.covid.covid_vaccines2


-- Creating a view for later visualizations

DROP TABLE IF EXISTS portfolio234.covid.covid_vaccines2;
CREATE VIEW portfolio234.covid.covid_vaccines2 AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location ORDER BY dea.location, dea.Date)AS RollingPeopleVaccinated
FROM portfolio234.covid.covid_deaths dea
JOIN portfolio234.covid.covid_vaccines vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null 
