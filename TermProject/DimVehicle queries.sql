
--check for unique VINs
SELECT 
    VIN, 
    Make, 
    Model, 
    EVType,
    Model_Year AS ModelYear,
    MAX(DOL) AS LatestDOL
INTO #Activity_Vehicles --temporary table
FROM 
    activity_staging
GROUP BY 
    VIN, Make, Model, EVType, Model_Year;

SELECT 
    VIN, 
    Make, 
    Model, 
    EVType, 
    Model_Year AS ModelYear,
    MAX(DOL) AS LatestDOL
INTO #Population_Vehicles 
FROM 
    population_staging
GROUP BY 
    VIN, Make, Model, EVType, Model_Year;

SELECT 
    VIN, 
    Make, 
    Model, 
    EVType, 
    ModelYear,
    MAX(LatestDOL) AS LatestDOL
FROM (
    SELECT * FROM #Activity_Vehicles
    UNION ALL
    SELECT * FROM #Population_Vehicles
) AS CombinedVehicles
GROUP BY 
    VIN, Make, Model, EVType, ModelYear;

--DimVehicle
drop table DimVehicle
CREATE TABLE DimVehicle (
    VehicleID UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY, 
    VIN VARCHAR(17) UNIQUE NOT NULL,                         
    Make VARCHAR(50),                              
    Model VARCHAR(50),                              
    EVType VARCHAR(50),                        
    ModelYear INT NOT NULL                              
);

--inserting data into dimvehicle
WITH RankedVehicles AS (
    SELECT 
        NEWID() AS VehicleID, 
        VIN, 
        Make, 
        Model, 
        EVType,
        ModelYear,
        ROW_NUMBER() OVER (PARTITION BY VIN ORDER BY LatestDOL DESC) AS RowNum
    FROM (
        SELECT * FROM #Activity_Vehicles
        UNION ALL
        SELECT * FROM #Population_Vehicles
    ) AS CombinedVehicles
)

-- Insert only the latest row per VIN(no LatestDOL)
INSERT INTO DimVehicle (VehicleID, VIN, Make, Model, EVType, ModelYear)
SELECT 
    VehicleID, 
    VIN, 
    Make, 
    Model, 
    EVType, 
    ModelYear
FROM RankedVehicles
WHERE RowNum = 1;

select * from DimVehicle WHERE FullLocation is NULL
select distinct VIN from DimVehicle

--adding locationID as FK
ALTER TABLE DimVehicle
ADD CONSTRAINT FK_DimVehicle_Location
FOREIGN KEY (LocationID) REFERENCES DimLocation(LocationID);

ALTER TABLE DimVehicle
ADD FullLocation VARCHAR(255);

update dv
set dv.FullLocation = p.Vehicle_Location
from DimVehicle dv
join population_staging p
on dv.VIN = p.VIN

Alter table DimVehicle add LocationID UNIQUEIDENTIFIER

UPDATE dv
SET dv.LocationID = dl.LocationID
FROM DimVehicle dv
JOIN population_staging ps ON dv.VIN = ps.VIN  -- Joining on VIN
JOIN DimLocation dl 
    ON ps.State = dl.State 
    AND ps.County = dl.County 
    AND ps.City = dl.City
    AND ps.Postal_Code = dl.PostalCode;


--ETL Process

--select all newly added records in the staging table
MERGE DimVehicle AS Target
USING (
    WITH DeduplicatedVehicles AS (
        SELECT 
            VIN, Make, Model, ElectricVehicleType, ModelYear, FullLocation,
            ROW_NUMBER() OVER (PARTITION BY VIN ORDER BY UpdatedDate DESC) AS RowNum
        FROM pop_staging
    )
    SELECT * 
    FROM DeduplicatedVehicles
    WHERE RowNum = 1
) AS Source
ON Target.VIN = Source.VIN

--for updating exisitng records(not taking into account VIN change)
WHEN MATCHED THEN
    UPDATE SET
        Target.Make = Source.Make,
        Target.Model = Source.Model,
        Target.ElectricVehicleType = Source.ElectricVehicleType,
        Target.ModelYear = Source.ModelYear,
        Target.FullLocation = Source.FullLocation

-- for new records
WHEN NOT MATCHED BY Target THEN
    INSERT (VehicleID, VIN, Make, Model, ElectricVehicleType, ModelYear, FullLocation)
    VALUES (NEWID(), Source.VIN, Source.Make, Source.Model, Source.ElectricVehicleType, Source.ModelYear, Source.FullLocation);

