select  count(*) as  count,  getdate()  as date, 'Varun Nair'  as name from MANUFACTURE_FACT

SELECT count(QTY_PASSED),COUNT(QTY_FAILED) FROM MANUFACTURE_FACT WHERE FACTORY_KEY = 'm_491424'

SELECT  * FROM CALENDAR_MANUFACTURE_DIM

SELECT FACTORY_KEY, COUNT(QTY_PASSED) AS CountQtyPassed,count(QTY_FAILED) 
FROM MANUFACTURE_FACT 
GROUP BY FACTORY_KEY;

SELECT *   FROM MANUFACTURE_FACT

--Q2
WITH MonthlyData AS (
    SELECT
        f.FACTORY_LABEL AS FactoryName,
        CONCAT(
            FORMAT(MONTH(c.MANUFACTURE_DAY_DATE), '00'), '-',
            CASE MONTH(c.MANUFACTURE_DAY_DATE)
                WHEN 1 THEN 'January'
                WHEN 2 THEN 'February'
                WHEN 3 THEN 'March'
                WHEN 4 THEN 'April'
                WHEN 5 THEN 'May'
                WHEN 6 THEN 'June'
                WHEN 7 THEN 'July'
                WHEN 8 THEN 'August'
                WHEN 9 THEN 'September'
                WHEN 10 THEN 'October'
                WHEN 11 THEN 'November'
                WHEN 12 THEN 'December'
            END
        ) AS Month,
        MONTH(c.MANUFACTURE_DAY_DATE) AS MonthSort,
        SUM(m.QTY_PASSED) AS TotalUnitsPassed,
        SUM(m.QTY_FAILED) AS TotalUnitsFailed
    FROM 
        MANUFACTURE_FACT m
    JOIN
        CALENDAR_MANUFACTURE_DIM c ON m.MANUFACTURE_CAL_KEY = c.MANUFACTURE_CAL_KEY
    JOIN
        FACTORY_DIM f ON m.FACTORY_KEY = f.FACTORY_KEY
    WHERE 
        YEAR(c.MANUFACTURE_DAY_DATE) = 2022
    GROUP BY 
        f.FACTORY_LABEL,
        MONTH(c.MANUFACTURE_DAY_DATE)
)
SELECT 
    FactoryName,
    Month,
    TotalUnitsPassed,
    TotalUnitsFailed
FROM MonthlyData
GROUP BY 
    FactoryName,
    Month,
    MonthSort,
    TotalUnitsPassed,
    TotalUnitsFailed
WITH ROLLUP
HAVING 
    (Month IS NOT NULL OR FactoryName IS NOT NULL)
ORDER BY 
    COALESCE(FactoryName, 'ZZZZ'),
    CASE 
        WHEN Month IS NULL THEN 'ZZZZ'
        ELSE CAST(MonthSort AS VARCHAR(2))
    END;

--Q3
WITH MonthlyData AS (
    SELECT
        f.FACTORY_LABEL AS FactoryName,
        CONCAT(
            FORMAT(MONTH(c.MANUFACTURE_DAY_DATE), '00'), '-',
            CASE MONTH(c.MANUFACTURE_DAY_DATE)
                WHEN 1 THEN 'January'
                WHEN 2 THEN 'February'
                WHEN 3 THEN 'March'
                WHEN 4 THEN 'April'
                WHEN 5 THEN 'May'
                WHEN 6 THEN 'June'
                WHEN 7 THEN 'July'
                WHEN 8 THEN 'August'
                WHEN 9 THEN 'September'
                WHEN 10 THEN 'October'
                WHEN 11 THEN 'November'
                WHEN 12 THEN 'December'
            END
        ) AS Month,
		MONTH(c.MANUFACTURE_DAY_DATE) as MonthSort,
		p.BRAND_LABEL  as Brand,
		sum(m.QTY_PASSED) as TotalUnitsPassed,
		sum(QTY_FAILED) as TotalUnitsFailed
		from  MANUFACTURE_FACT m
		JOIN CALENDAR_MANUFACTURE_DIM c ON m.MANUFACTURE_CAL_KEY = c.MANUFACTURE_CAL_KEY
		JOIN FACTORY_DIM f ON m.FACTORY_KEY = f.FACTORY_KEY
		JOIN  PRODUCT_DIM  p ON  M.PRODUCT_KEY = P.PRODUCT_KEY
		WHERE YEAR(c.MANUFACTURE_DAY_DATE)=2022
		group by f.FACTORY_LABEL,MONTH(c.MANUFACTURE_DAY_DATE),p.BRAND_LABEL
		)
		select FactoryName,Month,Brand,TotalUnitsPassed,TotalUnitsFailed from MonthlyData
		group by  FactoryName,Month,Brand,MonthSort,TotalUnitsPassed,TotalUnitsFailed
		with rollup  having (Month is not null or FactoryName is  not  null   or  Brand is not null)
		order by coalesce(FactoryName,'ZZZZ'),
		CASE	
			WHEN Month is null then  'ZZZZ'
			ELSE CAST(MonthSort  as VARCHAR(2))
			END,
			COALESCE(Brand,'ZZZZ')


