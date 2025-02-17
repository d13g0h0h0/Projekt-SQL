CREATE DATABASE MPK_Baza
GO
USE MPK_Baza

IF OBJECT_ID('GetTicketSalesReport', 'P') IS NOT NULL
    DROP PROCEDURE GetTicketSalesReport;
IF OBJECT_ID('GetTimetableForStop', 'P') IS NOT NULL
    DROP PROCEDURE GetTimetableForStop;
IF OBJECT_ID('GetDirectLinesBetweenStops', 'P') IS NOT NULL
    DROP PROCEDURE GetDirectLinesBetweenStops;
IF OBJECT_ID('GetLineStops', 'P') IS NOT NULL
    DROP PROCEDURE GetLineStops;
IF OBJECT_ID('EmployeeSalaryWithBonus', 'V') IS NOT NULL
    DROP VIEW EmployeeSalaryWithBonus;
IF OBJECT_ID('VehicleNextInspection', 'V') IS NOT NULL
    DROP VIEW VehicleNextInspection;
IF OBJECT_ID('CalculateNextInspectionDate', 'FN') IS NOT NULL
    DROP FUNCTION CalculateNextInspectionDate;
IF OBJECT_ID('CalculateInspectorBonus', 'FN') IS NOT NULL
    DROP FUNCTION CalculateInspectorBonus;
IF OBJECT_ID('FinesSummaryByMonth', 'V') IS NOT NULL
    DROP VIEW FinesSummaryByMonth;
IF OBJECT_ID('LineFinesSummary', 'V') IS NOT NULL
    DROP VIEW LineFinesSummary;
IF OBJECT_ID('TicketSalesSummary', 'V') IS NOT NULL
    DROP VIEW TicketSalesSummary;
IF OBJECT_ID('SalaryStatsByWorkerType', 'V') IS NOT NULL
    DROP VIEW SalaryStatsByWorkerType;
IF OBJECT_ID('InspectorFinesByYear', 'V') IS NOT NULL
    DROP VIEW InspectorFinesByYear;
IF OBJECT_ID('BrokenVehicles', 'V') IS NOT NULL
    DROP VIEW BrokenVehicles;
IF OBJECT_ID('AddEmployee', 'P') IS NOT NULL
    DROP PROCEDURE AddEmployee;
IF OBJECT_ID('AddTicketSale', 'TR') IS NOT NULL
    DROP TRIGGER AddTicketSale;
IF OBJECT_ID('AddFailure', 'TR') IS NOT NULL
    DROP TRIGGER AddFailure;
IF OBJECT_ID('DeleteInspector', 'TR') IS NOT NULL
    DROP TRIGGER DeleteInspector;
IF OBJECT_ID('DeleteMechanic', 'TR') IS NOT NULL
    DROP TRIGGER DeleteMechanic;
IF OBJECT_ID('DeleteDriver', 'TR') IS NOT NULL
    DROP TRIGGER DeleteDriver;
IF OBJECT_ID('VehicleFailures', 'U') IS NOT NULL
    DROP TABLE VehicleFailures;
IF OBJECT_ID('ControlData', 'U') IS NOT NULL
	DROP TABLE ControlData;
IF OBJECT_ID('MechanicDepotMap', 'U') IS NOT NULL
	DROP TABLE MechanicDepotMap;
IF OBJECT_ID('VehicleDepotMap', 'U') IS NOT NULL
	DROP TABLE VehicleDepotMap;
IF OBJECT_ID('Depots', 'U') IS NOT NULL
	DROP TABLE Depots;
IF OBJECT_ID('LineDriverMap', 'U') IS NOT NULL
	DROP TABLE LineDriverMap;
IF OBJECT_ID('Inspectors', 'U') IS NOT NULL
	DROP TABLE Inspectors;
IF OBJECT_ID('Mechanics', 'U') IS NOT NULL
	DROP TABLE Mechanics;
