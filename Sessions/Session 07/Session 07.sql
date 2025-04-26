

/*
    ==========================================================
    جلسه ۷: دستورات DDL، CONSTRAINT ها و JOIN ها
    ==========================================================
    
    در این جلسه با دستورات **DDL** و **CONSTRAINT** ها برای مدیریت ساختار و محدودیت‌های داده‌ها آشنا می‌شویم. همچنین دستورات **JOIN** برای ترکیب داده‌ها از جداول مختلف بررسی می‌شود.
    
    این مثال‌ها از دیتابیس‌های **University** و **pubs** گرفته شده است که شامل جداول `Student`, `titles`, `publishers`, `sales`, و `authors` است.

    مفاهیم یادگیری شده:
    1. **SELECT** - انتخاب داده‌ها
    2. **LEN** - محاسبه طول رشته‌ها
    3. **ALTER TABLE** - تغییر ساختار جدول
    4. **CONSTRAINT** - اعمال محدودیت‌ها
    5. **INNER JOIN** - ترکیب داده‌ها از دو جدول
    6. **LEFT JOIN** - ترکیب داده‌ها با اولویت به جدول اول
    7. **WHERE** - فیلتر کردن داده‌ها
    ==========================================================
*/


/* ========================================================
   1. انتخاب تمام داده‌ها از جدول Student همراه با طول رشته StudentNational
   ========================================================== */

SELECT *, LEN(StudentNational)
	FROM Student;


/* ========================================================
   2. اضافه کردن محدودیت (Constraint) برای بررسی طول رشته StudentNational
   ========================================================== */

ALTER TABLE Student
ADD CONSTRAINT chNationalID CHECK (LEN(StudentNational) = 10);



/* ========================================================
   3. انتخاب داده‌ها از جدول titles با ستون‌های title_id، title و pub_id
   ========================================================== */

SELECT title_id, title, pub_id
	FROM titles;


/* ========================================================
   4. انتخاب داده‌ها از جدول publishers با ستون‌های pub_id و pub_name
   ========================================================== */

SELECT pub_id, pub_name
	FROM publishers;


/* ========================================================
   5. استفاده از INNER JOIN برای ترکیب داده‌ها از جداول titles و publishers
   ========================================================== */

SELECT title_id, title, publishers.pub_id, pub_name
	FROM titles
	INNER JOIN publishers ON titles.pub_id = publishers.pub_id;


/* ========================================================
   6. استفاده از INNER JOIN برای ترکیب داده‌ها از جداول sales و titles
   ========================================================== */

SELECT sales.*, title
	FROM sales
	INNER JOIN titles ON titles.title_id = sales.title_id;


/* ========================================================
   7. استفاده از LEFT JOIN برای ترکیب داده‌ها از جداول titles و sales
   ========================================================== */

SELECT sales.*, title
	FROM titles
	LEFT JOIN sales ON sales.title_id = titles.title_id;


/* ========================================================
   8. استفاده از LEFT JOIN برای ترکیب داده‌ها از جداول publishers و titles
   ========================================================== */

SELECT *
	FROM publishers
	LEFT JOIN titles ON titles.pub_id = publishers.pub_id;


/* ========================================================
   9. انتخاب فقط رکوردهایی از publishers که داده‌ای در جدول titles ندارند
   ========================================================== */

SELECT publishers.*
	FROM publishers
	LEFT JOIN titles ON titles.pub_id = publishers.pub_id
	WHERE title_id IS NULL



/* ========================================================
   10. انتخاب داده‌ها از جدول titles با ستون‌های title_id و title
   ========================================================== */

SELECT title_id, title
	FROM titles


/* ========================================================
   11. انتخاب داده‌ها از جدول authors با ستون‌های au_id، au_fname و au_lname
   ========================================================== */

SELECT au_id, au_fname, au_lname
	FROM authors


/* ========================================================
   12. استفاده از INNER JOIN برای ترکیب داده‌ها از جداول publishers، titles و sales
  ========================================================== */
  
SELECT ord_num, ord_date, t.title_id, title, price, qty, p.pub_id, pub_name
	FROM publishers AS p INNER JOIN 
		 titles		AS t ON t.pub_id = p.pub_id	INNER JOIN 
		 sales		AS s ON s.title_id = t.title_id


/* ========================================================
   13. استفاده از INNER JOIN برای ترکیب داده‌ها از جداول titles، titleauthor و authors
   ==========================================================
   این کوئری داده‌ها را از جداول `titles`، `titleauthor` و `authors` ترکیب می‌کند.
*/
SELECT t.title_id, title, a.au_id, au_fname, au_lname
	FROM titles			t INNER JOIN 
		 titleauthor	i ON i.title_id = t.title_id INNER JOIN 
		 authors a ON a.au_id = i.au_id;


/* ========================================================
   14. استفاده از RIGHT JOIN برای ترکیب داده‌ها از جداول titles، titleauthor و authors
  ========================================================== */
  
SELECT c.au_lname, a.title 
	FROM titles			AS a RIGHT JOIN 
		 titleauthor	AS b ON a.title_id = b.title_id RIGHT JOIN 
		 authors		AS c ON b.au_id = c.au_id
	WHERE title IS NULL;


/* ========================================================
   15. انتخاب داده‌ها از جدول authors که داده‌ای در جدول titleauthor ندارند
  ========================================================== */
  
SELECT a.*
	FROM authors a LEFT JOIN 
		 titleauthor t ON t.au_id = a.au_id
	WHERE title_id IS NULL;


/* ========================================================
   16. انتخاب داده‌ها از جدول titles که داده‌ای در جدول titleauthor ندارند
    ========================================================== */
  
SELECT t.*
	FROM titles t LEFT JOIN 
		 titleauthor a ON a.title_id = t.title_id
	WHERE au_id IS NULL;



/*

	SELECT DISTINCT TOP N PERCENT * 
		FROM Table_A INNER JOIN 
			 Table_B ON Key_A = Key_B
		WHERE Condition 
		ORDER BY f DESC

*/


/* ========================================================
   17. انتخاب داده‌ها از جداول titles و sales با محاسبه مبلغ (Amount) برای نوع 'business'
    ========================================================== */
  
SELECT t.title_id, title, type, price, qty, price * qty AS Amount
	FROM titles t INNER JOIN 
		 sales  s ON s.title_id = t.title_id
	WHERE type = 'business'
	ORDER BY t.title_id;


/* ========================================================
   18. انتخاب داده‌ها از جداول titles و sales با محاسبه مبلغ (Amount) برای نوع 'business' و ترتیب نزولی بر اساس Amount
    ========================================================== */
  
SELECT t.title_id, title, type, price, qty, price * qty AS Amount
	FROM titles t INNER JOIN 
		 sales  s ON s.title_id = t.title_id
	WHERE type = 'business'
	ORDER BY Amount DESC;


/* ========================================================
   19. انتخاب داده‌ها از جداول titles و sales با محاسبه مبلغ (Amount) برای رکوردهایی که مبلغ بیشتر از ۳۰۰ دارند
    ========================================================== */
  
SELECT t.title_id, title, type, price, qty, price * qty AS Amount
	FROM titles t INNER JOIN 
		 sales  s ON s.title_id = t.title_id
	WHERE price * qty > 300
	ORDER BY Amount DESC;
