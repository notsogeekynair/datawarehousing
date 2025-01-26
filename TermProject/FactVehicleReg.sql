--table creation
drop table FactVehicleReg

CREATE TABLE FactVehicleReg (
    FactRegID UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), 
    VIN VARCHAR(50),                                        
    VehicleID UNIQUEIDENTIFIER,                             
    LatestDOL INT,                        
    TotalRegistrations INT,                                 
    TotalCost DECIMAL(18,2),                                 
    ActiveRegistrations INT,                                 
    InactiveRegistrations INT,                              
    LatestRegistrationDate DATE,
    LocationID UNIQUEIDENTIFIER,                            
    TimeID UNIQUEIDENTIFIER                                 
);
--query to populate fact
WITH RegistrationSummary AS (
    SELECT
        VehicleID,
        COUNT(VehicleID) AS TotalRegistrations,
        SUM(TransactionCost) AS TotalCost,
        COUNT(CASE WHEN CAST(GETDATE() AS DATE) BETWEEN StartDate AND EndDate THEN 1 END) AS ActiveRegistrations,
        COUNT(CASE WHEN CAST(GETDATE() AS DATE) NOT BETWEEN StartDate AND EndDate THEN 1 END) AS InactiveRegistrations
    FROM DimRegistration
    GROUP BY VehicleID
),
LatestRegistration AS (
    SELECT
        VehicleID,
        DOL_Vehicle_ID,
        StartDate,
        ROW_NUMBER() OVER (PARTITION BY VehicleID ORDER BY StartDate DESC) AS RowNum
    FROM DimRegistration
),
RegistrationWithTimeLocation AS (
    SELECT
        lr.VehicleID,
        lr.DOL_Vehicle_ID,
        lr.StartDate,
        ls.TotalRegistrations,
        ls.TotalCost,
        ls.ActiveRegistrations,
        ls.InactiveRegistrations,
        dv.LocationID,
        dt.TimeID
    FROM LatestRegistration lr
    JOIN RegistrationSummary ls ON lr.VehicleID = ls.VehicleID
    JOIN DimVehicle dv ON lr.VehicleID = dv.VehicleID
    JOIN DimTime dt ON dt.Date = CAST(lr.StartDate AS DATE)  
    WHERE lr.RowNum = 1  
)
INSERT INTO FactVehicleReg (VIN, VehicleID, LatestDOL, TotalRegistrations, TotalCost, ActiveRegistrations, InactiveRegistrations, LatestRegistrationDate, LocationID, TimeID)
SELECT 
    dv.VIN,
    r.VehicleID,
    r.DOL_Vehicle_ID, 
    r.TotalRegistrations,
    r.TotalCost,
    r.ActiveRegistrations,
    r.InactiveRegistrations,
    r.StartDate AS LatestRegistrationDate, 
    r.LocationID, 
    r.TimeID 
FROM RegistrationWithTimeLocation r
JOIN DimVehicle dv ON r.VehicleID = dv.VehicleID;

select * from FactVehicleReg

--cumulative snapshot
WITH CumulativeSnapshot AS (
    SELECT
        f.VehicleID,
        f.VIN,
        f.LatestDOL,
        f.TotalRegistrations,
        f.TotalCost,
        f.ActiveRegistrations,
        f.InactiveRegistrations,
        f.LatestRegistrationDate,
        f.LocationID,
        f.TimeID,
        SUM(f.TotalRegistrations) OVER (PARTITION BY f.VehicleID ORDER BY f.TimeID) AS CumulativeTotalRegistrations,
        SUM(f.TotalCost) OVER (PARTITION BY f.VehicleID ORDER BY f.TimeID) AS CumulativeTotalCost,
        SUM(f.ActiveRegistrations) OVER (PARTITION BY f.VehicleID ORDER BY f.TimeID) AS CumulativeActiveRegistrations,
        SUM(f.InactiveRegistrations) OVER (PARTITION BY f.VehicleID ORDER BY f.TimeID) AS CumulativeInactiveRegistrations
    FROM FactVehicleReg f
)
SELECT
    ds.Year,
    ds.Month,
    cs.VehicleID,
    cs.VIN,
    SUM(cs.CumulativeTotalRegistrations) AS TotalRegistrationsByMonth,
    SUM(cs.CumulativeTotalCost) AS TotalCostByMonth,
    SUM(cs.CumulativeActiveRegistrations) AS ActiveRegistrationsByMonth,
    SUM(cs.CumulativeInactiveRegistrations) AS InactiveRegistrationsByMonth
FROM CumulativeSnapshot cs
JOIN DimTime ds ON cs.TimeID = ds.TimeID
GROUP BY ds.Year, ds.Month, cs.VehicleID, cs.VIN
ORDER BY ds.Year, ds.Month, cs.VehicleID;

select * from FactVehicleReg where VehicleID='9F639982-E286-4CFA-B53D-ADCBC73D12E5'