


/* ============================================================
   🧾 جلسه شانزدهم: توابع پارامتری، APPLY، و SP با مدیریت خطا
   ============================================================

📌 موضوعات این جلسه شامل موارد زیر است:

1️⃣ تعریف و استفاده از توابع اسکالر و جدولی پارامتری (SVF & TVF)
   - محاسبه فروش بر اساس ناشر (`svfPublishersAmount`, `tvfPublishersAmount`)
   - پیاده‌سازی منطق شرطی در توابع برگشتی جدولی با استفاده از INSERT در TVF
   - مقایسه کاربردی بین ویوها و توابع TVF

2️⃣ کاربردهای عملی `CROSS APPLY` و `OUTER APPLY`
   - نمایش ارتباطی ناشران با کتاب‌هایشان
   - فیلتر نویسندگان بر اساس وضعیت رشته `au_id`

3️⃣ توابع چندمقداری با جدول بازگشتی
   - `tvfState` برای بازیابی داده از چند جدول مرتبط با `state`

4️⃣ استفاده از `string_split` و `PIVOT` برای تحلیل رشته‌ای و ساختاردهی داده

5️⃣ تعریف و اجرای Stored Procedure:
   - `spJobsInsert` و `spTitlesUpdate` برای عملیات درج و بروزرسانی
   - نمونه‌سازی خروجی و استفاده از `OUTPUT`
   - پیاده‌سازی ساختار TRY...CATCH در Stored Procedure برای مدیریت خطا و استخراج جزئیات آن

🎯 هدف آموزشی:
- تسلط به انواع توابع در SQL Server
- توانایی ترکیب توابع با دستورات پیشرفته مانند APPLY، PIVOT، و مدیریت خطا
- درک تفاوت اجرایی و پرفورمنسی بین TVF و View

🔧 نکات کلیدی:
- توابع TVF نسبت به View‌ها برای منطق‌های پیچیده‌تر قابل نگهداری‌تر و منعطف‌تر هستند.
- استفاده از APPLY در کنار توابع پارامتری موجب بهینه‌سازی کوئری‌های شرطی می‌شود.
- ساختار TRY...CATCH برای هندل دقیق خطا در SP ضروری است.
*/



---------------------------------------------------------------------



USE T_pubs
GO



---------------------------------------------------------------------



/* ============================================================
   🔹 تعریف تابع اسکالر برای محاسبه مجموع فروش ناشر خاص
   ============================================================

📌 تابع `svfPublishersAmount` یک تابع اسکالر (Scalar-Valued Function) است که با دریافت شناسه ناشر `@PubID`، مجموع مبلغ فروش کتاب‌های منتشرشده توسط آن ناشر را محاسبه و بازمی‌گرداند.

🛠️ ورودی:
- `@PubID` : شناسه ناشر از نوع `char(4)`

📤 خروجی:
- نوع `money` شامل جمع (price * qty) برای ناشر مذکور

🎯 کاربردها:
- قابل استفاده در گزارش‌گیری‌ها برای نمایش عملکرد مالی ناشران
- استفاده در SELECT های ترکیبی برای محاسبه مقدار فروش داینامیک

*/

CREATE OR ALTER FUNCTION svfPublishersAmount(@PubID char(4))
RETURNS money 
AS
BEGIN 
	RETURN (
		SELECT SUM(qty * price)
		FROM titles t
		INNER JOIN sales s ON s.title_id = t.title_id
		WHERE pub_id = @PubID
	)
END 
GO

-- 🔍 نکته پرفورمنسی:
-- تابع اسکالر در صورت فراخوانی در حجم بالا ممکن است باعث کاهش سرعت شود (scalar performance hit)،
-- زیرا برای هر ردیف به صورت مجزا اجرا می‌شود. در چنین مواردی توابع جدولی (TVF) گزینه بهتری هستند.



---------------------------------------------------------------------



