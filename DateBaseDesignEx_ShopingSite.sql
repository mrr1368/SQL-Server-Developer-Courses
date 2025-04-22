

/*
    دیتابیس: فروشگاه اینترنتی
    توضیح: این دیتابیس برای مدیریت اطلاعات محصولات، سفارش‌ها، کاربران، پرداخت‌ها و ارسال طراحی شده است.
    ساختار شامل موجودیت‌هایی مانند محصولات، دسته‌بندی‌ها، کاربران، سبد خرید، سفارش‌ها و بررسی کاربران است.
*/


USE master
GO 


IF (SELECT COUNT(*)
		 FROM sys.databases
		 WHERE name = 'DateBaseDesignEx_ShopingSite' ) = 1
	 ALTER DATABASE DateBaseDesignEx_ShopingSite SET SINGLE_USER 
	 WITH ROLLBACK IMMEDIATE

DROP DATABASE IF EXISTS DateBaseDesignEx_ShopingSite
GO


-- ایجاد دیتابیس
CREATE DATABASE DateBaseDesignEx_ShopingSite
GO

USE DateBaseDesignEx_ShopingSite
GO
-- جدول کشورها
CREATE TABLE Country (
    CountryID INT NOT NULL PRIMARY KEY,
    CountryName NVARCHAR(100)
);

-- جدول آدرس‌ها
CREATE TABLE Address (
    AddressID INT NOT NULL PRIMARY KEY,
    UnitNumber NVARCHAR(50),
    StreetNumber NVARCHAR(50),
    AddressLine1 NVARCHAR(100),
    AddressLine2 NVARCHAR(100),
    City NVARCHAR(50),
    Region NVARCHAR(50),
    PostalCode NVARCHAR(20),
    CountryID INT,
    FOREIGN KEY (CountryID) REFERENCES Country(CountryID)
);

-- جدول کاربران سایت
CREATE TABLE SiteUser (
    UserID INT NOT NULL PRIMARY KEY,
    UserFirstName NVARCHAR(50),
    UserLastname NVARCHAR(50),
    EmailAddress NVARCHAR(100),
    Password NVARCHAR(100)
);

-- جدول دسته‌بندی محصولات
CREATE TABLE ProductCategory (
    ProductCategoryID INT NOT NULL PRIMARY KEY,
    ParentProductCategoryID INT,
    ProductCategoryName NVARCHAR(100),
    FOREIGN KEY (ParentProductCategoryID) REFERENCES ProductCategory(ProductCategoryID)
);

-- جدول محصولات
CREATE TABLE Product (
    ProductID INT NOT NULL PRIMARY KEY,
    ProductCategoryID INT,
    ProductName NVARCHAR(100),
    ProductDescription NVARCHAR(500),
    ProductImage VARBINARY(MAX),
    FOREIGN KEY (ProductCategoryID) REFERENCES ProductCategory(ProductCategoryID)
);

-- جدول آیتم‌های محصول
CREATE TABLE ProductItem (
    ProductItemID INT NOT NULL PRIMARY KEY,
    ProductID INT,
    SKU NVARCHAR(50),
    QtyInStock INT,
    ProductImage NVARCHAR(100),
    Price INT,
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
);

-- جدول تنوع محصول
CREATE TABLE Variation (
    VariationID INT NOT NULL PRIMARY KEY,
    ProductCategoryID INT,
    VariationName NVARCHAR(100),
    FOREIGN KEY (ProductCategoryID) REFERENCES ProductCategory(ProductCategoryID)
);

-- جدول گزینه‌های تنوع
CREATE TABLE VariationOption (
    VariationOptionID INT NOT NULL PRIMARY KEY,
    VariationID INT,
    Value NVARCHAR(100),
    FOREIGN KEY (VariationID) REFERENCES Variation(VariationID)
);

-- جدول پیکربندی تنوع تولید
CREATE TABLE ProductionConfig (
    ProductionConfigID INT NOT NULL PRIMARY KEY,
    VariationOptionID INT,
    ProductItemID INT,
    FOREIGN KEY (VariationOptionID) REFERENCES VariationOption(VariationOptionID),
    FOREIGN KEY (ProductItemID) REFERENCES ProductItem(ProductItemID)
);

-- جدول سبد خرید
CREATE TABLE ShopingCart (
    ShapingCartID INT NOT NULL PRIMARY KEY,
    UserID INT,
    FOREIGN KEY (UserID) REFERENCES SiteUser(UserID)
);

