# Baza danych przedsiębiorstwa komunikacji miejskiej
### Diego Ostoja-Kowalski, Piotr Pabian
## Założenia 
Projekt jest implementacją bazy danych lokalnego przedsiębiorstwa komunikacji miejskiej. Ułatwia on pielęgnowanie i gromadzenie różnych danych statysycznych potrzebnych do prawidłowego działania firmy. Oferuje on również uzyskiwanie przydatnych informacji dla konsumentów takich jak np. połączenia bezpośrednie między przystankami. 
## Strategia pielęgnacji 
## Diagram ER
## Schemat bazy danych
## Tabele
| Nazwa tabeli | Przechowywane dane |
| --- | --- |
| Stops | Informacje na temat przystanków |
| Lines | Informacje na temat lini |
| LinesStopMap | Łączy przystanki wraz z obsługiwanymi liniami pojazdów |
| TimeTables | Godziny odjazdów  |
| Types | rodzaje pojazdów |
| Vehicles | Informacje na temat posiadanych pojazdów |
| Employees | Dane pracowników firmy |
| Tickets | Informacje o sprzedawanych biletach |
| TicketSales | Historia sprzedaży biletów |
| Drivers | Kategorie praw jazdy kierowców |
| Mechanics | Informacja na temat specjalizacji mechanika |
| Inspectors | Znane języki obce kontrolerów |
| LineDriveMap | Przypisuje kierowców do poszczególnych lini |
| Depots | Informacje na temat hangarów |
| VehicleDepotMap | Informacje na temat ulokowania pojazdów w hangarach |
| MechanicDepotMap | Rozmieszczenie mechaników w hangarach |
| ControlData | Historia kontroli biletów |
| VehicleFailures | Historia awarii pojazdów |
## Funkcje
##### CalculateInspectorBonus
```sql 
CREATE FUNCTION CalculateInspectorBonus (@InspectorID INT)
RETURNS MONEY
AS
BEGIN
	DECLARE @Bonus MONEY;
	DECLARE @Month INT;
	DECLARE @Year INT;
	IF MONTH(GETDATE()) = 1
	BEGIN
		SET @Month = 12;
		SET @Year = YEAR(GETDATE()) - 1;
	END
	ELSE
	BEGIN
		SET @Month = MONTH(GETDATE()) - 1;
		SET @Year = YEAR(GETDATE());
	END
	SELECT @Bonus = ISNULL(SUM(C.NumberOfFines) * 10, 0)
	FROM ControlData C
	WHERE C.ID_Inspector = @InspectorID
		AND MONTH(C.Date) = @Month
		AND YEAR(C.Date) = @Year;
	RETURN @Bonus;
END;
```
Funkcja ta przyjmuje id kontrolera biletów, po czym na podstawie ilości wystawionych przez niego mandatów w ubiegłym miesiącu, oblicza stosowną premie pieniężną.

##### CalculateNextInspectionDate
```sql
CREATE FUNCTION CalculateNextInspectionDate (@VehicleID INT)
RETURNS DATE
AS
BEGIN
	DECLARE @ProductionDate DATE;
	DECLARE @LastInspectionDate DATE;
	DECLARE @FailureCount INT;
	DECLARE @YearsSinceProduction INT;
	DECLARE @MonthsToAdvance INT;
	DECLARE @NextInspectionDate DATE;
	SELECT
		@ProductionDate = ProductionDate,
		@LastInspectionDate = LastInspectionDate
	FROM Vehicles
	WHERE ID = @VehicleID;
	SELECT
		@FailureCount = COUNT(*)
	FROM VehicleFailures
	WHERE ID_Vehicle = @VehicleID;
	SET @YearsSinceProduction = DATEDIFF(YEAR, @ProductionDate, @LastInspectionDate);
	SET @MonthsToAdvance = (@YearsSinceProduction / 5) * 2 + @FailureCount;
	SET @NextInspectionDate = DATEADD(MONTH, -@MonthsToAdvance, DATEADD(YEAR, 5, @LastInspectionDate));
	RETURN @NextInspectionDate;
END;
``` 
Funkcja przyjmuje id pojazdu, następnie sprawdza kiedy wypada jego następna rutynowa kontrola, oblicza jej datę na podstawie roku produkcji i ilości awarii pojazdu.

