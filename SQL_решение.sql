USE analytics_final;

-- Собираем товарные строки в чеки за год
CREATE OR REPLACE VIEW checks_year AS
SELECT
    STR_TO_DATE(date_new, '%d/%m/%Y') AS operation_date,
    ID_client,
    Id_check,
    SUM(CAST(Sum_payment AS DECIMAL(18, 2))) AS check_amount,
    SUM(Count_products) AS products_count
FROM transactions_info
WHERE STR_TO_DATE(date_new, '%d/%m/%Y') >= '2015-06-01'
  AND STR_TO_DATE(date_new, '%d/%m/%Y') < '2016-06-01'
GROUP BY
    STR_TO_DATE(date_new, '%d/%m/%Y'),
    ID_client,
    Id_check;

-- Проверяем количество чеков и клиентов по месяцам
SELECT
    DATE_FORMAT(operation_date, '%Y-%m') AS month,
    COUNT(*) AS checks_count,
    COUNT(DISTINCT ID_client) AS clients_count,
    ROUND(SUM(check_amount), 2) AS total_payment
FROM checks_year
GROUP BY DATE_FORMAT(operation_date, '%Y-%m')
ORDER BY month;


-- Задание 1. Клиенты с покупками во всех 12 месяцах
SELECT
    ID_client,
    COUNT(DISTINCT DATE_FORMAT(operation_date, '%Y-%m'))
        AS active_months,
    COUNT(*) AS checks_per_year,
    ROUND(AVG(check_amount), 2) AS avg_check,
    ROUND(SUM(check_amount) / 12, 2) AS avg_monthly_payment,
    ROUND(SUM(check_amount), 2) AS total_payment
FROM checks_year
GROUP BY ID_client
HAVING COUNT(
    DISTINCT DATE_FORMAT(operation_date, '%Y-%m')
) = 12
ORDER BY ID_client;


-- Задание 1. Помесячные показатели постоянных клиентов
WITH regular_clients AS (
    SELECT ID_client
    FROM checks_year
    GROUP BY ID_client
    HAVING COUNT(
        DISTINCT DATE_FORMAT(operation_date, '%Y-%m')
    ) = 12
)
SELECT
    c.ID_client,
    DATE_FORMAT(c.operation_date, '%Y-%m') AS month,
    COUNT(*) AS checks_count,
    ROUND(AVG(c.check_amount), 2) AS avg_check,
    ROUND(SUM(c.check_amount), 2) AS monthly_payment
FROM checks_year AS c
JOIN regular_clients AS r
    ON c.ID_client = r.ID_client
GROUP BY
    c.ID_client,
    DATE_FORMAT(c.operation_date, '%Y-%m')
ORDER BY c.ID_client, month;






-- Задание 2. Ежемесячные показатели
WITH monthly AS (
    SELECT
        DATE_FORMAT(operation_date, '%Y-%m') AS month,
        COUNT(*) AS operations_count,
        COUNT(DISTINCT ID_client) AS clients_count,
        SUM(check_amount) AS payment_sum,
        AVG(check_amount) AS avg_check
    FROM checks_year
    GROUP BY DATE_FORMAT(operation_date, '%Y-%m')
)
SELECT
    month,
    ROUND(avg_check, 2) AS avg_check,
    operations_count,
    clients_count,
    ROUND(payment_sum, 2) AS payment_sum,
    ROUND(AVG(operations_count) OVER (), 2)
        AS avg_monthly_operations,
    ROUND(AVG(clients_count) OVER (), 2)
        AS avg_monthly_clients,
    ROUND(
        100.0 * operations_count
        / SUM(operations_count) OVER (), 2
    ) AS operations_share_pct,
    ROUND(
        100.0 * payment_sum
        / SUM(payment_sum) OVER (), 2
    ) AS payment_share_pct
FROM monthly
ORDER BY month;




