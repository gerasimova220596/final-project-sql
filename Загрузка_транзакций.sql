TRUNCATE TABLE analytics_final.transactions_info;

LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/transactions.csv'
INTO TABLE analytics_final.transactions_info
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(date_new, Id_check, ID_client, Count_products, Sum_payment);

SHOW WARNINGS LIMIT 20;

SELECT COUNT(*) AS loaded_rows
FROM analytics_final.transactions_info;