

/* ============================================================
   🧾 جلسه ۱۳: بررسی عمیق دستورات DML (INSERT, UPDATE, DELETE, MERGE)
   ============================================================

   🎯 این جلسه به بررسی و تمرین پیشرفته دستورات DML در SQL Server اختصاص دارد.
   در این جلسه با نحوه‌ی درج، به‌روزرسانی، حذف، و ادغام داده‌ها در جداول آشنا می‌شویم.

   📌 سرفصل‌های مهم این جلسه:
   1. استفاده از INSERT به همراه OUTPUT برای مشاهده مقادیر درج‌شده
   2. بررسی روش‌های مختلف برای بازیابی آخرین مقدار درج‌شده (IDENTITY)
   3. به‌روزرسانی شرطی با استفاده از CASE و SUBQUERY
   4. خروجی گرفتن از تغییرات قبل و بعد از UPDATE
   5. حذف شرطی با استفاده از JOIN و CTE
   6. استفاده از MERGE برای همگام‌سازی جداول با امکانات کامل INSERT / UPDATE / DELETE
   7. تولید داده‌ی نمونه با استفاده از `SELECT INTO` و `ORDER BY NEWID()`
   8. ایجاد جداول موقتی و استفاده از آن‌ها در عملیات DML

   🗂 دیتابیس‌های مورد استفاده:
   - `pubs`
   - `AdventureWorks2022`

   📈 هدف کلی:
   تسلط بیشتر بر عملکرد دستورات DML و بهینه‌سازی آن‌ها از نظر کاربرد، ساختار و پرفورمنس.
   ============================================================
*/



-----------------------------------------------------------------



USE pubs
GO 



-----------------------------------------------------------------



/* ============================================================
   1. 🎯 ایجاد و درج داده در جدول TitleAmount با استفاده از ROW_NUMBER
   ============================================================

   📌 ابتدا جدول TitleAmount با استفاده از دستور `SELECT INTO` ساخته می‌شود و داده‌هایی شامل شناسه (Id)، عنوان کتاب، نوع کتاب و مبلغ فروش (Amount) را با استفاده از `ROW_NUMBER` مرتب می‌کند.
   📥 سپس از `INSERT INTO ... SELECT` برای درج داده‌های جدید به صورت کامل و یا فقط ۱۰ رکورد اول استفاده شده است.
*/

-- ساخت جدول و درج داده اولیه بر اساس فروش هر عنوان
DROP TABLE IF EXISTS TitleAmount;

SELECT 
    ROW_NUMBER() OVER (ORDER BY SUM(qty * price) DESC) AS Id,
    t.title_id, 
    title, 
    type, 
    SUM(qty * price) AS Amount
INTO TitleAmount
FROM titles t
INNER JOIN sales s ON s.title_id = t.title_id
GROUP BY t.title_id, title, type;



-- درج مجدد کل داده‌ها در جدول ساخته‌شده (تکراری اگر حذف نشده باشد)
INSERT INTO TitleAmount
SELECT 
    ROW_NUMBER() OVER (ORDER BY SUM(qty * price) DESC) AS Id,
    t.title_id, 
    title, 
    type, 
    SUM(qty * price) AS Amount
FROM titles t
INNER JOIN sales s ON s.title_id = t.title_id
GROUP BY t.title_id, title, type;



-- درج فقط ۱۰ عنوان اول با بیشترین فروش
INSERT INTO TitleAmount
SELECT TOP 10 
    ROW_NUMBER() OVER (ORDER BY SUM(qty * price) DESC) AS Id,
    t.title_id, 
    title, 
    type, 
    SUM(qty * price) AS Amount
FROM titles t
INNER JOIN sales s ON s.title_id = t.title_id
GROUP BY t.title_id, title, type;

