
/*	=============================================

این اسکریپت یک دیتابیس برای مدیریت اطلاعات دانشگاهی ایجاد می‌کند.
دیتابیس شامل جداولی برای ذخیره‌سازی اطلاعات دانشجویان، درس‌ها، معلمان، کلاس‌ها، ارزیابی‌ها و فاکتورها است. 
روابط میان جداول با استفاده از کلید خارجی تعریف شده‌اند تا یکپارچگی داده‌ها حفظ شود.
این ساختار برای مدیریت اطلاعات مربوط به تحصیلات و ارزیابی‌های دانشجویان مناسب است
و به عنوان یک الگو برای یادگیری طراحی دیتابیس و ارتباطات میان جداول می‌تواند مفید باشد.میان جداول می‌تواند مفید ب

=============================================	*/

USE master
GO 


IF (SELECT COUNT(*)
		 FROM sys.databases
		 WHERE name = 'Session05_DB_University' ) = 1
	 ALTER DATABASE Session02_DB_Iran SET SINGLE_USER 
	 WITH ROLLBACK IMMEDIATE

DROP DATABASE IF EXISTS Session05_DB_University
GO

CREATE DATABASE Session05_DB_University
GO 

USE Session05_DB_University
GO

CREATE TABLE Student (StudentID int IDENTITY PRIMARY KEY , 
					  StudentFirstname nvarchar(50) , 
					  StudentLastname nvarchar(50) ,
					  StudentNational char(10) , 
					  EducationID tinyint , 
					  FieldID smallint ,
					  IsActive bit DEFAULT 1)

CREATE TABLE Education (EducationID tinyint PRIMARY KEY IDENTITY(10,1) , 
						EducationTitle nvarchar(25))

CREATE TABLE Field (FieldID smallint PRIMARY KEY IDENTITY(1000,1) , 
					FieldTitle nvarchar(30))

ALTER TABLE Student 
ADD CONSTRAINT fk_Student_Education FOREIGN KEY (EducationID) REFERENCES Education (EducationID)

ALTER TABLE Student 
ADD CONSTRAINT fk_Student_Field FOREIGN KEY (FieldID) REFERENCES Field (FieldID)
ON DELETE NO ACTION 
		  --SET NULL 
		  --SET DEFAULT
		  --CASCADE 
ON UPDATE NO ACTION 
		  --SET NULL 
		  --SET DEFAULT
		  --CASCADE 

CREATE TABLE Lesson (LessonID int IDENTITY PRIMARY KEY , 
					 LessonTitle nvarchar(40) NOT NULL , 
					 LessonUnit tinyint ,
					 ReqLessonID int REFERENCES Lesson (LessonID))


CREATE TABLE Teacher (TeacherID int IDENTITY PRIMARY KEY)

CREATE TABLE Class (ClassID int IDENTITY PRIMARY KEY , 
					LessonID int FOREIGN KEY REFERENCES Lesson (LessonID) , 
					TeacherID int FOREIGN KEY REFERENCES Teacher (TeacherID))

CREATE TABLE ClassStudent (ClassID int FOREIGN KEY REFERENCES Class (ClassID) NOT NULL, 
						   StudentID int FOREIGN KEY REFERENCES Student (StudentID) NOT NULL)

ALTER TABLE ClassStudent 
ADD CONSTRAINT pk_ClassStudent PRIMARY KEY (ClassID,StudentID)

CREATE TABLE Question (QuestionID int IDENTITY PRIMARY KEY , 
					   QuestionDesc nvarchar(100))


CREATE TABLE Assessment (Id int IDENTITY PRIMARY KEY , 
						 QuestionID int FOREIGN KEY REFERENCES Question (QuestionID) , 
						 ClassID int , 
						 StudentID int , 
						 Result tinyint)

ALTER TABLE Assessment 
ADD CONSTRAINT fk_Assessment_Class_Student FOREIGN KEY (ClassID,StudentID) REFERENCES ClassStudent (ClassID,StudentID)

CREATE UNIQUE NONCLUSTERED INDEX ixStudentNational ON Student (StudentNational)
