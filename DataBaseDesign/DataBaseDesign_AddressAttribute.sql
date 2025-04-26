

/*	=============================================


 این اسکریپت برای ایجاد یک ساختار ساده دیتابیس طراحی شده که شامل اطلاعات مشتری، آدرس و کشورهاست.
 روابط بین جداول از طریق کلیدهای خارجی (Foreign Key) برقرار شده و هدف اصلی، تمرین طراحی اصولی دیتابیس است.


=============================================	*/


USE master;
GO

IF (SELECT COUNT(*)
		 FROM sys.databases
		 WHERE name = 'DataBaseDesign_AddressAttribute' ) = 1
	 ALTER DATABASE DataBaseDesign_AddressAttribute SET SINGLE_USER 
	 WITH ROLLBACK IMMEDIATE

DROP DATABASE IF EXISTS DataBaseDesign_AddressAttribute
GO


-- ایجاد دیتابیس
CREATE DATABASE DataBaseDesign_AddressAttribute;
GO

USE DataBaseDesign_AddressAttribute;
GO

-- جدول Country
CREATE TABLE Country (CountryID INT NOT NULL,
					  CountryName NCHAR(10) NULL,
					  CONSTRAINT PK_Country PRIMARY KEY CLUSTERED (CountryID))


-- جدول Address
CREATE TABLE Address (AddressID INT NOT NULL,
					  UnitNumber NCHAR(10) NULL,
					  StreetNumber NCHAR(10) NULL,
					  AddressLine1 NCHAR(10) NULL,
					  AddressLine2 NCHAR(10) NULL,
					  City NCHAR(10) NULL,
					  Region NCHAR(10) NULL,
					  PostalCode NCHAR(10) NULL,
					  CountryID INT NULL,
					  CONSTRAINT PK_Address PRIMARY KEY CLUSTERED (AddressID))


-- جدول Customer
CREATE TABLE Customer (CustomerID INT NOT NULL,
					   CustomerFirstName NCHAR(10) NULL,
					   CustomerLastName NCHAR(10) NULL,
					   CONSTRAINT PK_Customer PRIMARY KEY CLUSTERED (CustomerID))


-- جدول CustomerAddress
CREATE TABLE CustomerAddress (CustomerAddressID INT NULL,
							  CustomerID INT NULL,
							  AddressID INT NULL)


-- روابط خارجی (Foreign Keys)
ALTER TABLE Address WITH CHECK ADD CONSTRAINT FK_Address_Country
FOREIGN KEY (CountryID) REFERENCES Country (CountryID);
GO

ALTER TABLE Address CHECK CONSTRAINT FK_Address_Country;
GO

ALTER TABLE CustomerAddress WITH CHECK ADD CONSTRAINT FK_CustomerAddress_Address
FOREIGN KEY (AddressID) REFERENCES Address (AddressID);
GO

ALTER TABLE CustomerAddress CHECK CONSTRAINT FK_CustomerAddress_Address;
GO

ALTER TABLE CustomerAddress WITH CHECK ADD CONSTRAINT FK_CustomerAddress_Customer
FOREIGN KEY (CustomerID) REFERENCES Customer (CustomerID);
GO

ALTER TABLE CustomerAddress CHECK CONSTRAINT FK_CustomerAddress_Customer;
GO
