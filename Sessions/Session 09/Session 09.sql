

/*
    ==========================================================
    جلسه ۹: دستورات پیچیده SQL، Aggregation، JOIN و CASE Expressions
    ==========================================================
    
    در این جلسه، با مجموعه‌ای از دستورات پیچیده SQL آشنا می‌شویم که به شما کمک می‌کنند تا عملیات‌های پیچیده‌تری روی داده‌ها انجام دهید.
	مفاهیم و تکنیک‌های این جلسه شامل موارد زیر می‌باشند:
    
    1. **Aggregation Functions**: محاسبه مجموع (SUM)، میانگین (AVG)، حداکثر و حداقل (MAX/MIN) و تعداد رکوردها (COUNT) بر اساس گروه‌ها یا شرایط خاص.
    2. **JOINs**: ترکیب داده‌ها از چندین جدول مختلف با استفاده از دستورات مختلف مانند **INNER JOIN**، **LEFT JOIN** و **RIGHT JOIN**.
    3. **GROUP BY**: گروه‌بندی داده‌ها بر اساس یک یا چند ستون خاص و انجام عملیات روی گروه‌ها.
    4. **HAVING**: فیلتر کردن داده‌های گروه‌بندی شده بر اساس شرایط خاص.
    5. **CASE Expressions**: پردازش مقادیر به صورت شرطی و ایجاد مقادیر جدید بر اساس شرایط خاص (استفاده از CASE و IIF).
    6. **Subqueries**: استفاده از زیرپرس‌جو برای استخراج نتایج خاص در داخل یک پرس‌وجو.
    7. **NULL Handling**: مدیریت مقادیر **NULL** در داده‌ها.
    
    این جلسه به شما این امکان را می‌دهد که بتوانید تحلیل‌های پیچیده‌تری روی داده‌ها انجام داده و نتایج دقیق‌تری استخراج کنید.
*/





/* ========================================================
   1. محاسبه مجموع فروش‌ها برای هر نویسنده با در نظر گرفتن تعداد نویسندگان هر عنوان
   این کوئری برای هر نویسنده مجموع فروش‌ها را با در نظر گرفتن تعداد نویسندگان (که با استفاده از یک زیرپرس‌جو محاسبه می‌شود) محاسبه می‌کند. 
   **INNER JOIN** برای ترکیب داده‌ها از جداول مختلف استفاده شده است.
   ==========================================================
*/
SELECT a.au_id, au_fname, au_lname, SUM(qty * price / CountAuthor) AS Amount
FROM titles t
INNER JOIN sales s ON s.title_id = t.title_id
INNER JOIN titleauthor i ON i.title_id = t.title_id
INNER JOIN authors a ON a.au_id = i.au_id
INNER JOIN (SELECT title_id, COUNT(*) AS CountAuthor 
			FROM titleauthor 
			GROUP BY title_id) c ON c.title_id = t.title_id
GROUP BY a.au_id, au_fname, au_lname;


/* ========================================================
   2. شمارش تعداد عنوان‌ها برای هر کتاب
   این کوئری شمارش تعداد رکوردهای هر عنوان را از جدول `titles` و `titleauthor` محاسبه می‌کند.
   **INNER JOIN** برای ترکیب داده‌ها استفاده شده است.
   ==========================================================
*/
SELECT t.title_id, title, COUNT(*)
FROM titles t
INNER JOIN titleauthor a ON a.title_id = t.title_id
GROUP BY t.title_id, title;


/* ========================================================
   3. شمارش تعداد نویسندگان برای هر عنوان کتاب
   این کوئری تعداد نویسندگان هر عنوان را با استفاده از **Subquery** محاسبه می‌کند.
   **INNER JOIN** برای ترکیب داده‌ها از جداول `titles` و `titleauthor` استفاده شده است.
   ==========================================================
*/
SELECT t.title_id, title, CoAu
FROM titles t
INNER JOIN (SELECT title_id, COUNT(*) AS CoAu 
			FROM titleauthor 
			GROUP BY title_id) a ON a.title_id = t.title_id;


