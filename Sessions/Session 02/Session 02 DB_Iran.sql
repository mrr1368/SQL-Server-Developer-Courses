/*	=============================================

این اسکریپت یک دیتابیس ساده برای مدل‌سازی ساختار جغرافیایی کشور ایران ایجاد می‌کند.
دیتابیس شامل سه جدول اصلی برای استان‌ها، شهرستان‌ها و شهرهاست و ارتباط بین آن‌ها به‌صورت
کلید خارجی تعریف شده. این ساختار می‌تواند به‌عنوان یک پایه تمرینی برای یادگیری روابط 
بین جدول‌ها در SQL استفاده شود.

=============================================	*/


USE master
GO

IF (SELECT COUNT(*)
		 FROM sys.databases
		 WHERE name = 'Session02_DB_Iran' ) = 1
	 ALTER DATABASE Session02_DB_Iran SET SINGLE_USER 
	 WITH ROLLBACK IMMEDIATE

DROP DATABASE IF EXISTS Session02_DB_Iran
GO


CREATE DATABASE Session02_DB_Iran
GO

USE Session02_DB_Iran
GO

CREATE TABLE Ostan(OstanID int PRIMARY KEY IDENTITY,
				   OstanName nvarchar(30))

CREATE TABLE Shahrestan(ShahrestanID int PRIMARY KEY IDENTITY,
					    ShahrestanName nvarchar(30),
						OstanID int FOREIGN KEY REFERENCES Ostan(OstanID))


CREATE TABLE Shahr(ShahrID int PRIMARY KEY IDENTITY,
				   ShahrName nvarchar(30),
				   SharestanID int FOREIGN KEY REFERENCES Shahrestan(ShahrestanID))