IF OBJECT_ID('Drivers', 'U') IS NOT NULL
	DROP TABLE Drivers;
IF OBJECT_ID('TicketSales', 'U') IS NOT NULL
	DROP TABLE TicketSales;
IF OBJECT_ID('Tickets', 'U') IS NOT NULL
	DROP TABLE Tickets;
IF OBJECT_ID('Employees', 'U') IS NOT NULL
	DROP TABLE Employees;
IF OBJECT_ID('Vehicles', 'U') IS NOT NULL
	DROP TABLE Vehicles;
IF OBJECT_ID('Types', 'U') IS NOT NULL
	DROP TABLE Types;
IF OBJECT_ID('Timetables', 'U') IS NOT NULL
	DROP TABLE Timetables;
IF OBJECT_ID('LineStopMap', 'U') IS NOT NULL
	DROP TABLE LineStopMap;
IF OBJECT_ID('Lines', 'U') IS NOT NULL
	DROP TABLE Lines;
IF OBJECT_ID('Stops', 'U') IS NOT NULL
	DROP TABLE Stops;


CREATE TABLE Stops(
	ID INT IDENTITY(0, 1),
	Name NVARCHAR(256) UNIQUE NOT NULL,
	CONSTRAINT PK_Stops PRIMARY KEY(ID),
);

CREATE TABLE Lines(
	ID INT IDENTITY(0, 1),
	Name NVARCHAR(10) UNIQUE NOT NULL,
	CONSTRAINT PK_Lines PRIMARY KEY(ID)
);

CREATE INDEX IX_Stops_Name ON Stops(Name);

CREATE TABLE LineStopMap(
	ID INT IDENTITY(0, 1),
	ID_Line INT NOT NULL,
	ID_Stop INT NOT NULL,
	StopOrder INT NOT NULL,
	CONSTRAINT PK_LineStopMap PRIMARY KEY (ID),
	CONSTRAINT UC_LineStopOrder UNIQUE(ID_Line, StopOrder),
	CONSTRAINT FK_ID_Stop_LineStopMap FOREIGN KEY(ID_Stop) REFERENCES Stops(ID),
	CONSTRAINT FK_ID_Line_LineStopMap FOREIGN KEY(ID_Line) REFERENCES Lines(ID),
);

CREATE INDEX IX_LineStopMap_ID_Line ON LineStopMap(ID_Line);
CREATE INDEX IX_LineStopMap_ID_Stop ON LineStopMap(ID_Stop);

CREATE TABLE Timetables(
	ID INT IDENTITY(0, 1),
	ID_LineStopMap INT NOT NULL,
	Time TIME(0) NOT NULL,
	Direction NCHAR NOT NULL,
	CONSTRAINT PK_Timetables PRIMARY KEY(ID),
	CONSTRAINT FK_ID_LineStopMap FOREIGN KEY(ID_LineStopMap) REFERENCES LineStopMap(ID),
	CONSTRAINT CK_Direction_AB CHECK (Direction IN (N'A', N'B'))
);

CREATE TABLE Types(
	ID INT IDENTITY(0, 1),
	Description NVARCHAR(256) NOT NULL,
	Category NCHAR NOT NULL,
	NumberOfSeats INT NOT NULL,
	CONSTRAINT PK_Types PRIMARY KEY(ID),
	CONSTRAINT CK_Category_Types CHECK (Category IN (N'A', N'T'))
);

CREATE TABLE Vehicles(
	ID INT IDENTITY(0, 1),
	ID_Type INT NOT NULL,
	ProductionDate DATE NOT NULL,
	LastInspectionDate DATE NOT NULL,
	CONSTRAINT PK_Vehicles PRIMARY KEY(ID),
	CONSTRAINT FK_ID_Type FOREIGN KEY(ID_Type) REFERENCES Types(ID)
);

