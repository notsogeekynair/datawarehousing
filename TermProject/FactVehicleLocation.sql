--create FactVehicleLocation 

drop table FactVehicleLoc
create table FactVehicleLoc (
    FactLocationID UNIQUEIDENTIFIER PRIMARY KEY,
    VehicleID UNIQUEIDENTIFIER,                   
    LocationID UNIQUEIDENTIFIER,
	VIN varchar(50),
    Latitude DECIMAL(10,7),                       
    Longitude DECIMAL(10,7)
	)

--insert data into fact
INSERT INTO FactVehicleLoc (FactLocationID, VehicleID, LocationID, VIN, Latitude, Longitude)
SELECT
    NEWID(),
    dv.VehicleID, 
    dl.LocationID,
    dv.VIN,
    CAST(
        SUBSTRING(dv.FullLocation, 
            CHARINDEX('(', dv.FullLocation) + 1, 
            CHARINDEX(' ', dv.FullLocation, CHARINDEX('(', dv.FullLocation)) - CHARINDEX('(', dv.FullLocation) - 1
        ) AS DECIMAL(10,7)
    ) AS Latitude,
    CAST(
        SUBSTRING(dv.FullLocation, 
            CHARINDEX(' ', dv.FullLocation, CHARINDEX('(', dv.FullLocation)) + 1, 
            CHARINDEX(')', dv.FullLocation) - CHARINDEX(' ', dv.FullLocation, CHARINDEX('(', dv.FullLocation)) - 1
        ) AS DECIMAL(10,7)
    ) AS Longitude
FROM
    DimVehicle dv
JOIN
    DimLocation dl ON dv.LocationID = dl.LocationID
WHERE
    dv.FullLocation IS NOT NULL;


--total vehicles by county
SELECT 
    dl.County, 
    COUNT(fvl.VehicleID) AS TotalVehicles
FROM 
    FactVehicleLoc fvl
JOIN 
    DimLocation dl ON fvl.LocationID = dl.LocationID
GROUP BY 
    dl.County
ORDER BY 
    TotalVehicles DESC;

--top cities with most registered vehicles
SELECT 
    dl.City, 
    COUNT(fvl.VehicleID) AS VehicleCount
FROM 
    FactVehicleLoc fvl
JOIN 
    DimLocation dl ON fvl.LocationID = dl.LocationID
GROUP BY 
    dl.City
ORDER BY 
    VehicleCount DESC;


--market expansion opportunities
SELECT 
    dl.City, 
    COUNT(fvl.VehicleID) AS TotalVehicles
FROM 
    FactVehicleLoc fvl
JOIN 
    DimLocation dl ON fvl.LocationID = dl.LocationID
	WHERE State = 'WA'
GROUP BY 
    dl.City
ORDER BY 
    TotalVehicles ASC 

--county-city pairs with less than 100 EVs

SELECT 
    dl.County,
    dl.City,
    COUNT(fvl.VehicleID) AS TotalVehicles
FROM 
    FactVehicleLoc fvl
JOIN 
    DimLocation dl ON fvl.LocationID = dl.LocationID
	where dl.State='WA'
GROUP BY 
    ROLLUP(dl.County, dl.City)
ORDER BY 
    dl.County, dl.City;

--county wise distribution of vehicles in percentage
WITH Total AS (
    SELECT COUNT(*) AS TotalVehicles FROM FactVehicleLoc
)
SELECT 
    dl.County,
    COUNT(fvl.VehicleID) AS CountyTotal,
    (COUNT(fvl.VehicleID) * 100.0 / (SELECT TotalVehicles FROM Total)) AS PercentOfTotal
FROM 
    FactVehicleLoc fvl
JOIN 
    DimLocation dl ON fvl.LocationID = dl.LocationID
GROUP BY 
    dl.County
ORDER BY 
    PercentOfTotal DESC;