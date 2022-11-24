
/*Exercise 1
How many products were available for sale on 1 Jan 2013 ?
*/

SELECT COUNT(ProductID) AS 'Number of Products' 
FROM Production.Product
WHERE SellStartDate <= '2013-01-01'
AND SellEndDate > '2013-01-01'
AND SafetyStockLevel != 0;


/*Excersie 2
Who were our top 5 customers in 2012 to 2013 ?
*/

--2a)Top 5 Customers in 2012 to 2013 by Total Payments( i.e. Sum of TotalDue)
SELECT TOP 5
	   sub.CustomerID,
	   sc.Name,
	   sub.TotalSales
FROM Sales.vStoreWithContacts sc,
     Sales.Customer c,
	 Person.BusinessEntityContact be, 
	 (SELECT TOP 5 CustomerID, ROUND(SUM(TotalDue),2) AS TotalSales
	 FROM Sales.SalesOrderHeader  
	 WHERE OrderDate BETWEEN '2012-01-01' AND '2013-12-31'  
	 GROUP BY CustomerID
	 ORDER BY TotalSales DESC) sub
WHERE sub.CustomerID = c.CustomerID
AND c.PersonID = be.PersonID
AND be.BusinessEntityID = sc.BusinessEntityID;

--2b)Top 5 Customers in 2012 to 2013 by profits generated.
SELECT 
	   sub.CustomerID,
	   sc.Name,
	   sub.SumOfProfit
FROM Sales.vStoreWithContacts sc,
     Sales.Customer c,
	 Person.BusinessEntityContact be, 
	 (SELECT TOP 5
			 oh.CustomerID, 
	 	     ROUND (SUM( od.UnitPrice - pp.StandardCost), 2) AS SumOfProfit
	 FROM Sales.SalesOrderHeader oh, Sales.SalesOrderDetail od, Production.Product pp  
	 WHERE OrderDate BETWEEN '2012-01-01' AND '2013-12-31' 
	 AND od.ProductID = pp.ProductID
	 AND od.SalesOrderID = oh.SalesOrderID
	 GROUP BY oh.CustomerID
	 ORDER BY SumOfProfit DESC) sub
WHERE sub.CustomerID = c.CustomerID
AND c.PersonID = be.PersonID
AND be.BusinessEntityID = sc.BusinessEntityID;


/*Exercise 3
Briefly explain how you defined “top 5” for exercise 2. above

=ANSWER=
In 2a, I categorized the top 5 customers by the total payment amount each customer has made. This was derived using the sum of TotalDue amount.
In 2b, I produced the top 5 customers by the total profit amount generated. This was calculated using the sum of profit generated from the sale of each product.
*/

/*Exercise 4
Produce a report showing breakdown of sales in each currency we transacted in for 2013.
Include any key figures you consider relevant for each currency.
*/

SELECT  c.CurrencyCode, 
		c.Name AS 'Currency Name', 
		COUNT(*) AS 'Count of Orders',
		ROUND(SUM(oh.TotalDue), 2) AS 'Sales Amount in USD',
		ROUND(SUM(oh.TotalDue)*100/(SELECT SUM(TotalDue) 
								   FROM Sales.SalesOrderHeader
								   WHERE OrderDate BETWEEN '2013-01-01' AND '2013-12-31'),0) AS 'Sales in %'
FROM Sales.SalesOrderHeader oh
		LEFT JOIN Sales.CurrencyRate cr
			ON oh.currencyRateID = cr.currencyRateID
		LEFT JOIN Sales.Currency c
			ON cr.ToCurrencyCode = c.currencyCode
WHERE oh.OrderDate BETWEEN '2013-01-01' AND '2013-12-31'
GROUP BY c.CurrencyCode, c.Name
ORDER BY 'Sales Amount in USD' DESC;

/*Exercise 5
5. What is the average number of items ordered on each sale ?
*/

SELECT AVG (ItemCount) AS 'Average Items Ordered'
FROM (SELECT SalesOrderID, 
		     COUNT(ProductID) AS ItemCount
	  FROM Sales.SalesOrderDetail
	  GROUP BY SalesOrderID) ItemOrdered;


/*Exercise 6
6. Which is the order that had the largest number of individual items ? How does this order
rank amongst all orders in terms of freight cost ?
*/

