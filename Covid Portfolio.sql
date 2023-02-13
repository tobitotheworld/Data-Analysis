/* Because of how large this dataset is, I'm only going to be using a select few of the columns. Which are: location, date, total_cases, 
new_cases,total_deaths,population. As seen below */

SELECT
	location,
	date,
	total_cases,
    new_cases,
    total_deaths,
     population
FROM coviddeaths
ORDER BY location, date;


-- I'll be using Canada as my case study as it's my country of residence -- 

-- Task 1a: Extract the data for Total cases vs Total Deaths in Canada ---

SELECT
	location,
    date,
    total_cases,
    total_deaths
FROM coviddeaths
WHERE location =  'Canada' ;  

-- Task 1b: Extract the percentage outcome of Total cases vs Total Deaths in Canada. ---

SELECT
	location,
    date,
    total_cases,
    total_deaths,
	(total_deaths * 100/total_cases) AS 'Percentage of Death'
FROM coviddeaths
WHERE location =  'Canada'  
ORDER BY location AND date;

/* NOTE: the result set tells you the chances you have to die if you caught COVID in Canada.
For example, if you catch the virus by this date 3/30/2021 your chances of survival is 2.36% */
 
 
-- Task 3a: -- Extract the total cases vs the Population in Canada --

SELECT
	location,
	date,
	total_cases
	population 
FROM coviddeaths
WHERE location ='Canada'
ORDER BY location AND date;

  
  -- Task 3b: -- Also, extract the Percentage total cases vs the Population in Canada --
  
  SELECT
	location,
	date,
    population,
	total_cases,
    round(total_cases * 100/population,2) AS 'Percentage of Canadians Affected'
FROM coviddeaths
WHERE location ='Canada'
ORDER BY location AND date;

-- NOTE: with this info, I'm able to know what percentage of people had Covid rounded to 2 decimal places)


-- Task 4: Country with the highest infection rate --

SELECT
    location,
	SUM(total_cases) AS TotalCasesCount
FROM coviddeaths
GROUP BY location
ORDER BY TotalCasesCount DESC;

-- ANSWER: Europe has the highest cases by continent. Specifically, United States is the country with the highest cases (5094206088).



-- Task 5: Country with the Maximum infection rate compared to its population --

SELECT
	location,
    population,
	MAX(total_cases) AS 'Max Infections',
    MAX(total_cases * 100/population) AS MAXPercentagePopulationAffected
FROM coviddeaths
GROUP BY location, population
ORDER BY MAXPercentagePopulationAffected DESC;


-- Task 5b: Countries with the Maximum death --


SELECT 
	location, 
	CAST(MAX(total_deaths AS INT) AS HighestDeath 
FROM coviddeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY HighestDeath DESC;


-- GLOBAL NUMBERS

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
--Where location like '%canada%'
where continent is not null 
--Group By date
order by 1,2



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 








-- VERSION 2 (A LONGER METHOD): JOINING TABLES (covid deaths and covid vaccination): to find out total number of people vaxxed in the world --


		-- 1a. FIRST, I'll create a view to store the total population in each continent --
CREATE VIEW PopulationSum AS
SELECT continent, SUM(population) AS sumpop
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent;

		-- 1b. Create a View to store the actual number of the total population (for the purpose of easy recall)--

CREATE VIEW worldpop AS
SELECT SUM(sumpop) AS worldpopSum
FROM PopulationSum;


		-- 2a. Create a View to store the total population in each continent --

CREATE VIEW FullyVaxxed AS
SELECT continent, SUM(people_fully_vaccinated) as FullyVaxed
FROM covidvaccinations
GROUP BY continent;

		-- 2b. Create a View  the actual number of the total population that is vaxxed (for the purpose of easy recall) --

CREATE VIEW FullyVaxedPop AS
SELECT SUM(FullyVaxed) AS FullyVaxedSum
FROM FullyVaxxed;


-------------

SELECT SUM(sumpop)
FROM PopulationSum;


SELECT worldpopSum, FullyVaxedSum
FROM worldpop w
JOIN fullyvaxedpop f
	ON w.worldpopSum = f.FullyVaxedSum;


