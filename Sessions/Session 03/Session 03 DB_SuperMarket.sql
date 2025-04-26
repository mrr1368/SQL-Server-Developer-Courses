/*	=============================================

این اسکریپت برای ایجاد دیتابیس و جداول یک فروشگاه آنلاین است.
ابتدا دیتابیس موجود را در صورت وجود حذف می‌کند و سپس یک دیتابیس جدید به نام 
'SqlCourseS02_SuperMarket'
ایجاد می‌کند. جداول شامل اطلاعات مختلف مربوط به دسته‌بندی‌ها،
مشتریان، فروشندگان، محصولات، فاکتورها و آیتم‌های فاکتور می‌شود.
این اسکریپت همچنین ایندکس یکتا برای شماره تلفن مشتریان ایجاد می‌کند تا از ورود داده‌های تکراری جلوگیری شود.

=============================================	*/

USE master
GO

IF (SELECT COUNT(*)
		 FROM sys.databases
		 WHERE name = 'Session03_DB_SuperMarket' ) = 1
	 ALTER DATABASE Session03_DB_SuperMarket SET SINGLE_USER 
	 WITH ROLLBACK IMMEDIATE

DROP DATABASE IF EXISTS Session03_DB_SuperMarket
GO

CREATE DATABASE Session03_DB_SuperMarket
GO

USE Session03_DB_SuperMarket
GO

CREATE TABLE Category(CategoryID SMALLINT PRIMARY KEY IDENTITY,
					  CategoryName NVARCHAR(30))

CREATE TABLE Customer(CustomerID INT PRIMARY KEY IDENTITY(1000,1),
					  CustomerFname NVARCHAR(30),
				      CustomerLname NVARCHAR(30),
					  CustomerPhone VARCHAR(11))

CREATE TABLE Reseller(ResellerID INT PRIMARY KEY IDENTITY,
					  ResellerName NVARCHAR(30))

CREATE TABLE Product(ProductID INT PRIMARY KEY IDENTITY,
					 ProductName NVARCHAR(30),
					 CategoryID SMALLINT FOREIGN KEY REFERENCES Category(CategoryID))

CREATE TABLE Invoice(InvoiceID INT PRIMARY KEY IDENTITY,
					 CustomerID INT FOREIGN KEY REFERENCES Customer(CustomerID),
					 SellDate DATETIME,
					 ResellerID INT FOREIGN KEY REFERENCES Reseller(ResellerID))

CREATE TABLE InvoiceItem(InvoiceID INT FOREIGN KEY REFERENCES Invoice(InvoiceID),
						 ProductID INT FOREIGN KEY REFERENCES Product(ProductID),
						 Price INT,
						 Quantity SMALLINT,
						 PRIMARY KEY(InvoiceID, ProductID))

CREATE UNIQUE INDEX ixCustomerPhone ON Customer(CustomerPhone)
