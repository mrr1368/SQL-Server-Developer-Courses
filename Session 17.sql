


/* ============================================================
🧷 جلسه ۱۷: بررسی و پیاده‌سازی تریگرها (Triggers) در SQL Server
===============================================================

📌 در این جلسه، تمرکز ما روی مبحث *تریگرها* (Triggers) است — ابزارهایی برای نظارت و واکنش خودکار به عملیات‌های DML مانند INSERT، UPDATE و DELETE.

📍 سرفصل‌های مهم این جلسه:

1️⃣ **ساختار کلی تریگرها**  
   - تعریف اولیه با `CREATE TRIGGER` یا `CREATE OR ALTER TRIGGER`
   - استفاده از جداول مجازی `inserted` و `deleted`

2️⃣ **پیاده‌سازی تریگرهای لاگ‌گیری برای جدول‌ها**
   - ثبت تغییرات در `jobs` و `publishers` به همراه اطلاعات کاربری (`loginame`, `net_address`)
   - ذخیره‌سازی تاریخچه قیمت‌ها در `PriceLog` برای جدول `titles`

3️⃣ **مدیریت EndTime برای تغییر قیمت‌ها**  
   - با هر بروزرسانی قیمت، تاریخ پایان رکورد قبلی به‌روز شده و رکورد جدیدی درج می‌شود

4️⃣ **پوشش داده‌شده‌های مکمل**
   - استفاده از `sp_who`، `sp_who2` و `@@SPID` برای دریافت اطلاعات نشست فعلی
   - مقایسه CROSS APPLY با LEFT JOIN و بررسی حالت‌های EXISTS / NOT EXISTS

🎯 کاربرد:
- پیاده‌سازی سیاست‌های لاگ‌گیری
- تحلیل تغییرات در دیتا به مرور زمان
- بررسی تغییرات اعمال‌شده توسط کاربران مختلف

⚙️ نکات پرفورمنسی:
- در طراحی تریگرها باید مراقب چرخه‌های بی‌نهایت (recursion) و افت کارایی باشید
- استفاده از جداول مجازی محدود به ردیف‌های تغییر یافته در هر عملیات است
- بررسی شرط‌های WHERE دقیق می‌تواند از عملیات‌های غیر ضروری روی لاگ‌ها جلوگیری کند

*/



--------------------------------------------------------------------------------------------------------



/*

	CREATE TRIGGER tiName ON TableName 
	FOR INSERT , UPODATE , DELETE 
	AS 
	BEGIN
			.
			.
			.
			.
	END 
	GO

*/



/* ============================================================
🔹 ساختار عمومی ایجاد تریگر در SQL Server
===============================================================

📌 قالب کلی ایجاد تریگر (Trigger) در SQL Server به کمک دستور `CREATE TRIGGER` مشخص می‌شود. تریگرها ابزاری هستند که به صورت خودکار پس از اجرای عملیات‌های `INSERT`, `UPDATE`, یا `DELETE` روی یک جدول فعال می‌شوند.

📋 ساختار پیشنهادی:
---------------------------------------------------------------
CREATE TRIGGER tiName ON TableName 
FOR INSERT, UPDATE, DELETE 
AS 
BEGIN
    -- عملیات دلخواه شما در این بخش قرار می‌گیرد
END
GO
---------------------------------------------------------------

🛠 نکات فنی:
- از `inserted` برای دسترسی به داده‌های جدید و از `deleted` برای داده‌های قدیمی استفاده می‌شود.
- با استفاده از `AFTER` (پیش‌فرض SQL Server)، تریگر بعد از تکمیل عملیات اجرا می‌شود.
- امکان استفاده از دستورات شرطی و توابع سیستمی برای سفارشی‌سازی رفتار تریگر وجود دارد.

🎯 کاربرد:
- ثبت لاگ تغییرات
- اعتبارسنجی و محدودسازی تغییرات داده‌ای
- اجرای خودکار عملیات وابسته یا مکمل

*/



