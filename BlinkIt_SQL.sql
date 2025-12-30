

create database BlinkIt
use BlinkIt

select * from blinkit_cleaned;

-- Total Revenue
select sum(Item_outlet_sales) as Total_Revenue 
from blinkit_cleaned;

--  Sales Growth by Outlet
select outlet_identifier, 
sum(Item_outlet_sales) as Total_Sales,
avg(Item_outlet_sales) as Avg_Transaction_Value 
from blinkit_cleaned
group by outlet_identifier
order by Total_sales desc;

-- Average Transaction value, minimum and maximum sale
select avg(Item_outlet_sales) as Avg_Transaction_Value,
min(Item_outlet_sales) as min_sale,
max(Item_outlet_sales) as max_sale
from blinkit_cleaned;

-- Top 3 performing outlet by sales
select outlet_identifier, max(Item_outlet_sales) as max_sale
from blinkit_cleaned
group by outlet_identifier
order by max_sale desc
limit 3;

-- Bottom 3 performing outlet by sales
select outlet_identifier, min(Item_outlet_sales) as min_sale
from blinkit_cleaned
group by outlet_identifier
order by min_sale desc
limit 3;

-- Top 5 selling product categories
select item_type, sum(item_outlet_sales) as total_revenue,
count(*) as Units_sold
from blinkit_cleaned
group by item_type
order by total_revenue desc
limit 5;

-- Bottom 5 selling product categories 
select item_type, sum(item_outlet_sales) as total_revenue,
count(*) as Units_sold
from blinkit_cleaned
group by item_type
order by total_revenue 
limit 5;

-- Product visibility impact on sales
select item_type, avg(item_visibility) as avg_visibility,
avg(item_outlet_sales) as avg_sales
from blinkit_cleaned
group by item_type
order by avg_sales desc;

-- Outlet type performance comparison 
select outlet_type,
count(distinct outlet_identifier) as outlet_count,
sum(item_outlet_sales) as total_sales
from blinkit_cleaned
group by outlet_type
order by total_sales desc;

-- Location tier performance
select outlet_location_type,
count(distinct outlet_identifier) as outlet_count,
sum(item_outlet_sales) as total_sales
from blinkit_cleaned
group by outlet_location_type
order by total_sales desc;

-- Oulet Age vs Sales performance
select
	Case 
		when outlet_age <= 20 then 'New (0-20 years)'
		when outlet_age <= 30 then 'Matured (21-30 years)'
		else 'Established (30+ years)'
	End as outlet_age_group,
    count(distinct outlet_identifier) as outlet_count,
    avg(item_outlet_sales) as avg_sales
from blinkit_cleaned
group by outlet_age_group
order by avg_sales desc;

Q1: Which product types drive the most revenue across different outlet sizes?
select outlet_size,
item_type, sum(item_outlet_sales) as total_sales,
count(*) as Units_Sold
from blinkit_cleaned
group by outlet_size, item_type
order by total_sales desc;

Q2: Do customers prefer low-fat or regular items, and how does this vary by location?
select outlet_location_type,
       item_fat_content,
       count(*) as product_count,
       sum(item_outlet_sales) as total_sales,
       avg(item_outlet_sales) as avg_sales
from blinkit_cleaned
group by outlet_location_type, item_fat_content
order by outlet_location_type, total_sales desc;

Q3: Which outlets are underperforming compared to their outlet type average?
with outletavg as (
    select outlet_type,
           avg(item_outlet_sales) as type_avg_sales
    from blinkit_cleaned
    group by outlet_type
)
select b.outlet_identifier,
       b.outlet_type,
       b.outlet_size,
       sum(b.item_outlet_sales) as total_sales,
       oa.type_avg_sales * count(*) as expected_sales,
       sum(b.item_outlet_sales) - (oa.type_avg_sales * count(*)) as performance_gap
from blinkit_cleaned b
join outletavg oa on b.outlet_type = oa.outlet_type
group by b.outlet_identifier, b.outlet_type, b.outlet_size, oa.type_avg_sales
having sum(b.item_outlet_sales) < (oa.type_avg_sales * count(*))
order by performance_gap asc;

Q4: How does outlet establishment year impact current sales performance?
select outlet_establishment_year,
       outlet_age,
       count(distinct outlet_identifier) as outlet_count,
       avg(item_outlet_sales) as avg_sales,
       sum(item_outlet_sales) as total_sales
from blinkit_cleaned
group by outlet_establishment_year, outlet_age
order by outlet_establishment_year;

Q5: What is the sales performance of high-visibility vs low-visibility products?
select 
    case 
        when item_visibility < 0.05 then 'low visibility'
        when item_visibility < 0.10 then 'medium visibility'
        else 'high visibility'
    end as visibility_category,
    count(*) as product_count,
    avg(item_outlet_sales) as avg_sales,
    sum(item_outlet_sales) as total_sales
from blinkit_cleaned
group by visibility_category
order by avg_sales desc;

Q6: Which item categories perform best in each price range?
select price_category,
       item_category,
       count(*) as item_count,
       sum(item_outlet_sales) as total_revenue,
       avg(item_mrp) as avg_price
from blinkit_cleaned
group by price_category, item_category
order by price_category, total_revenue desc;

Q7: What is the correlation between item weight and sales?
select 
    case 
        when item_weight < 10 then 'light (<10kg)'
        when item_weight < 15 then 'medium (10-15kg)'
        else 'heavy (>15kg)'
    end as weight_category,
    count(*) as item_count,
    avg(item_outlet_sales) as avg_sales,
    sum(item_outlet_sales) as total_sales
from blinkit_cleaned
group by weight_category
order by avg_sales desc;

Q8: Which outlet configurations (type + size + location) generate the highest revenue?
select outlet_type,
       outlet_size,
       outlet_location_type,
       count(distinct outlet_identifier) as outlet_count,
       sum(item_outlet_sales) as total_revenue,
       avg(item_outlet_sales) as avg_transaction
from blinkit_cleaned
group by outlet_type, outlet_size, outlet_location_type
order by total_revenue desc
limit 10;

Q9: What percentage of total sales comes from each item type at different outlets?

with totalsales as (
    select outlet_identifier,
           sum(item_outlet_sales) as outlet_total
    from blinkit_cleaned
    group by outlet_identifier
)
select b.outlet_identifier,
       b.item_type,
       sum(b.item_outlet_sales) as category_sales,
       ts.outlet_total,
       round(100.0 * sum(b.item_outlet_sales) / ts.outlet_total, 2) as sales_percentage
from blinkit_cleaned b
join totalsales ts on b.outlet_identifier = ts.outlet_identifier
group by b.outlet_identifier, b.item_type, ts.outlet_total
order by b.outlet_identifier, sales_percentage desc;

Q10: Identify top performers: outlets with high sales despite low product visibility?
select outlet_identifier,
       outlet_type,
       avg(item_visibility) as avg_visibility,
       sum(item_outlet_sales) as total_sales,
       count(*) as transaction_count
from blinkit_cleaned
group by outlet_identifier, outlet_type
having avg(item_visibility) < (select avg(item_visibility) from blinkit_cleaned)
order by total_sales desc
limit 10;



