/* ========================================================
   4. شمارش تعداد عنوان‌های منتشر شده توسط هر نویسنده
   این کوئری تعداد عنوان‌ها را برای هر نویسنده شمارش می‌کند. 
   داده‌ها با استفاده از **INNER JOIN** از جداول `authors` و `titleauthor` ترکیب شده است.
   ==========================================================
*/
SELECT authors.au_id, au_fname, au_lname, COUNT(*) AS CountTitles
FROM authors
INNER JOIN titleauthor t ON t.au_id = authors.au_id
GROUP BY authors.au_id, au_fname, au_lname;


/* ========================================================
   5. شمارش تعداد عنوان‌های منتشر شده توسط هر نویسنده (با استفاده از Subquery)
   این کوئری تعداد عنوان‌ها را برای هر نویسنده شمارش می‌کند، اما در اینجا از یک **Subquery** برای محاسبه تعداد عنوان‌ها استفاده شده است.
   **INNER JOIN** برای ترکیب داده‌ها استفاده شده است.
   ==========================================================
*/
SELECT authors.au_id, au_fname, au_lname, CountTitles
FROM authors
INNER JOIN
    (SELECT au_id, COUNT(*) AS CountTitles
     FROM titleauthor 
     GROUP BY au_id) AS t ON t.au_id = authors.au_id;


/* ========================================================
   6. تغییر نام نوع کتاب (type) با استفاده از IIF
   این کوئری از تابع **IIF** برای تغییر مقادیر ستون `type` استفاده می‌کند. 
   اگر `type` برابر با `'mod_cook'` باشد، نام آن به `'modern cooking'` تغییر می‌کند؛ در غیر این صورت، مقدار اصلی `type` باقی می‌ماند.
   ==========================================================
*/
SELECT title_id, title, type, IIF(type = 'mod_cook', 'modern cooking', type)
FROM titles;




/*

	CASE Filed  WHEN Expr1 THEN Value1 
				WHEN Expr2 THEN Value2 
				WHEN Expr3 THEN Value3 
				.
				.
				.
						   ELSE Value
	END

	CASE WHEN  Condition1 THEN Value1 
		 WHEN  Condition2 THEN Value2 
		 WHEN  Condition3 THEN Value3 
						  ELSE Value
	END
*/




/* ========================================================
   7. تغییر نوع کتاب با استفاده از CASE
   این کوئری از **CASE** برای تغییر مقادیر در ستون `type` استفاده می‌کند. 
   اگر `type` برابر با `'mod_cook'` باشد، مقدار آن به `'modern cooking'` تغییر می‌کند، 
   اگر برابر با `'trad_cook'` باشد به `'traditional cooking'` تغییر می‌کند و در غیر این صورت، 
   مقدار اصلی `type` باقی می‌ماند.
   ==========================================================
*/
SELECT title_id, title, type, 
       CASE 
           WHEN type = 'mod_cook' THEN 'modern cooking'
           WHEN type = 'trad_cook' THEN 'traditional cooking'
           WHEN type = 'popular_comp' THEN 'popular computer'
           ELSE type
       END
FROM titles;


/* ========================================================
   8. محاسبه قیمت جدید با استفاده از IIF
   این کوئری از تابع **IIF** برای محاسبه قیمت جدید استفاده می‌کند. 
   اگر قیمت بیشتر از ۱۰ باشد، قیمت جدید ۱.۱ برابر با قیمت اصلی خواهد بود؛ 
   در غیر این صورت، قیمت جدید ۰.۹۹ برابر با قیمت اصلی خواهد بود.
   ==========================================================
*/
SELECT title_id, title, price, 
       IIF(price > 10, price * 1.1, price * 0.99) AS NewPrice
FROM titles;


/* ========================================================
   9. محاسبه قیمت جدید با استفاده از CASE
   این کوئری از **CASE** برای محاسبه قیمت جدید استفاده می‌کند. 
   اگر قیمت بیشتر از ۱۰ باشد، قیمت جدید ۱.۱ برابر با قیمت اصلی خواهد بود؛ 
   در غیر این صورت، قیمت جدید ۰.۹۹ برابر با قیمت اصلی خواهد بود.
   ==========================================================
*/
SELECT title_id, title, price, 
       CASE 
           WHEN price > 10 THEN price * 1.1
           ELSE price * 0.99
       END AS NewPrice
FROM titles;


