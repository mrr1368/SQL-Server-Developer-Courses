

/* =============================================


دیتابیس سیستم پیامرسان با ساختار کامل:
- مدیریت کاربران و احراز هویت
- سیستم مکالمات فردی و گروهی
- پیام‌های متنی و فایلی
- سیستم نقش‌ها و دسترسی‌های مدیریتی


============================================= */



USE master
GO

IF (SELECT COUNT(*)
		 FROM sys.databases
		 WHERE name = 'Session05_DB_Messenger' ) = 1
	 ALTER DATABASE Session05_DB_Messenger SET SINGLE_USER 
	 WITH ROLLBACK IMMEDIATE


-- ایجاد دیتابیس
CREATE DATABASE Session05_DB_Messenger
GO

USE Session05_DB_Messenger
GO

-- جدول اطلاعات کاربران
CREATE TABLE User_Info (User_Info_ID INT IDENTITY(1,1) PRIMARY KEY,
						User_First_Name NVARCHAR(30),
						User_Last_Name NVARCHAR(30),
						Profile_Photo BINARY(1))
GO

-- جدول احراز هویت کاربران
CREATE TABLE Authoriza_User (Authoriza_User_ID INT IDENTITY(1,1) PRIMARY KEY,
							 User_Info_ID INT FOREIGN KEY REFERENCES User_Info(User_Info_ID),
							 Username VARCHAR(20),
							 User_Password VARCHAR(20),
							 Email NVARCHAR(50),
							 Is_Con_Email BIT DEFAULT 0,
							 Mobile CHAR(11) CHECK (Mobile LIKE '09[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
							 Is_Con_Mobile BIT DEFAULT 0)
GO

-- جدول مکالمات
CREATE TABLE Conversation_Table (Conversation_ID INT IDENTITY(1,1) PRIMARY KEY,
								 Conversayion_Name NVARCHAR(50))
GO

-- جدول گروه‌های کاربران
CREATE TABLE Group_User (Group_User INT IDENTITY(1,1) PRIMARY KEY,
						 Conversation_ID INT FOREIGN KEY REFERENCES Conversation_Table(Conversation_ID),
						 User_Info_ID INT FOREIGN KEY REFERENCES User_Info(User_Info_ID),
						 Joiend_Datetime DATETIME DEFAULT GETDATE(),
						 Left_Datetime DATETIME DEFAULT GETDATE())
GO

-- جدول پیام‌ها
CREATE TABLE Message_Table (Message_ID INT IDENTITY(1,1) PRIMARY KEY,
							From_User_ID INT,
							To_User_ID INT,
							Message_Text NVARCHAR(MAX),
							Message_File VARBINARY(MAX),
							Send_Datetime DATETIME DEFAULT GETDATE(),
							Send_Check BIT DEFAULT 0,
							Deliver_Datetime DATETIME DEFAULT GETDATE(),
							Deliver_Check BIT DEFAULT 0,
							ReadCheck BIT DEFAULT 0,
							Parent_Message_ID INT FOREIGN KEY REFERENCES Message_Table(Message_ID),
							Conversation_ID INT FOREIGN KEY REFERENCES Conversation_Table(Conversation_ID))
GO

-- جداول مدیریت نقش‌ها و دسترسی‌ها
CREATE TABLE M_Action (Action_ID INT IDENTITY(1,1) PRIMARY KEY,
					   Action_Name NVARCHAR(50))
GO

CREATE TABLE M_Role (Role_ID INT IDENTITY(1,1) PRIMARY KEY,
					 Role_Title NVARCHAR(30))
GO

CREATE TABLE M_User_Role (M_User_Role_ID INT IDENTITY(1,1) PRIMARY KEY,
						  M_User_ID INT FOREIGN KEY REFERENCES Authoriza_User(Authoriza_User_ID),
						  Role_ID INT FOREIGN KEY REFERENCES M_Role(Role_ID))
GO

CREATE TABLE Role_Action (Role_Action_ID INT IDENTITY(1,1) PRIMARY KEY,
						Role_ID INT FOREIGN KEY REFERENCES M_Role(Role_ID),
						Action_ID INT FOREIGN KEY REFERENCES M_Action(Action_ID))
GO