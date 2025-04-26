
/*
    دیتابیس: Instagram Simulation
    توضیح: این ساختار دیتابیس برای شبیه‌سازی عملکردهای اصلی یک شبکه اجتماعی مانند اینستاگرام طراحی شده است.
    شامل جدول‌هایی برای مدیریت کاربران، پست‌ها، فالوئرها، ری‌اکشن‌ها، کامنت‌ها، رسانه‌های چندرسانه‌ای و افکت‌ها می‌باشد.
    هدف از طراحی این دیتابیس، پیاده‌سازی اصولی و قابل گسترش برای تمرین یا پروژه‌های آموزشی مرتبط با SQL Server است.
*/

USE master
GO 


IF (SELECT COUNT(*)
		 FROM sys.databases
		 WHERE name = 'DateBaseDesignEx_Instagram' ) = 1
	 ALTER DATABASE DateBaseDesignEx_Instagram SET SINGLE_USER 
	 WITH ROLLBACK IMMEDIATE

DROP DATABASE IF EXISTS DataBaseDesignEx_Instagram
GO


-- ایجاد دیتابیس
CREATE DATABASE DataBaseDesignEx_Instagram
GO

USE DataBaseDesignEx_Instagram
GO
-- جدول کاربران
CREATE TABLE AppUser (
    AppUserID INT NOT NULL PRIMARY KEY,
    UserFirstName NVARCHAR(50) NOT NULL,
    UserLastName NVARCHAR(50) NOT NULL,
    UserProfileName NVARCHAR(50) NOT NULL,
    SignupDate DATETIME NOT NULL DEFAULT GETDATE()
);

-- جدول کامنت‌ها
CREATE TABLE Comment (
    CommentID INT NOT NULL PRIMARY KEY,
    CreateByAppUserID INT,
    PostID INT,
    CreateDatetime DATETIME NOT NULL,
    Comment NVARCHAR(300),
    RepliedCommentToID INT
);

-- جدول افکت‌ها
CREATE TABLE Effect (
    EffectID INT NOT NULL PRIMARY KEY,
    EffectName NVARCHAR(100)
);

-- جدول فیلترها
CREATE TABLE Filter (
    FilterID INT NOT NULL PRIMARY KEY,
    FilterDetail NVARCHAR(100)
);

-- جدول دنبال‌کننده‌ها
CREATE TABLE Follower (
    FollowerID INT NOT NULL PRIMARY KEY,
    AppUserFollowing INT,
    AppUserFollowed INT
);

-- جدول پست‌ها
CREATE TABLE Post (
    PostID INT NOT NULL PRIMARY KEY,
    AppUserID INT NOT NULL,
    CreateDatetime DATETIME NOT NULL,
    Caption NVARCHAR(300),
    PostTypeID INT
);

-- جدول افکت‌های استفاده شده در پست‌ها
CREATE TABLE PostEffect (
    PostEffectID INT NOT NULL PRIMARY KEY,
    EffectID INT NOT NULL,
    EffectDetail NVARCHAR(100),
    EffectScale NVARCHAR(50) NOT NULL,
    PostMediaID INT
);

-- جدول رسانه‌های پست
CREATE TABLE PostMedia (
    PostMediaID INT NOT NULL PRIMARY KEY,
    PostID INT NOT NULL,
    MediaFile VARBINARY(MAX),
    Position NVARCHAR(50) NOT NULL,
    Location NVARCHAR(100) NOT NULL,
    FilterID INT NOT NULL
);

-- جدول نوع پست
CREATE TABLE PostType (
    PostTypeID INT NOT NULL PRIMARY KEY,
    PostTypeName NVARCHAR(100)
);

-- جدول واکنش‌ها
CREATE TABLE Reaction (
    ReactionID INT NOT NULL PRIMARY KEY,
    AppUserID INT,
    PostID INT
);

-- جدول تگ کاربران روی رسانه‌ها
CREATE TABLE UserPostMediaTag (
    UserPostMediaTagID INT NOT NULL PRIMARY KEY,
    AppUserID INT NOT NULL,
    PostMediaID INT NOT NULL,
    XCoordinate NVARCHAR(50),
    YCoordinate NVARCHAR(50)
);

-- روابط بین جداول (Foreign Keys)

-- Comment
ALTER TABLE Comment ADD FOREIGN KEY (CreateByAppUserID) REFERENCES AppUser(AppUserID);
ALTER TABLE Comment ADD FOREIGN KEY (PostID) REFERENCES Post(PostID);
ALTER TABLE Comment ADD FOREIGN KEY (RepliedCommentToID) REFERENCES Comment(CommentID);

-- Follower
ALTER TABLE Follower ADD FOREIGN KEY (AppUserFollowing) REFERENCES AppUser(AppUserID);
ALTER TABLE Follower ADD FOREIGN KEY (AppUserFollowed) REFERENCES AppUser(AppUserID);

-- Post
ALTER TABLE Post ADD FOREIGN KEY (AppUserID) REFERENCES AppUser(AppUserID);
ALTER TABLE Post ADD FOREIGN KEY (PostTypeID) REFERENCES PostType(PostTypeID);

-- PostEffect
ALTER TABLE PostEffect ADD FOREIGN KEY (EffectID) REFERENCES Effect(EffectID);
ALTER TABLE PostEffect ADD FOREIGN KEY (PostMediaID) REFERENCES PostMedia(PostMediaID);

-- PostMedia
ALTER TABLE PostMedia ADD FOREIGN KEY (PostID) REFERENCES Post(PostID);
ALTER TABLE PostMedia ADD FOREIGN KEY (FilterID) REFERENCES Filter(FilterID);

-- Reaction
ALTER TABLE Reaction ADD FOREIGN KEY (AppUserID) REFERENCES AppUser(AppUserID);
ALTER TABLE Reaction ADD FOREIGN KEY (PostID) REFERENCES Post(PostID);

-- UserPostMediaTag
ALTER TABLE UserPostMediaTag ADD FOREIGN KEY (AppUserID) REFERENCES AppUser(AppUserID);
ALTER TABLE UserPostMediaTag ADD FOREIGN KEY (PostMediaID) REFERENCES PostMedia(PostMediaID);