SELECT TOP 2 od.SalesOrderID, 
	   COUNT(od.ProductID) AS ItemCount ,
	   ROUND(SUM(oh.Freight)*100/(SELECT SUM(Freight) 
								 FROM Sales.SalesOrderHeader),2) AS '%FrieghtCost'
FROM Sales.SalesOrderDetail od, Sales.SalesOrderHeader oh
WHERE od.SalesOrderID = oh.SalesOrderID
GROUP BY od.SalesOrderID
ORDER BY ItemCount DESC;

/*Excercise 7
7. What were our top selling products in 2013 ? Analyse this question from multiple angles –
popularity, profitability etc.
*/

--7a)Top 10 selling products in 2013
SELECT TOP 10 
	   od.ProductID,
	   pp.Name,
	   ROUND (SUM(oh.SubTotal), 2) AS TotalSale
FROM Sales.SalesOrderDetail od, Sales.SalesOrderHeader oh, Production.Product pp
WHERE od.SalesOrderID = oh.SalesOrderID
AND od.ProductID = pp.ProductID
AND oh.OrderDate BETWEEN '2013-01-01' AND '2013-12-31'
GROUP BY od.ProductID,pp.Name
ORDER BY TotalSale DESC;

--7b)Top 10 popular products in 2013
SELECT TOP 10 
	   od.ProductID,
	   pp.Name,
	   COUNT(pp.ProductID) AS ItemCount
FROM Sales.SalesOrderDetail od, Sales.SalesOrderHeader oh, Production.Product pp
WHERE od.SalesOrderID = oh.SalesOrderID
AND od.ProductID = pp.ProductID
AND oh.OrderDate BETWEEN '2013-01-01' AND '2013-12-31'
GROUP BY od.ProductID,pp.Name
ORDER BY ItemCount DESC;

--7c)Top 10 Profitable Products in 2013
SELECT TOP 10 
	   od.ProductID,
	   pp.Name,
	   ROUND (SUM( od.UnitPrice - pp.StandardCost), 2) AS SumOfProfit
FROM Sales.SalesOrderDetail od, Sales.SalesOrderHeader oh, Production.Product pp
WHERE od.SalesOrderID = oh.SalesOrderID
AND od.ProductID = pp.ProductID
AND oh.OrderDate BETWEEN '2013-01-01' AND '2013-12-31'
GROUP BY od.ProductID,pp.Name
ORDER BY SumOfProfit DESC;

--7d)Top 10 Profitable Products in Other Currency in 2013
SELECT TOP 10 
	   od.ProductID,
	   pp.Name AS ProductName,
	   ROUND (SUM(oh.SubTotal), 2) AS TotalSale
FROM Sales.SalesOrderDetail od, Sales.SalesOrderHeader oh, Production.Product pp
WHERE od.SalesOrderID = oh.SalesOrderID
AND od.ProductID = pp.ProductID
AND oh.OrderDate BETWEEN '2013-01-01' AND '2013-12-31'
AND oh.CurrencyRateID IS NOT NULL
GROUP BY od.ProductID,pp.Name
ORDER BY TotalSale DESC;

--7e)Top 10 Profitable Products in Originally in USD in 2013
SELECT TOP 10 
	   od.ProductID,
	   pp.Name AS ProductName,
	   ROUND (SUM(oh.SubTotal), 2) AS TotalSale
FROM Sales.SalesOrderDetail od, Sales.SalesOrderHeader oh, Production.Product pp
WHERE od.SalesOrderID = oh.SalesOrderID
AND od.ProductID = pp.ProductID
AND oh.OrderDate BETWEEN '2013-01-01' AND '2013-12-31'
AND oh.CurrencyRateID IS NULL
GROUP BY od.ProductID,pp.Name
ORDER BY TotalSale DESC;

--7f)Top 10 Discounted Products in 2013
SELECT TOP 10 
	   od.ProductID,
	   pp.Name AS ProductName,
	   ROUND (SUM( od.UnitPriceDiscount), 2) AS SumOfDiscount
FROM Sales.SalesOrderDetail od, Sales.SalesOrderHeader oh, Production.Product pp
WHERE od.SalesOrderID = oh.SalesOrderID
AND od.ProductID = pp.ProductID
AND oh.OrderDate BETWEEN '2013-01-01' AND '2013-12-31'
GROUP BY od.ProductID,pp.Name
ORDER BY SumOfDiscount DESC;

