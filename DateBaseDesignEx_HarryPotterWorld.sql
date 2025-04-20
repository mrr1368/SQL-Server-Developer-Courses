


/*	=============================================


    این دیتابیس برای مدیریت اطلاعات دنیای هری پاتر طراحی شده است. 
    شامل جداولی برای ذخیره اطلاعات خانه‌ها، کلاس‌ها، دانش‌آموزان، اساتید، تیم‌های کوییدیچ و مسابقات مختلف است.


=============================================	*/


USE master;
GO

IF (SELECT COUNT(*)
		 FROM sys.databases
		 WHERE name = 'DateBaseDesignEx_HarryPotterWorld' ) = 1
	 ALTER DATABASE DateBaseDesignEx_HarryPotterWorld SET SINGLE_USER 
	 WITH ROLLBACK IMMEDIATE

DROP DATABASE IF EXISTS DateBaseDesignEx_HarryPotterWorld
GO

CREATE DATABASE DateBaseDesignEx_HarryPotterWorld;
GO

USE DateBaseDesignEx_HarryPotterWorld;
GO

/****** جدول کلاس‌ها: برای ذخیره اطلاعات در مورد کلاس‌ها و ارتباطات با استاد و موضوع ******/

CREATE TABLE Class(
    ClassID INT NOT NULL,
    TeacherID INT NULL,
    SubjectID INT NULL,
    CONSTRAINT PK_Class PRIMARY KEY CLUSTERED (ClassID)
)
GO

/****** جدول خانه‌ها: برای ذخیره اطلاعات مربوط به خانه‌های هاگوارتز ******/


CREATE TABLE House(
    HouseID INT NOT NULL,
    HouseName NCHAR(10) NULL,
    FounderedFirstName NCHAR(10) NULL,
    FounderedLastname NCHAR(10) NULL,
    PrimaryColor NCHAR(10) NULL,
    SecondaryColor NCHAR(10) NULL,
    CONSTRAINT PK_House PRIMARY KEY CLUSTERED (HouseID)
)
GO

/****** جدول امتیاز خانه‌ها: برای ذخیره اطلاعات امتیازات خانه‌ها در هر سال ******/

CREATE TABLE Housepoint(
    HousePoint INT NOT NULL,
    HouseID INT NULL,
    Year DATE NULL,
    TotalPoint INT NULL,
    CONSTRAINT PK_Housepoint PRIMARY KEY CLUSTERED (HousePoint)
)
GO

/****** جدول مسابقات: برای ذخیره اطلاعات مربوط به مسابقات و نتایج آنها ******/

CREATE TABLE Match(
    MatchID INT NOT NULL,
    Team1ID INT NULL,
    Team2ID INT NULL,
    Team1Score INT NULL,
    Team2Score INT NULL,
    DatePlayed DATETIME NULL,
    CONSTRAINT PK_Match PRIMARY KEY CLUSTERED (MatchID)
)
GO

/****** جدول تیم‌های کوییدیچ: برای ذخیره اطلاعات مربوط به تیم‌های کوییدیچ هر خانه ******/

CREATE TABLE QuiddechTeam(
    QuiddechTeamID INT NOT NULL,
    HouseID INT NULL,
    TeamYear DATE NULL,
    CONSTRAINT PK_QuiddechTeam PRIMARY KEY CLUSTERED (QuiddechTeamID)
)
GO

/****** جدول دانش‌آموزان: برای ذخیره اطلاعات دانش‌آموزان و خانه‌های آنها ******/

CREATE TABLE Student(
    StudentID INT NOT NULL,
    HouseID INT NULL,
    StudentFirstName NCHAR(10) NULL,
    StudentLastname NCHAR(10) NULL,
    Enrolled DATE NULL,
    CONSTRAINT PK_Student PRIMARY KEY CLUSTERED (StudentID)
)
GO

/****** جدول کلاس‌های دانش‌آموزان: برای ذخیره ارتباط بین دانش‌آموزان و کلاس‌ها ******/