## Widoki
### VehicleNextInspection
```sql
CREATE VIEW VehicleNextInspection AS
SELECT
	V.ID AS VehicleID,
	V.LastInspectionDate,
	dbo.CalculateNextInspectionDate(V.ID) AS NextInspectionDate
FROM Vehicles V;
```
Widok wyświetla dla wszystkich pojazdów przedsiębiorstwa ich następną datę inspekcji
#####  EmployeeSalaryWithBonus
```sql
CREATE VIEW EmployeeSalaryWithBonus AS
SELECT
	E.ID AS EmployeeID,
	E.Salary AS StandardSalary,
	ISNULL(dbo.CalculateInspectorBonus(E.ID), 0) AS Bonus,
	(E.Salary + ISNULL(dbo.CalculateInspectorBonus(E.ID), 0)) AS GrossTotalSalary,
	(E.Salary + ISNULL(dbo.CalculateInspectorBonus(E.ID), 0)) * 0.8 AS NetTotalSalary
FROM Employees E;
```
Widok wyświetla płace wszystkich pracowników w wariacji netto i brutto, już po uwzględnieniu premii.

##### BrokenVehicles
```sql
CREATE VIEW BrokenVehicles AS
	SELECT *
	FROM VehicleFailures
	WHERE RepairDate IS NULL;
```
Widok pokazuje wszystkie obecnie uskodzone pojazdy.

##### InspectorFinesByYear
```sql
CREATE VIEW InspectorFinesByYear AS
	SELECT
		I.ID_Inspector AS InspectorID,
		Y.Year,
		ISNULL(SUM(c.NumberOfFines), 0) AS TotalFines
	FROM
		(SELECT DISTINCT YEAR(Date) AS Year FROM ControlData) Y
	CROSS JOIN
		Inspectors	I
	LEFT JOIN
		ControlData C ON I.ID_Inspector = C.ID_Inspector AND YEAR(C.Date) = Y.Year
	GROUP BY
		I.ID_Inspector , Y.Year;
```
Widok wyświetla sumaryczną ilość wystawionych mandatów dla każdego inspektora.

##### SalaryStatsByWorkerType
```sql
CREATE VIEW SalaryStatsByWorkerType AS
	SELECT 
		'Mechanics' AS WorkerType,
		ROUND(AVG(E.Salary), 2) AS AvgSalary,
		MIN(e.Salary) AS MinSalary,
		MAX(e.Salary) AS MaxSalary,
		SUM(e.Salary) AS TotalSalary
	FROM 
		Employees E
	JOIN 
		Mechanics M ON E.ID = M.ID_Mechanic
	UNION ALL
	SELECT 
		'Inspectors' AS WorkerType,
		ROUND(AVG(E.Salary), 2) AS AvgSalary,
		MIN(E.Salary) AS MinSalary,
		MAX(E.Salary) AS MaxSalary,
		SUM(E.Salary) AS TotalSalary
	FROM
		Employees E
	JOIN
		Inspectors I ON E.ID = I.ID_Inspector
	UNION ALL
	SELECT
		'Drivers' AS WorkerType,
		ROUND(AVG(E.Salary), 2) AS AvgSalary,
		MIN(E.Salary) AS MinSalary,
		MAX(E.Salary) AS MaxSalary,
		SUM(E.Salary) AS TotalSalary
	FROM 
		Employees E
	JOIN
		Drivers D ON E.ID = D.ID_Driver;
```
Widok pokazuje dane statystyczne w sferze zarobków pracowników z podziałem na kategorie.

##### TicketSalesSummary
```sql 
CREATE VIEW TicketSalesSummary AS
	SELECT 
		T.ID AS ID_Ticket,
		Y.Year,
		M.Month,
		ISNULL(SUM(TS.Quantity), 0) AS AmountSold,
		ISNULL(SUM(CAST(TS.Quantity AS Money) * T.Price), 0) AS TotalEarnings
	FROM 
		(SELECT DISTINCT YEAR(SaleDate) AS Year FROM TicketSales) Y
	CROSS JOIN
		(SELECT DISTINCT MONTH(SaleDate) AS Month FROM TicketSales) M
	CROSS JOIN 
		Tickets t
	LEFT JOIN 
		TicketSales TS ON T.ID = TS.TicketID AND YEAR(TS.SaleDate) = Y.Year AND MONTH(TS.SaleDate) = M.Month
	GROUP BY 
		T.ID, Y.Year, M.Month;
```
Widok podsumuwujący sprzedaż biletów w miesięcznych interwałach czasowych.

