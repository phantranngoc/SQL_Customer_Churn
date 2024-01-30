---- QUESTION 1: Compare the quantity of orders in different years---------------
---------------- Notes:  The question was addressed with the CTE and Window functions. It's faster than Excel. 
  WITH yearly_order AS (
    SELECT 
        YEAR(OrderDate) AS year, 
        COUNT(DISTINCT OrderID) AS num_orders
    FROM Sales.Orders
    GROUP BY YEAR(OrderDate)
)

-- Compare this year's sales to last year's 
SELECT 
    *, 
    LAG(num_orders) OVER (ORDER BY year) AS last_year_order, 
    num_orders - LAG(num_orders) OVER (ORDER BY year) AS diff_from_last_year
FROM yearly_order;


---- QUESTION 2: Determine the client group with the greatest financial loss due to orders not being translated into invoices.-----------------------

------------------In the database WideWorldImporters, write a SQL query which reports the highest loss of money
------------------from orders not being converted into invoices, by customer category.

------------------The name & id of the customer who generated this highest loss must also be identified.
-------------------The resultset is ordered by highest loss.

---==> Using CTE, Subqueries, and Window functions to answer this question. 

WITH  MERGE_CUS_INFOR AS ( --- find and calculate the customers who lost the money 
		SELECT CU.CustomerID, CU.CustomerName, CU_CAT.CustomerCategoryName
		FROM Sales.Customers AS CU INNER JOIN 
			Sales.CustomerCategories AS CU_CAT ON CU.CustomerCategoryID =CU_CAT.CustomerCategoryID
), 
	VALUE_LOSS AS (
		SELECT O3.CustomerID, SUM(OL.Quantity *OL.UnitPrice) AS LOSS
		FROM Sales.Orders AS O3 INNER JOIN Sales.OrderLines AS OL ON O3.OrderID = OL.OrderID
		WHERE O3.OrderID IN (

			SELECT O2.OrderID
			FROM Sales.Customers AS CU2 INNER JOIN Sales.Orders AS O2 ON CU2.CustomerID = O2.CustomerID
			WHERE O2.OrderID IN (

				SELECT O.OrderID
				FROM Sales.Orders AS O LEFT JOIN Sales.Invoices AS I ON I.OrderID = O.OrderID
				WHERE I.OrderID IS NULL
			)
		)
		GROUP BY O3.CustomerID
)
	SELECT
		CustomerCategoryName,
		LOSS AS MaxLoss,
		CustomerName,
		CustomerID
	FROM (
		SELECT
			MER_CUS.CustomerCategoryName,
			VL.LOSS,
			MER_CUS.CustomerName,
			MER_CUS.CustomerID,

			-- Order the row with window function

			ROW_NUMBER() OVER (PARTITION BY MER_CUS.CustomerCategoryName ORDER BY VL.LOSS DESC) AS ROW_NUM

		FROM VALUE_LOSS AS VL
		INNER JOIN MERGE_CUS_INFOR AS MER_CUS ON VL.CustomerID = MER_CUS.CustomerID 
		) RANKED_DATA
	WHERE
		ROW_NUM = 1
	ORDER BY MaxLoss DESC;

---- QUESTION 3: Review customer turnover (# customer churn) by monthly, quarterly, and monthly.-----------------------
--Q3: 
--Using the database WideWorldImporters, write a T-SQL stored procedure called ReportCustomerTurnover.
--This procedure takes two parameters: Choice and Year, both integers.

--When Choice = 1 and Year = <aYear>, ReportCustomerTurnover selects all the customer names and 
-------their total monthly turnover (invoiced value) for the year <aYear>.

---When Choice = 2 and Year = <aYear>, ReportCustomerTurnover  selects all the customer names and 
----------their total quarterly (3 months) turnover (invoiced value) for the year <aYear>.

----When Choice = 3, the value of Year is ignored and ReportCustomerTurnover  
-------selects all the customer names and their total yearly turnover (invoiced value).

----When no value is provided for the parameter Choice, the default value of Choice must be 1.
-----When no value is provided for the parameter Year, the default value is 2013. This doesn't impact Choice = 3.

----For Choice = 3, the years can be hard-coded within the range of [2013-2016].

---NULL values in the resultsets are not acceptable and must be substituted to 0.

---All output resultsets are ordered by customer names alphabetically.

---Example datasets are provided for the following calls:
---EXEC dbo.ReportCustomerTurnover;
---EXEC dbo.ReportCustomerTurnover 1, 2014;
---EXEC dbo.ReportCustomerTurnover 2, 2015;

---EXEC dbo.ReportCustomerTurnover 3;

--------------------------------------------------------------------------------------
--My approach: 
--1) Find out the customers evenly who did not buy anyting (Note: join & InvoiceDate)
--2) Pivot table to transpose data 
--3) Show data as a manager's request: Jan instead of 1