CREATE TABLE Employees(
	ID INT IDENTITY(0, 1),
	FirstName NVARCHAR(128) NOT NULL,
	LastName NVARCHAR(128) NOT NULL,
	PESEL NVARCHAR(11) NOT NULL,
	DateOfBirth DATE NOT NULL,
	DateOfEmployment DATE NOT NULL,
	Salary MONEY NOT NULL,
	CONSTRAINT PK_Employees PRIMARY KEY(ID),
	CONSTRAINT UC_PESEL UNIQUE(PESEL)
);

CREATE TABLE Tickets (
	ID INT IDENTITY(0, 1),
	Price MONEY NOT NULL,
	DurationMinutes INT NOT NULL,
	Type NVARCHAR(10) NOT NULL,
	TotalNumber INT NOT NULL,
	CONSTRAINT PK_Tickets PRIMARY KEY (ID),
	CONSTRAINT CK_TicketType CHECK (Type IN (N'reduced', N'standard'))
);

CREATE TABLE TicketSales (
	ID INT IDENTITY(0, 1),
	TicketID INT NOT NULL,
	Quantity INT NOT NULL,
	LineID INT NOT NULL,
	SaleDate DATE NOT NULL DEFAULT GETDATE(),
	CONSTRAINT PK_TicketSales PRIMARY KEY(ID),
	CONSTRAINT FK_TicketID FOREIGN KEY (TicketID) REFERENCES Tickets(ID),
	CONSTRAINT FK_LineID FOREIGN KEY (LineID) REFERENCES Lines(ID),
	CONSTRAINT CK_Quantity CHECK (Quantity > 0)
);

CREATE TABLE Drivers(
	ID_Driver INT NOT NULL UNIQUE,
	DrivingLicense NVARCHAR(10) NOT NULL,
	CONSTRAINT FK_ID_Driver FOREIGN KEY(ID_Driver) REFERENCES Employees(ID) ON DELETE CASCADE
);

CREATE TABLE Mechanics(
	ID_Mechanic INT NOT NULL UNIQUE,
	Specialization NCHAR NOT NULL,
	CONSTRAINT FK_ID_Mechanic FOREIGN KEY(ID_Mechanic) REFERENCES Employees(ID) ON DELETE CASCADE
);

CREATE TABLE Inspectors(
	ID_Inspector INT NOT NULL UNIQUE,
	ForeignLanguages NVARCHAR(10) NOT NULL,
	CONSTRAINT FK_ID_Inspector FOREIGN KEY(ID_Inspector) REFERENCES Employees(ID) ON DELETE CASCADE
);

CREATE TABLE LineDriverMap(
	ID INT IDENTITY(0, 1),
	ID_Driver INT NOT NULL,
	ID_Line INT NOT NULL,
	CONSTRAINT PK_LineDriverMap PRIMARY KEY (ID),
	CONSTRAINT FK_ID_Driver_LineDriverMap FOREIGN KEY (ID_Driver) REFERENCES Drivers(ID_Driver) ON DELETE CASCADE,
	CONSTRAINT FK_ID_Line_LineDriverMap FOREIGN KEY (ID_Line) REFERENCES Lines(ID)
);

CREATE TABLE Depots(
	ID INT IDENTITY(0, 1),
	Name NVARCHAR(256) NOT NULL,
	Address NVARCHAR(256) NOT NULL,
	Category NCHAR NOT NULL,
	CONSTRAINT PK_Depots PRIMARY KEY (ID),
	CONSTRAINT CK_Category_Depots CHECK (Category IN (N'A', N'T'))
);

CREATE TABLE VehicleDepotMap(
	ID INT IDENTITY(0, 1),
	ID_Vehicle INT NOT NULL,
	ID_Depot INT NOT NULL,
	CONSTRAINT PK_VehicleDepotMap PRIMARY KEY (ID),
	CONSTRAINT FK_ID_Vehicle_VehicleDepotMap FOREIGN KEY (ID_Vehicle) REFERENCES Vehicles(ID),
	CONSTRAINT FK_ID_Depot_VehicleDepotMap FOREIGN KEY (ID_Depot) REFERENCES Depots(ID)
);