-- آیتم‌های سبد خرید
CREATE TABLE ShopingCartItem (
    ShapingCartItemID INT NOT NULL PRIMARY KEY,
    ProductItemID INT,
    ShopingCartID INT,
    FOREIGN KEY (ProductItemID) REFERENCES ProductItem(ProductItemID),
    FOREIGN KEY (ShopingCartID) REFERENCES ShopingCart(ShapingCartID)
);

-- جدول نوع پرداخت
CREATE TABLE PaymentType (
    PaymentTypeID INT NOT NULL PRIMARY KEY,
    PaymentValue NVARCHAR(100)
);

-- روش‌های پرداخت کاربر
CREATE TABLE UserPaymentMethod (
    UserPaymentMethodID INT NOT NULL PRIMARY KEY,
    UserID INT,
    PaymentTypeID INT,
    Provider NVARCHAR(100),
    AccountNumber NVARCHAR(100),
    ExpiryDate DATETIME,
    IsDefault BIT,
    FOREIGN KEY (UserID) REFERENCES SiteUser(UserID),
    FOREIGN KEY (PaymentTypeID) REFERENCES PaymentType(PaymentTypeID)
);

-- جدول روش ارسال
CREATE TABLE ShippingMethod (
    ShippingMethodID INT NOT NULL PRIMARY KEY,
    Name NVARCHAR(100),
    Price INT
);

-- وضعیت سفارش
CREATE TABLE OrderStatus (
    OrderStatusID INT NOT NULL PRIMARY KEY,
    Status NVARCHAR(100)
);

-- جدول سفارش
CREATE TABLE ShopOrder (
    ShopOrderID INT NOT NULL PRIMARY KEY,
    UserID INT,
    OrderDate DATE,
    PaymentMethodID INT,
    ShippingAddressID INT,
    ShippingMethodID INT,
    OrderStatusID INT,
    FOREIGN KEY (UserID) REFERENCES SiteUser(UserID),
    FOREIGN KEY (PaymentMethodID) REFERENCES UserPaymentMethod(UserPaymentMethodID),
    FOREIGN KEY (ShippingAddressID) REFERENCES Address(AddressID),
    FOREIGN KEY (ShippingMethodID) REFERENCES ShippingMethod(ShippingMethodID),
    FOREIGN KEY (OrderStatusID) REFERENCES OrderStatus(OrderStatusID)
);

-- اقلام سفارش
CREATE TABLE OrderLine (
    OrderLineID INT NOT NULL PRIMARY KEY,
    ProductItemID INT,
    OrderID INT,
    Qty INT,
    Price INT,
    FOREIGN KEY (ProductItemID) REFERENCES ProductItem(ProductItemID),
    FOREIGN KEY (OrderID) REFERENCES ShopOrder(ShopOrderID)
);

-- جدول نقد و بررسی کاربران
CREATE TABLE UserReview (
    UserReviewID INT NOT NULL PRIMARY KEY,
    UserID INT,
    OrderLineID INT,
    RatingValue NVARCHAR(50),
    Comment NVARCHAR(500),
    FOREIGN KEY (UserID) REFERENCES SiteUser(UserID),
    FOREIGN KEY (OrderLineID) REFERENCES OrderLine(OrderLineID)
);

-- آدرس‌های کاربر
CREATE TABLE UserAddress (
    UserAddressID INT NOT NULL PRIMARY KEY,
    UserID INT,
    AddressID INT,
    IsDefault BIT,
    FOREIGN KEY (UserID) REFERENCES SiteUser(UserID),
    FOREIGN KEY (AddressID) REFERENCES Address(AddressID)
);

-- جدول تخفیف‌ها
CREATE TABLE Promotion (
    PromotionID INT NOT NULL PRIMARY KEY,
    Name NVARCHAR(100),
    Description NVARCHAR(300),
    DiscountRate NVARCHAR(50),
    StartDate DATE,
    EndDate DATE
);

-- تخفیف روی دسته‌بندی‌ها
CREATE TABLE PromotionCategory (
    PromotionCategoryID INT NOT NULL PRIMARY KEY,
    PromotionID INT,
    ProductCategoryID INT,
    FOREIGN KEY (PromotionID) REFERENCES Promotion(PromotionID),
    FOREIGN KEY (ProductCategoryID) REFERENCES ProductCategory(ProductCategoryID)
);
