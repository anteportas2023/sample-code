-- 1. Provide the list of markets in which customer "Atliq Exclusive" 
--    operates its business in the APAC region

Select market
From dim_customer
Where customer = "Atliq Exclusive"
And region = "APAC";

-- 2. What is the percentage of unique product increase in 2021 vs. 2020? 
-- The final output contains these fields, unique_products_2020 unique_products_2021 percentage_chg

with cte20 as
    (Select  Count(Distinct(product_code)) As unique_products_2020 
     From fact_sales_monthly
     Where fiscal_year = 2020
     ), 
 cte21 as 
  (Select  Count(Distinct(product_code)) As unique_products_2021     
   From fact_sales_monthly
     Where fiscal_year = 2021
     ) 
Select cte20.unique_products_2020, cte21.unique_products_2021, 
Round(( unique_products_2021 - unique_products_2020) * 100 / unique_products_2020,2) 
As unique_products_2020unique_products_2021_percentage_chg
From cte20 Cross Join cte21;


-- 3. Provide a report with all the unique product counts for each segment 
--    and sort them in descending order of product counts. 
--    The final output contains 2 fields, segment product_count

Select segment, Count(Distinct(product_code)) As product_count
From dim_product
Group By segment
Order By product_count Desc;

-- 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
-- The final output contains these fields, segment product_count_2020 product_count_2021 difference

with prod_seg as
      (SELECT p.segment, COUNT(DISTINCT(s.product_code)) AS product_count, s.fiscal_year 
       FROM dim_product p Join fact_sales_monthly s On p.product_code = s.product_code
       GROUP BY p.segment, s.fiscal_year)
Select prod_2020.segment, prod_2020.product_count As product_count_2020,
       prod_2021.product_count As product_count_2021,
       prod_2021.product_count - prod_2020.product_count As difference
From prod_seg As prod_2020
Join prod_seg As prod_2021
On prod_2020.segment = prod_2021.segment
And prod_2020.fiscal_year = 2020
And prod_2021.fiscal_year = 2021
Order By difference Desc;


-- 5. Get the products that have the highest and lowest manufacturing costs. 
--    The final output should contain these fields, 
--     product_code product manufacturing_cost

Select p.product_code, p.product, c.manufacturing_cost
From fact_manufacturing_cost c
Join dim_product p On c.product_code = p.product_code
Where c.manufacturing_cost = (Select Max(c.manufacturing_cost) From fact_manufacturing_cost c)
Or c.manufacturing_cost = (Select Min(c.manufacturing_cost) From fact_manufacturing_cost c)
Order By p.product_code Desc;


-- 6. Generate a report which contains the top 5 customers 
-- who received an average high pre_invoice_discount_pct for the fiscal year 2021 
-- and in the Indian market. The final output contains these fields, 
-- customer_code customer average_discount_percentage


Select c.customer_code, c.customer, Round(Avg(fd.pre_invoice_discount_pct),2) As average_discount_percetange
From fact_pre_invoice_deductions fd Join dim_customer c On fd.customer_code = c.customer_code
Where fd.fiscal_year = 2021
And c.market = "India"
Group By c.customer_code
Order By fd.pre_invoice_discount_pct Desc
Limit 5;


-- 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive”
-- for each month . This analysis helps to get an idea of low and high-performing months 
-- and take strategic decisions. The final report contains these columns: 
-- Month Year Gross sales Amount


Select Monthname(fs.date) As Month, Year(fs.date) As Year, 
Round(Sum(fg.gross_price * fs.sold_quantity),2) As Gross_Sales_Amount
From fact_sales_monthly fs Join dim_customer c On fs.customer_code = c.customer_code
Join fact_gross_price fg On fg.fiscal_year = fs.fiscal_year 
And fg.product_code = fs.product_code
Where c.customer = "Atliq Exclusive"
Group By Month, Year
Order By Gross_Sales_Amount Desc;


-- 8. In which quarter of 2020, got the maximum total_sold_quantity? 
-- The final output contains these fields sorted by the total_sold_quantity, 
-- Quarter total_sold_quantity


Select case
          When Month(date) In (9, 10, 11) Then "Q1"
          When Month(date) In (12, 1, 2) Then "Q2"
          When Month(date) In (3, 4, 5) Then "Q3"
          Else "Q4"
          End As quarter, Sum(sold_quantity) As total_sold_quantity
From fact_sales_monthly
Where fiscal_year = 2020
Group By quarter
Order By total_sold_quantity Desc;


-- 9. Which channel helped to bring more gross sales in the fiscal year 2021 
-- and the percentage of contribution? The final output contains these fields, 
-- channel gross_sales_mln percentage


with cte21 as(
      Select channel, 
              Round(Sum(fg.gross_price * fs.sold_quantity)/1000000,2) As gross_sales
       From dim_customer c Join fact_sales_monthly fs On c.customer_code = fs.customer_code
       Join fact_gross_price fg On fg.product_code = fs.product_code 
       And fg.fiscal_year = fs.fiscal_year
       Where fs.fiscal_year = 2021
       Group By channel
       Order By gross_sales Desc)
Select *, Concat(Round((gross_sales / Sum(gross_sales) over())*100,2),"%") As percentage
From cte21;


-- 10. Get the Top 3 products in each division that have a high total_sold_quantity 
-- in the fiscal_year 2021? 
-- The final output contains these fields, division product_code 
-- product total_sold_quantity rank_order

with cte21 As(
			  Select p.division, fs.product_code, p.product, Sum(fs.sold_quantity) 
                   As total_sold_quantity,  
              rank() OVER(partition by p.division Order By Sum(fs.sold_quantity)Desc) 
                    As rank_order
              From dim_product p Join fact_sales_monthly fs 
              On p.product_code = fs.product_code
              Where fs.fiscal_year = 2021
              Group By fs.product_code)
              
Select *
From cte21
Where rank_order In (1, 2, 3);