CREATE TABLE MechanicDepotMap(
	ID INT IDENTITY(0, 1),
	ID_Mechanic INT NOT NULL,
	ID_Depot INT NOT NULL,
	CONSTRAINT PK_MechanicDepotMap PRIMARY KEY (ID),
	CONSTRAINT FK_ID_Mechanic_MechanicDepotMap FOREIGN KEY (ID_Mechanic) REFERENCES Mechanics(ID_Mechanic) ON DELETE CASCADE,
	CONSTRAINT FK_ID_Depot_MechanicDepotMap FOREIGN KEY (ID_Depot) REFERENCES Depots(ID)
);

CREATE TABLE ControlData (
	ID INT IDENTITY(0, 1) PRIMARY KEY,
	ID_Inspector INT NULL,
	ID_Line INT NOT NULL,
	Date DATE NOT NULL,
	NumberOfFines INT NOT NULL,
	CONSTRAINT FK_ID_Inspector_ControlData FOREIGN KEY (ID_Inspector) REFERENCES Inspectors(ID_Inspector) ON DELETE SET NULL,
	CONSTRAINT FK_ID_Line_ControlData FOREIGN KEY (ID_Line) REFERENCES Lines(ID)
);

CREATE TABLE VehicleFailures (
	ID INT IDENTITY(0, 1) PRIMARY KEY,
	ID_Vehicle INT NOT NULL,
	ID_Mechanic INT DEFAULT NULL,
	ReportDate DATE NOT NULL,
	RepairDate DATE DEFAULT NULL,
	Description NVARCHAR(MAX),
	CONSTRAINT FK_ID_Vehicle_VehicleFailures FOREIGN KEY (ID_Vehicle) REFERENCES Vehicles(ID),
	CONSTRAINT FK_ID_Repairing_Mechanic_VehicleFailures FOREIGN KEY (ID_Mechanic) REFERENCES Mechanics(ID_Mechanic) ON DELETE SET NULL
);

INSERT INTO Stops VALUES
(N'Kurczaki'),
(N'Paderewskiego'),
(N'plac Niepodległości'),
(N'Piotrkowska Centrum'),
(N'Zamenhofa'),
(N'Kilińskiego'),
(N'Doły'),
(N'rondo Lotników Lwowskich'),
(N'Przędzalniana'),
(N'Niciarniana'),
(N'Lutomierska'),
(N'Pomorska'),
(N'Chocianowice IKEA'),
(N'Dworzec Łódź Widzew'),
(N'Łazowskiego'),
(N'Stoki'),
(N'Kopernika'),
(N'Inflancka'),
(N'Manufaktura'),
(N'Zgierska');

INSERT INTO Lines VALUES
(N'6'),
(N'8'),
(N'15'),
(N'61'),
(N'75A'),
(N'75B'),
(N'N2');

INSERT INTO LineStopMap VALUES
(0, 0, 0), (0, 2, 1), (0, 4, 2), (0, 5, 3), (0, 8, 4), (0, 6, 5),
(1, 0, 0), (1, 1, 1), (1, 3, 2), (1, 8, 3), (1, 16, 4), (1, 18, 5), (1, 13, 6),
(2, 19, 0), (2, 17, 1), (2, 7, 2), (2, 9, 3), (2, 16, 4), (2, 15, 5), (2, 3, 6), (2, 10, 7), (2, 12, 8),
(3, 4, 0), (3, 14, 1), (3, 9, 2), (3, 10, 3),
(4, 0, 0), (4, 2, 1), (4, 5, 2), (4, 17, 3), (4, 12, 4), (4, 4, 5), (4, 11, 6), (4, 15, 7),
(5, 0, 0), (5, 2, 1), (5, 1, 2), (5, 17, 3), (5, 8, 4), (5, 4, 5), (5, 11, 6), (5, 15, 7),
(6, 3, 0), (6, 4, 1), (6, 9, 2), (6, 11, 3);