--------------------------------------------------------------------------------------------------------



/* ============================================================
🔸 ثبت تغییرات روی جدول Jobs با استفاده از تریگر
===============================================================

📌 در این بخش، یک تریگر با نام `tiJobsLog` برای جدول `jobs` تعریف شده است که تغییرات مربوط به عملیات `INSERT`، `UPDATE` و `DELETE` را در جدول لاگ `JobsLog` ذخیره می‌کند.

🧾 اجزای ساختار:
- `JobsLog`: جدول لاگ برای ثبت سابقه تغییرات با فیلدهای کاربردی مانند:
  - `ActionType`: نوع عملیات ('i' برای INSERT، 'd' برای DELETE)
  - `ActionTime`: زمان ثبت تغییر
  - `loginame`, `net_address`: اطلاعات کاربر و سیستم اعمال کننده

⚙️ عملکرد تریگر:
- داده‌های حذف‌شده از جدول `deleted` و داده‌های جدید از `inserted` گرفته شده و در `JobsLog` ثبت می‌شوند.

📈 مزایا:
- ردیابی آسان تغییرات اطلاعاتی
- مستندسازی تغییرات داده‌ای برای اهداف ممیزی یا تحلیل

📌 مثال‌های کاربردی:
- بررسی تغییرات اخیر در جدول `jobs`
- تحلیل کاربران و زمان تغییرات از طریق `sys.sysprocesses`

*/

-- نمایش داده‌های اولیه جدول jobs
SELECT * FROM jobs
GO

-- حذف جدول لاگ در صورت وجود قبلی
DROP TABLE IF EXISTS JobsLog

-- ساخت جدول لاگ برای ثبت تغییرات
CREATE TABLE JobsLog (
	Id int IDENTITY,
	job_id int, 
	job_desc varchar(50), 
	min_lvl tinyint, 
	max_lvl tinyint,
	ActionType char(1), 
	ActionTime datetime DEFAULT GETDATE(), 
	loginame VARCHAR(50), 
	net_address VARCHAR(30)
)
GO

-- ایجاد تریگر ثبت لاگ تغییرات
CREATE TRIGGER tiJobsLog ON jobs 
FOR INSERT, UPDATE, DELETE 
AS 
BEGIN
	INSERT INTO JobsLog (job_id, job_desc, min_lvl, max_lvl, ActionType) 
		SELECT job_id, job_desc, min_lvl, max_lvl, 'd'
		FROM deleted

	INSERT INTO JobsLog (job_id, job_desc, min_lvl, max_lvl, ActionType) 
		SELECT job_id, job_desc, min_lvl, max_lvl, 'i'
		FROM inserted
END
GO

-- درج داده آزمایشی در جدول jobs
INSERT INTO jobs VALUES ('Test', 100, 200)

-- مشاهده لاگ تغییرات
SELECT * FROM JobsLog

-- به‌روزرسانی یک رکورد جهت تست تریگر
UPDATE jobs SET min_lvl = 50 WHERE job_id = 14

-- بررسی اطلاعات کاربران متصل برای لاگ دقیق‌تر
EXECUTE sp_who
EXECUTE sp_who2
SELECT @@SPID

-- مشاهده نام کاربری و آدرس شبکه درخواست‌دهنده
SELECT loginame, net_address
	FROM SYS.sysprocesses
	WHERE spid = @@SPID
GO



--------------------------------------------------------------------------------------------------------