/* ============================================================
   🔸 تابع جدولی پارامتری برای محاسبه فروش ناشر خاص (TVF)
   ============================================================

📌 در این قسمت، تابع `tvfPublishersAmount` تعریف شده است که با دریافت شناسه ناشر (`@PubID`) مجموع فروش مربوط به آن ناشر را به صورت جدول بازمی‌گرداند.

🧮 پارامتر ورودی:
- `@PubID` : شناسه ناشر (char(4))

📋 خروجی:
- ستونی با نام `Amount` که مجموع `price * qty` را برای کتاب‌های آن ناشر نمایش می‌دهد.

✅ مزایای TVF نسبت به SVF:
- قابل استفاده مستقیم در `JOIN` و `APPLY`
- ایندکس‌پذیر در بسیاری از سناریوها
- عملکرد بهتر به‌ویژه در سناریوهای چندردیفی

*/

CREATE OR ALTER FUNCTION tvfPublishersAmount (@PubID char(4))
RETURNS TABLE 
RETURN 
(
	SELECT SUM(qty * price) AS Amount
	FROM titles t 
	INNER JOIN sales s ON s.title_id = t.title_id 
	WHERE pub_id = @PubID
)
GO

-- 📊 تست مقایسه‌ای با SVF
SELECT pub_id, pub_name, dbo.svfPublishersAmount(pub_id)
FROM publishers
GO

-- 📥 تست مستقیم TVF با مقدار ثابت
SELECT * 
FROM tvfPublishersAmount('1389')
GO

/*
-- 📎 توجه: می‌توان از TVF در INNER JOIN نیز استفاده کرد
SELECT * 
FROM publishers INNER JOIN 
     tvfPublishersAmount(pub_id) ON ...
*/



---------------------------------------------------------------------



/* ============================================================
   🔹 مقایسه روش‌های مختلف Join و Apply در SQL Server
   ============================================================

📌 در این بخش، هدف بررسی تکنیک‌های مختلف اتصال و فیلتر بین دو جدول (مثل `publishers` و `titles`) است:

📘 تکنیک‌های استفاده‌شده:
1. `EXISTS` و `NOT EXISTS` برای فیلتر کردن ناشرانی که دارای کتاب هستند یا نیستند.
2. `INNER JOIN` و `LEFT JOIN` برای اتصال داده‌ها و بررسی وجود یا عدم وجود رکوردهای متناظر.
3. `CROSS APPLY` و `OUTER APPLY` برای اعمال زیرکوئری به ازای هر ردیف از جدول بیرونی.
4. استفاده از `CROSS APPLY` با تابع TVF (`tvfPublishersAmount`) برای فراخوانی پارامتریک.

🎯 مزایا و نکات پرفورمنسی:
- `EXISTS` سریع‌تر از `JOIN` در مواقعی‌ست که صرفاً بررسی وجود اهمیت دارد.
- `CROSS APPLY` برای فراخوانی توابع جدولی بسیار بهینه است.
- `OUTER APPLY` مشابه `LEFT JOIN` عمل می‌کند ولی برای توابع یا ساب‌کوئری‌ها کاربرد بیشتری دارد.

*/

-- 🔎 ناشرانی که کتابی منتشر کرده‌اند
SELECT * 
FROM publishers p 
WHERE EXISTS (
	SELECT * 
	FROM titles
	WHERE titles.pub_id = p.pub_id
)

-- 🔗 اتصال مستقیم ناشران به کتاب‌هایشان
SELECT * 
FROM publishers p 
INNER JOIN titles t ON t.pub_id = p.pub_id

-- 🔁 اجرای کوئری داخلی برای هر ناشر (معادل INNER JOIN)
SELECT * 
FROM publishers p 
CROSS APPLY (
	SELECT * 
	FROM titles t 
	WHERE t.pub_id = p.pub_id
) AS tm