-- Задание 2e. Клиенты и расходы по полу
WITH gender_monthly AS (
    SELECT
        DATE_FORMAT(c.operation_date, '%Y-%m') AS month,
        COALESCE(NULLIF(TRIM(i.Gender), ''), 'NA') AS gender,
        COUNT(DISTINCT c.ID_client) AS clients_count,
        SUM(c.check_amount) AS payment_sum
    FROM checks_year AS c
    LEFT JOIN customer_info AS i
        ON c.ID_client = i.Id_client
    GROUP BY
        DATE_FORMAT(c.operation_date, '%Y-%m'),
        COALESCE(NULLIF(TRIM(i.Gender), ''), 'NA')
)
SELECT
    month,
    gender,
    clients_count,
    ROUND(
        100.0 * clients_count
        / SUM(clients_count) OVER (PARTITION BY month),
        2
    ) AS clients_share_pct,
    ROUND(payment_sum, 2) AS payment_sum,
    ROUND(
        100.0 * payment_sum
        / SUM(payment_sum) OVER (PARTITION BY month),
        2
    ) AS payment_share_pct
FROM gender_monthly
ORDER BY month, gender;




-- Задание 3. Показатели по возрастным группам за год
WITH age_checks AS (
    SELECT
        c.ID_client,
        c.check_amount,
        CASE
            WHEN i.Age IS NULL THEN 'Возраст не указан'
            ELSE CONCAT(
                FLOOR(i.Age / 10) * 10,
                '-',
                FLOOR(i.Age / 10) * 10 + 9
            )
        END AS age_group,
        COALESCE(FLOOR(i.Age / 10) * 10, 999) AS age_sort
    FROM checks_year AS c
    LEFT JOIN customer_info AS i
        ON c.ID_client = i.Id_client
)
SELECT
    age_group,
    COUNT(DISTINCT ID_client) AS clients_count,
    COUNT(*) AS operations_count,
    ROUND(SUM(check_amount), 2) AS payment_sum,
    ROUND(AVG(check_amount), 2) AS avg_check,
    ROUND(
        SUM(check_amount) / COUNT(DISTINCT ID_client), 2
    ) AS avg_payment_per_client
FROM age_checks
GROUP BY age_group, age_sort
ORDER BY age_sort;





-- Задание 3. Возрастные группы по кварталам
WITH age_checks AS (
    SELECT
        YEAR(c.operation_date) AS year_num,
        QUARTER(c.operation_date) AS quarter_num,
        c.ID_client,
        c.check_amount,
        CASE
            WHEN i.Age IS NULL THEN 'Возраст не указан'
            ELSE CONCAT(
                FLOOR(i.Age / 10) * 10, '-',
                FLOOR(i.Age / 10) * 10 + 9
            )
        END AS age_group,
        COALESCE(FLOOR(i.Age / 10) * 10, 999) AS age_sort
    FROM checks_year AS c
    LEFT JOIN customer_info AS i
        ON c.ID_client = i.Id_client
),
quarterly AS (
    SELECT
        year_num,
        quarter_num,
        age_group,
        age_sort,
        COUNT(DISTINCT ID_client) AS clients_count,
        COUNT(*) AS operations_count,
        SUM(check_amount) AS payment_sum,
        AVG(check_amount) AS avg_check
    FROM age_checks
    GROUP BY year_num, quarter_num, age_group, age_sort
)
SELECT
    CONCAT(year_num, '-Q', quarter_num) AS quarter,
    age_group,
    clients_count,
    operations_count,
    ROUND(payment_sum, 2) AS payment_sum,
    ROUND(avg_check, 2) AS avg_check,
    ROUND(
        payment_sum / clients_count, 2
    ) AS avg_payment_per_client,
    ROUND(
        1.0 * operations_count / clients_count, 2
    ) AS avg_operations_per_client,
    ROUND(
        100.0 * clients_count /
        SUM(clients_count) OVER (
            PARTITION BY year_num, quarter_num
        ), 2
    ) AS clients_share_pct,
    ROUND(
        100.0 * operations_count /
        SUM(operations_count) OVER (
            PARTITION BY year_num, quarter_num
        ), 2
    ) AS operations_share_pct,
    ROUND(
        100.0 * payment_sum /
        SUM(payment_sum) OVER (
            PARTITION BY year_num, quarter_num
        ), 2
    ) AS payment_share_pct
FROM quarterly
ORDER BY year_num, quarter_num, age_sort;