--4) Try to solve the monthly=> can deal with quarterly, and Monthly 

--) Note for the year: show results not affected by the choice of year

----------------------------------------------------------------------------------------

CREATE PROCEDURE ReportCustomerTurnover
    @Choice INT = 1,
    @Year INT = 2013
AS
BEGIN
    SET NOCOUNT ON;

    IF @Choice = 1
    BEGIN
       SELECT 
			CustomerName, 
            ISNULL([1], 0) AS Jan,
            ISNULL([2], 0) AS Feb,
            ISNULL([3], 0) AS Mar,
            ISNULL([4], 0) AS Apr,
            ISNULL([5], 0) AS May,
            ISNULL([6], 0) AS Jun,
            ISNULL([7], 0) AS Jul,
            ISNULL([8], 0) AS Aug,
            ISNULL([9], 0) AS Sep,
            ISNULL([10], 0) AS Oct,
            ISNULL([11], 0) AS Nov,
            ISNULL([12], 0) AS Dec
        FROM (
            SELECT 
                C.CustomerName,
                ISNULL(MONTH(I.InvoiceDate), 0) AS Month_order,
                ISNULL(SUM(IL.Quantity * IL.UnitPrice), 0) AS MonthlyTurnover
            FROM
                Sales.Customers AS C
				LEFT JOIN Sales.Invoices AS I ON c.CustomerID = I.CustomerID AND YEAR(I.InvoiceDate) = @Year
				LEFT JOIN Sales.InvoiceLines AS IL ON I.InvoiceID = IL.InvoiceID
            GROUP BY
                C.CustomerName, MONTH(I.InvoiceDate)

        ) AS Table_monthly_turnover
        
		PIVOT 
        (
            SUM(MonthlyTurnover) FOR Month_order IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])

        ) AS PivotTable_monthy_turnover  

        ORDER BY CustomerName;

    END

    ELSE IF @Choice = 2

		BEGIN
	        SELECT 
            CustomerName,
            ISNULL([1], 0) AS Q1,
            ISNULL([2], 0) AS Q2,
            ISNULL([3], 0) AS Q3,
            ISNULL([4], 0) AS Q4

			 FROM (
					SELECT 
						C.CustomerName,
						DATEPART(QUARTER, i.InvoiceDate) AS Quarter_order,
						ISNULL(SUM(il.Quantity * il.UnitPrice), 0) AS QuarterlyTurnover

					FROM
						Sales.Customers AS C
						LEFT JOIN Sales.Invoices AS I ON c.CustomerID = I.CustomerID AND YEAR(I.InvoiceDate) = @Year
						LEFT JOIN Sales.InvoiceLines AS IL ON I.InvoiceID = IL.InvoiceID

					GROUP BY
						C.CustomerName, DATEPART(QUARTER, I.InvoiceDate)

				) AS Table_quarterly_turnover
        
			PIVOT 
				(
					SUM(QuarterlyTurnover) FOR Quarter_order IN ([1] , [2] , [3] , [4])

				) AS PivotTable_quarterly_turnover 
			
			ORDER BY CustomerName;
		END

    ELSE IF @Choice = 3

    BEGIN
        SELECT 
            CustomerName,
            ISNULL([2013], 0) AS [2013],
            ISNULL([2014], 0) AS [2014],
            ISNULL([2015], 0) AS [2015],
            ISNULL([2016], 0) AS [2016]
        FROM (
            SELECT 
                C.CustomerName,
                YEAR(I.InvoiceDate) AS Year_order,
                ISNULL(SUM(IL.Quantity * IL.UnitPrice), 0) AS YearlyTurnover

            FROM
                Sales.Customers AS C
				LEFT JOIN Sales.Invoices AS I ON C.CustomerID = I.CustomerID AND YEAR(I.InvoiceDate) = YEAR(I.InvoiceDate)
				LEFT JOIN Sales.InvoiceLines AS IL ON I.InvoiceID = IL.InvoiceID

            GROUP BY
                C.CustomerName, YEAR(I.InvoiceDate)

        ) AS Table_yearly_turnover
       
	   PIVOT 
       
			(
				SUM(YearlyTurnover) FOR Year_order IN ([2013], [2014], [2015], [2016])

			) AS PivotTable_yearly_turnover 
       
	   ORDER BY CustomerName;
    END

END;
GO

USE [WideWorldImporters]
GO

DECLARE @choice int;
DECLARE @year int;

-- TODO: Set parameter values here.
SET @Choice= 3;
SET @Year = 2015;
EXECUTE  [dbo].[ReportCustomerTurnover] 
   @Choice
  ,@Year;
GO

------------
drop procedure ReportCustomerTurnover (--use it if you need to re-run or test the code)