-- 🚫 ناشرانی که هیچ کتابی ندارند
SELECT * 
FROM publishers p 
WHERE NOT EXISTS (
	SELECT * 
	FROM titles
	WHERE titles.pub_id = p.pub_id
)

-- ⛓️ اتصال چپ برای یافتن ناشرانی بدون کتاب
SELECT * 
FROM publishers p 
LEFT JOIN titles t ON t.pub_id = p.pub_id
WHERE title_id IS NULL

-- 🔍 نسخه Apply برای یافتن ناشران بدون کتاب
SELECT * 
FROM publishers p 
OUTER APPLY (
	SELECT * 
	FROM titles t 
	WHERE t.pub_id = p.pub_id
) AS tm
WHERE title_id IS NULL

-- 📈 استفاده از TVF پارامتریک برای استخراج فروش هر ناشر
SELECT * 
FROM publishers 
CROSS APPLY tvfPublishersAmount(pub_id)
GO



---------------------------------------------------------------------



/* ============================================================
   🔹 تابع جدولی چندمنظوره برای بررسی اطلاعات ایالتی
   ============================================================

📌 این بخش شامل تعریف یک تابع Table-Valued Function (TVF) با نام `tvfState` است که با گرفتن کد ایالت (`@StateID`) اطلاعات مرتبط با ناشران، نویسندگان و فروشگاه‌های مربوط به آن ایالت را استخراج می‌کند.

🧮 پارامتر ورودی:
- `@StateID`: کد ایالت به صورت `char(2)`

📋 خروجی:
- جدول شامل ستون‌های:
  - `Id`: شناسه ناشر، نویسنده یا فروشگاه
  - `name`: نام کامل
  - `type`: نوع رکورد (p = Publisher, a = Author, s = Store)

🎯 مزایا و کاربردها:
- تجمیع داده‌های مرتبط از چندین جدول در یک خروجی واحد
- مناسب برای گزارش‌گیری بر اساس موقعیت جغرافیایی
- قابل استفاده در فرم‌ها و نمودارهای تحلیلی

🔧 نکته پرفورمنسی:
- استفاده از `RETURNS @Table TABLE` (Multi-Statement TVF) در این نوع سناریوها منطقی است زیرا کوئری‌های متعدد نیاز به افزودن اطلاعات مرحله‌ای دارند.
- خروجی این نوع TVF قابل ایندکس نیست ولی برای داده‌های محدود یا گزارش‌های سبک مشکلی ایجاد نمی‌کند.

*/

CREATE OR ALTER FUNCTION tvfState (@StateID char(2))
RETURNS @Table TABLE (Id VARCHAR(15), name varchar(100) , type char(1))
AS
BEGIN

	-- 🎯 Publishers
	INSERT INTO @Table
	SELECT pub_id , pub_name , 'p'
	FROM publishers 
	WHERE state = @StateID

	-- 🧑‍💼 Authors
	INSERT INTO @Table
	SELECT au_id , au_fname + ' ' + au_lname , 'a'
	FROM authors
	WHERE state = @StateID

	-- 🏪 Stores
	INSERT INTO @Table
	SELECT stor_id , stor_name , 's'
	FROM stores 
	WHERE state = @StateID

	RETURN
END
GO

-- 📊 مشاهده خروجی برای ایالت CA
SELECT * 
FROM tvfState('CA')
GO



---------------------------------------------------------------------