/* ========================================================
   10. محاسبه قیمت جدید بر اساس ایالت ناشر
   این کوئری از **CASE** برای محاسبه قیمت جدید استفاده می‌کند. اگر ایالت ناشر `'CA'` باشد، قیمت ۱.۱ برابر می‌شود؛
   در غیر این صورت، قیمت ۰.۹۹ برابر می‌شود.
   **INNER JOIN** برای ترکیب داده‌ها از جداول `titles` و `publishers` استفاده شده است.
   ==========================================================
*/
SELECT title_id, title, price, 
       CASE 
           WHEN state = 'CA' THEN price * 1.1
           ELSE price * 0.99
       END AS NewPrice
FROM titles t
INNER JOIN publishers p ON p.pub_id = t.pub_id;


/* ========================================================
   11. محاسبه قیمت جدید بر اساس ایالت ناشر (با Subquery)
   این کوئری مشابه کوئری قبلی است اما از **Subquery** برای بررسی ایالت ناشر استفاده می‌کند. 
   اگر ناشر از ایالت `'CA'` باشد، قیمت ۱.۱ برابر می‌شود؛ در غیر این صورت، قیمت ۰.۹۹ برابر می‌شود.
   ==========================================================
*/
SELECT title_id, title, price, 
       CASE 
           WHEN pub_id IN (SELECT pub_id 
                            FROM publishers 
                            WHERE state = 'CA') THEN price * 1.1
           ELSE price * 0.99
       END AS NewPrice
FROM titles t;


/* ========================================================
   12. محاسبه قیمت جدید بر اساس تعداد نویسندگان
   این کوئری از **CASE** برای تغییر قیمت هر عنوان بر اساس تعداد نویسندگان استفاده می‌کند. 
   اگر تعداد نویسندگان بیشتر از ۱ باشد، قیمت ۱.۱ برابر می‌شود؛ در غیر این صورت، قیمت ۰.۹۹ برابر می‌شود.
   **INNER JOIN** برای ترکیب داده‌ها از جداول `titles` و `titleauthor` استفاده شده است.
   ==========================================================
*/
SELECT t.title_id, title, 
       CASE 
           WHEN COUNT(*) > 1 THEN price * 1.1
           ELSE price * 0.99
       END AS NewPrice
FROM titles t
INNER JOIN titleauthor ON titleauthor.title_id = t.title_id
GROUP BY t.title_id, title, price;


/* ========================================================
   13. محاسبه قیمت جدید بر اساس تعداد نویسندگان برای هر عنوان
   این کوئری مشابه کوئری قبلی است اما در اینجا از یک **Subquery** برای بررسی تعداد نویسندگان هر عنوان استفاده می‌کند. 
   اگر تعداد نویسندگان بیشتر از ۱ باشد، قیمت ۱.۱ برابر می‌شود؛ در غیر این صورت، قیمت ۰.۹۹ برابر می‌شود.
   ==========================================================
*/
SELECT title_id, title, 
       CASE 
           WHEN title_id IN (SELECT title_id
                             FROM titleauthor 
                             GROUP BY title_id
                             HAVING COUNT(*) > 1) THEN price * 1.1
           ELSE price * 0.99
       END AS NewPrice
FROM titles;


/* ========================================================
   14. محاسبه قیمت جدید بر اساس مجموع فروش
   این کوئری از **CASE** برای تغییر قیمت هر عنوان بر اساس مجموع فروش‌ها استفاده می‌کند.
   اگر مجموع فروش‌ها بیشتر از ۵۰۰ باشد، قیمت ۱.۱ برابر می‌شود؛ در غیر این صورت، قیمت ۰.۹۹ برابر می‌شود.
   **INNER JOIN** برای ترکیب داده‌ها از جداول `titles` و `sales` استفاده شده است.
   ==========================================================
*/
SELECT t.title_id, title, 
       CASE 
           WHEN SUM(qty * price) > 500 THEN price * 1.1
           ELSE price * 0.99
       END AS NewPrice
FROM titles t
INNER JOIN sales s ON s.title_id = t.title_id
GROUP BY t.title_id, title, price;