-- 📊 نکات پرفورمنسی:
-- - استفاده از `ROW_NUMBER()` کمک می‌کند تا داده‌ها مرتب‌سازی شوند و به سادگی بتوان رکورد خاصی (مثلاً Top 10) را مدیریت کرد.
-- - برای جلوگیری از درج رکوردهای تکراری باید قبل از `INSERT` بررسی انجام شود یا از `NOT EXISTS` یا `EXCEPT` استفاده شود.



/*

UPDATE Table SET F1 = Expr1 , ... 
OUTPUT inseryed.* , deleted.*
WHERE Condition

*/



/* ============================================================
   2. 🛠️ به‌روزرسانی داده‌ها در جدول titles
   ============================================================

   📌 این کوئری‌ها انواع مختلف دستورات `UPDATE` را نشان می‌دهند، از ساده‌ترین حالت تا استفاده از `OUTPUT` برای نمایش مقدار قبلی و جدید ستون‌ها.
   📤 دستور `OUTPUT` در SQL Server بسیار مفید است برای بررسی تغییرات انجام‌شده روی داده‌ها در هنگام اجرای دستورات DML.

*/


-- تغییر قیمت به ۱۵ برای عنوان خاص
UPDATE titles 
SET price = 15
WHERE title_id = 'BU1032';



-- افزایش ۱۰٪ قیمت برای کتاب‌های نوع 'business'
UPDATE titles 
SET price = price * 1.1 
WHERE type = 'business';



-- افزایش ۱۰٪ قیمت برای کتاب‌هایی که قیمتشان بیشتر از ۱۰ است
UPDATE titles 
SET price = price * 1.1 
WHERE price > 10;



-- افزایش ۱۰٪ برای نوع 'business' با نمایش قیمت قبل و بعد از تغییر
UPDATE titles 
SET price = price * 1.1 
OUTPUT 
    deleted.title_id, 
    deleted.title, 
    deleted.price AS OldPrice, 
    inserted.price AS NewPrice
WHERE type = 'business';

-- 📊 نکات پرفورمنسی:
-- - به‌روزرسانی داده‌ها روی ستون‌های زیاد یا بدون ایندکس می‌تواند منجر به استفاده بیشتر از منابع شود.
-- - دستور `OUTPUT` اطلاعات مفیدی برای بررسی عملیات بدون نیاز به اجرای SELECT مجدد فراهم می‌کند.
-- - دقت شود که در عملیات سنگین از تراکنش‌ها (TRANSACTION) برای اطمینان از کامل بودن عملیات استفاده گردد.



/* ============================================================
   3. 🎯 به‌روزرسانی مشروط قیمت کتاب‌ها با CASE
   ============================================================

   🧠 این مجموعه کوئری‌ها از عبارت شرطی `CASE` در دستور `UPDATE` استفاده می‌کند تا بر اساس شرایط خاص، قیمت کتاب‌ها را به‌روزرسانی کند.
   🧾 در بعضی کوئری‌ها، از `OUTPUT` برای نمایش مقادیر قبل و بعد از تغییر استفاده شده است.

*/

-- افزایش ۱۰٪ قیمت برای کتاب‌هایی با قیمت بیش از ۱۰، و کاهش ۱٪ برای بقیه
UPDATE titles 
SET price = CASE 
              WHEN price > 10 THEN price * 1.1 
              ELSE price * 0.99 
           END
OUTPUT 
    deleted.title_id, 
    deleted.title, 
    deleted.price AS OldPrice, 
    inserted.price AS NewPrice;



-- شرط بر اساس ناشرانی که در ایالت CA هستند
UPDATE titles 
SET price = CASE 
              WHEN pub_id IN (
                  SELECT pub_id FROM publishers WHERE state = 'CA'
              ) THEN price * 1.1 
              ELSE price * 0.99 
           END;



-- همان شرط قبلی ولی با استفاده از JOIN برای خوانایی بهتر
UPDATE titles 
SET price = CASE 
              WHEN state = 'CA' THEN price * 1.1 
              ELSE price * 0.99 
           END
