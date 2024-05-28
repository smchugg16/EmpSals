/* Exploratory Analysis */

---Check Columns---
SELECT *
FROM EmpData.dbo.EmpSals
ORDER BY EmployeeID;

---Deleting Null Rows (Just In Case)---
DELETE FROM EmpData.dbo.EmpSals
WHERE EmployeeID IS NULL OR Name IS NULL;

---Basic Stats (Min, Max, Mean, Median)---
SELECT MIN(Salary) AS Min_Salary, MAX(Salary) AS Max_Salary, AVG(Salary) AS Mean_Salary,
    MIN(Raise) AS Min_Raise, MAX(Raise) AS Max_Raise, AVG(Raise) AS Mean_Raise
FROM (
    SELECT EmployeeID, Salary,
		MAX(Salary) OVER (PARTITION BY EmployeeID) - MIN(Salary) OVER (PARTITION BY EmployeeID) AS Raise
    FROM EmpData.dbo.EmpSals
) AS EmpStats
WHERE Raise > 0;

WITH SalaryMedian AS (
    SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Salary) OVER () AS Median_Salary
    FROM EmpData.dbo.EmpSals
),
RaiseMedian AS (
    SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Raise) OVER () AS Median_Raise
    FROM (
        SELECT EmployeeID, 
            MAX(Salary) - MIN(Salary) AS Raise
        FROM EmpData.dbo.EmpSals
        GROUP BY EmployeeID
        HAVING MAX(Salary) - MIN(Salary) > 0
    ) AS Raises
)
SELECT TOP 1 Median_Salary, Median_Raise
FROM SalaryMedian, RaiseMedian;

------------
/*a. Write a query to find each employee’s most recent salary.
b. Write a query to calculate the total amount of money each employee has
earned since they started working at this company.
c. Write a query to calculate which department had the highest payroll each
year.
d. Provide written explanations of each query in a-c, how each works, and why
you wrote the query the way you did.
e. Write a short narrative (two or three paragraphs) summarizing the findings
and making any recommendations you think appropriate.
*/

---Most Recent Salary---
SELECT EmployeeID, Name, Dept, Salary, StartDate
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY EmployeeID ORDER BY StartDate DESC) AS rownum
    FROM EmpData.dbo.EmpSals
) AS sub
WHERE rownum = 1
ORDER BY EmployeeID;


---Total Amount Made per Employee---
SELECT EmployeeID,Name,
    ROUND(SUM(FLOOR(DATEDIFF(Day, StartDate, EndDate) * Salary)/365), 2) AS TotalEarnings
FROM EmpData.dbo.EmpSals
GROUP BY EmployeeId, Name
ORDER BY EmployeeID;


---Highest Paid Department Each Year---
WITH RankedDepartments AS (
    SELECT YEAR(StartDate) AS Year, Dept, SUM(salary) AS TotalSalary,
           ROW_NUMBER() OVER (PARTITION BY Year(StartDate) ORDER BY SUM(salary) DESC) AS rank
    FROM EmpData.dbo.EmpSals
    GROUP BY Year(StartDate), Dept
)
SELECT Year, Dept, TotalSalary
FROM RankedDepartments
WHERE rank = 1
ORDER BY Year desc;
