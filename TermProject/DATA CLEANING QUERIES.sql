SELECT * FROM pop WHERE Vehicle_Location IS NULL
DELETE FROM pop WHERE Vehicle_Location IS NULL;


SELECT * FROM pop
WHERE VIN IS NULL
   OR County IS NULL
   OR City IS NULL
   OR State IS NULL
   OR Postal_Code IS NULL
   OR Model_Year IS NULL
   OR Make IS NULL
   OR Model IS NULL
   OR Electric_Vehicle_Type is NULL
   OR Electric_Range IS NULL
   OR Base_MSRP IS NULL
   OR DOL_Vehicle_ID IS NULL
   OR Vehicle_Location IS NULL

   select * from activity
   WHERE VIN IS NULL
   OR DOL_Vehicle_ID IS NULL
   OR Model_Year IS NULL
   OR Make IS NULL
   OR Model IS NULL
   OR County IS NULL
   OR City IS NULL
   OR State IS NULL
   OR Postal_Code IS NULL
   
   SELECT * FROM activity where Sale_Date IS NULL