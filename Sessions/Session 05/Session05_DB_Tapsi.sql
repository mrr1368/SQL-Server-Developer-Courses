


/* =============================================


دیتابیس سیستم تاکسی اینترنتی (تپسی)
با ساختار کامل:
- مدیریت رانندگان و مسافران
- سیستم سفرها و پرداخت‌ها
- ارزیابی و نظرسنجی
- سیستم نقش‌ها و دسترسی‌ها


============================================= */


USE master
GO 


IF (SELECT COUNT(*)
		 FROM sys.databases
		 WHERE name = 'Session05_DB_Tapsi' ) = 1
	 ALTER DATABASE Session05_DB_Tapsi SET SINGLE_USER 
	 WITH ROLLBACK IMMEDIATE

DROP DATABASE IF EXISTS Session05_DB_Tapsi
GO


-- ایجاد دیتابیس
CREATE DATABASE Session05_DB_Tapsi
GO

USE Session05_DB_Tapsi
GO

-- جداول اصلی
CREATE TABLE Car (CarID INT IDENTITY(1,1) PRIMARY KEY,
				  CarModel NVARCHAR(50) NOT NULL,
				  CarNumber NVARCHAR(30) NOT NULL)

CREATE TABLE Driver (DriverID INT IDENTITY(1,1) PRIMARY KEY,
					 DriverFirstName NVARCHAR(30) NOT NULL,
					 DriverLastName NVARCHAR(30) NOT NULL,
					 DriverNationalID NVARCHAR(10) NOT NULL,
					 DriverPhone NVARCHAR(11) NOT NULL,
					 UserRole INT)

CREATE TABLE Passenger (PassengerID INT IDENTITY(1,1) PRIMARY KEY,
						PassengerFirstName NVARCHAR(30) NOT NULL,
						PassengerLastName NVARCHAR(30) NOT NULL,
						PassengerNationalID NVARCHAR(10) NOT NULL,
						PassengerPhone NVARCHAR(11) NOT NULL,
						UserRole INT)

CREATE TABLE PassengerRide (PassengerRideID INT IDENTITY(1,1) PRIMARY KEY,
							PassengerID INT FOREIGN KEY REFERENCES Passenger(PassengerID),
							RideID INT)

CREATE TABLE PassAssesment (PassAssesmentID INT IDENTITY(1,1) PRIMARY KEY,
							PassAssesmentResult INT,
							PassQuestionID INT,
							PassengerRideID INT)

-- جداول ارتباطی
CREATE TABLE DriverCarRide (DriverCarRideID INT IDENTITY(1,1) PRIMARY KEY,
							DriverID INT FOREIGN KEY REFERENCES Driver(DriverID),
							CarID INT FOREIGN KEY REFERENCES Car(CarID))

CREATE TABLE Ride (RideID INT IDENTITY(1,1) PRIMARY KEY,
				   DriverCarRideID INT FOREIGN KEY REFERENCES DriverCarRide(DriverCarRideID),
				   Origin NVARCHAR(500) NOT NULL,
				   Distination NVARCHAR(500) NOT NULL,
				   Price INT,
				   StartRide DATETIME DEFAULT GETDATE(),
				   EndRide DATETIME DEFAULT GETDATE())

-- جداول پرداخت
CREATE TABLE Dri_Car_Pay (Dri_Car_PayID INT IDENTITY(1,1) PRIMARY KEY,
						  DriverCarRideID INT FOREIGN KEY REFERENCES DriverCarRide(DriverCarRideID),
						  Price INT)

CREATE TABLE PassPay (PassPayID INT IDENTITY(1,1) PRIMARY KEY,
					  PassengerRideID INT FOREIGN KEY REFERENCES PassengerRide(PassengerRideID),
					  Price INT)

-- جداول نظرسنجی
CREATE TABLE Dri_Car_Question (Dri_Car_QuestionID INT IDENTITY(1,1) PRIMARY KEY,
							   Dri_Car_QuestionDesc NVARCHAR(500) NOT NULL)

-- جدول ارزیابی‌ها که به این سوالات وصل می‌شود
CREATE TABLE Dri_Car_Assesment (Dri_Car_AssesmentID INT IDENTITY(1,1) PRIMARY KEY,
								Dri_Car_Result INT,
								Dri_Car_QuestionID INT FOREIGN KEY REFERENCES Dri_Car_Question(Dri_Car_QuestionID), -- ارتباط با جدول سوالات
								DriverCarRideID INT FOREIGN KEY REFERENCES DriverCarRide(DriverCarRideID)) -- ارتباط با سفرهای راننده

CREATE TABLE PassQuestion (PassQuestionID INT IDENTITY(1,1) PRIMARY KEY,
						   PassQuestionDesc NVARCHAR(500) NOT NULL)

-- جدول نقش‌های سیستم (مثل: راننده، مسافر، ادمین)
CREATE TABLE SystemRole (RoleID INT IDENTITY(1,1) PRIMARY KEY,
						 RoleTitle NVARCHAR(30))

-- جدول تخصیص نقش به کاربران (هر کاربر می‌تواند چندین نقش داشته باشد)
CREATE TABLE UserRole (UserRoleID INT IDENTITY(1,1) PRIMARY KEY,
					   UserID INT , -- ارتباط با کاربران
					   RoleID INT FOREIGN KEY REFERENCES SystemRole(RoleID)) -- ارتباط با نقش‌ها	

--  اگر کاربران همان رانندگان/مسافران هستند 
ALTER TABLE UserRole
ADD CONSTRAINT FK_UserRole_Driver 
FOREIGN KEY (UserID) REFERENCES Driver(DriverID)

-- یا برای مسافران
ALTER TABLE UserRole
ADD CONSTRAINT FK_UserRole_Passenger 
FOREIGN KEY (UserID) REFERENCES Passenger(PassengerID)


-- ایجاد ایندکس‌های منحصر به فرد
CREATE UNIQUE INDEX ix_DriverNationalID ON Driver(DriverNationalID)
CREATE UNIQUE INDEX ix_PassengerNationalID ON Passenger(PassengerNationalID)


ALTER TABLE PassengerRide ADD FOREIGN KEY (PassengerID) REFERENCES Passenger(PassengerID)
ALTER TABLE PassengerRide ADD FOREIGN KEY (RideID) REFERENCES Ride(RideID)
ALTER TABLE PassAssesment ADD FOREIGN KEY (PassQuestionID) REFERENCES PassQuestion(PassQuestionID)
ALTER TABLE PassAssesment ADD FOREIGN KEY (PassengerRideID) REFERENCES PassengerRide(PassengerRideID)
ALTER TABLE PassPay ADD FOREIGN KEY (PassengerRideID) REFERENCES PassengerRide(PassengerRideID)
ALTER TABLE UserRole ADD FOREIGN KEY (UserRoleID) REFERENCES UserRole(UserRoleID)
ALTER TABLE Ride ADD FOREIGN KEY (RideID) REFERENCES Ride(RideID)
ALTER TABLE PassengerRide ADD FOREIGN KEY (PassengerRideID) REFERENCES PassengerRide(PassengerRideID)
ALTER TABLE PassQuestion ADD FOREIGN KEY (PassQuestionID) REFERENCES PassQuestion(PassQuestionID)

-- در جدول رانندگان:
ALTER TABLE Driver 
ADD FOREIGN KEY (UserRole) REFERENCES UserRole(UserRoleID)

-- در جدول مسافران:
ALTER TABLE Passenger 
ADD FOREIGN KEY (UserRole) REFERENCES UserRole(UserRoleID)