INSERT INTO Timetables VALUES
(0, '08:00:00', 'A'), (0, '12:30:00', 'A'), (0, '21:27:00', 'A'), (0, '10:24:00', 'B'), (0, '15:59:00', 'B'), (0, '23:38:00', 'B'),
(1, '08:09:00', 'A'), (1, '12:34:00', 'A'), (1, '21:29:00', 'A'), (1, '10:20:00', 'B'), (1, '15:46:00', 'B'), (1, '23:25:00', 'B'),
(2, '08:13:00', 'A'), (2, '12:38:00', 'A'), (2, '21:35:00', 'A'), (2, '10:16:00', 'B'), (2, '15:43:00', 'B'), (2, '23:22:00', 'B'),
(3, '08:19:00', 'A'), (3, '12:53:00', 'A'), (3, '21:38:00', 'A'), (3, '10:12:00', 'B'), (3, '15:38:00', 'B'), (3, '23:18:00', 'B'),
(4, '08:27:00', 'A'), (4, '13:01:00', 'A'), (4, '21:44:00', 'A'), (4, '10:10:00', 'B'), (4, '15:35:00', 'B'), (4, '23:15:00', 'B'),
(5, '08:29:00', 'A'), (5, '13:33:00', 'A'), (5, '21:48:00', 'A'), (5, '10:02:00', 'B'), (5, '15:32:00', 'B'), (5, '23:13:00', 'B'),
(6, '07:30:00', 'A'), (6, '17:17:00', 'A'), (6, '12:24:00', 'B'), (6, '19:40:00', 'B'),
(7, '07:35:00', 'A'), (7, '17:23:00', 'A'), (7, '12:22:00', 'B'), (7, '19:36:00', 'B'),
(8, '07:43:00', 'A'), (8, '17:28:00', 'A'), (8, '12:14:00', 'B'), (8, '19:30:00', 'B'),
(9, '07:54:00', 'A'), (9, '17:36:00', 'A'), (9, '12:10:00', 'B'), (9, '19:26:00', 'B'),
(10, '08:03:00', 'A'), (10, '17:42:00', 'A'), (10, '12:06:00', 'B'), (10, '19:24:00', 'B'),
(11, '08:12:00', 'A'), (11, '17:47:00', 'A'), (11, '12:03:00', 'B'), (11, '19:19:00', 'B'),
(12, '08:16:00', 'A'), (12, '17:50:00', 'A'), (12, '11:58:00', 'B'), (12, '19:15:00', 'B'),
(13, '12:00:00', 'A'), (13, '16:23:00', 'A'), (13, '20:08:00', 'A'), (13, '05:03:00', 'B'), (13, '11:46:00', 'B'), (13, '14:12:00', 'B'),
(14, '12:04:00', 'A'), (14, '16:27:00', 'A'), (14, '20:12:00', 'A'), (14, '05:01:00', 'B'), (14, '11:44:00', 'B'), (14, '14:04:00', 'B'),
(15, '12:12:00', 'A'), (15, '16:32:00', 'A'), (15, '20:14:00', 'A'), (15, '04:58:00', 'B'), (15, '11:41:00', 'B'), (15, '14:00:00', 'B'),
(16, '12:15:00', 'A'), (16, '16:36:00', 'A'), (16, '20:18:00', 'A'), (16, '04:54:00', 'B'), (16, '11:37:00', 'B'), (16, '13:51:00', 'B'),
(17, '12:18:00', 'A'), (17, '16:43:00', 'A'), (17, '20:21:00', 'A'), (17, '04:51:00', 'B'), (17, '11:33:00', 'B'), (17, '13:45:00', 'B'),
(18, '12:26:00', 'A'), (18, '16:45:00', 'A'), (18, '20:24:00', 'A'), (18, '04:48:00', 'B'), (18, '11:31:00', 'B'), (18, '13:41:00', 'B'),
(19, '12:34:00', 'A'), (19, '16:47:00', 'A'), (19, '20:26:00', 'A'), (19, '04:46:00', 'B'), (19, '11:28:00', 'B'), (19, '13:39:00', 'B'),
(20, '12:37:00', 'A'), (20, '16:52:00', 'A'), (20, '20:27:00', 'A'), (20, '04:43:00', 'B'), (20, '11:25:00', 'B'), (20, '13:38:00', 'B'),
(21, '12:42:00', 'A'), (21, '16:56:00', 'A'), (21, '20:28:00', 'A'), (21, '04:40:00', 'B'), (21, '11:20:00', 'B'), (21, '13:31:00', 'B'),
(22, '13:14:00', 'A'), (22, '22:18:00', 'A'), (22, '12:37:00', 'B'), (22, '19:22:00', 'B'),
(23, '13:16:00', 'A'), (23, '22:21:00', 'A'), (23, '12:33:00', 'B'), (23, '19:15:00', 'B'),
(24, '13:23:00', 'A'), (24, '22:25:00', 'A'), (24, '12:24:00', 'B'), (24, '19:10:00', 'B'),
(25, '13:28:00', 'A'), (25, '22:29:00', 'A'), (25, '12:21:00', 'B'), (25, '19:04:00', 'B'),
(26, '09:28:00', 'A'), (26, '16:36:00', 'B'),
(27, '09:31:00', 'A'), (27, '16:34:00', 'B'),
(28, '09:33:00', 'A'), (28, '16:29:00', 'B'),
(29, '09:36:00', 'A'), (29, '16:27:00', 'B'),
(30, '09:38:00', 'A'), (30, '16:26:00', 'B'),
(31, '09:43:00', 'A'), (31, '16:24:00', 'B'),
(32, '09:45:00', 'A'), (32, '16:21:00', 'B'),
(33, '09:47:00', 'A'), (33, '16:16:00', 'B'),
(34, '13:55:00', 'A'), (34, '20:07:00', 'B'),
(35, '13:56:00', 'A'), (35, '20:04:00', 'B'),
(36, '14:02:00', 'A'), (36, '20:02:00', 'B'),
(37, '14:06:00', 'A'), (37, '19:56:00', 'B'),
(38, '14:07:00', 'A'), (38, '19:53:00', 'B'),
(39, '14:14:00', 'A'), (39, '19:46:00', 'B'),
(40, '14:17:00', 'A'), (40, '19:44:00', 'B'),
(41, '14:20:00', 'A'), (41, '19:41:00', 'B'),
(42, '08:13:00', 'A'), (42, '18:00:00', 'A'), (42, '15:04:00', 'B'), (42, '19:19:00', 'B'),
(43, '08:18:00', 'A'), (43, '18:20:00', 'A'), (43, '14:56:00', 'B'), (43, '19:15:00', 'B'),
(44, '08:25:00', 'A'), (44, '18:23:00', 'A'), (44, '14:48:00', 'B'), (44, '19:11:00', 'B'),
(45, '08:40:00', 'A'), (45, '18:27:00', 'A'), (45, '14:43:00', 'B'), (45, '19:06:00', 'B');

