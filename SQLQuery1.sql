--Tạo database
CREATE DATABASE Sales_Data_Analysis;
go
--use database vừa tạo
use Sales_Data_Analysis;
go
--import bảng Sales Data và xem tất cả trong bảng
select * from [dbo].[Sales Data]
--xóa cột không cần thiết
alter table [dbo].[Sales Data]
drop column column1;
--truy vấn các giá trị null có trong cột
select *
from [dbo].[Sales Data]
where [Order_ID] IS NULL
   OR [Product] IS NULL
   OR [Quantity_Ordered] IS NULL
   OR [Price_Each] IS NULL
   OR [Order_Date] IS NULL
   OR [Purchase_Address] IS NULL
   OR [Month] IS NULL
   OR [Sales] IS NULL
   OR [City] IS NULL
   OR [Hour] IS NULL;
--không có giá trị null

--kiểm tra trùng lặp
SELECT s.*
FROM [dbo].[Sales Data] s
JOIN (
    SELECT [Product], COUNT(*) AS DuplicateCount
    FROM [dbo].[Sales Data]
    GROUP BY [Product]
    HAVING COUNT(*) > 1
) dup
ON s.[Product] = dup.[Product];
--vậy là không có trùng lặp

--không có kết quả vậy dữ liệu này về cơ bản là sạch

--xem xét cột city
select distinct [City]
from [dbo].[Sales Data];

/*
Los Angeles
Portland
Austin
Seattle
Atlanta
Boston
Dallas
San Francisco
New York City
*/

--xem xét cột product
select distinct [Product]
from [dbo].[Sales Data];

/*
Flatscreen TV
LG Washing Machine
Google Phone
Vareebadd Phone
27in 4K Gaming Monitor
USB-C Charging Cable
Bose SoundSport Headphones
Wired Headphones
ThinkPad Laptop
AA Batteries (4-pack)
AAA Batteries (4-pack)
Apple Airpods Headphones
34in Ultrawide Monitor
20in Monitor
LG Dryer
Macbook Pro Laptop
iPhone
Lightning Charging Cable
27in FHD Monitor
*/

--tạo các cột khác phục vụ phân tích
SELECT *,
    CASE
        WHEN [Hour] BETWEEN 6 AND 12 THEN 'Morning'
        WHEN [Hour] BETWEEN 12 AND 18 THEN 'Afternoon'
        WHEN [Hour] BETWEEN 18 AND 24 THEN 'Evening'
        ELSE 'Night'
    END AS [Day_Part],
    
    CASE
        WHEN [City] IN ('Boston', 'New York City') THEN 'Northeast'
        WHEN [City] IN ('Atlanta', 'Dallas', 'Austin') THEN 'South'
        WHEN [City] IN ('Los Angeles', 'San Francisco', 'Portland', 'Seattle') THEN 'West'
        ELSE 'Unknown'
    END AS [Region],
    
    CASE
        WHEN [Product] IN ('Flatscreen TV', 'Google Phone', 'Vareebadd Phone', 'ThinkPad Laptop', 'Macbook Pro Laptop', 'iPhone', '27in 4K Gaming Monitor', '34in Ultrawide Monitor', '20in Monitor', '27in FHD Monitor') 
        THEN 'Electronics'
        WHEN [Product] IN ('USB-C Charging Cable', 'Lightning Charging Cable', 'Bose SoundSport Headphones', 'Wired Headphones', 'Apple Airpods Headphones', 'AA Batteries (4-pack)', 'AAA Batteries (4-pack)') 
        THEN 'Accessories'
        WHEN [Product] IN ('LG Washing Machine', 'LG Dryer') 
        THEN 'Home Appliances'
        ELSE 'Others'
    END AS [Product_Category],
    
    CASE
        WHEN [Price_Each] > 1000 THEN 'Yes'
        ELSE 'No'
    END AS [Is_Expensive],
    
    CASE
        WHEN [Month] IN (12, 1, 2) THEN 'Winter'
        WHEN [Month] IN (3, 4, 5) THEN 'Spring'
        WHEN [Month] IN (6, 7, 8) THEN 'Summer'
        WHEN [Month] IN (9, 10, 11) THEN 'Fall'
    END AS [Season],
    
    CASE
        WHEN MONTH([Order_Date]) = 1 AND DAY([Order_Date]) = 1 THEN 'New Year'  -- Ngày 1 tháng 1
        WHEN MONTH([Order_Date]) = 2 AND DAY([Order_Date]) = 14 THEN 'Valentine''s Day'  -- Ngày 14 tháng 2
        WHEN MONTH([Order_Date]) = 4 AND DAY([Order_Date]) = 21 THEN 'Easter'  -- Ngày 21 tháng 4
        WHEN MONTH([Order_Date]) = 5 AND DAY([Order_Date]) = 1 THEN 'Labor Day'  -- Ngày 1 tháng 5
        WHEN MONTH([Order_Date]) = 7 AND DAY([Order_Date]) = 4 THEN 'Independence Day'  -- Ngày 4 tháng 7
        WHEN MONTH([Order_Date]) = 11 AND DAY([Order_Date]) = 28 THEN 'Thanksgiving'  -- Ngày 28 tháng 11
        WHEN MONTH([Order_Date]) = 11 AND DAY([Order_Date]) = 29 THEN 'Black Friday'  -- Ngày 29 tháng 11
        WHEN MONTH([Order_Date]) = 12 AND DAY([Order_Date]) = 25 THEN 'Christmas'  -- Ngày 25 tháng 12
        WHEN MONTH([Order_Date]) = 12 AND DAY([Order_Date]) = 31 THEN 'New Year''s Eve'  -- Ngày 31 tháng 12
        ELSE 'No Holiday'  -- Không thuộc ngày lễ nào
    END AS [Holiday_Season],
    
    CASE
        WHEN COUNT([Order_ID]) OVER (PARTITION BY [Purchase_Address]) > 1 THEN 'Yes'
        ELSE 'No'
    END AS [Repeat_Customer]
    
