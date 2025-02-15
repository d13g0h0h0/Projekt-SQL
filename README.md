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
| Types | Modele pojazdów |
| Vehicles | Informacje na temat posiadanych pojazdów |
| Employees | Dane pracowników firmy, z której dziedziczą Drivers, Mechanics i Inspectors (Table-Per-Type) |
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
Funkcja ta przyjmuje ID kontrolera biletów, po czym na podstawie ilości wystawionych przez niego mandatów w ubiegłym miesiącu, oblicza stosowną premię pieniężną.

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
Funkcja przyjmuje ID pojazdu, następnie sprawdza, kiedy wypada jego następna rutynowa kontrola, oblicza jej datę na podstawie roku produkcji i ilości awarii pojazdu.

## Widoki
##### VehicleNextInspection
```sql
CREATE VIEW VehicleNextInspection AS
SELECT
	V.ID AS VehicleID,
	V.LastInspectionDate,
	dbo.CalculateNextInspectionDate(V.ID) AS NextInspectionDate
FROM Vehicles V;
```
Widok wyświetla dla wszystkich pojazdów przedsiębiorstwa ich następną datę inspekcji.
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
Widok pokazuje wszystkie obecnie uszkodzone pojazdy.

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
Widok wyświetla sumaryczną ilość wystawionych mandatów dla każdego kontrolera.

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
Widok podsumowujący sprzedaż biletów w miesięcznych interwałach czasowych.

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
Po otrzymaniu ID linii, wyświetla jej całą trasę.

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
Po otrzymaniu ID lini, oraz przedziału czasowego, zwraca statystyki sprzedaży biletów dla tej lini w podanym okresie.

