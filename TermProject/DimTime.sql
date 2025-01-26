--create table DimTime
drop table DimTime

CREATE TABLE DimTime (
    TimeID UNIQUEIDENTIFIER PRIMARY KEY,
    Date DATE,                           
    Year INT,                            
    Month INT,                          
    Day INT,                                                     
    WeekdayName VARCHAR(20),           
    Quarter INT,                       
    WeekOfYear INT,                  
    IsWeekend BIT,                        
    DayOfYear INT                        
);


DECLARE @MinDate DATE, @MaxDate DATE;

--get minimum and maximum dates from activity_staging
SELECT 
    @MinDate = MIN(CAST(Timestamp AS DATE)), 
    @MaxDate = MAX(CAST(Timestamp AS DATE))
FROM activity_staging;

--generate sequence of dates between MinDate and MaxDate
WITH DateSequence AS (
    SELECT @MinDate AS DateValue
    UNION ALL
    SELECT DATEADD(DAY, 1, DateValue)
    FROM DateSequence
    WHERE DateValue < @MaxDate
)

--insert into DimTime
INSERT INTO DimTime (TimeID, Date, Year, Month, Day,WeekdayName, Quarter, WeekOfYear, IsWeekend, DayOfYear)
SELECT 
    NEWID() AS TimeID, 
    DateValue AS Date,
    YEAR(DateValue) AS Year,
    MONTH(DateValue) AS Month,
    DAY(DateValue) AS Day,
    DATENAME(WEEKDAY, DateValue) AS WeekdayName,  
    DATEPART(QUARTER, DateValue) AS Quarter, 
    DATEPART(WEEK, DateValue) AS WeekOfYear, 
    CASE WHEN DATEPART(WEEKDAY, DateValue) IN (1, 7) THEN 1 ELSE 0 END AS IsWeekend,
    DATEPART(DAYOFYEAR, DateValue) AS DayOfYear
FROM DateSequence
OPTION (MAXRECURSION 0);

select * from DimTime order by date asc