/* ========================================================
   15. محاسبه قیمت جدید بر اساس مجموع فروش در جدول sales
   این کوئری از **Subquery** و **CASE** برای تغییر قیمت هر عنوان کتاب استفاده می‌کند. 
   اگر مجموع فروش‌ها (مجموع qty * قیمت) برای هر عنوان کتاب بیشتر از ۵۰۰ باشد، قیمت ۱.۱ برابر می‌شود؛
   در غیر این صورت، قیمت ۰.۹۹ برابر خواهد بود.
   **Subquery** برای محاسبه مجموع فروش‌ها برای هر عنوان کتاب از جدول `sales` استفاده می‌شود.
   ==========================================================
*/
SELECT title_id, title, 
       CASE 
           WHEN title_id IN (SELECT title_id 
                             FROM sales 
                             GROUP BY title_id 
                             HAVING SUM(qty) * price > 500) THEN price * 1.1
           ELSE price * 0.99
       END AS NewPrice
FROM titles;


/* ========================================================
   16. محاسبه مجموع فروش برای هر عنوان کتاب
   این کوئری مجموع فروش‌ها برای هر عنوان کتاب را محاسبه می‌کند. 
   از **INNER JOIN** برای ترکیب داده‌ها از جداول `titles` و `sales` استفاده شده است.
   نتیجه به صورت مجموع `qty * price` برای هر عنوان کتاب نمایش داده می‌شود.
   ==========================================================
*/
SELECT t.title_id, title, SUM(qty * price) AS Amount
FROM titles t
INNER JOIN sales s ON s.title_id = t.title_id
GROUP BY t.title_id, title;




/*

	      Amount < 200			-> 0
	200 < Amount < 500			-> 10
	500 < Amount < 800			-> 15
	800 < Amount < 1000			-> 20
		  Amount > 1000			-> 25


*/




/* ========================================================
   17. محاسبه مالیات بر اساس مجموع فروش
   این کوئری مالیات را بر اساس مجموع فروش‌ها محاسبه می‌کند. 
   در اینجا، مالیات به صورت مقیاس بندی شده محاسبه می‌شود. برای هر بازه از فروش‌ها یک درصد متفاوت اعمال می‌شود.
   اگر مجموع فروش‌ها کمتر از ۲۰۰ باشد، مالیات صفر است؛ 
   اگر بین ۲۰۰ تا ۵۰۰ باشد، مالیات به درصد ۱۰ درصد اعمال می‌شود و به همین ترتیب برای مقادیر بیشتر.
   **INNER JOIN** برای ترکیب داده‌ها از جداول `titles` و `sales` استفاده شده است.
   ==========================================================
*/
SELECT t.title_id, title, SUM(qty * price) AS Amount, 
       CASE 
           WHEN SUM(qty * price) < 200 THEN 0
           WHEN SUM(qty * price) < 500 THEN 0 + (SUM(qty * price) - 200) * 0.10
           WHEN SUM(qty * price) < 800 THEN 0 + 30 + (SUM(qty * price) - 500) * 0.15
           WHEN SUM(qty * price) < 1000 THEN 0 + 30 + 45 + (SUM(qty * price) - 800) * 0.20
           ELSE 0 + 30 + 45 + 40 + (SUM(qty * price) - 1000) * 0.25
       END AS Tax
FROM titles t
INNER JOIN sales s ON s.title_id = t.title_id
GROUP BY t.title_id, title;


/* ========================================================
   18. محاسبه مالیات بر اساس میزان فروش
   این کوئری مشابه کوئری قبلی است، اما در اینجا از یک **Subquery** برای محاسبه مقدار فروش (Amount) استفاده می‌شود.
   مالیات به صورت مقیاس بندی شده محاسبه می‌شود که بر اساس مقدار فروش برای هر عنوان کتاب یک درصد مالیات متفاوت اعمال می‌شود.
   ==========================================================
*/
SELECT *, 
       CASE 
           WHEN Amount < 200 THEN 0
           WHEN Amount < 500 THEN (Amount - 200) * 0.10
           WHEN Amount < 800 THEN 30 + (Amount - 500) * 0.15
           WHEN Amount < 1000 THEN 75 + (Amount - 800) * 0.20
           ELSE 115 + (Amount - 1000) * 0.25
       END AS Tax
FROM 
    (SELECT t.title_id, title, SUM(qty * price) AS Amount
     FROM titles t 
     INNER JOIN sales s ON s.title_id = t.title_id
     GROUP BY t.title_id, title) AS DQ;


