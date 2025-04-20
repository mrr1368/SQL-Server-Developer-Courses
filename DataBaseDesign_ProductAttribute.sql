

/*	=============================================


 اسکریپت طراحی پایگاه داده برای نگهداری ویژگی‌های محصولات مانند رنگ، جنس، اندازه و دسته‌بندی آن‌ها
 این اسکریپت شامل ساخت جداول، کلیدهای اصلی و روابط بین جداول می‌باشد


=============================================	*/


USE master;
GO

IF (SELECT COUNT(*)
		 FROM sys.databases
		 WHERE name = 'DataBaseDesign_ProductAttribute' ) = 1
	 ALTER DATABASE DataBaseDesign_ProductAttribute SET SINGLE_USER 
	 WITH ROLLBACK IMMEDIATE

DROP DATABASE IF EXISTS DataBaseDesign_ProductAttribute
GO

-- ایجاد دیتابیس
CREATE DATABASE DataBaseDesign_ProductAttribute;
GO

USE DataBaseDesign_ProductAttribute;
GO

-- جدول Color
CREATE TABLE Color (
    ColorID INT NOT NULL,
    ColorValue NCHAR(10) NOT NULL,
    CONSTRAINT PK_Color PRIMARY KEY CLUSTERED (ColorID)
)
GO

-- جدول Material
CREATE TABLE Material (
    MaterialID INT NOT NULL,
    MaterialValue NCHAR(50) NOT NULL,
    CONSTRAINT PK_Material PRIMARY KEY CLUSTERED (MaterialID)
)
GO

-- جدول Product
CREATE TABLE Product (
    ProductID INT NOT NULL,
    ProductName NVARCHAR(50) NOT NULL,
    Description NVARCHAR(500) NOT NULL,
    CONSTRAINT PK_Product PRIMARY KEY CLUSTERED (ProductID)
)
GO

-- جدول Siza (نام صحیح‌تر می‌تواند Size باشد)
CREATE TABLE Siza (
    SizeID INT NOT NULL,
    SizeValue NCHAR(10) NOT NULL,
    CONSTRAINT PK_Siza PRIMARY KEY CLUSTERED (SizeID)
)
GO

-- جدول میانی ProductEntry برای ارتباط بین ویژگی‌ها
CREATE TABLE ProductEntry (
    SizeID INT NOT NULL,
    ProductID INT NOT NULL,
    MaterialID INT NOT NULL,
    ColorID INT NOT NULL
)
GO

-- تعریف روابط خارجی
ALTER TABLE ProductEntry ADD CONSTRAINT FK_Color_ProductEntry
FOREIGN KEY (ColorID) REFERENCES Color(ColorID)
GO

ALTER TABLE ProductEntry ADD CONSTRAINT FK_Material_ProductEntry
FOREIGN KEY (MaterialID) REFERENCES Material(MaterialID)
GO

ALTER TABLE ProductEntry ADD CONSTRAINT FK_Product_ProductEntry
FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
GO

ALTER TABLE ProductEntry ADD CONSTRAINT FK_Siza_ProductEntry
FOREIGN KEY (SizeID) REFERENCES Siza(SizeID)
GO