CREATE OR ALTER FUNCTION tvfPrice()
RETURNS @t TABLE (title_id varchar(6) , NewPrice money)
AS 
BEGIN 
		
		INSERT INTO @t SELECT title_id , price * 1.20
							FROM titles t 
							WHERE pub_id IN (SELECT pub_id FROM publishers WHERE state = 'CA')


		INSERT INTO @t SELECT title_id , price * 1.15
							FROM titles t 
							WHERE title_id IN (SELECT title_id
													FROM titleauthor 
													GROUP BY title_id 
													HAVING COUNT(*) > 1) AND 
								  title_id NOT IN (SELECT title_id FROM @t)

		INSERT INTO @t SELECT title_id , price * 1.10
							FROM titles t 
							WHERE title_id IN (SELECT title_id
													FROM sales 
													GROUP BY title_id 
													HAVING SUM(qty) * price > 200) AND 
								  title_id NOT IN (SELECT title_id FROM @t)

		INSERT INTO @t SELECT title_id , price * .99
							FROM titles t 
							WHERE   title_id NOT IN (SELECT title_id FROM @t)

		UPDATE @t SET NewPrice = 25 
			WHERE NewPrice > 20
	
		RETURN
END 
GO



-- اجرای تابع قیمت
SELECT * FROM tvfPrice()

-- مشاهده جدول نویسندگان
SELECT * FROM authors

-- تجزیه رشته با جداکننده "-"
SELECT * FROM string_split('238-95-7766', '-')

-- اجرای تابع محاسبه فروش ناشر برای هر ناشر با CROSS APPLY
SELECT * 
	FROM publishers CROSS APPLY tvfPublishersAmount(pub_id)



---------------------------------------------------------------------



/* ============================================================
   🔢 استفاده از APPLY و PIVOT برای استخراج مؤلفه‌های شناسه
   ============================================================

📌 این بخش نمونه‌ای از تجزیه رشته شناسه (مثلاً au_id) به اجزای جداگانه و نمایش ستونی آن‌ها است:

🔄 مراحل:
1. استفاده از `CROSS APPLY` و تابع `STRING_SPLIT` برای شکستن `au_id` که فرمت مانند '123-45-6789' دارد.
2. استفاده از `ROW_NUMBER()` برای شماره‌گذاری ترتیب مقادیر شکسته شده در هر `au_id`.
3. استفاده از `PIVOT` برای تبدیل ردیف‌ها به ستون و استخراج ۳ بخش شناسه به عنوان [1], [2], [3].

🎯 کاربردها:
- تبدیل داده‌های رمزگذاری‌شده یا رشته‌ای به ساختارهای خوانا و ستونی
- تحلیل داده‌هایی که در قالب رشته ذخیره شده‌اند

⚙ نکات پرفورمنسی:
- تابع `STRING_SPLIT` تا SQL Server 2016 به بالا پشتیبانی می‌شود و ممکن است ترتیب مقادیر خروجی را تضمین نکند، اما در اینجا `ROW_NUMBER()` کمک می‌کند که ترتیب کنترل شود.
- استفاده از `PIVOT` برای گزارش‌گیری ستونی بسیار مؤثر است ولی بهتر است روی داده‌هایی با حجم بالا با دقت بررسی شود.
*/

;WITH cte AS (
	SELECT 
		au_id, 
		au_fname, 
		au_lname, 
		value, 
		ROW_NUMBER() OVER (PARTITION BY au_id ORDER BY au_id) AS Id
	FROM authors 
	CROSS APPLY string_split(au_id, '-')
)
SELECT *
FROM (
	SELECT * FROM cte
) AS DQ
PIVOT (
	MAX(value) FOR Id IN ([1], [2], [3])
) AS PQ
GO


---------------------------------------------------------------------



/* ============================================================
   🛠️ ساخت و اجرای یک Stored Procedure ساده برای درج اطلاعات
   ============================================================

📌 در این بخش یک پروسیجر به نام `spJobsInsert` ساخته می‌شود که برای درج رکورد جدید در جدول `jobs` استفاده می‌گردد.

🧾 پارامترهای ورودی:
- `@JobDesc` : توضیحات شغلی
- `@Min`     : حداقل سطح
- `@Max`     : حداکثر سطح

🧩 عملکرد:
- با استفاده از دستور `INSERT INTO` رکورد جدیدی را با پارامترهای دریافتی به جدول `jobs` اضافه می‌کند.

🎯 کاربرد:
- ساختاردهی به عملیات درج برای جلوگیری از تکرار کد
- تسهیل فرآیند نگهداری و توسعه

⚙ نکات پرفورمنسی و توسعه‌ای:
- استفاده از `Stored Procedure` امنیت، کارایی و قابلیت نگهداری بالاتری نسبت به اجرای مستقیم کوئری دارد.
- در صورت نیاز به بررسی یا اعتبارسنجی داده‌ها قبل از درج، می‌توان از منطق‌های اضافی در بلوک `BEGIN...END` استفاده کرد.
*/

