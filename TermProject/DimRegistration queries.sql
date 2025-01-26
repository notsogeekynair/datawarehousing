select * from activity_staging

--create DimRegistration
drop table DimRegistration
CREATE TABLE DimRegistration (
    RegistrationID UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), 
    VehicleID UNIQUEIDENTIFIER,
    DOL_Vehicle_ID INT,
    StartDate DATE,
    StartDateTimestamp datetime,
    EndDate DATE,
	TransactionType varchar(50),
	TransactionCost decimal(10,2),
    IsCurrent BIT
);

INSERT INTO DimRegistration (VehicleID, DOL_Vehicle_ID, StartDate, StartDateTimestamp, EndDate,TransactionType,TransactionCost, IsCurrent)
SELECT 
    dv.VehicleID,
    asg.DOL,
    asg.Registration_Date AS StartDate,  
	asg.Timestamp as StartDateTimestamp,
    DATEADD(YEAR, 1, asg.Registration_Date) AS EndDate,
	asg.Transaction_Type,
	asg.Cost,
    CASE 
        WHEN GETDATE() BETWEEN asg.Registration_Date AND DATEADD(YEAR, 1, asg.Registration_Date) THEN 1
        ELSE 0
    END AS IsCurrent
FROM 
    activity_staging asg
JOIN 
    DimVehicle dv ON asg.VIN = dv.VIN


	
WITH CTE_Duplicates AS (
    SELECT 
        DOL_Vehicle_ID, 
        StartDate, 
        TransactionType,
        ROW_NUMBER() OVER (PARTITION BY DOL_Vehicle_ID, StartDate, TransactionType ORDER BY StartDate) AS RowNum
    FROM DimRegistration
)
DELETE FROM DimRegistration
WHERE EXISTS (
    SELECT 1
    FROM CTE_Duplicates
    WHERE CTE_Duplicates.RowNum > 1
    AND CTE_Duplicates.DOL_Vehicle_ID = DimRegistration.DOL_Vehicle_ID
    AND CTE_Duplicates.StartDate = DimRegistration.StartDate
    AND CTE_Duplicates.TransactionType = DimRegistration.TransactionType
);

	select * from DimRegistration



--sheet 3 test
select 
	count(VehicleID),sum(TransactionCost) 
	from DimRegistration 
	where Year(StartDate) =2024  and TransactionType='Original Registration'

	select 
	count(VehicleID),sum(TransactionCost) 
	from DimRegistration 
	where Year(StartDate) =2024  and TransactionType='Original Title'

	select * from DimRegistration

--ETL Process

--for new records
INSERT INTO DimRegistration (VehicleID, DOL_Vehicle_ID, StartDate,StartDateTimestamp, EndDate,TransactionType,TransactionCost, IsCurrent)
SELECT 
    dv.VehicleID,
    asg.DOL,
    asg.Registration_Date AS StartDate,
	asg.Timestamp,
    DATEADD(YEAR, 1, asg.Registration_Date) AS EndDate,
	asg.Transaction_Type,
	asg.Cost,
    CASE 
        WHEN GETDATE() BETWEEN asg.Registration_Date AND DATEADD(YEAR, 1, asg.Registration_Date) THEN 1
        ELSE 0
    END AS IsCurrent
FROM 
    activity_staging asg
JOIN 
    DimVehicle dv ON asg.VIN = dv.VIN
LEFT JOIN 
    DimRegistration dr ON asg.DOL = dr.DOL_Vehicle_ID
WHERE 
    dr.DOL_Vehicle_ID IS NULL;

--updating expired registrations
UPDATE DimRegistration
SET 
    EndDate = DATEADD(YEAR, 1, StartDate),
    IsCurrent = 0
WHERE 
    EndDate < GETDATE() AND IsCurrent = 1;

--setting active registrations
UPDATE DimRegistration
SET 
    IsCurrent = 1
WHERE 
    GETDATE() BETWEEN StartDate AND EndDate
  AND IsCurrent = 0;

  SELECT 
  SUM(CASE WHEN IsCurrent = 0 THEN 1 ELSE 0 END) AS ExpiredReg,
  SUM(CASE WHEN IsCurrent = 1 THEN 1 ELSE 0 END) AS ActiveReg
FROM DimRegistration;

select * from DimRegistration order by DOL_Vehicle_ID asc
select * from DimRegistration where VehicleID ='9F639982-E286-4CFA-B53D-ADCBC73D12E5' order by StartDate

select * from activity_staging


drop table DimRegistration


--delta report queries
CREATE TABLE DimRegistration (
    RegistrationID UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    VIN VARCHAR(50) NOT NULL,
    DOLVehicleID BIGINT NOT NULL, 
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL ,
    PreviousDOL BIGINT NULL, 
    IsCurrent BIT NOT NULL
);
select * from activity_staging

--intial data load
WITH OrderedData AS (
    SELECT
        VIN,
        DOL,
        MIN(Transaction_Date) AS StartDate,
        DATEADD(YEAR, 1, MIN(Transaction_Date)) AS EndDate,
        LAG(DOL) OVER (PARTITION BY VIN ORDER BY MIN(Transaction_Date)) AS PreviousDOL
    FROM (
        SELECT DISTINCT VIN, DOL, Transaction_Date
        FROM activity_staging
    ) AS DeduplicatedData
    GROUP BY VIN, DOL
)
INSERT INTO DimRegistration (VIN, DOLVehicleID, StartDate, EndDate, PreviousDOL, IsCurrent)
SELECT
    VIN,
    DOL,
    StartDate,
    EndDate,
    PreviousDOL,
    CASE
        WHEN GETDATE() BETWEEN StartDate AND EndDate THEN 1
        ELSE 0
    END AS IsCurrent
FROM OrderedData;
 select * from DimRegistration

--testing ETL
INSERT INTO activity_staging (VIN, DOL, Transaction_Date)
VALUES ('WDDVP9AB5G', '103458937', '2024-09-10');

--check
select * from DimRegistration where VIN ='WDDVP9AB5G' ORDER BY StartDate
select VIN,DOL,Transaction_Date from activity_staging where VIN ='WDDVP9AB5G' ORDER BY Transaction_Date

--loading newly added records from staging table ( SCD Type 2 & 3)
WITH NewData AS (
    SELECT
        a.VIN,
        a.DOL,
        a.Transaction_Date AS StartDate,
        DATEADD(YEAR, 1, a.Transaction_Date) AS EndDate
    FROM activity_staging a
    LEFT JOIN DimRegistration d
        ON a.VIN = d.VIN
        AND a.DOL = d.DOLVehicleID
    WHERE d.VIN IS NULL --select only new records
)

INSERT INTO DimRegistration (VIN, DOLVehicleID, StartDate, EndDate, PreviousDOL, IsCurrent)
SELECT
    NewData.VIN,
    NewData.DOL,
    NewData.StartDate,
    NewData.EndDate,
    (SELECT TOP 1 DOLVehicleID
     FROM DimRegistration
     WHERE VIN = NewData.VIN
     ORDER BY StartDate DESC) AS PreviousDOL,
    CASE
        WHEN GETDATE() BETWEEN NewData.StartDate AND NewData.EndDate THEN 1
        ELSE 0
    END AS IsCurrent
FROM NewData
WHERE NOT EXISTS (
    SELECT 1
    FROM DimRegistration r
    WHERE r.VIN = NewData.VIN
    AND r.DOLVehicleID = NewData.DOL
);