INSERT INTO Types VALUES
(N'PESA 122N', N'T', 63), (N'Konstal 805Na', N'T', 20), (N'Siemens NF6D', N'T', 72),
(N'Solaris Urbino 18', N'A', 40),  (N'Mercedes Benz 628 Conecto LF', N'A', 29),  (N'Isuzu NovoCiti Life', N'A', 24);

INSERT INTO Vehicles VALUES
(0, '2009-12-01', '2024-05-06'), (0, '2012-04-26', '2023-11-20'), (0, '2009-12-05', '2024-07-12'),
(1, '1987-03-31', '2023-12-31'), (1, '1978-04-04', '2024-02-29'), (1, '1983-02-16', '2024-11-13'), (1, '1994-05-28', '2024-08-14'),
(2, '1992-07-29', '2023-07-15'), (2, '1992-08-07', '2024-01-08'),
(3, '2023-06-03', '2024-05-08'), (3, '2023-05-27', '2024-04-11'),
(4, '2010-09-16', '2024-12-22'), (4, '2010-03-22', '2024-02-05'),
(5, '2018-11-18', '2023-01-07'), (5, '2018-03-23', '2024-04-01'), (5, '2018-04-19', '2023-05-24'), (5, '2018-05-11', '2024-07-09');

INSERT INTO Tickets (Price, DurationMinutes, Type, TotalNumber) VALUES 
(10.00, 60, N'reduced', 4568),  
(15.00, 60, N'standard', 21341), 
(20.00, 120, N'reduced', 23422), 
(30.00, 120, N'standard', 1999),
(5.00, 30, N'reduced', 2022),   
(7.50, 30, N'standard', 470);