##### AddEmployee
```sql
CREATE PROCEDURE AddEmployee
(
	@FirstName NVARCHAR(128),
	@LastName NVARCHAR(128),
	@PESEL NVARCHAR(11),
	@DateOfBirth DATE,
	@DateOfEmployment DATE,
	@Salary MONEY,
	@Type NVARCHAR(20),
	@Details NVARCHAR(20)
)
	AS
	IF EXISTS(SELECT E.PESEL FROM Employees E WHERE PESEL = @PESEL)
	BEGIN
		PRINT(N'Ten numer PESEL jest już zajęty, dodanie nowego pracownika nie powiodło się.')
	END
	ELSE
	BEGIN
		IF @Type NOT IN(N'Kierowca', N'Mechanik', N'Kontroler')
		BEGIN
			PRINT(N'Podano niepoprawną kategorię pracownika, dodanie nowego pracownika nie powiodło się.')
		END
		ELSE
		BEGIN
			INSERT INTO Employees VALUES (@FirstName, @LastName, @PESEL, @DateOfBirth, @DateOfEmployment, @Salary)
			DECLARE @ID INT = (SELECT E.ID FROM Employees E WHERE PESEL = @PESEL);
			IF @Type = N'Kierowca' INSERT INTO Drivers VALUES (@ID, @Details)
			IF @Type = N'Mechanik' INSERT INTO Mechanics VALUES (@ID, @Details)
			IF @Type = N'Kontroler' INSERT INTO Inspectors VALUES (@ID, @Details)
		END
	END;
```
Po otrzymaniu danych o nowym pracowniku, sprawdza, czy podany numer PESEL nie był już wcześniej użyty w tabeli Employees. Jeżeli nie był, dane pracownika są dodawane do tabeli Employees oraz dokładnie jednej spośród tabel Drivers, Mechanics lub Inspectors, w zależności od roli pracownika podanej przedostatnim argumentem.
## Wyzwalacze
##### DeleteDriver
```sql
CREATE TRIGGER DeleteDriver ON Drivers
AFTER DELETE
AS
	DECLARE Employee_Cursor CURSOR FOR
	SELECT ID_Driver FROM DELETED;
	OPEN Employee_Cursor
	DECLARE @ID INT
	FETCH Employee_Cursor INTO @ID
	WHILE @@FETCH_STATUS = 0
	BEGIN
		DELETE FROM Employees WHERE ID = @ID;
		FETCH Employee_Cursor INTO @ID
	END
	CLOSE Employee_Cursor
	DEALLOCATE Employee_Cursor
```
Po usunięciu danych jednego lub więcej kierowców z tabeli Drivers, automatycznie usuwa odpowiednie dane z tabeli Employees.
##### DeleteMechanic
```sql
CREATE TRIGGER DeleteMechanic ON Mechanics
AFTER DELETE
AS
	DECLARE Employee_Cursor CURSOR FOR
	SELECT ID_Mechanic FROM DELETED;
	OPEN Employee_Cursor
	DECLARE @ID INT
	FETCH Employee_Cursor INTO @ID
	WHILE @@FETCH_STATUS = 0
	BEGIN
		DELETE FROM Employees WHERE ID = @ID;
		FETCH Employee_Cursor INTO @ID
	END
	CLOSE Employee_Cursor
	DEALLOCATE Employee_Cursor
```
Po usunięciu danych jednego lub więcej mechaników z tabeli Mechanics, automatycznie usuwa odpowiednie dane z tabeli Employees.
##### DeleteInspector
```sql
CREATE TRIGGER DeleteInspector ON Inspectors
AFTER DELETE
AS
	DECLARE Employee_Cursor CURSOR FOR
	SELECT ID_Inspector FROM DELETED;
	OPEN Employee_Cursor
	DECLARE @ID INT
	FETCH Employee_Cursor INTO @ID
	WHILE @@FETCH_STATUS = 0
	BEGIN
		DELETE FROM Employees WHERE ID = @ID;
		FETCH Employee_Cursor INTO @ID
	END
	CLOSE Employee_Cursor
	DEALLOCATE Employee_Cursor
```
Po usunięciu danych jednego lub więcej kontrolerów z tabeli Inspectors, automatycznie usuwa odpowiednie dane z tabeli Employees.
##### AddFailure
```sql
CREATE TRIGGER AddFailure ON VehicleFailures
AFTER INSERT
AS
	DECLARE Failure_Cursor CURSOR FOR
	SELECT ID, ID_Vehicle, ID_Mechanic FROM DELETED;
	OPEN Failure_Cursor
	DECLARE @ID_Row INT
	DECLARE @ID_Vehicle INT
	DECLARE @ID_Mechanic INT
	FETCH Failure_Cursor INTO @ID_Row, @ID_Vehicle, @ID_Mechanic
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @ID_Mechanic IS NULL
		BEGIN
			DECLARE @Vehicle_Depot INT
			SELECT @Vehicle_Depot = VDM.ID_Depot
			FROM Vehicles V JOIN VehicleDepotMap VDM ON V.ID = VDM.ID_Vehicle
			WHERE V.ID = @ID_Vehicle

			IF EXISTS (
				SELECT M.ID_Mechanic
				FROM Mechanics M JOIN MechanicDepotMap MDM ON M.ID_Mechanic = MDM.ID_Mechanic
				WHERE MDM.ID_Depot = @Vehicle_Depot AND M.ID_Mechanic NOT IN 
				(SELECT VF.ID_Mechanic FROM VehicleFailures VF WHERE VF.RepairDate IS NULL)
			)
			BEGIN
				SET @ID_Mechanic = (
					SELECT TOP 1 M.ID_Mechanic
					FROM Mechanics M JOIN MechanicDepotMap MDM ON M.ID_Mechanic = MDM.ID_Mechanic
					WHERE MDM.ID_Depot = @Vehicle_Depot AND M.ID_Mechanic NOT IN 
					(SELECT VF.ID_Mechanic FROM VehicleFailures VF WHERE VF.RepairDate IS NULL AND VF.ID_Mechanic IS NOT NULL)
				)
				UPDATE VehicleFailures
				SET ID_Mechanic = @ID_Mechanic
				WHERE ID = @ID_Row
				PRINT(N'Udało się znaleźć wolnego mechanika, dodano go do zgłoszenia.')
			END
			ELSE
			BEGIN
				PRINT(N'Nie udało się znaleźć wolnego mechanika.')
			END
		END
		FETCH Failure_Cursor INTO @ID_Vehicle, @ID_Mechanic
	END
	CLOSE Failure_Cursor
	DEALLOCATE Failure_Cursor
```
Po dodaniu informacji o jednej lub większej liczbie usterek do tabeli VehicleFailures z wartością ```sql NULL``` w polu ID_Mechanic, próbuje znaleźć mechaników, którzy pracują w hangarze danego pojazdu i nie są zajęci naprawianiem innego pojazdu. W przypadku znalezienia takowych, jeden z nich jest przypisywany do naprawy danego pojazdu.
##### AddTicketSale
```sql
CREATE TRIGGER AddTicketSale ON TicketSales
INSTEAD OF INSERT
AS
	DECLARE Ticket_Cursor CURSOR FOR
	SELECT TicketID, Quantity FROM INSERTED;
	OPEN Ticket_Cursor
	DECLARE @TicketID INT
	DECLARE @Quantity INT
	DECLARE @TooFewTickets BIT
	SET @TooFewTickets = 0
	FETCH Ticket_Cursor INTO @TicketID, @Quantity
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF (SELECT T.TotalNumber FROM Tickets T WHERE T.ID = @TicketID) < @Quantity
		BEGIN SELECT * FROM Tickets
			SET @TooFewTickets = 1
		END
		FETCH Ticket_Cursor INTO @TicketID, @Quantity
	END
	CLOSE Ticket_Cursor
	DEALLOCATE Ticket_Cursor
	IF @TooFewTickets = 0
	BEGIN
		INSERT INTO TicketSales (TicketID, Quantity, LineID, SaleDate)
		SELECT I.TicketID, I.Quantity, I.LineID, I.SaleDate FROM INSERTED I;
		DECLARE Ticket_Cursor2 CURSOR FOR
		SELECT TicketID, Quantity FROM INSERTED;
		OPEN Ticket_Cursor2
		FETCH Ticket_Cursor2 INTO @TicketID, @Quantity
		WHILE @@FETCH_STATUS = 0
		BEGIN
			UPDATE Tickets
			SET TotalNumber = TotalNumber - @Quantity
			WHERE ID = @TicketID
			FETCH Ticket_Cursor2 INTO @TicketID, @Quantity
		END
		CLOSE Ticket_Cursor2
		DEALLOCATE Ticket_Cursor2
		PRINT(N'Transakcja się powiodła.')
	END
	ELSE
	BEGIN
		PRINT(N'Transakcja się nie powiodła, brakuje biletów.')
	END
```
Przy próbie dodania nowych zakupów biletów do tabeli AddTicketSales sprawdza, czy jest dostępna odpowiednia liczba biletów. Jeżeli wystarcza biletów wszystkich żądanych typów, dane sprzedaży biletów są odzwierciedlane w bazie danych, w przeciwnym razie żadne dane nie są zmieniane i wyświetlane jest powiadomienie o niewystarczającej liczbie biletów.
## Przykładowe zapytania 
##### Dodanie nowego pracownika
```sql
EXEC AddEmployee N'Stefan', N'Kotarski', N'98041365776', '1998-04-13', '2025-01-30', 5000.00, N'Kierowca', N'A';
```
##### Dopisanie informacji o nowej usterce
```sql
INSERT INTO VehicleFailures VALUES
(1, NULL, '2025-01-22', NULL, N'Broken axle')
```

