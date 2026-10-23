USE analytics_final;

LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/customers.csv'
INTO TABLE customer_info
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    Id_client,
    Total_amount,
    @gender,
    @age,
    Count_city,
    Response_communcation,
    Communication_3month,
    Tenure
)
SET
    Gender = NULLIF(TRIM(@gender), ''),
    Age = NULLIF(TRIM(@age), '');