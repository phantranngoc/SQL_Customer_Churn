---- QUESTION 1: Compare the quantity of orders in different years---------------

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

--- Notes:  The question was addressed with the CTE and Window functions. It's faster than Excel. 

---- QUESTION 1: Compare the quantity of orders in different years-----------------------