CREATE TABLE StudentClass(
    StudentClassID INT NOT NULL,
    ClassID INT NULL,
    StudentID INT NULL,
    CONSTRAINT PK_StudentClass PRIMARY KEY CLUSTERED (StudentClassID)
)
GO

/****** جدول تیم‌های کوییدیچ دانش‌آموزان: برای ذخیره اطلاعات ارتباط دانش‌آموزان با تیم‌های کوییدیچ ******/

CREATE TABLE StudentQuiddechTeam(
    StudentQuiddechTeamID INT NOT NULL,
    StudentID INT NULL,
    QuiddechTeam INT NULL,
    IsCaptain BIT NULL,
    CONSTRAINT PK_StudentQuiddechTeam PRIMARY KEY CLUSTERED (StudentQuiddechTeamID)
)
GO

/****** جدول موضوعات: برای ذخیره اطلاعات مربوط به موضوعات درسی ******/

CREATE TABLE Subject(
    SubjectID INT NOT NULL,
    SubjectName NCHAR(10) NULL,
    CONSTRAINT PK_Subject PRIMARY KEY CLUSTERED (SubjectID)
)
GO

/****** جدول اساتید: برای ذخیره اطلاعات اساتید و نام‌های آنها ******/

CREATE TABLE Teacher(
    TeacherID INT NOT NULL,
    TeacherFirstname NCHAR(10) NULL,
    TeacherLastname NCHAR(10) NULL,
    CONSTRAINT PK_Teacher PRIMARY KEY CLUSTERED (TeacherID)
)
GO

/****** جدول اساتید مسئول خانه‌ها: برای ذخیره اطلاعات اساتیدی که مسئول خانه‌ها هستند ******/

CREATE TABLE TeacherHeadOFHouse(
    TeacherHeadOFHouseID INT NOT NULL,
    HouseID INT NULL,
    TeacherID INT NULL,
    YearCommences DATE NULL,
    CONSTRAINT PK_TeacherHeadOFHouse PRIMARY KEY CLUSTERED (TeacherHeadOFHouseID)
)
GO


/****** 
    این بخش شامل ایجاد روابط بین جداول مختلف دیتابیس با استفاده از کلیدهای خارجی است.
    این کلیدهای خارجی تضمین می‌کنند که داده‌ها با یکدیگر به درستی مرتبط باشند.
******/





/****** افزودن کلید خارجی به جدول [Class] برای ارتباط با جدول [Subject] ******/

ALTER TABLE Class WITH CHECK ADD CONSTRAINT FK_Class_Subject FOREIGN KEY(SubjectID)
REFERENCES Subject (SubjectID)
GO
ALTER TABLE Class CHECK CONSTRAINT FK_Class_Subject
GO

/****** افزودن کلید خارجی به جدول [Class] برای ارتباط با جدول [Teacher] ******/

ALTER TABLE Class WITH CHECK ADD CONSTRAINT FK_Class_Teacher FOREIGN KEY(TeacherID)
REFERENCES Teacher (teacherID)
GO
ALTER TABLE Class CHECK CONSTRAINT FK_Class_Teacher
GO

/****** افزودن کلید خارجی به جدول [Housepoint] برای ارتباط با جدول [House] ******/

ALTER TABLE Housepoint WITH CHECK ADD CONSTRAINT FK_Housepoint_House FOREIGN KEY(houseID)
REFERENCES House (HouseID)
GO
ALTER TABLE Housepoint CHECK CONSTRAINT FK_Housepoint_House
GO

/****** افزودن کلید خارجی به جدول [Match] برای ارتباط با جدول [QuiddechTeam] ******/

ALTER TABLE Match WITH CHECK ADD CONSTRAINT FK_Match_QuiddechTeam FOREIGN KEY(Team1ID)
REFERENCES QuiddechTeam (QuiddechTeamID)
GO
ALTER TABLE Match CHECK CONSTRAINT FK_Match_QuiddechTeam
GO

/****** افزودن کلید خارجی به جدول [Match] برای ارتباط با جدول [QuiddechTeam] برای تیم 2 ******/