--Q4
WITH MonthlyData AS (
    SELECT
        f.FACTORY_LABEL AS FactoryName,
        CONCAT(
            FORMAT(MONTH(c.MANUFACTURE_DAY_DATE), '00'), '-',
            CASE MONTH(c.MANUFACTURE_DAY_DATE)
                WHEN 1 THEN 'January'
                WHEN 2 THEN 'February'
                WHEN 3 THEN 'March'
                WHEN 4 THEN 'April'
                WHEN 5 THEN 'May'
                WHEN 6 THEN 'June'
                WHEN 7 THEN 'July'
                WHEN 8 THEN 'August'
                WHEN 9 THEN 'September'
                WHEN 10 THEN 'October'
                WHEN 11 THEN 'November'
                WHEN 12 THEN 'December'
            END
        ) AS Month,
		MONTH(c.MANUFACTURE_DAY_DATE) as MonthSort,
		p.BRAND_LABEL  as Brand,
		sum(m.QTY_PASSED) as TotalUnitsPassed,
		sum(QTY_FAILED) as TotalUnitsFailed
		from  MANUFACTURE_FACT m
		JOIN CALENDAR_MANUFACTURE_DIM c ON m.MANUFACTURE_CAL_KEY = c.MANUFACTURE_CAL_KEY
		JOIN FACTORY_DIM f ON m.FACTORY_KEY = f.FACTORY_KEY
		JOIN  PRODUCT_DIM  p ON  M.PRODUCT_KEY = P.PRODUCT_KEY
		WHERE YEAR(c.MANUFACTURE_DAY_DATE)=2022
		group by f.FACTORY_LABEL,MONTH(c.MANUFACTURE_DAY_DATE),p.BRAND_LABEL
		)
		select FactoryName,Month,Brand,TotalUnitsPassed,TotalUnitsFailed from MonthlyData
		group by  FactoryName,Month,Brand,MonthSort,TotalUnitsPassed,TotalUnitsFailed
		with CUBE  having (Month is not null or FactoryName is  not  null   or  Brand is not null)
		order by coalesce(FactoryName,'ZZZZ'),
		CASE	
			WHEN Month is null then  'ZZZZ'
			ELSE CAST(MonthSort  as VARCHAR(2))
			END,
			COALESCE(Brand,'ZZZZ')

--q6
select
YearlyProduction.Year,
YearlyProduction.FactoryLabel,
YearlyProduction.QtyPassed  as TotalUnitsPassed  FROM(
	select 
	c.MANUFACTURE_YEAR  as Year,
	f.FACTORY_LABEL  AS FactoryLabel,
	sum(m.QTY_PASSED) as QtyPassed,
	ROW_NUMBER() over (partition by c.MANUFACTURE_YEAR  order by sum(m.QTY_PASSED) desc) as FactoryRank
	from 
	MANUFACTURE_FACT m
	JOIN
	CALENDAR_MANUFACTURE_DIM  c  ON m.MANUFACTURE_CAL_KEY = c.MANUFACTURE_CAL_KEY
	join
	FACTORY_DIM f ON  m.FACTORY_KEY = f.FACTORY_KEY
	where month(c.MANUFACTURE_DAY_DATE) = 2 AND  YEAR(c.MANUFACTURE_DAY_DATE) in(2022,2021,2020,2019,2018)
	GROUP BY
	C.MANUFACTURE_YEAR,f.FACTORY_LABEL
	) AS YearlyProduction where YearlyProduction.FactoryRank <= 3 order by  YearlyProduction.Year DESC,YearlyProduction.FactoryRank


--q7
SELECT * 
FROM (
    SELECT 
        YearlyProduction.Year,
        YearlyProduction.FactoryLabel,
        YearlyProduction.QtyPassed AS TotalUnitsPassed
    FROM (
        SELECT 
            YEAR(c.MANUFACTURE_DAY_DATE) AS Year,
            f.FACTORY_LABEL AS FactoryLabel,
            SUM(m.QTY_PASSED) AS QtyPassed,
            SUM(m.QTY_FAILED) AS QtyFailed,
            ROW_NUMBER() OVER (PARTITION BY YEAR(c.MANUFACTURE_DAY_DATE) ORDER BY SUM(m.QTY_PASSED) DESC) AS FactoryRank
        FROM 
            MANUFACTURE_FACT m
        JOIN
            CALENDAR_MANUFACTURE_DIM c ON m.MANUFACTURE_CAL_KEY = c.MANUFACTURE_CAL_KEY
        JOIN
            FACTORY_DIM f ON m.FACTORY_KEY = f.FACTORY_KEY
        WHERE 
            YEAR(c.MANUFACTURE_DAY_DATE) IN (2022, 2021, 2020, 2019, 2018) 
            AND MONTH(c.MANUFACTURE_DAY_DATE) = 2
        GROUP BY
            YEAR(c.MANUFACTURE_DAY_DATE), f.FACTORY_LABEL
    ) AS YearlyProduction 
    WHERE YearlyProduction.FactoryRank <= 3
) AS SourceTable
PIVOT (
    SUM(TotalUnitsPassed) 
    FOR Year IN ([2022], [2021], [2020], [2019], [2018])
) AS PivotTable
ORDER BY FactoryLabel

	