FROM [dbo].[Sales Data];
--lưu vào bảng hiện tại
ALTER TABLE [dbo].[Sales Data]
ADD 
    Day_Part VARCHAR(20),
    Region VARCHAR(20),
    Product_Category VARCHAR(20),
    Is_Expensive VARCHAR(3),
    Season VARCHAR(10),
    Holiday_Season VARCHAR(20),
    Repeat_Customer VARCHAR(3);

WITH CustomerCounts AS (
    SELECT 
        *,
        COUNT([Order_ID]) OVER (PARTITION BY [Purchase_Address]) AS Repeat_Customer_Count
    FROM [dbo].[Sales Data]
)
UPDATE [dbo].[Sales Data]
SET 
    Day_Part = 
        CASE
            WHEN CC.[Hour] BETWEEN 6 AND 12 THEN 'Morning'
            WHEN CC.[Hour] BETWEEN 12 AND 18 THEN 'Afternoon'
            WHEN CC.[Hour] BETWEEN 18 AND 24 THEN 'Evening'
            ELSE 'Night'
        END,
    
    Region = 
        CASE
            WHEN CC.[City] IN ('Boston', 'New York City') THEN 'Northeast'
            WHEN CC.[City] IN ('Atlanta', 'Dallas', 'Austin') THEN 'South'
            WHEN CC.[City] IN ('Los Angeles', 'San Francisco', 'Portland', 'Seattle') THEN 'West'
            ELSE 'Unknown'
        END,
    
    Product_Category = 
        CASE
            WHEN CC.[Product] IN ('Flatscreen TV', 'Google Phone', 'Vareebadd Phone', 'ThinkPad Laptop', 'Macbook Pro Laptop', 'iPhone', '27in 4K Gaming Monitor', '34in Ultrawide Monitor', '20in Monitor', '27in FHD Monitor') 
            THEN 'Electronics'
            WHEN CC.[Product] IN ('USB-C Charging Cable', 'Lightning Charging Cable', 'Bose SoundSport Headphones', 'Wired Headphones', 'Apple Airpods Headphones', 'AA Batteries (4-pack)', 'AAA Batteries (4-pack)') 
            THEN 'Accessories'
            WHEN CC.[Product] IN ('LG Washing Machine', 'LG Dryer') 
            THEN 'Home Appliances'
            ELSE 'Others'
        END,
    
    Is_Expensive = 
        CASE
            WHEN CC.[Price_Each] > 1000 THEN 'Yes'
            ELSE 'No'
        END,
    
    Season = 
        CASE
            WHEN MONTH(CC.[Order_Date]) IN (12, 1, 2) THEN 'Winter'
            WHEN MONTH(CC.[Order_Date]) IN (3, 4, 5) THEN 'Spring'
            WHEN MONTH(CC.[Order_Date]) IN (6, 7, 8) THEN 'Summer'
            WHEN MONTH(CC.[Order_Date]) IN (9, 10, 11) THEN 'Fall'
        END,
    
    Holiday_Season = 
        CASE
            WHEN MONTH(CC.[Order_Date]) = 1 AND DAY(CC.[Order_Date]) = 1 THEN 'New Year'
            WHEN MONTH(CC.[Order_Date]) = 2 AND DAY(CC.[Order_Date]) = 14 THEN 'Valentine''s Day'
            WHEN MONTH(CC.[Order_Date]) = 4 AND DAY(CC.[Order_Date]) = 21 THEN 'Easter'
            WHEN MONTH(CC.[Order_Date]) = 5 AND DAY(CC.[Order_Date]) = 1 THEN 'Labor Day'
            WHEN MONTH(CC.[Order_Date]) = 7 AND DAY(CC.[Order_Date]) = 4 THEN 'Independence Day'
            WHEN MONTH(CC.[Order_Date]) = 11 AND DAY(CC.[Order_Date]) = 28 THEN 'Thanksgiving'
            WHEN MONTH(CC.[Order_Date]) = 11 AND DAY(CC.[Order_Date]) = 29 THEN 'Black Friday'
            WHEN MONTH(CC.[Order_Date]) = 12 AND DAY(CC.[Order_Date]) = 25 THEN 'Christmas'
            WHEN MONTH(CC.[Order_Date]) = 12 AND DAY(CC.[Order_Date]) = 31 THEN 'New Year''s Eve'
            ELSE 'No Holiday'
        END,
    
    Repeat_Customer = 
        CASE
            WHEN CC.Repeat_Customer_Count > 1 THEN 'Yes'
            ELSE 'No'
        END
FROM CustomerCounts CC
WHERE [dbo].[Sales Data].[Order_ID] = CC.[Order_ID];
--Check
select *
from [dbo].[Sales Data]
--lấy ra các tên cột
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Sales Data'