/* ============================================================
🔁 نسخه تکمیلی تریگر ثبت لاگ روی جدول Jobs با اطلاعات کاربر
===============================================================

📌 در این نسخه از تریگر `tiJobsLog`، علاوه بر اطلاعات رکوردهای تغییر یافته، اطلاعات مربوط به کاربری که عملیات را انجام داده است نیز در لاگ ثبت می‌شود.

🧾 تغییرات مهم:
- استفاده از `CROSS JOIN` با `sys.sysprocesses` برای استخراج:
  - `loginame`: نام کاربری وارد شده به SQL Server
  - `net_address`: آدرس شبکه کلاینت

🔧 نکته مهم:
- از `@@SPID` برای یافتن شناسه نشست جاری استفاده می‌شود تا فقط اطلاعات کاربر همان نشست ثبت شود.
- به این شکل امکان ردیابی دقیق‌تری روی لاگ وجود دارد.

🎯 کاربرد:
- ممیزی و پیگیری عملیات کاربران در سطح دقیق‌تر
- تحلیل امنیتی بر اساس کاربران و دستگاه‌های متصل

*/

-- بروزرسانی تریگر قبلی و اضافه کردن اطلاعات کاربری
CREATE OR ALTER TRIGGER tiJobsLog ON jobs 
FOR INSERT, UPDATE, DELETE 
AS 
BEGIN
	INSERT INTO JobsLog (job_id, job_desc, min_lvl, max_lvl, ActionType, loginame, net_address) 
		SELECT job_id, job_desc, min_lvl, max_lvl, 'd', loginame, net_address
		FROM deleted
		CROSS JOIN (SELECT loginame, net_address
					FROM SYS.sysprocesses
					WHERE spid = @@SPID) AS sp

	INSERT INTO JobsLog (job_id, job_desc, min_lvl, max_lvl, ActionType, loginame, net_address) 
		SELECT job_id, job_desc, min_lvl, max_lvl, 'i', loginame, net_address
		FROM inserted
		CROSS JOIN (SELECT loginame, net_address
					FROM SYS.sysprocesses
					WHERE spid = @@SPID) AS sp
END
GO

-- تست درج اطلاعات جدید
INSERT INTO jobs VALUES ('Test1', 100, 200)

-- نمایش لاگ
SELECT * FROM JobsLog

-- تست بروزرسانی رکورد
UPDATE jobs SET min_lvl = 50 WHERE job_id = 15



--------------------------------------------------------------------------------------------------------



/* ============================================================
📝 تریگر لاگ‌برداری از تغییرات روی جدول Publishers
===============================================================

📌 این تریگر `tiPublishersLog` برای ثبت خودکار تغییرات اعمال شده روی جدول `publishers` طراحی شده است.

📥 عملیات ثبت شده:
- `INSERT` (ورودی جدید)
- `UPDATE` (بروزرسانی)
- `DELETE` (حذف)

📋 ساختار جدول لاگ:
- اطلاعات ناشر
- نوع عملیات (`i`, `d`)
- زمان عملیات
- نام کاربری و آدرس شبکه کاربر

🔍 مزایا:
- رهگیری تغییرات داده‌ها در سطح دقیق
- حفظ سابقه‌ای قابل اعتماد برای تحلیل‌های آینده

⚠️ نکته امنیتی:
- استفاده از `sys.sysprocesses` برای تشخیص اطلاعات نشست فعلی (`@@SPID`)
- قابل توسعه برای ثبت عملیات خاص یا ترکیب با ابزارهای امنیتی

*/

-- ساخت جدول لاگ برای ناشران
CREATE TABLE PublishersLog (
	Id int IDENTITY,
	pub_id char(4) NOT NULL,
	pub_name varchar(40) NULL,
	city varchar(20) NULL,
	state char(2) NULL,
	country varchar(30) NULL,
	ActionType char(1),
	ActionTime datetime DEFAULT GETDATE(),
	loginame VARCHAR(50),
	net_address VARCHAR(30)
)
GO

