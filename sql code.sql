#creating the table in SQL becuase pandas defaulty cretaes columns with highest space so that will take more memory 
#example it will bigint where int is enough  , 
#so best practice is to create table in SQL and just append
create table df_orders (
 order_id int primary key, 
 order_date date,
 ship_mode varchar(20), 
 segment varchar(20), 
 country varchar(20),
 city varchar(20), 
 state varchar(20), 
 postal_code varchar(20),
 region varchar(20), 
 category varchar(20), 
 sub_category varchar(20), 
 product_id varchar(20), 
 quantity int, 
 discount decimal(7,2), 
 sale_price decimal(7,2), 
 profit decimal(7,2));
 
 select * from df_orders ;
 
 #Finding answers to queries
 
#1) Find top 10 highest revenue generating products
 
select order_id  , category , sub_category ,quantity from df_orders where product_id = 'FUR-BO-10001798';
 
 
# Using CTE to create total sales column and then using the created column to find top 10 products

with cte1 as( select * , 
 (quantity * sale_price) as total_sale_price 
 from df_orders)
 select product_id , sum(total_sale_price) as sales 
 from cte1 
 group by product_id 
 order by sales desc
 LIMIT 10 ; 
 
 #2 Find top 5 highest selling products in each region 
WITH cte1 AS (
    SELECT product_id, region, quantity, sale_price,
           (quantity * sale_price) AS total_sale_price
    FROM df_orders
),
cte2 AS (
    SELECT product_id, region, total_sale_price,
           DENSE_RANK() OVER(PARTITION BY region ORDER BY total_sale_price DESC) AS drn
    FROM cte1
)
SELECT *
FROM cte2
WHERE drn <= 5; 
 
 #3 Find month over month growth comparison for 2022 and 2023 sales ex jan2022 vs jan2023
 WITH cte1 AS (
    SELECT * , 
           (quantity * sale_price) AS total_sale_price
    FROM df_orders
) ,
cte2 as (Select year(order_date) as order_year , month(order_date) as order_month , 
sum(total_sale_price) as sales from cte1
group by year(order_date),month(order_date)
order by year(order_date),month(order_date))

Select order_month, 
SUM(CASE WHEN order_year = 2022 then sales else 0 end) as sales_2022,
SUM(CASE WHEN order_year = 2023 then sales else 0 end) as sales_2023
from cte2
group by order_month
order by order_month ;

#4 For each category which month had highest sales
WITH cte1 AS (
    SELECT * , 
           (quantity * sale_price) AS total_sale_price
    FROM df_orders
),
monthly_sales as (
Select category, month(order_date) as order_month, year(order_date) as order_year,
SUM(total_sale_price) as sales
from cte1 
GROUP BY category, month(order_date) ,year(order_date) order by order_month ,order_year),

ranked_sales as (Select * , 
dense_rank() over(partition by category order by sales DESC) as rnk
from monthly_sales)

Select category , order_month , order_year , sales
from ranked_sales where rnk =1 order by category;

#5 Which sub category had highest growth by profit in 2023 compare to 2022
WITH cte1 AS (
    SELECT * , 
           (quantity * sale_price) AS total_sale_price
    FROM df_orders
) ,
cte2 as (
Select sub_category , year(order_date) as order_year , 
sum(total_sale_price) as sales 
from cte1
group by sub_category, year(order_date)
) , 
cte3 as (
Select sub_category,
SUM(CASE WHEN order_year = 2022 then sales else 0 end) as sales_2022,
SUM(CASE WHEN order_year = 2023 then sales else 0 end) as sales_2023
from cte2
group by sub_category
)

Select * , 
(sales_2023 - sales_2022)*100/sales_2022 as growth_percentage
from cte3 order by growth_percentage DESC LIMIT 1;