FROM titles 
INNER JOIN publishers ON publishers.pub_id = titles.pub_id;



-- افزایش قیمت برای کتاب‌هایی که بیش از یک نویسنده دارند
UPDATE titles 
SET price = CASE 
              WHEN title_id IN (
                  SELECT title_id 
                  FROM titleauthor 
                  GROUP BY title_id 
                  HAVING COUNT(*) > 1
              ) THEN price * 1.1 
              ELSE price * 0.99 
           END;



-- نسخه بهینه‌تر با استفاده از زیر‌کوئری به عنوان جدول موقتی (derived table)
UPDATE titles 
SET price = CASE 
              WHEN CoAu > 1 THEN price * 1.1 
              ELSE price * 0.99 
           END
FROM titles 
INNER JOIN (
    SELECT title_id, COUNT(*) AS CoAu
    FROM titleauthor 
    GROUP BY title_id
) AS titleauthor ON titleauthor.title_id = titles.title_id;



-- افزایش قیمت برای کتاب‌هایی که مجموع فروششان بیشتر از ۵۰۰ شده
UPDATE titles 
SET price = CASE 
              WHEN title_id IN (
                  SELECT s.title_id 
                  FROM sales s 
                  GROUP BY title_id 
                  HAVING SUM(qty) * price > 500
              ) THEN price * 1.1 
              ELSE price * 0.99 
           END;

-- 📌 نکات پرفورمنسی:
-- - شرط‌های تو در تو می‌توانند باعث کاهش کارایی شوند اگر اندیس‌ها بهینه نباشند.
-- - استفاده از `JOIN` یا `CTE` برای محاسبه شرط‌ها معمولاً خواناتر و در مواقعی سریع‌تر است.
-- - دستور `OUTPUT` همچنان ابزاری بسیار مفید برای بررسی تأثیر تغییرات است.



/* ============================================================
   4. 📦 به‌روزرسانی قیمت بر اساس حجم فروش با استفاده از CTE
   ============================================================

   🎯 این کوئری از CTE (عبارت WITH) برای محاسبه مجموع فروش هر کتاب استفاده می‌کند.
   🔁 سپس با استفاده از `JOIN`، قیمت کتاب‌ها را بر اساس شرط حجم فروش به‌روزرسانی می‌کند.
   🧾 همچنین از دستور `OUTPUT` برای مقایسه مقادیر قبل و بعد از بروزرسانی استفاده شده است.
*/

;WITH cte AS (
    SELECT title_id, SUM(qty) AS Qty
    FROM sales 
    GROUP BY title_id
)

UPDATE titles 
SET price = CASE 
              WHEN Qty * price > 500 THEN price * 1.1 
              ELSE price * 0.99 
           END
OUTPUT 
    deleted.title_id, 
    deleted.title, 
    deleted.price AS OldPrice, 
    inserted.price AS NewPrice
FROM titles 
INNER JOIN cte ON cte.title_id = titles.title_id;

-- 🧠 استفاده از CTE باعث افزایش خوانایی و نگهداری بهتر کوئری شده است.
-- ⚙️ این روش برای دیتاست‌های بزرگ، کارایی بالاتری نسبت به زیرکوئری‌های تو در تو دارد.
-- 📊 خروجی `OUTPUT` برای بررسی صحت به‌روزرسانی بسیار مفید است.



------------------------------------------------------------------------------------



/* ============================================================
   5. 🗑️ حذف رکورد خاص از جدول TitleAmount
   ============================================================

   🎯 در این کوئری، رکوردی با شناسه (Id) مشخص از جدول `TitleAmount` حذف می‌شود.
   📌 این نوع حذف زمانی استفاده می‌شود که بخواهیم یک رکورد خاص و شناخته‌شده را حذف کنیم.
*/

DELETE TitleAmount 
WHERE Id = 16;

-- 📋 بررسی محتویات جدول بعد از حذف برای اطمینان از صحت عملیات:
SELECT * 
FROM TitleAmount;