INSERT INTO TicketSales (TicketID, Quantity, LineID, SaleDate) VALUES
(2, 3, 1, '2025-01-01'), 
(4, 1, 3, '2025-01-01'), 
(5, 4, 1, '2025-01-03'), 
(1, 1, 1, '2025-01-04'),
(3, 1, 4, '2025-02-01'),  
(1, 3, 2, '2025-02-03'), 
(0, 2, 6, '2025-02-05'), 
(1, 1, 2, '2025-02-05');

INSERT INTO Employees VALUES
(N'Barbara', N'Ostaszewska', N'89070785765', '1989-07-07', '2014-06-07', 8700),
(N'Jan', N'Kowalski', N'91041617614', '1991-04-16', '2015-02-09', 5600),
(N'Anastazja', N'Ćwiklińska', N'76061516424', '1976-06-15', '1999-01-17', 6300),
(N'Janina', N'Stefańska', N'76061714723', '1976-06-17', '1996-09-30', 7340),
(N'Stefan', N'Nowak', N'03222855614', '2003-02-28', '2022-12-04', 6390),
(N'Mateusz', N'Rachwał', N'82052342974', '1982-05-23', '2002-05-07', 7800),
(N'Borys', N'Wilczyński', N'86071815158', '1986-07-18', '2011-11-11', 5440),
(N'Adam', N'Glapiński', N'02260146452', '2002-06-01', '2024-06-12', 5890),
(N'Amelia', N'Królak', N'90042336245', '1990-04-23', '2007-01-16', 7600),
(N'Nikola', N'Skurzewska', N'00270836226', '2000-07-08', '2019-03-25', 5980),
(N'Ada', N'Dziedzina', N'82050144622', '1982-05-01', '2014-10-31', 6700),
(N'Alodia', N'Rutkowska', N'93120723487', '1993-12-07', '2018-07-27', 7610);

INSERT INTO Drivers VALUES
(1, N'AT'), (2, 'A'), (3, 'T'), (4, 'AT'), (10, 'AT');

INSERT INTO Mechanics VALUES
(0, N'A'), (8, N'T'), (9, N'A');

INSERT INTO Inspectors VALUES
(5, N'EDR'), (6, N'E'), (7, N'ER'), (11, N'R');

INSERT INTO LineDriverMap VALUES
(1, 0), (1, 1), (1, 4), (1, 6),
(2, 3), (2, 5), (2, 6),
(3, 1), (3, 0),
(4, 5), (4, 0), (4, 2), (4, 3),
(10, 1), (10, 2), (10, 4);

INSERT INTO Depots VALUES
(N'Limanowskiego', N'ul. Bolesława Limanowskiego 147', N'A'),
(N'Nowe Sady', N'ul. Nowe Sady 15', N'A'),
(N'Helenówek', N'ul. Zgierska 256', N'T'),
(N'Chocianowice', N'ul. Pabianicka 215', N'T');