CREATE OR ALTER PROCEDURE spJobsInsert 
	@JobDesc varchar(50), 
	@Min tinyint, 
	@Max tinyint 
AS
BEGIN 
	INSERT INTO jobs VALUES (@JobDesc , @Min , @Max)
END 
GO

EXECUTE spJobsInsert 'DBA' , 100 , 200

SELECT * 
FROM jobs
GO



---------------------------------------------------------------------



/* ============================================================
   🔄 بروز رسانی قیمت کتاب با استفاده از Stored Procedure
   ============================================================

📌 در این بخش، پروسیجری به نام `spTitlesUpdate` تعریف شده است که برای بروزرسانی قیمت کتاب‌ها بر اساس `title_id` مورد استفاده قرار می‌گیرد.

🧾 پارامترهای ورودی:
- `@title_id` : شناسه کتاب
- `@price`    : قیمت جدید کتاب

🧩 عملکرد:
- عملیات `UPDATE` روی جدول `titles` انجام می‌شود تا قیمت کتاب مشخص شده بروزرسانی گردد.
- با استفاده از `OUTPUT`، مقادیر قبل و بعد از بروزرسانی به عنوان گزارش تغییرات ارائه می‌شود.

🎯 کاربرد:
- اعمال تغییرات کنترل‌شده روی داده‌ها
- ذخیره‌سازی یا لاگ‌گیری تغییرات جهت بررسی و تحلیل

⚙ نکات پرفورمنسی:
- استفاده از کلید اصلی (`title_id`) برای فیلتر، از ایندکس بهره می‌برد و عملکرد بهینه دارد.
- `OUTPUT` می‌تواند به جدول موقتی برای ذخیره تغییرات هدایت شود، به منظور پیاده‌سازی audit log.
*/

CREATE OR ALTER PROCEDURE spTitlesUpdate 
	@title_id varchar(6), 
	@price money
AS
BEGIN	
	UPDATE titles 
	SET price = @price
	OUTPUT deleted.title_id, deleted.title, deleted.price AS OldPrice, inserted.price AS NewPrice
	WHERE title_id = @title_id
END
GO

EXEC spTitlesUpdate 'BU1032', 19.99
GO



---------------------------------------------------------------------



/* ============================================================
   🔁 درج شغل جدید و دریافت شناسه خروجی با Stored Procedure
   ============================================================

📌 در این بخش، یک پروسیجر به نام `spJobsInsert` طراحی شده که با دریافت اطلاعات شغلی، یک رکورد جدید در جدول `jobs` وارد می‌کند و شناسه رکورد درج‌شده را به صورت `OUTPUT` بازمی‌گرداند.

🧾 پارامترهای ورودی:
- `@JobDesc` : شرح شغل
- `@Min`     : حداقل سطح
- `@Max`     : حداکثر سطح

📤 پارامتر خروجی:
- `@Id`      : شناسه رکورد درج‌شده

🧩 عملکرد:
- عملیات `INSERT` انجام می‌شود.
- شناسه رکورد جدید با استفاده از `IDENT_CURRENT('jobs')` بازیابی شده و به متغیر خروجی اختصاص داده می‌شود.

⚠ نکته مهم:
- `IDENT_CURRENT` ممکن است در محیط‌های چندکاربره مقادیر غیرمنتظره‌ای بدهد. استفاده از `SCOPE_IDENTITY()` به جای آن توصیه می‌شود برای دقیق‌تر بودن در سطح session.

🎯 کاربرد:
- درج کنترل‌شده و لاگ‌گیری شناسه‌های جدید
*/

