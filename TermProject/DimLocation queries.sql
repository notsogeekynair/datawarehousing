CREATE TABLE DimLocation (
    LocationID UNIQUEIDENTIFIER PRIMARY KEY,    
    State VARCHAR(100),
    County VARCHAR(100),
    City VARCHAR(100),
    PostalCode VARCHAR(20)
);
drop table DimLocation
--populating DimLocation
insert into DimLocation(LocationID,State,County,City,PostalCode)
SELECT 
    NEWID() AS LocationID,    
    ps.State,                
    ps.County,               
    ps.City,                  
    ps.Postal_Code            
FROM 
    DimVehicle dv
JOIN 
    population_staging ps ON dv.VIN = ps.VIN 
WHERE 
    ps.State IS NOT NULL     
    AND ps.City IS NOT NULL  
GROUP BY 
    ps.State, ps.County, ps.City, ps.Postal_Code; 

	select * from DimLocation where State ='WA' order by State,County

--ETL Process

--identify records that need to be updated
WITH NewLocations AS (
    SELECT 
        NEWID() AS LocationID,
        ps.State,                
        ps.County,               
        ps.City,                  
        ps.Postal_Code,
        dv.VIN                   
    FROM 
        population_staging ps
    JOIN 
        DimVehicle dv ON ps.VIN = dv.VIN 
    WHERE 
        ps.State IS NOT NULL     
        AND ps.City IS NOT NULL  
)

-- update existing records
UPDATE dl
SET 
    dl.State = nl.State,
    dl.County = nl.County,
    dl.City = nl.City,
    dl.PostalCode = nl.Postal_Code
FROM 
    DimLocation dl
JOIN 
    NewLocations nl ON dl.VIN = nl.VIN
WHERE 
    dl.State != nl.State
    OR dl.County != nl.County
    OR dl.City != nl.City
    OR dl.PostalCode != nl.Postal_Code

--insert new records 
INSERT INTO DimLocation (LocationID, State, County, City, PostalCode)
SELECT 
    NEWID() AS LocationID, 
    ps.State, 
    ps.County, 
    ps.City, 
    ps.Postal_Code
FROM 
    population_staging ps
WHERE 
    NOT EXISTS (
        SELECT 1
        FROM DimLocation dl
        WHERE dl.State = ps.State
        AND dl.County = ps.County
        AND dl.City = ps.City
        AND dl.PostalCode = ps.Postal_Code
    )
    AND ps.State IS NOT NULL
    AND ps.City IS NOT NULL
GROUP BY 
    ps.State, ps.County, ps.City, ps.Postal_Code

	select * from DimLocation