/* ========================================================
   19. انتخاب ناشرانی که کتابی ندارند
   این کوئری **LEFT JOIN** را برای پیدا کردن ناشرانی که هیچ کتابی در جدول `titles` ندارند، استفاده می‌کند.
   اگر در جدول `titles` هیچ رکوردی برای `title_id` آن‌ها موجود نباشد، این ناشران نمایش داده می‌شوند.
   ==========================================================
*/
SELECT p.*
FROM publishers p
LEFT JOIN titles t ON t.pub_id = p.pub_id
WHERE title_id IS NULL;


/* ========================================================
   20. انتخاب ناشرانی که هیچ کتابی ندارند با استفاده از Subquery
   این کوئری از **Subquery** برای پیدا کردن ناشرانی که در جدول `titles` کتابی ندارند استفاده می‌کند. 
   اگر ناشر در جدول `titles` حضور نداشته باشد، نمایش داده می‌شود.
   ==========================================================
*/
SELECT *
FROM publishers
WHERE pub_id NOT IN (SELECT pub_id 
					 FROM titles);


/* ========================================================
   21. انتخاب ناشرانی که هیچ کتابی ندارند با استفاده از EXISTS
   این کوئری از دستور **NOT EXISTS** استفاده می‌کند تا ناشرانی را نمایش دهد که هیچ کتابی در جدول `titles` ندارند.
   در اینجا، از **NOT EXISTS** برای بررسی وجود رکوردهایی در جدول `titles` برای هر ناشر استفاده شده است.
   ==========================================================
*/
SELECT *
FROM publishers
WHERE NOT EXISTS (SELECT * 
				  FROM titles 
				  WHERE titles.pub_id = publishers.pub_id);


----------------------------------------------------------------------
----------------------------------------------------------------------



-- استفاده از دیتابیس 'pubs'
USE T_pubs;
GO

-- حذف جدول‌ها در صورتی که قبلاً وجود داشته باشند
DROP TABLE IF EXISTS StudentLesson;
GO

DROP TABLE IF EXISTS Lesson;
GO

DROP TABLE IF EXISTS Student;
GO

-- ایجاد جدول دانش‌آموزان
CREATE TABLE Student (
    StudentID INT PRIMARY KEY IDENTITY,             -- شناسه یکتا برای هر دانش‌آموز
    StudentFirstname NVARCHAR(20),                  -- نام کوچک دانش‌آموز
    StudentLastname NVARCHAR(20)                    -- نام خانوادگی دانش‌آموز
);
GO

-- ایجاد جدول درس‌ها
CREATE TABLE Lesson (
    LessonID INT PRIMARY KEY,                       -- شناسه یکتا برای هر درس
    LessonTitle NVARCHAR(50),                       -- عنوان درس
    LessonUnit TINYINT,                             -- تعداد واحدهای درس
    RequiredLessonID INT FOREIGN KEY REFERENCES Lesson(LessonID) -- پیش‌نیاز درس
);
GO

-- ایجاد جدول ارتباط بین دانش‌آموز و درس
CREATE TABLE StudentLesson (
    StudentLessonID INT PRIMARY KEY IDENTITY,       -- شناسه یکتا برای هر انتخاب واحد
    StudentID INT FOREIGN KEY REFERENCES Student(StudentID), -- دانش‌آموز مربوطه
    LessonID INT FOREIGN KEY REFERENCES Lesson(LessonID)      -- درس مربوطه
);
GO

-- درج داده‌های نمونه در جدول دانش‌آموزان
INSERT INTO Student (StudentFirstname, StudentLastname) VALUES
    ('Ali', 'Alavi'),
    ('Taghi', 'Taghavi'),
    ('Naghi', 'Naghavi'),
    ('Kati', 'Katayouni');
GO

-- درج داده‌های نمونه در جدول درس‌ها
INSERT INTO Lesson (LessonID, LessonTitle, LessonUnit, RequiredLessonID) VALUES
    (1, 'Mathematics1', 2, NULL),
    (2, 'Physics', 2, NULL),
    (3, 'Programming1', 3, NULL),
    (4, 'DataStructure', 3, 3),
    (5, 'Mathematics2', 2, 1),
    (6, 'Database', 3, 4),
    (7, 'Data Science', 2, 6),
    (8, 'Database Administrator', 3, 7),
    (9, 'Engineering Mathematics', 2, 5);