-- ⚠️ این نوع حذف مستقیم برای حذف رکوردهای خاص مؤثر است،
-- اما برای حذف‌های پیچیده‌تر بهتر است از JOIN یا CTE استفاده شود.



------------------------------------------------------------------------------------



/* ============================================================
   6. 🧹 حذف مشاغلی که در جدول jobs وجود دارند ولی مجدداً تأیید نمی‌شوند
   ============================================================

   🎯 این کوئری به ظاهر هدفی ندارد چون شرطی که بررسی می‌کند همیشه نتیجه‌ای خالی برمی‌گرداند!
   ❌ `job_id NOT IN (SELECT job_id FROM jobs)` همیشه FALSE است چون همه job_idها در خود جدول هستند.
   🛠️ اگر قصد بررسی با یک جدول مرجع دیگر باشد، باید آن جدول در شرط جایگزین شود.
*/

DELETE 
	jobs
OUTPUT deleted.*	
WHERE job_id NOT IN (SELECT job_id FROM jobs); -- ❌ این شرط همیشه FALSE خواهد بود

-- 🧪 بهتر است در این حالت از JOIN با جدول دیگر استفاده شود تا رکوردهای ناهمسان حذف شوند.



/* ============================================================
   7. 🧑‍💼 حذف مشاغلی که هیچ کارمندی با آن‌ها مرتبط نیست
   ============================================================

   🎯 این کوئری مشاغلی را از جدول `jobs` حذف می‌کند که هیچ کارمندی در جدول `employee` به آن‌ها وابسته نیست.
   🔗 با استفاده از LEFT JOIN و شرط `emp_id IS NULL`، رکوردهایی که در جدول employee وجود ندارند، شناسایی و حذف می‌شوند.
*/

DELETE jobs
OUTPUT deleted.*
FROM jobs LEFT JOIN 
	employee ON employee.job_id = jobs.job_id
WHERE emp_id IS NULL;

-- 📊 این روش کاربردی برای پاکسازی داده‌های بدون استفاده در سیستم‌هایی با روابط کلیدی است.
-- 💡 استفاده از `LEFT JOIN` برای شناسایی داده‌های orphan بسیار مؤثر و پرفورمنس مناسبه.



------------------------------------------------------------------------------------



/* ============================================================
   8. ❌ حذف کتاب‌هایی که بیش از یک نویسنده دارند
   ============================================================

   🎯 این کوئری عنوان‌هایی از جدول `titles` را حذف می‌کند که بیش از یک نویسنده دارند.
   🔍 از ساب‌کوئری در شرط `IN` استفاده شده که `title_id`هایی را برمی‌گرداند که در جدول `titleauthor` بیش از یک بار تکرار شده‌اند.
*/

DELETE titles 
WHERE title_id IN (
	SELECT title_id 
	FROM titleauthor 
	GROUP BY title_id 
	HAVING COUNT(*) > 1
);

-- 🧹 مفید برای پاک‌سازی داده‌های تکراری یا پیچیده.
-- ⚠️ اگر کلیدهای خارجی (foreign key) مرتبط با `title_id` در دیگر جداول وجود داشته باشند، ممکن است نیاز به حذف ترتیبی یا غیرفعال کردن موقت محدودیت‌ها باشد.



------------------------------------------------------------------------------------



/* ============================================================
   9. 🧼 حذف عنوان‌هایی با بیش از یک نویسنده با استفاده از CTE
   ============================================================

   🎯 این کوئری از CTE برای محاسبه تعداد نویسندگان هر عنوان استفاده می‌کند و سپس عنوان‌هایی را که بیش از یک نویسنده دارند حذف می‌کند.
   🧠 استفاده از `INNER JOIN` بین `titles` و خروجی `cte` باعث افزایش خوانایی و مدیریت بهتر شرایط پیچیده می‌شود.
*/