ALTER TABLE Match WITH CHECK ADD CONSTRAINT FK_Match_QuiddechTeam1 FOREIGN KEY(Team2ID)
REFERENCES QuiddechTeam (QuiddechTeamID)
GO
ALTER TABLE Match CHECK CONSTRAINT FK_Match_QuiddechTeam1
GO

/****** افزودن کلید خارجی به جدول [QuiddechTeam] برای ارتباط با جدول [House] ******/


ALTER TABLE QuiddechTeam WITH CHECK ADD CONSTRAINT FK_QuiddechTeam_House FOREIGN KEY(HouseID)
REFERENCES House (HouseID)
GO
ALTER TABLE QuiddechTeam CHECK CONSTRAINT FK_QuiddechTeam_House
GO

/****** افزودن کلید خارجی به جدول [Student] برای ارتباط با جدول [House] ******/

ALTER TABLE Student WITH CHECK ADD CONSTRAINT FK_Student_House FOREIGN KEY(HouseID)
REFERENCES House (HouseID)
GO
ALTER TABLE Student CHECK CONSTRAINT FK_Student_House
GO

/****** افزودن کلید خارجی به جدول [StudentClass] برای ارتباط با جدول [Class] ******/

ALTER TABLE StudentClass WITH CHECK ADD CONSTRAINT FK_StudentClass_Class FOREIGN KEY(ClassID)
REFERENCES Class (ClassID)
GO
ALTER TABLE StudentClass CHECK CONSTRAINT FK_StudentClass_Class
GO

/****** افزودن کلید خارجی به جدول [StudentClass] برای ارتباط با جدول [Student] ******/

ALTER TABLE StudentClass WITH CHECK ADD CONSTRAINT FK_StudentClass_Student FOREIGN KEY(StudentID)
REFERENCES Student (StudentID)
GO
ALTER TABLE StudentClass CHECK CONSTRAINT FK_StudentClass_Student
GO

/****** افزودن کلید خارجی به جدول [StudentQuiddechTeam] برای ارتباط با جدول [QuiddechTeam] ******/

ALTER TABLE StudentQuiddechTeam WITH CHECK ADD CONSTRAINT FK_StudentQuiddechTeam_QuiddechTeam FOREIGN KEY(QuiddechTeam)
REFERENCES QuiddechTeam (QuiddechTeamID)
GO
ALTER TABLE StudentQuiddechTeam CHECK CONSTRAINT FK_StudentQuiddechTeam_QuiddechTeam
GO

/****** افزودن کلید خارجی به جدول [StudentQuiddechTeam] برای ارتباط با جدول [Student] ******/

ALTER TABLE StudentQuiddechTeam WITH CHECK ADD CONSTRAINT FK_StudentQuiddechTeam_Student FOREIGN KEY(StudentID)
REFERENCES Student (StudentID)
GO
ALTER TABLE StudentQuiddechTeam CHECK CONSTRAINT FK_StudentQuiddechTeam_Student
GO

/****** افزودن کلید خارجی به جدول [TeacherHeadOFHouse] برای ارتباط با جدول [House] ******/

ALTER TABLE TeacherHeadOFHouse WITH CHECK ADD CONSTRAINT FK_TeacherHeadOFHouse_House FOREIGN KEY(HouseID)
REFERENCES House (HouseID)
GO
ALTER TABLE TeacherHeadOFHouse CHECK CONSTRAINT FK_TeacherHeadOFHouse_House
GO

/****** افزودن کلید خارجی به جدول [TeacherHeadOFHouse] برای ارتباط با جدول [Teacher] ******/

ALTER TABLE TeacherHeadOFHouse WITH CHECK ADD CONSTRAINT FK_TeacherHeadOFHouse_Teacher FOREIGN KEY(TeacherID)
REFERENCES Teacher (teacherID)
GO
ALTER TABLE TeacherHeadOFHouse CHECK CONSTRAINT FK_TeacherHeadOFHouse_Teacher
GO