GO

-- درج داده‌های نمونه در جدول ارتباطی بین دانش‌آموز و درس
INSERT INTO StudentLesson (StudentID, LessonID) VALUES
    (1, 1), (1, 2), (1, 3), (1, 4), (1, 5),
    (1, 6), (1, 7), (1, 8), (1, 9),
    (2, 3), (2, 4), (2, 6), (2, 8),
    (3, 3), (3, 4), (3, 5), (3, 6), (3, 7),
    (4, 3), (4, 4), (4, 6), (4, 8);
GO

-- نمایش تمام رکوردها از جدول دانش‌آموزان
SELECT * FROM Student;

-- نمایش تمام رکوردها از جدول درس‌ها
SELECT * FROM Lesson;

-- نمایش تمام رکوردها از جدول انتخاب واحد دانش‌آموزان
SELECT * FROM StudentLesson;

-- نمایش نام، نام خانوادگی و درس‌های انتخاب شده توسط هر دانش‌آموز
SELECT 
    s.StudentID, 
    s.StudentFirstname, 
    s.StudentLastname, 
    l.LessonTitle
FROM 
    Student s
INNER JOIN 
    StudentLesson sl ON sl.StudentID = s.StudentID
INNER JOIN 
    Lesson l ON l.LessonID = sl.LessonID;
 


 /* ===================================================================
   🎯 صورت سوال:
   نمایش نام و نام خانوادگی تمام دانشجویانی که تمام دروس موجود 
   در جدول Lesson را اخذ کرده‌اند.

   ✅ نکته: برای این کار از تکنیک NOT EXISTS تو در تو استفاده می‌کنیم 
   که از نظر پرفورمنس یکی از بهترین روش‌ها برای این نوع کوئری‌هاست.
=================================================================== */

/* ===================================================================
   🧠 راه‌حل:
   ابتدا بررسی می‌کنیم که آیا برای دانشجوی موردنظر درسی وجود دارد 
   که او آن را انتخاب نکرده باشد؟ اگر چنین درسی وجود نداشته باشد، 
   یعنی آن دانشجو تمام دروس را انتخاب کرده است.
=================================================================== */

SELECT 
    s.StudentID, 
    s.StudentFirstname, 
    s.StudentLastname
FROM 
    Student s
WHERE 
    NOT EXISTS (  -- بررسی اینکه درسی وجود نداشته باشد که توسط دانشجو انتخاب نشده باشد
        SELECT *
        FROM Lesson l
        WHERE NOT EXISTS (  -- اگر برای این درس، رکوردی در جدول StudentLesson برای دانشجو نباشد
            SELECT *
            FROM StudentLesson sl
            WHERE sl.StudentID = s.StudentID
              AND sl.LessonID = l.LessonID
        )
    );



/* ========================================================
   ❓ صورت سؤال:
   نمایش تمام دانشجویانی که *تمام دروس سه واحدی* (LessonUnit = 3) را انتخاب کرده‌اند.
   در این سؤال فقط دروسی مد نظر هستند که تعداد واحد آن‌ها برابر با 3 است.
   یعنی اگر حتی یک درس سه واحدی را انتخاب نکرده باشند، نباید در نتایج نمایش داده شوند.

=================================================================== */

/* ===================================================================

   ✅ راه حل:
   با استفاده از `NOT EXISTS` تو در تو، بررسی می‌کنیم که آیا دانشجویی وجود دارد که
   هیچ کدام از دروس سه واحدی را جا نینداخته باشد یا خیر.
   اگر چنین درسی وجود نداشته باشد → یعنی همه دروس 3 واحدی را انتخاب کرده است.
======================================================== */

SELECT s.StudentID, s.StudentFirstname, s.StudentLastname
FROM Student s
WHERE NOT EXISTS (
    SELECT *
    FROM Lesson l
    WHERE l.LessonUnit = 3
      AND NOT EXISTS (
          SELECT *
          FROM StudentLesson sl
          WHERE sl.StudentID = s.StudentID
            AND sl.LessonID = l.LessonID
      )
);