;WITH cte AS (
	SELECT title_id, COUNT(*) AS CoAu
	FROM titleauthor
	GROUP BY title_id
)

DELETE titles
FROM titles 
INNER JOIN cte ON cte.title_id = titles.title_id;

-- ✅ این روش نسبت به `IN` در مواردی که زیرکوئری سنگین است، عملکرد بهتری دارد.
-- 📌 بهتر است قبل از اجرای این نوع حذف‌ها، بررسی کامل روابط کلید خارجی انجام شود.



------------------------------------------------------------------------------------



/* ============================================================
   10. 🔄 حذف رکوردهای مرتبط در چند جدول با رعایت وابستگی‌ها
   ============================================================

   🎯 این مجموعه کوئری‌ها برای حذف عنوان‌هایی که بیش از یک نویسنده دارند استفاده می‌شود. چون جدول `titles` با جداولی مثل `roysched`, `sales`, `titleauthor` رابطه دارد،
   قبل از حذف رکورد از جدول اصلی (`titles`) باید رکوردهای وابسته از جداول دیگر حذف شوند.

   🔍 ابتدا با استفاده از `OBJECT_ID` و `sys.foreign_keys` بررسی می‌کنیم که چه جدول‌هایی به `titles` وابسته هستند.
*/

SELECT OBJECT_ID('titles');
-- خروجی: 1045578763 (شناسه جدول titles)



SELECT 
	OBJECT_NAME(referenced_object_id) AS PrimaryTable, 
	OBJECT_NAME(parent_object_id) AS ForeignTable
FROM sys.foreign_keys
WHERE referenced_object_id = 1045578763;



-- 🔴 حالا رکوردهای وابسته را به ترتیب از جدول‌های مرتبط حذف می‌کنیم:



DELETE roysched 
WHERE title_id IN (
	SELECT title_id 
	FROM titleauthor 
	GROUP BY title_id 
	HAVING COUNT(*) > 1
);

DELETE sales 
WHERE title_id IN (
	SELECT title_id 
	FROM titleauthor 
	GROUP BY title_id 
	HAVING COUNT(*) > 1
);

DELETE titleauthor 
WHERE title_id IN (
	SELECT title_id 
	FROM titleauthor 
	GROUP BY title_id 
	HAVING COUNT(*) > 1
);

DELETE titles 
WHERE title_id IN (
	SELECT title_id 
	FROM titleauthor 
	GROUP BY title_id 
	HAVING COUNT(*) > 1
);



-- ✅ نسخه بهینه‌تر با استفاده از جدول موقت:



CREATE TABLE ##tmp (title_id varchar(6));

INSERT INTO ##tmp
SELECT title_id 
FROM titleauthor 
GROUP BY title_id 
HAVING COUNT(*) > 1;



-- یا با جدول موقت لوکال:



SELECT title_id 
INTO #tmp
FROM titleauthor 
GROUP BY title_id 
HAVING COUNT(*) > 1;



-- استفاده از جدول موقت در حذف‌های بعدی:



DELETE roysched WHERE title_id IN (SELECT title_id FROM #tmp);
DELETE sales WHERE title_id IN (SELECT title_id FROM #tmp);
DELETE titleauthor WHERE title_id IN (SELECT title_id FROM #tmp);
DELETE titles WHERE title_id IN (SELECT title_id FROM #tmp);



-- 📌 این رویکرد از لحاظ نگهداری و تست، بهتر و شفاف‌تر از استفاده مستقیم از `IN` است.
-- ⚠️ پیش از انجام حذف‌های زنجیره‌ای، تهیه نسخه پشتیبان یا اجرای کوئری در محیط تست توصیه می‌شود.



------------------------------------------------------------------



/* ============================================================
   11. 📊 ساخت و پر کردن جدول آماری فروش کتاب‌ها (TitleAmount)
   ============================================================

   🎯 در این بخش، اطلاعات فروش کتاب‌ها با استفاده از مجموع قیمت × تعداد فروش (Amount) محاسبه شده و در جدول جدیدی به نام `TitleAmount` ذخیره می‌شود.
   🔢 از تابع تحلیلی `ROW_NUMBER()` برای شماره‌گذاری ردیف‌ها بر اساس بیشترین فروش استفاده شده است.

   ⚙️ مراحل:
   1. حذف جدول `TitleAmount` در صورت وجود قبلی.
   2. ایجاد جدول جدید با استفاده از `SELECT ... INTO`.
   3. درج اطلاعات کامل دوباره با کوئری `INSERT INTO`.
   4. درج فقط 10 ردیف اول با بیشترین فروش با استفاده از `TOP`.
   5. نمایش جدول نهایی برای بررسی.

*/

DROP TABLE IF EXISTS TitleAmount;



-- ایجاد جدول TitleAmount با شماره ردیف و مجموع فروش برای هر عنوان
SELECT 
	ROW_NUMBER() OVER (ORDER BY SUM(qty * price) DESC) AS Id,
	t.title_id, 
	title, 
	type, 
	SUM(qty * price) AS Amount 
INTO TitleAmount	
FROM titles t 
INNER JOIN sales s ON s.title_id = t.title_id
GROUP BY t.title_id, title, type;



-- درج مجدد داده‌ها با ساختار مشابه
INSERT INTO TitleAmount
SELECT 
	ROW_NUMBER() OVER (ORDER BY SUM(qty * price) DESC) AS Id,
	t.title_id, 
	title, 
	type, 
	SUM(qty * price) AS Amount 
FROM titles t 
INNER JOIN sales s ON s.title_id = t.title_id
GROUP BY t.title_id, title, type;



-- درج فقط 10 ردیف اول بر اساس فروش
INSERT INTO TitleAmount
SELECT TOP 10 
	ROW_NUMBER() OVER (ORDER BY SUM(qty * price) DESC) AS Id,
	t.title_id, 
	title, 
	type, 
	SUM(qty * price) AS Amount 
FROM titles t 
INNER JOIN sales s ON s.title_id = t.title_id
GROUP BY t.title_id, title, type;



-- نمایش جدول نهایی
SELECT * 
FROM TitleAmount
ORDER BY Id;



-- 📝 نکته پرفورمنسی:
-- استفاده از `ROW_NUMBER()` و `SUM()` با `GROUP BY` روی دیتاست‌های بزرگ نیازمند ایندکس مناسب روی کلیدها (مثل `title_id`) است تا عملکرد بهینه شود.



------------------------------------------------------------------



/* ============================================================
   12. 🧪 ایجاد و بررسی جدول تستی برای عملیات Merge
   ============================================================

   🎯 در این بخش، یک جدول جدید با نام `titles_merge` ساخته می‌شود که نسخه‌ای تصادفی از جدول `titles` است. سپس، داده‌هایی به آن اضافه یا بروزرسانی می‌شوند تا آماده عملیات Merge باشد.

   ⚙️ مراحل:
   1. حذف جدول `titles_merge` در صورت وجود.
   2. ایجاد جدول با 16 ردیف تصادفی از `titles` با استفاده از `ORDER BY NEWID()`.
   3. بروزرسانی قیمت برای کتاب‌های نوع 'business'.
   4. افزودن چند ردیف جدید به صورت مستقیم به جدول.
   5. نمایش تفاوت بین جدول اصلی `titles` و نسخه‌ی Merge شده با استفاده از `FULL JOIN`.

*/



-- حذف جدول قبلی در صورت وجود
DROP TABLE IF EXISTS titles_merge;
GO



-- ایجاد جدول جدید از 16 ردیف تصادفی از جدول titles
SELECT TOP(16) * 
INTO titles_merge
FROM titles 
ORDER BY NEWID();
GO



-- بروزرسانی قیمت برای کتاب‌هایی با نوع 'business'
UPDATE titles_merge 
SET price = price * 1.1 
WHERE type = 'business';
GO



-- افزودن دو رکورد جدید به جدول titles_merge
INSERT INTO titles_merge (title_id, title, pub_id, type, price, pubdate) 
VALUES  
	(N'MC0000', N'The Gourmet Microwave', N'0877', N'mod_cook    ', CAST(3.28900 AS Numeric(22, 5)), GETDATE()),
	(N'TC0000', N'Onions, Leeks, and Garlic: Cooking Secrets of the Mediterranean', N'0877', N'trad_cook   ', CAST(23.04500 AS Numeric(22, 5)), GETDATE());
GO



-- مقایسه داده‌ها با جدول اصلی با استفاده از FULL JOIN
SELECT * 
FROM titles_merge 
FULL JOIN titles ON titles.title_id = titles_merge.title_id;

-- 📌 نکات پرفورمنسی:
-- استفاده از `ORDER BY NEWID()` در کوئری‌های بزرگ برای ایجاد انتخاب تصادفی ممکن است پرفورمنس پایینی داشته باشد.
-- درج داده‌ها با سایز فیلد مشخص شده (مانند Numeric(22,5)) به دقت نوع داده توجه شود تا تطابق کامل با ساختار اصلی حفظ گردد.



------------------------------------------------------------------



/* ============================================================
   13. 🔁 درج داده‌های جدید در جدول Merge بدون تکرار
   ============================================================

   🎯 هدف این کوئری، افزودن رکوردهایی از جدول `titles` به `titles_merge` است که در حال حاضر در `titles_merge` وجود ندارند.
   🧠 از `NOT IN` برای جلوگیری از درج داده‌های تکراری استفاده شده.
   📥 خروجی دستور `INSERT` نیز با `OUTPUT inserted.*` برای بررسی نتایج درج شده نمایش داده می‌شود.

*/

INSERT INTO titles_merge 
OUTPUT inserted.*
SELECT * 
FROM titles 
WHERE title_id NOT IN (SELECT title_id FROM titles_merge);

-- 📌 نکات پرفورمنسی:
-- استفاده از `NOT IN` می‌تونه روی مجموعه‌های داده‌ای بزرگ پرفورمنس پایین‌تری نسبت به `NOT EXISTS` یا `LEFT JOIN IS NULL` داشته باشه.
-- دستور `OUTPUT` کمک می‌کنه در محیط‌های تست، داده‌های درج شده رو بلافاصله مشاهده و بررسی کنیم.



------------------------------------------------------------------



/* ============================================================
   14. 🔄 به‌روزرسانی، حذف و همگام‌سازی با استفاده از MERGE
   ============================================================

   🛠️ بخش اول: به‌روزرسانی قیمت‌ها در `titles_merge` با استفاده از قیمت‌های جدول اصلی `titles`
   📥 دستور `UPDATE` همراه با `OUTPUT` برای مشاهده تفاوت قیمت‌های قبلی و جدید

*/

UPDATE titles_merge 
SET price = titles.price
OUTPUT deleted.*, inserted.*
FROM titles_merge 
INNER JOIN titles ON titles.title_id = titles_merge.title_id;

-- 📌 نکات پرفورمنسی:
-- استفاده از JOIN مستقیم با UPDATE در حجم‌های بزرگ ممکنه باعث افزایش مصرف منابع بشه.
-- `OUTPUT` کمک می‌کنه تغییرات را به‌صورت دقیق بررسی کنیم.



/* ============================================================
   15. 🧹 پاک‌سازی داده‌های اضافی از جدول Merge
   ============================================================

   🎯 حذف رکوردهایی در `titles_merge` که در جدول اصلی `titles` وجود ندارند.
   🧼 این مرحله باعث همگام‌سازی ساختار داده‌ای بین دو جدول می‌شود.

*/

DELETE titles_merge 
OUTPUT deleted.*
WHERE title_id NOT IN (SELECT title_id FROM titles);

-- 📌 توصیه پرفورمنسی:
-- برای مجموعه داده‌های بزرگ، استفاده از `NOT EXISTS` معمولاً سریع‌تر از `NOT IN` عمل می‌کنه.



/* ============================================================
   16. 🔄 همگام‌سازی کامل با دستور MERGE
   ============================================================

   🎯 همزمان انجام عملیات INSERT، UPDATE و DELETE بین دو جدول `titles_merge` و `titles`
   ⚙️ بر اساس تطابق `title_id`، تصمیم گرفته می‌شود چه عملی انجام شود.
   📊 نتیجه با `OUTPUT $ACTION` و سایر فیلدها نمایش داده می‌شود.

*/

MERGE titles_merge AS TARGET
USING titles AS SOURCE 
ON SOURCE.title_id = TARGET.title_id
WHEN NOT MATCHED BY TARGET THEN 
	INSERT (title_id , title , type , pub_id , price , advance , royalty , ytd_sales , notes , pubdate)
	VALUES (SOURCE.title_id , SOURCE.title , SOURCE.type , SOURCE.pub_id , SOURCE.price , 
			SOURCE.advance , SOURCE.royalty , SOURCE.ytd_sales , SOURCE.notes , SOURCE.pubdate)
WHEN MATCHED THEN 
	UPDATE SET price = SOURCE.price
WHEN NOT MATCHED BY SOURCE THEN 
	DELETE
OUTPUT $ACTION , 
		ISNULL(inserted.title_id , deleted.title_id) title_id , 
		ISNULL(inserted.title , deleted.title) title , 
		ISNULL(inserted.type , deleted.type) type , 
		deleted.price OldPrice , inserted.price NewPrice;

-- 🧠 تحلیل عملکردی:
-- `MERGE` ابزاری قدرتمند برای همگام‌سازی کامل داده‌ها در یک دستور واحد است.
-- ⚠️ توجه داشته باش که استفاده گسترده از `MERGE` در سناریوهای پیچیده ممکن است منجر به مشکلات پرفورمنسی و حتی تعارض‌ها شود، به‌ویژه در محیط‌های موازی.


------------------------------------------------------------------



/* ============================================================
   17. 🧪 تمرین بر روی جدول jobs_merge با عملیات INSERT و UPDATE
   ============================================================

   🧱 ایجاد جدول جدید `jobs_merge` با انتخاب تصادفی از جدول `jobs`
   ➕ اضافه کردن رکوردهای جدید برای موقعیت‌های شغلی خاص
   🔧 به‌روزرسانی سطح حداقل حقوق برای موقعیت‌های شغلی با شناسه کمتر از ۵
   🔍 مقایسه کامل دو جدول با استفاده از `FULL JOIN`

*/

DROP TABLE IF EXISTS jobs_merge;

SELECT TOP 10 *
INTO jobs_merge
FROM jobs
ORDER BY NEWID();



-- 📥 درج اطلاعات جدید در جدول merge
INSERT INTO jobs_merge 
VALUES 
('Database Administrator' , 150 , 250),
('BI Developer' , 150 , 250);



-- 🔧 افزایش حداقل حقوق برای شغل‌هایی با شناسه کمتر از ۵
UPDATE jobs_merge 
SET min_lvl = min_lvl + 10 
WHERE job_id < 5;



-- 🔍 مقایسه و بررسی تفاوت داده‌ها بین دو جدول مشابه
SELECT * 
FROM jobs 
FULL JOIN jobs_merge 
ON jobs.job_id = jobs_merge.job_id;

-- 📌 نکات کلیدی:
-- استفاده از `NEWID()` برای ترتیب تصادفی در `SELECT TOP` مناسب برای تست‌های متنوع.
-- `FULL JOIN` برای مشاهده تفاوت‌ها و مشابهت‌ها بین دو جدول ایده‌آل است.
	