##### LineFinesSummary
```sql
CREATE VIEW LineFinesSummary AS
	SELECT 
		L.ID AS ID_Line,
		L.Name AS LineName,
		ISNULL(SUM(C.NumberOfFines), 0) AS NumberOfFines
	FROM 
		Lines L
	LEFT JOIN 
		ControlData C ON l.ID = C.ID_Line
	GROUP BY
		L.ID, L.Name;
```
Dane na temat ilości wystawionych mandatów w poszczególnych liniach.
##### FinesSummaryByMonth
```sql
CREATE VIEW FinesSummaryByMonth AS
	SELECT
		MONTH(C.Date) AS Month,
		ISNULL(SUM(C.NumberOfFines), 0) AS NumberOfFines
	FROM
		ControlData C
	GROUP BY
		MONTH(C.Date);
```
Widok podsumuwujący ilość mandatów względem miesiąca. 
## Procedury
##### GetLineStops
```sql
CREATE PROCEDURE GetLineStops
(
	@LineID INT
)
AS
	SELECT
		S.ID AS StopID,
		S.Name AS StopName,
		LSM.StopOrder
	FROM
		LineStopMap LSM
	JOIN
		Stops S ON LSM.ID_Stop = S.ID
	WHERE
		LSM.ID_Line = @LineID
	ORDER BY
		LSM.StopOrder;
```
Po otrzymaniu id lini, wyświetla jej całą trasę.

##### GetDirectLinesBetweenStops
```sql
CREATE PROCEDURE GetDirectLinesBetweenStops
(
	@StopName1 NVARCHAR(256),
	@StopName2 NVARCHAR(256)
)
AS
	SELECT DISTINCT
		LSM1.ID_Line AS LineID,
		L.Name AS LineName
	FROM
		LineStopMap LSM1
	JOIN
		Stops S1 ON LSM1.ID_Stop = S1.ID
	JOIN
		LineStopMap LSM2 ON LSM1.ID_Line = LSM2.ID_Line
	JOIN
		Stops S2 ON LSM2.ID_Stop = S2.ID
	JOIN
		Lines L ON LSM1.ID_Line = L.ID
	WHERE
		S1.Name = @StopName1
		AND S2.Name = @StopName2;
```
Po otrzymaniu nazw przystanków wyświetla wszystkie linie łączącze te dwa przystanki.
##### GetTimetableForStop
```sql
CREATE PROCEDURE GetTimetableForStop
(
	@StopName NVARCHAR(256)
)
AS
	SELECT
		L.Name AS LineName,
		T.Time AS DepartureTime,
		T.Direction
	FROM
		Stops S
	JOIN
		LineStopMap LSM ON S.ID = LSM.ID_Stop
	JOIN
		Timetables T ON LSM.ID = T.ID_LineStopMap
	JOIN
		Lines L ON LSM.ID_Line = L.ID
	WHERE
		S.Name = @StopName
	ORDER BY
		T.Time;
```
Po otrzymaniu nazwy przstanku wyświetla jego rozkład jazdy.

##### GetTicketSalesReport
```sql
CREATE PROCEDURE GetTicketSalesReport
(
	@LineID INT,
	@StartDate DATE,
	@EndDate DATE
)
AS
	SELECT
		TS.SaleDate,
		T.Type AS TicketType,
		TS.Quantity,
		T.Price,
		(TS.Quantity * T.Price) AS TotalRevenue
	FROM 
		TicketSales TS
	JOIN
		Tickets T ON TS.TicketID = T.ID
	WHERE
		TS.LineID = @LineID
		AND TS.SaleDate BETWEEN @StartDate AND @EndDate
	ORDER BY
		TS.SaleDate;
```
Po otrzymaniu id lini, oraz przedziału czasowego, zwraca statyski sprzedaży biletów dla tej lini w podanym okresie.
## Wyzwalacze
## Przykładowe zapytania 