INSERT INTO VehicleDepotMap VALUES
(0, 2), (0, 3), (1, 2), (2, 2), (3, 3), (4, 3), (5, 2), (5, 3), (6, 3), (7, 2), (8, 2),
(9, 0), (10, 0), (11, 0), (11, 1), (12, 0), (12, 1), (13, 1), (14, 1), (15, 1), (16, 1);

INSERT INTO MechanicDepotMap VALUES
(0, 0), (8,2), (8, 3), (9, 0), (9, 1);

INSERT INTO ControlData (ID_Inspector, ID_Line, Date, NumberOfFines) VALUES
(6, 1, '2024-01-15', 5),
(7, 2, '2024-02-20', 3),
(11, 3, '2024-03-25', 4),
(5, 4, '2024-04-10', 0),
(6, 5, '2024-05-05', 6),
(6, 2, '2024-06-15', 1),
(7, 1, '2024-07-20', 3),
(11, 2, '2024-08-25', 5),
(11, 4, '2024-09-30', 2),
(5, 5, '2024-10-15', 0),
(6, 1, '2024-11-20', 3),
(7, 2, '2024-12-25', 6),
(11, 1, '2025-01-10', 2),
(7, 4, '2025-02-15', 4),
(11, 5, '2025-03-20', 1),
(6, 0, '2025-04-25', 0),
(7, 1, '2025-05-10', 3),
(11, 2, '2025-06-15', 2),
(6, 4, '2025-07-20', 4),
(7, 0, '2025-08-25', 6),
(6, 3, '2025-09-30', 1),
(5, 0, '2025-10-15', 0),
(11, 1, '2025-11-20', 3),
(6, 2, '2025-12-25', 2),
(7, 1, '2024-01-10', 0);

INSERT INTO VehicleFailures (ID_Vehicle, ID_Mechanic, ReportDate, RepairDate, Description) VALUES
(0, 8, '2024-01-15', '2024-01-20', N'Engine malfunction'),
(1, 8, '2024-02-10', '2024-02-15', N'Brake system failure'),
(2, 8, '2024-03-05', '2024-03-10', N'Transmission issue'),
(3, 9, '2024-04-01', '2024-04-07', N'Electrical problem'),
(4, 0, '2024-05-12', '2024-05-18', N'Suspension damage'),
(5, 9, '2025-06-20', NULL, N'Cooling system leak');

-- dodaj nowego pracownika
-- modyfikuj pracownika (jeśli jest to zmodyfikuj, a jak nie ma to wołasz o dodanie)
-- usuń (procedura + wyzwalacz)

GO

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

GO

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

GO

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

GO

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

GO

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

GO

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

GO

CREATE VIEW BrokenVehicles AS
	SELECT *
	FROM VehicleFailures
	WHERE RepairDate IS NULL;

GO

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

GO
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

GO

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
GO

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

GO

CREATE VIEW FinesSummaryByMonth AS
	SELECT
		MONTH(C.Date) AS Month,
		ISNULL(SUM(C.NumberOfFines), 0) AS NumberOfFines
	FROM
		ControlData C
	GROUP BY
		MONTH(C.Date);

GO

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

GO

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

GO

CREATE VIEW VehicleNextInspection AS
SELECT
	V.ID AS VehicleID,
	V.LastInspectionDate,
	dbo.CalculateNextInspectionDate(V.ID) AS NextInspectionDate
FROM Vehicles V;

GO

CREATE VIEW EmployeeSalaryWithBonus AS
SELECT
	E.ID AS EmployeeID,
	E.Salary AS StandardSalary,
	ISNULL(dbo.CalculateInspectorBonus(E.ID), 0) AS Bonus,
	(E.Salary + ISNULL(dbo.CalculateInspectorBonus(E.ID), 0)) AS GrossTotalSalary,
	(E.Salary + ISNULL(dbo.CalculateInspectorBonus(E.ID), 0)) * 0.8 AS NetTotalSalary
FROM Employees E;

GO

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

GO

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

GO

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

GO

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

USE master
DROP DATABASE MPK_Baza