CREATE OR ALTER PROCEDURE spJobsInsert 
	@JobDesc varchar(50), 
	@Min tinyint, 
	@Max tinyint, 
	@Id int OUTPUT
AS
BEGIN 
	INSERT INTO jobs VALUES (@JobDesc, @Min, @Max)
	SET @Id = IDENT_CURRENT('jobs')
END 
GO

DECLARE @JobId int
EXECUTE spJobsInsert 'DBA', 100, 200, @JobId OUTPUT
SELECT @JobId
GO



------------------------------------------------------------



/* ============================================================
   ✏️ بروزرسانی اطلاعات کتاب با استفاده از Stored Procedure
   ============================================================

📌 این پروسیجر به نام `spTitlesUpdate` طراحی شده تا اطلاعات یک کتاب را بر اساس `title_id` بروزرسانی کند. این اطلاعات شامل ناشر (`pub_id`) و قیمت (`price`) است.

🧾 پارامترهای ورودی:
- `@title_id`: شناسه کتاب
- `@pub_id`  : شناسه ناشر جدید
- `@price`   : قیمت جدید کتاب

🧾 خروجی:
- از طریق دستور `OUTPUT`، مقادیر قبلی و جدید برای فیلدهای `pub_id` و `price` نمایش داده می‌شوند.

🎯 کاربرد:
- بروزرسانی همزمان چند ستون همراه با لاگ‌گیری دقیق تغییرات برای تحلیل یا ذخیره در جدول لاگ

🔧 نکات پرفورمنسی:
- استفاده از `OUTPUT` در `UPDATE` باعث کاهش نیاز به کوئری‌های مجزای قبل و بعد از بروزرسانی می‌شود و عملکرد و پیاده‌سازی لاگ‌گیری را بهینه می‌کند.
*/

CREATE OR ALTER PROCEDURE spTitlesUpdate 
	@title_id varchar(6), 
	@pub_id char(4), 
	@price money
AS
BEGIN	
	UPDATE titles 
	SET pub_id = @pub_id, price = @price 
	OUTPUT deleted.title_id, deleted.title, deleted.pub_id AS OldPub, 
	       inserted.pub_id AS NewPub, deleted.price AS OldPrice, inserted.price AS NewPrice
	WHERE title_id = @title_id
END
GO

EXEC spTitlesUpdate 'BU1032', '0000', 19
GO



---------------------------------------------------------------------



/* ============================================================
   🚨 مدیریت خطا با بلوک TRY...CATCH در SQL Server
   ============================================================

📌 این ساختار برای مدیریت خطاها در T-SQL استفاده می‌شود تا در صورت بروز خطا در اجرای دستورات، بتوان اقدامات جایگزین مانند لاگ‌گیری، ارسال پیام و یا برگشت تراکنش را انجام داد.

🧱 ساختار:
BEGIN TRY
	-- دستورات اصلی (ممکن است خطا داشته باشند)
END TRY
BEGIN CATCH
	-- دستورات جایگزین در صورت وقوع خطا
END CATCH

🔧 نکات فنی:
- در بلوک CATCH می‌توان از توابع سیستمی مانند `ERROR_NUMBER()`, `ERROR_MESSAGE()`, `ERROR_LINE()` استفاده کرد تا جزئیات خطا را به‌دست آورد.
- مناسب برای تضمین پایداری برنامه‌های پایگاه داده در هنگام بروز خطاهای پیش‌بینی‌نشده.

🎯 کاربرد:
- بروزرسانی و حذف امن داده‌ها
- مدیریت عملیات حساس مانند تراکنش‌ها
- ثبت خطاها در جدول مخصوص یا ارسال هشدار

*/