-- تعریف یا بازنویسی تریگر برای ثبت عملیات در جدول لاگ
CREATE OR ALTER TRIGGER tiPublishersLog ON publishers 
FOR INSERT, UPDATE, DELETE 
AS 
BEGIN
	INSERT INTO PublishersLog (pub_id, pub_name, city, state, country, ActionType, loginame, net_address) 
		SELECT pub_id, pub_name, city, state, country, 'd', loginame, net_address
		FROM deleted
		CROSS JOIN (
			SELECT loginame, net_address
			FROM SYS.sysprocesses
			WHERE spid = @@SPID
		) AS sp

	INSERT INTO PublishersLog (pub_id, pub_name, city, state, country, ActionType, loginame, net_address) 
		SELECT pub_id, pub_name, city, state, country, 'i', loginame, net_address
		FROM inserted
		CROSS JOIN (
			SELECT loginame, net_address
			FROM SYS.sysprocesses
			WHERE spid = @@SPID
		) AS sp
END
GO

-- مثال: بروزرسانی اطلاعات ناشر خاص
UPDATE publishers 
SET city = 'Boston', state = 'MA', country = 'USA' 
WHERE pub_id = '9999'

-- نمایش لاگ ثبت شده
SELECT * FROM PublishersLog
GO



--------------------------------------------------------------------------------------------------------



/* ============================================================
🔁 تریگر ثبت تاریخچه تغییر قیمت در جدول Titles
===============================================================

📌 در این اسکریپت، با استفاده از تریگر `tiPriceLog`، تاریخچه تغییرات قیمت کتاب‌ها در جدول `titles` ذخیره می‌شود.

🧾 جدول لاگ:
- `PriceLog`: ثبت `price` هر کتاب در زمان‌های مختلف، همراه با زمان شروع و پایان

🛠 ساختار تریگر:
- با هر عملیات `INSERT` یا `UPDATE` یا `DELETE` روی جدول `titles`:
  - رکورد قبلی در جدول `PriceLog` به‌روزرسانی می‌شود (`EndTime`)
  - رکورد جدید با قیمت فعلی و `StartTime` ثبت می‌گردد

🎯 کاربردها:
- رهگیری روند قیمت‌گذاری
- تحلیل رفتار فروش بر اساس تغییرات قیمت
- پشتیبان‌گیری تاریخی برای بررسی مشکلات احتمالی

📌 نکته:
- این مدل مناسب برای تحلیل‌های سری زمانی است.
- توصیه می‌شود ستون‌های کلیدی (مثل `title_id`) ایندکس‌گذاری شوند تا عملکرد بهینه بماند.

*/

-- ایجاد جدول ثبت تاریخچه قیمت‌ها
DROP TABLE IF EXISTS PriceLog
GO

CREATE TABLE PriceLog (
	Id int IDENTITY,
	title_id varchar(6) NOT NULL,
	price money,
	StartTime datetime DEFAULT GETDATE(),
	EndTime datetime
)
GO

-- درج اولیه داده‌ها از جدول titles
INSERT INTO PriceLog
SELECT title_id, price, pubdate, NULL
FROM titles
GO

-- تعریف یا بازنویسی تریگر برای ثبت تغییرات قیمت
CREATE OR ALTER TRIGGER tiPriceLog ON titles 
FOR INSERT, UPDATE, DELETE 
AS 
BEGIN 
	-- به‌روزرسانی تاریخ پایان برای قیمت قبلی
	UPDATE PriceLog 
	SET EndTime = GETDATE()
	WHERE EndTime IS NULL 
	AND title_id IN (SELECT title_id FROM deleted)

	-- درج رکورد جدید برای قیمت جاری
	INSERT INTO PriceLog 
	SELECT title_id, price, GETDATE(), NULL
	FROM inserted
END 
GO

-- نمونه تغییر قیمت کتاب
UPDATE titles SET price = 20 WHERE title_id = 'BU1032'

-- نمایش تاریخچه قیمت‌ها
SELECT * FROM PriceLog

-- افزایش قیمت کتاب‌های نوع "business"
UPDATE titles SET price = price * 1.1 
WHERE type = 'business'

-- تغییر ناشر کتاب خاص
UPDATE titles SET pub_id = '0736' WHERE title_id = 'BU1032'
