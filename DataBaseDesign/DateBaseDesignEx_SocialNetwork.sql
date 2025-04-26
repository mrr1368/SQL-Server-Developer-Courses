


/*
    دیتابیس: شبکه اجتماعی
    توضیح: این پایگاه داده شامل کاربران، پست‌ها، لایک‌ها، کامنت‌ها و ارتباطات دوستی بین کاربران است.
*/


USE master
GO 


IF (SELECT COUNT(*)
		 FROM sys.databases
		 WHERE name = 'DateBaseDesignEx_SocialNetwork' ) = 1
	 ALTER DATABASE DateBaseDesignEx_SocialNetwork SET SINGLE_USER 
	 WITH ROLLBACK IMMEDIATE

DROP DATABASE IF EXISTS DateBaseDesignEx_SocialNetwork
GO


-- ایجاد دیتابیس
CREATE DATABASE DateBaseDesignEx_SocialNetwork
GO

USE DateBaseDesignEx_SocialNetwork
GO

-- جدول کاربران
CREATE TABLE UserProfile (
    UserProfileID INT NOT NULL PRIMARY KEY,
    UserName NVARCHAR(50),
    Password NVARCHAR(100),
    Email NVARCHAR(100),
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50)
);

-- جدول پست‌های کاربران
CREATE TABLE UserPost (
    UserPostsID INT NOT NULL PRIMARY KEY,
    UserProfileID INT NOT NULL,
    WrittenPost NVARCHAR(1000),
    MediaLocation VARBINARY(MAX),
    CreateDatetime DATETIME NOT NULL,
    FOREIGN KEY (UserProfileID) REFERENCES UserProfile(UserProfileID)
);

-- جدول لایک‌ها
CREATE TABLE PostLike (
    PostLikeID INT NOT NULL PRIMARY KEY,
    UserPostID INT,
    UserProfileID INT,
    CreateDatetime DATETIME,
    FOREIGN KEY (UserPostID) REFERENCES UserPost(UserPostsID),
    FOREIGN KEY (UserProfileID) REFERENCES UserProfile(UserProfileID)
);

-- جدول کامنت‌های پست
CREATE TABLE PostComment (
    PostCommentID INT NOT NULL PRIMARY KEY,
    UserProfileID INT,
    UserPostID INT,
    CommentText NVARCHAR(500),
    CreateDatetime DATETIME,
    FOREIGN KEY (UserProfileID) REFERENCES UserProfile(UserProfileID),
    FOREIGN KEY (UserPostID) REFERENCES UserPost(UserPostsID)
);

-- جدول دوستی بین کاربران
CREATE TABLE Friendship (
    FriendshipID INT NOT NULL PRIMARY KEY,
    UserProfileIDReq INT,
    UserProfileIDAcc INT,
    FOREIGN KEY (UserProfileIDReq) REFERENCES UserProfile(UserProfileID),
    FOREIGN KEY (UserProfileIDAcc) REFERENCES UserProfile(UserProfileID)
);