-- مثال ساختاری بدون اجرای واقعی
BEGIN TRY
	-- دستور 1
	-- دستور 2
	-- دستور 3 ممکن است خطا داشته باشد
	-- دستور 4
	-- دستور 5
END TRY
BEGIN CATCH
	-- مدیریت خطا (نمایش پیام، ذخیره در لاگ، rollback، ...)
END CATCH
GO



---------------------------------------------------------------------



/* ============================================================
   🧪 ذخیره‌سازی خطای سفارشی با استفاده از TRY...CATCH و OUTPUT
   ============================================================

📌 در این بخش، رویه‌ی `spTitlesUpdate` با قابلیت مدیریت خطا طراحی شده است تا ضمن بروزرسانی اطلاعات یک کتاب، در صورت بروز خطا پیام خطا به صورت ساخت‌یافته برگشت داده شود.

🧮 پارامترها:
- `@title_id` : شناسه کتاب
- `@pub_id` : ناشر جدید
- `@price` : قیمت جدید
- `@Msg` : پارامتر خروجی برای پیام خطا (در صورت وقوع)

🛠️ نحوه عملکرد:
- اگر بروزرسانی بدون خطا انجام شود، اطلاعات خروجی از طریق `OUTPUT` نمایش داده می‌شود.
- در صورت بروز خطا، اطلاعات دقیق خطا مانند شماره، سطح، پیام و نام رویه در پارامتر خروجی `@Msg` ذخیره می‌شود.

🎯 کاربرد:
- افزایش کنترل و شفافیت در عملیات بروزرسانی
- مناسب برای محیط‌های عملیاتی با نیاز به log دقیق خطاها

📋 مزایا:
- بدون نیاز به rollback صریح
- کاربر نهایی می‌تواند دلیل خطا را بررسی کند

*/

CREATE OR ALTER PROCEDURE spTitlesUpdate 
	@title_id varchar(6), 
	@pub_id char(4), 
	@price money, 
	@Msg varchar(max) OUTPUT
AS
BEGIN	
	BEGIN TRY
		UPDATE titles 
		SET pub_id = @pub_id , price = @price 
		OUTPUT deleted.title_id , deleted.title , deleted.pub_id AS OldPub, inserted.pub_id AS NewPub, 
		       deleted.price AS OldPrice, inserted.price AS NewPrice
		WHERE title_id = @title_id
	END TRY
	BEGIN CATCH
		SET @Msg = CONCAT(
			'Error Code: ', ERROR_NUMBER(), CHAR(13),
			'Error Level: ', ERROR_SEVERITY(), CHAR(13),
			'Error State: ', ERROR_STATE(), CHAR(13),
			'Error Procedure: ', ERROR_PROCEDURE(), CHAR(13),
			'Error Line: ', ERROR_LINE(), CHAR(13),
			'Error Message: ', ERROR_MESSAGE(), CHAR(13)
		)
	END CATCH 
END
GO

-- اجرای تستی رویه:
DECLARE @Message varchar(max)
EXEC spTitlesUpdate 'BU1032', '0000', 19, @Message OUTPUT
PRINT @Message


-- بررسی اطلاعات دیتابیس و کد رویه:
EXECUTE sp_helpdb 'pubs'
EXECUTE sp_helptext 'spTitlesUpdate'

/* 🔍 نکات پرفورمنسی:
- استفاده از `OUTPUT` برای مشاهده تغییرات قبل و بعد از بروزرسانی بسیار مفید در دیباگ و گزارش‌گیری است.
- پیاده‌سازی `TRY...CATCH` بدون تراکنش، برای این مورد کافی است اما برای عملیات‌های چندمرحله‌ای بهتر است از `BEGIN TRAN...ROLLBACK` نیز استفاده شود.
*/

 