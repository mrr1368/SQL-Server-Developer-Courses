/*	=============================================

این اسکریپت برای ایجاد دیتابیس و جداول یک دفتر وکالت است.
ابتدا دیتابیس موجود را در صورت وجود حذف می‌کند و سپس یک دیتابیس جدید به نام 
'SqlCourseS03_LawOffice' ایجاد می‌کند. جداول شامل اطلاعات مربوط به پرونده‌ها، 
مشتریان، وکلا و پرداخت‌های مشتریان و وکلا می‌شود.

=============================================	*/


USE master
GO 

IF (SELECT COUNT(*) 
		FROM sys.databases 
		WHERE name = 'Session04_DB_LawOffice' ) = 1
	ALTER DATABASE Session04_DB_LawOffice SET  SINGLE_USER
	WITH ROLLBACK IMMEDIATE
GO

DROP DATABASE IF EXISTS Session04_DB_LawOffice
GO

CREATE DATABASE Session04_DB_LawOffice
GO

USE Session04_DB_LawOffice
GO 

CREATE TABLE Client(ClientID int PRIMARY KEY IDENTITY , 
					ClientFirstname varchar(20) , 
					ClientLastname varchar(20) , 
					ClientNationalID char(10) NOT NULL , 
					IsActive bit DEFAULT 1)

CREATE TABLE CaseLaw (CaseID int IDENTITY(1000,1) PRIMARY KEY , 
					  SubjectID tinyint , 
					  CreateDate date DEFAULT GETDATE())

CREATE TABLE CaseClient	(CaseID int FOREIGN KEY REFERENCES  CaseLaw (CaseID) , 
						 ClientID int FOREIGN KEY REFERENCES  Client(ClientID) 
						 CONSTRAINT pk_Case_Client PRIMARY KEY (CaseID , ClientID))

CREATE TABLE Subject (SubjectID tinyint PRIMARY KEY IDENTITY , 
					  SubjectTitle nvarchar(35))

ALTER TABLE CaseLaw 
ADD CONSTRAINT fk_Case_Subject FOREIGN KEY (SubjectID) REFERENCES  Subject (SubjectID)


CREATE TABLE ClientPay (ClientPayID int IDENTITY PRIMARY KEY , 
						CaseID int ,
						ClientID int )

ALTER TABLE ClientPay 
ADD CONSTRAINT fk_Client_Pay FOREIGN KEY (CaseID , ClientID) REFERENCES  CaseClient (CaseID , ClientID)

CREATE TABLE Lawyer (LawyerID tinyint , 
					 LawyerFirstname varchar(35) , 
					 LawyerLastname varchar(35))


ALTER TABLE Lawyer
ALTER COLUMN  LawyerID int NOT NULL
GO

ALTER TABLE Lawyer 
ADD CONSTRAINT pk_LawyerID PRIMARY KEY (LawyerID) 
GO

CREATE TABLE CaseLawyer (CaseLawyerID int PRIMARY KEY IDENTITY , 
						 CaseID int FOREIGN KEY REFERENCES  CaseLaw (CaseID) , 
						 LawyerID int FOREIGN KEY REFERENCES  Lawyer(LawyerID))

CREATE TABLE LawyerPay (LawyerPayID int PRIMARY KEY IDENTITY , 
						CaseLawyerID int FOREIGN KEY REFERENCES CaseLawyer (CaseLawyerID))