


/* ============================================================
   🧾 جلسه ۱۸: بررسی Triggerها، System-Versioned Tables، 
               Transactions، Isolation Levels و Cursors
   ============================================================

📌 در این جلسه، موضوعات زیر بررسی و پیاده‌سازی شده‌اند:

1️⃣ **System-Versioned Temporal Tables**
   - معرفی و ایجاد جدول با قابلیت نگهداری تاریخچه
   - بازیابی داده‌های تاریخچه‌ای و خاموش/روشن کردن versioning

2️⃣ **Triggerهای AFTER و INSTEAD OF**
   - ایجاد لاگ برای تغییرات روی جدول‌ها (مثلاً jobs و titles)
   - استفاده از `inserted` و `deleted` در Triggers
   - مدیریت حالت soft-delete و cascade triggers

3️⃣ **Transaction Handling**
   - استفاده از `BEGIN TRANSACTION`, `COMMIT`, و `ROLLBACK`
   - استفاده از `TRY...CATCH` برای مدیریت خطاها در تراکنش‌ها
   - بررسی خطا با `@@ERROR` و پیاده‌سازی `GOTO`

4️⃣ **Transaction Isolation Levels**
   - بررسی سطوح مختلف ایزولیشن (`READ UNCOMMITTED`, `REPEATABLE READ`, `SNAPSHOT` و ...)
   - تفاوت‌ها در قفل‌گذاری، consistency و همزمانی

5️⃣ **Cursors**
   - ساخت Cursorهای ساده و کاربردی
   - استفاده از Cursor برای backup‌گیری، مشاهده داده‌ها، و گزارش‌گیری

6️⃣ **Stored Procedures کاربردی**
   - ایجاد stored procedure برای update و insert با خطایابی
   - پیاده‌سازی دستور Backup به‌صورت داینامیک روی چند دیتابیس

🎯 نکات آموزشی مهم:
- Triggers ابزاری قدرتمند ولی حساس هستند و باید با احتیاط از آن‌ها استفاده شود.
- System-Versioned Tables به شدت برای audit و گزارش‌گیری مفید هستند.
- انتخاب صحیح Isolation Level نقش کلیدی در کارایی و درستی داده‌ها دارد.
- استفاده از Cursorها زمانی مفید است که پردازش رکورد به رکورد ضروری باشد، ولی بهتر است در حجم بالا از Set-based Logic استفاده شود.

*/



--------------------------------------------------------------------



/* ============================================================
   🧍‍♂️ جدول با پشتیبانی از تاریخچه: System-Versioned Temporal Table
   ============================================================

📌 در این بخش، با ویژگی System-Versioned Tables آشنا می‌شویم که به ما اجازه می‌دهد تغییرات رکوردها را در طول زمان ردیابی کنیم.

🔧 ساختار:
- `StartDate` و `EndDate` فیلدهای سیستمی هستند که SQL Server آن‌ها را مدیریت می‌کند.
- گزینه `SYSTEM_VERSIONING = ON` فعال‌سازی تاریخچه‌سازی را انجام می‌دهد.
- رکوردهای قدیمی به‌صورت خودکار در جدول `PersonelHistory` ذخیره می‌شوند.

🎯 کاربردها:
- تحلیل تغییرات در داده‌ها (مثلاً تغییر حقوق پرسنل در بازه زمانی)
- پشتیبان‌گیری منطقی، بازیابی نسخه‌های گذشته و auditing

🛠️ عملیات انجام‌شده:
- درج داده‌های اولیه
- اعمال تغییر حقوق و مشاهده رکورد در جدول تاریخچه‌ای
- افزودن فیلد جدید به جدول اصلی (نیازمند غیرفعال‌سازی موقت versioning)
- حذف جداول پس از پایان تست

📌 نکته پرفورمنسی:
- در جداول با بار بالا، فعال بودن versioning ممکن است موجب کاهش کارایی درج و به‌روزرسانی شود.
- بهتر است از فیلدهای ایندکس شده در WHERE clause برای دسترسی سریع‌تر به تاریخچه استفاده شود.

*/

-- 👇 اجرای کوئری‌ها
CREATE TABLE dbo.Personel
(
	PersonelID int NOT NULL PRIMARY KEY CLUSTERED IDENTITY,
	Name nvarchar(100) NOT NULL,
	AnnualSalary decimal (10,2) NOT NULL,
	StartDate datetime2 GENERATED ALWAYS AS ROW START,
	EndDate datetime2 GENERATED ALWAYS AS ROW END,
	PERIOD FOR SYSTEM_TIME (StartDate, EndDate)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.PersonelHistory));

INSERT INTO Personel (Name, AnnualSalary) VALUES 
('Ali', 12345.34), 
('Taghi', 12345.34), 
('Naghi', 12345.34), 
('Kati', 12345.34);

SELECT * FROM Personel;

UPDATE Personel SET AnnualSalary = AnnualSalary * 1.1 
WHERE PersonelID = 3;

SELECT * FROM PersonelHistory;

ALTER TABLE Personel
ADD IsActive bit;

UPDATE Personel SET IsActive = 1;

ALTER TABLE Personel
SET (SYSTEM_VERSIONING = OFF);

ALTER TABLE Personel
SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.PersonelHistory));

DROP TABLE Personel;
DROP TABLE PersonelHistory;



--------------------------------------------------------------------



/* ============================================================
   💸 به‌روزرسانی خودکار مبلغ فاکتور با استفاده از تریگر
   ============================================================

📌 در این سناریو، ما دو جدول `Invoice` و `InvoiceItem` داریم که برای ثبت فاکتورها و اقلام فاکتور طراحی شده‌اند.

📦 ساختار:
- `Invoice`: اطلاعات کلی فاکتور شامل شناسه مشتری و مبلغ کل
- `InvoiceItem`: اقلام فاکتور شامل تعداد و قیمت هر کالا

🛠️ تریگر `tiInvoiceAmount`:
- این تریگر به صورت **AFTER TRIGGER** برای عملیات `INSERT`, `UPDATE`, `DELETE` روی جدول `InvoiceItem` تعریف شده است.
- در هر عملیات، مبلغ فاکتور (`Amount`) با مجموع `Qty * Price` اقلام افزوده‌شده یا حذف‌شده تنظیم می‌شود.

🎯 مزایا:
- تضمین همگام‌سازی خودکار بین جدول اقلام و جدول فاکتور
- حذف نیاز به محاسبه دستی مبلغ کل فاکتور

⚠️ نکات پرفورمنسی:
- استفاده از `SUM` روی جدول `inserted`/`deleted` با `GROUP BY` عملکرد بهتری نسبت به استفاده مستقیم از `INSERTED.Qty * INSERTED.Price` دارد.
- در حجم داده بالا، پیچیدگی تریگر می‌تواند باعث کاهش سرعت درج/بروزرسانی شود.
- بررسی تکرار اعمال مقادیر روی یک `InvoiceID` در هر `DML` مهم است، مخصوصاً برای `UPDATE`.

*/

DROP TABLE IF EXISTS InvoiceItem;
DROP TABLE IF EXISTS Invoice;

CREATE TABLE Invoice (
	Id int PRIMARY KEY IDENTITY, 
	CustomerID int NOT NULL,
	Date smalldatetime DEFAULT GETDATE(),
	Amount money DEFAULT 0
);

CREATE TABLE InvoiceItem (
	Id int PRIMARY KEY IDENTITY, 
	InvoiceID int FOREIGN KEY REFERENCES Invoice(Id),
	ProductID int NOT NULL,
	Qty tinyint,
	Price int
);

INSERT INTO Invoice (CustomerID) VALUES (1), (34), (23);
SELECT * FROM Invoice;

GO

ALTER TRIGGER tiInvoiceAmount ON InvoiceItem
FOR INSERT, UPDATE, DELETE
AS
BEGIN
	-- اعمال مجموع اقلام اضافه‌شده
	UPDATE Invoice SET Amount += ItemAmount
	FROM Invoice
	INNER JOIN (
		SELECT InvoiceID, SUM(Qty * Price) AS ItemAmount
		FROM inserted
		GROUP BY InvoiceID
	) AS inserted ON inserted.InvoiceID = Invoice.Id;

	-- حذف مجموع اقلام حذف‌شده
	UPDATE Invoice SET Amount -= ItemAmount
	FROM Invoice
	INNER JOIN (
		SELECT InvoiceID, SUM(Qty * Price) AS ItemAmount
		FROM deleted
		GROUP BY InvoiceID
	) AS deleted ON deleted.InvoiceID = Invoice.Id;
END
GO

-- 🧪 تست تریگر با عملیات مختلف
INSERT INTO InvoiceItem (InvoiceID, ProductID, Qty, Price) VALUES (1, 234, 2, 450000);
INSERT INTO InvoiceItem (InvoiceID, ProductID, Qty, Price) VALUES (1, 27, 4, 100000);
INSERT INTO InvoiceItem (InvoiceID, ProductID, Qty, Price) VALUES (2, 27, 4, 100000);

UPDATE InvoiceItem SET Qty = 2 WHERE InvoiceID = 1 AND ProductID = 27;

INSERT INTO InvoiceItem (InvoiceID, ProductID, Qty, Price) VALUES 
(3, 27, 4, 100000), 
(3, 207, 1, 150000), 
(3, 75, 1, 400000), 
(3, 276, 3, 600000);

SELECT * FROM Invoice;



--------------------------------------------------------------------



/* =============================================================
   🔁 تریگر INSTEAD OF برای کنترل کامل بروزرسانی‌ها
   =============================================================

📌 در این مثال، یک تریگر از نوع `INSTEAD OF` برای جدول `titles` تعریف شده که به‌جای اجرای مستقیم عملیات `UPDATE`، ابتدا مقادیر جدید و قدیم را بررسی می‌کند.

🔍 هدف:
- نمایش رکوردهای `inserted` (مقدار جدید) و `deleted` (مقدار قدیم) هنگام بروزرسانی
- معمولاً به‌منظور کنترل دقیق، اعتبارسنجی داده‌ها، یا تغییر منطق قبل از اعمال تغییرات استفاده می‌شود.

🛠️ ساختار:
- `INSTEAD OF` به SQL Server می‌گوید که عملیات اصلی (`UPDATE`) را اجرا نکند و در عوض تریگر اجرا شود.

⚠️ نکته مهم:
- اگر در تریگر `INSTEAD OF` عملیات بروزرسانی واقعی انجام نشود، تغییرات اعمال نخواهند شد.
- در این نمونه، چون هیچ `UPDATE` در بدنه تریگر وجود ندارد، `price` تغییری نخواهد کرد.

🎯 کاربردهای دیگر:
- زمانی که محدودیت‌های خاص یا قوانین سفارشی برای بروزرسانی دارید.
- ترکیب با اعتبارسنجی‌ها و منطق شرطی پیچیده.

*/

CREATE OR ALTER TRIGGER tiTitlesUpdate ON titles
INSTEAD OF UPDATE 
AS
BEGIN 
	-- 👀 نمایش مقادیر جدید (inserted) و قدیم (deleted)
	SELECT * FROM inserted;
	SELECT * FROM deleted;
END
GO

-- 📈 تلاش برای بروزرسانی قیمت‌ها (موفق نخواهد بود مگر اینکه در تریگر اعمال شود)
UPDATE titles SET price = price * 1.1;



--------------------------------------------------------------------



/* =============================================================
   ❌ تریگر INSTEAD OF برای حذف نرم (Soft Delete)
   =============================================================

📌 در این اسکریپت یک تریگر `INSTEAD OF DELETE` روی جدول `JobDel` پیاده‌سازی شده تا به جای حذف فیزیکی رکوردها، فقط فلگ `IsDeleted` را به 1 تغییر دهد.

🧾 مراحل:
1. جدول `JobDel` از جدول `Jobs` ساخته شده و ستون جدیدی به نام `IsDeleted` به آن اضافه شده.
2. تریگر `tiJobDelete` ایجاد شده تا عملیات حذف را تغییر دهد و به جای `DELETE` واقعی، مقدار `IsDeleted` را به 1 تنظیم کند.
3. حذف نرم روی رکوردهایی که `job_id > 14` انجام شده.
4. امکان فیلتر و بازیابی رکوردهای حذف‌شده با استفاده از فیلد `IsDeleted`.

📋 مزایا:
- حفظ تاریخچه داده‌ها بدون حذف فیزیکی.
- امکان بازیابی داده‌ها در آینده.
- کاربردی برای ساخت سیستم‌هایی با آرشیو، لاگ، یا قابلیت "Undo".

⚠️ نکات پرفورمنسی:
- در گزارش‌گیری‌ها همیشه باید شرط `IsDeleted = 0` لحاظ شود.
- ممکن است در جداول بزرگ منجر به رشد داده‌های غیرضروری شود مگر اینکه مرتباً پاک‌سازی شود.

*/

-- ایجاد نسخه‌ای از جدول Jobs با ستون Soft Delete
SELECT *, CAST(0 AS bit) AS IsDeleted
INTO JobDel
FROM Jobs;

-- ایجاد تریگر حذف نرم
CREATE TRIGGER tiJobDelete ON JobDel
INSTEAD OF DELETE
AS
BEGIN
	UPDATE JobDel
	SET IsDeleted = 1
	WHERE job_id IN (SELECT job_id FROM deleted);
END;
GO

-- حذف نرم روی رکوردهایی با job_id > 14
DELETE JobDel WHERE job_id > 14;

-- نمایش همه رکوردها
SELECT * FROM JobDel;

-- نمایش فقط رکوردهای فعال (حذف نشده)
SELECT * FROM JobDel WHERE IsDeleted = 0;

-- بازیابی رکوردهای حذف‌شده (تغییر فلگ به 0)
UPDATE JobDel SET IsDeleted = 0 WHERE job_id BETWEEN 11 AND 14;



--------------------------------------------------------------------



/* =============================================================
   🔁 نسخه پیشرفته‌تر تریگر حذف نرم (Soft Delete) با بررسی وضعیت
   =============================================================

📌 در این نسخه از تریگر `tiJobDelete`، ابتدا بررسی می‌شود که آیا رکورد قبلاً حذف شده بوده یا نه:
- اگر قبلاً حذف شده باشد (`IsDeleted = 1`)، رکورد واقعاً از جدول پاک می‌شود.
- اگر هنوز حذف نشده باشد (`IsDeleted = 0`)، فقط فلگ `IsDeleted` فعال می‌شود.

🧾 مزایا:
- امکان حذف کامل رکوردهایی که قبلاً حذف نرم شده‌اند.
- کنترل دقیق‌تر روی عملیات حذف.
- مدیریت موثرتر داده‌های آرشیوی.

🔄 روند تریگر:
1. `DELETE` از رکوردهایی که از قبل `IsDeleted = 1` داشته‌اند.
2. `UPDATE` رکوردهایی که هنوز حذف نشده‌اند، و تبدیل آنها به حالت حذف نرم (`IsDeleted = 1`).

⚠️ نکات پرفورمنسی:
- بهتر است فیلد `IsDeleted` ایندکس شود تا عملیات حذف سریع‌تر شود.
- این تریگر نیاز به بررسی دقیق در محیط‌های تولیدی دارد تا از حذف ناخواسته داده جلوگیری شود.

*/

CREATE OR ALTER TRIGGER tiJobDelete ON JobDel
INSTEAD OF DELETE
AS
BEGIN 
	-- حذف کامل رکوردهایی که قبلاً حذف نرم شده‌اند
	DELETE JobDel 
	WHERE job_id IN (SELECT job_id FROM deleted) 
	  AND IsDeleted = 1;

	-- انجام حذف نرم روی رکوردهایی که هنوز فعال هستند
	UPDATE JobDel 
	SET IsDeleted = 1
	WHERE job_id IN (SELECT job_id FROM deleted);
END;
GO

-- اجرای عملیات حذف (که اکنون به صورت شرطی انجام می‌شود)
DELETE JobDel WHERE job_id > 14;



--------------------------------------------------------------------



/*

	BEGIN TRANSACTION 
		.
		.
		.
		.
		.
		COMMIT
		ROLLBACK

*/



/* =============================================================
   🔁 ساختار پایه تراکنش در SQL Server
   =============================================================

📌 در این بخش، قالب کلی اجرای تراکنش‌ها با استفاده از دستورات `BEGIN TRANSACTION`, `COMMIT`, و `ROLLBACK` نمایش داده شده است.

🧩 ساختار کلی:
- `BEGIN TRANSACTION`: شروع تراکنش
- ... انجام عملیات مختلف مانند INSERT/UPDATE/DELETE
- `COMMIT`: در صورت موفقیت‌آمیز بودن همه مراحل، اعمال تغییرات
- `ROLLBACK`: در صورت وقوع خطا یا شرایط خاص، بازگرداندن تمامی تغییرات

🎯 کاربرد:
- تضمین یکپارچگی داده‌ها
- کنترل دقیق بر اجرای گروهی از دستورات
- جلوگیری از اعمال ناقص و ناخواسته تغییرات

🛡 نکات امنیتی و پرفورمنسی:
- بررسی دقیق شرط‌های اجرای COMMIT یا ROLLBACK الزامی است.
- استفاده از TRY...CATCH برای مدیریت بهتر خطاها توصیه می‌شود.
- بررسی وضعیت تراکنش با `@@TRANCOUNT` پیش از `COMMIT` یا `ROLLBACK` مفید است.

*/

BEGIN TRANSACTION
	-- عملیات‌های حساس و مهم مانند:
	-- UPDATE titles SET price = price * 1.1
	-- DELETE FROM jobs WHERE job_id > 20

	-- در ادامه با شرایط مورد نظر بررسی و انتخاب بین COMMIT و ROLLBACK
	-- IF (شرط صحیح) COMMIT ELSE ROLLBACK
COMMIT -- یا ROLLBACK بر اساس منطق کسب‌وکار



--------------------------------------------------------------------



/* =============================================================
   📉 مدیریت تراکنش با استفاده از شرط بر اساس میانگین قیمت
   =============================================================

📌 در این بخش، ابتدا با بررسی میانگین قیمت کتاب‌ها (`AVG(price)`) تصمیم‌گیری برای اجرای یا لغو تراکنش انجام می‌شود.

📦 مراحل:
1. بررسی تراکنش‌های باز با `DBCC OPENTRAN`
2. استفاده از `KILL` برای پایان دادن به تراکنش‌های مزاحم در صورت نیاز
3. ذخیره میانگین قیمت در یک متغیر (`@avg`)
4. آغاز تراکنش با `BEGIN TRANSACTION`
5. اجرای `UPDATE` بر روی جدول `titles`
6. تصمیم‌گیری بین `COMMIT` و `ROLLBACK` بر اساس مقدار `@avg`

🎯 کاربرد:
- کنترل پویای تراکنش‌ها بر اساس شرایط بیزینسی
- جلوگیری از افزایش قیمت غیر منطقی

⚙️ نکات پرفورمنسی و امنیتی:
- استفاده از متغیر پیش از آغاز تراکنش باعث حفظ atomicity نیست؛ بهتر است مقدار `AVG(price)` پس از `BEGIN TRANSACTION` استخراج شود.
- از متغیر مستقل از داده‌های جاری استفاده نشود مگر در شرایط پایدار.
- بررسی تراکنش‌های باز با `DBCC OPENTRAN` تنها برای عیب‌یابی است، در برنامه عملیاتی استفاده نشود.

*/

DBCC OPENTRAN
KILL 64  -- فقط برای اهداف آزمایشی، مراقب استفاده باشید

DECLARE @avg money = (SELECT AVG(price) FROM titles)
--SELECT IIF( @avg > 17 , 'ROLLBACK' , 'COMMIT')
BEGIN TRANSACTION 
	UPDATE titles SET price = price * 1.1
	IF @avg > 17
		ROLLBACK
	ELSE
		COMMIT

SELECT AVG(price)
	FROM titles



--------------------------------------------------------------------



/* =============================================================
   🛡️ مدیریت تراکنش با بلاک‌های TRY...CATCH در SQL Server
   =============================================================

📌 در این مثال، دو عملیات `UPDATE` درون یک تراکنش تحت نظر بلوک `TRY...CATCH` اجرا می‌شود.

📦 مراحل اجرای کوئری:
1. شروع تراکنش با `BEGIN TRANSACTION`
2. اجرای چند دستور در بلوک `TRY`
3. اگر همه دستورات موفق بودند: `COMMIT`
4. اگر خطایی رخ دهد: `ROLLBACK` در `CATCH`
5. تعریف متغیر برای ذخیره کد خطا (در این بخش هنوز استفاده نشده)

🧩 مزایا:
- حفظ atomicity (اتمی بودن تراکنش)
- مدیریت حرفه‌ای خطاها در اجرای کوئری‌های حساس

⚙️ نکات پرفورمنسی و امنیتی:
- استفاده از `TRY...CATCH` در تراکنش‌های حساس به خطا توصیه می‌شود.
- برای ثبت دقیق‌تر خطاها می‌توان از توابع سیستمی مثل `ERROR_MESSAGE()`, `ERROR_LINE()` و ... در `CATCH` استفاده کرد.
- تغییر کلیدهای اصلی مانند `pub_id` اگر محدودیت‌های Foreign Key داشته باشد ممکن است باعث خطا شود.

*/

BEGIN TRANSACTION 
	BEGIN TRY
		UPDATE titles SET price = price * 1.1
		UPDATE publishers SET pub_id = '0000'
		COMMIT
	END TRY
	BEGIN CATCH
		ROLLBACK
	END CATCH

DECLARE @intErrorCode int;



--------------------------------------------------------------------



/* =============================================================
   🛠️ مدیریت تراکنش با استفاده از GOTO و بررسی مستقیم خطا
   =============================================================

📌 در این ساختار از کنترل خطا بدون استفاده از `TRY...CATCH` و با تکیه بر `@@ERROR` و دستور `GOTO` استفاده شده است.

📦 ساختار اجرای کوئری:
1. آغاز تراکنش با `BEGIN TRANSACTION`
2. اجرای یک یا چند `UPDATE`
3. بررسی مقدار `@@ERROR` بعد از هر دستور
4. در صورت بروز خطا: انتقال کنترل با `GOTO PROBLEM`
5. اگر بدون خطا: اجرای `COMMIT`
6. در بخش `PROBLEM`: چاپ پیام خطا و `ROLLBACK`

📌 `@@ERROR`: وضعیت اجرای دستور قبلی را بررسی می‌کند. اگر 0 باشد، خطایی رخ نداده است.

⚠️ نکات مهم:
- این روش سنتی و قدیمی‌تر است و امروزه استفاده از `TRY...CATCH` توصیه می‌شود.
- استفاده از `GOTO` می‌تواند خوانایی کد را کاهش دهد، اما در برخی ساختارها برای کنترل شرطی دقیق همچنان کاربرد دارد.

*/

BEGIN TRANSACTION
	UPDATE Authors SET Phone = '415 354-9866ASDASDASDASDASDASDASDASDASD'
			WHERE au_id = '724-80-9391'

	SET @intErrorCode = @@ERROR
	IF (@intErrorCode <> 0) 
		GOTO PROBLEM

	UPDATE Publishers SET city = 'Tehran', country = 'Iran'
			WHERE pub_id = '9999'

	SET @intErrorCode = @@ERROR
	IF (@intErrorCode <> 0) 
		GOTO PROBLEM

	COMMIT TRANSACTION

PROBLEM:
IF (@intErrorCode <> 0) 
BEGIN
	PRINT 'Unexpected error occurred!'
	ROLLBACK TRAN
END



--------------------------------------------------------------------



/* ==========================================================
   ⚖️ اجرای تراکنش همراه با کنترل خطا توسط TRY...CATCH
   ==========================================================

📌 در این کوئری، از ساختار مدرن `TRY...CATCH` برای مدیریت تراکنش‌ها استفاده شده است. دو عملیات `UPDATE` پشت سر هم اجرا می‌شوند و در صورت وقوع خطا در هرکدام، کل تراکنش بازگردانده می‌شود (rollback).

🧩 گام‌ها:
1. آغاز تراکنش با `BEGIN TRANSACTION`
2. اجرای دو عملیات `UPDATE`
3. در صورت موفقیت هر دو، اجرای `COMMIT`
4. در صورت بروز خطا در هرکدام، اجرا وارد بخش `CATCH` شده و `ROLLBACK` انجام می‌شود

🎯 مزایا:
- جلوگیری از اعمال ناقص تغییرات در پایگاه داده
- افزایش پایداری و یکپارچگی داده‌ها
- ساده‌تر و قابل فهم‌تر نسبت به استفاده از `GOTO`

🚨 نکته:
- در صورت رخ دادن خطا در `UPDATE Authors`، تغییرات قبلی در `UPDATE Publishers` نیز برگشت داده می‌شود.
- دستور `PRINT` می‌تواند در بخش `CATCH` برای ثبت لاگ یا بازخورد سریع استفاده شود.

*/

BEGIN TRANSACTION 
	BEGIN TRY
		UPDATE Publishers SET city = 'Tehran', country = 'Iran'
				WHERE pub_id = '9999'
		UPDATE Authors SET Phone = '415 354-986NGKJHKJHKJHKJHKJHKJHKJ'
				WHERE au_id = '724-80-9391'
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
			PRINT 'Unexpected error occurred!'
			ROLLBACK TRAN
	END CATCH

-- نمایش مقدار نهایی جدول ناشران برای بررسی اعمال شدن تغییرات
SELECT * 
	FROM publishers
	WHERE pub_id = '9999'



--------------------------------------------------------------------



/* ================================================================
   📊 تراکنش شرطی مبتنی بر حجم فروش
   ================================================================

📌 در این کوئری یک تراکنش ساده بر اساس نتیجه‌ی شرطی از جدول فروش اجرا می‌شود. اگر تعداد رکوردهای جدول `sales` بیش از ۵۰ باشد، عملیات به‌روزرسانی قیمت اعمال و تایید می‌شود؛ در غیر این صورت، تغییرات لغو می‌شوند.

🔁 گام‌ها:
1. آغاز تراکنش با `BEGIN TRANSACTION`
2. به‌روزرسانی قیمت کتاب‌ها در جدول `titles`
3. بررسی شرط: اگر تعداد فروش‌ها بیش از ۵۰ باشد، `COMMIT` انجام شود؛ در غیر این صورت، `ROLLBACK`

🎯 کاربرد:
- جلوگیری از تغییرات ناخواسته در شرایط خاص
- اجرای شرطی عملیات سنگین یا حساس

⚠️ نکته مهم:
- اگر شرط `COUNT(*) > 50` برقرار نباشد، همه تغییرات به حالت اولیه بازمی‌گردند.
- عدم استفاده از کنترل خطا (`TRY...CATCH`) ممکن است در صورت خطای غیرمنتظره باعث باقی‌ماندن تراکنش باز شود.

*/

BEGIN TRANSACTION 
	UPDATE titles SET price = price *  1.1
	IF (SELECT COUNT(*) FROM sales ) > 50
		COMMIT
	ELSE 
		ROLLBACK



--------------------------------------------------------------------



/* ================================================================
   📊 تراکنش شرطی بر اساس میانگین قیمت
   ================================================================

📌 در این تراکنش، ابتدا قیمت کتاب‌ها در جدول `titles` افزایش می‌یابد و سپس میانگین قیمت بررسی می‌شود. اگر میانگین قیمت جدید بیشتر از ۱۷ باشد، تغییرات تأیید می‌شوند (`COMMIT`)، در غیر این صورت بازگردانده می‌شوند (`ROLLBACK`).

🔁 مراحل اجرای تراکنش:
1. آغاز تراکنش با `BEGIN TRANSACTION`
2. افزایش قیمت همه کتاب‌ها
3. بررسی شرط: آیا میانگین قیمت از ۱۷ بیشتر شده است؟
4. تأیید یا بازگرداندن تراکنش
5. بررسی وضعیت تراکنش با `@@TRANCOUNT`

🎯 کاربرد:
- اعمال سیاست‌های قیمت‌گذاری کنترل‌شده
- اجرای تصمیمات حساس با شرط‌های عددی

🔧 نکات پرفورمنسی:
- استفاده از `AVG(price)` پس از تغییر، کارایی مناسبی دارد چون فقط روی یک ستون عمل می‌کند.
- استفاده از `@@TRANCOUNT` برای اطمینان از وضعیت فعلی تراکنش مفید است.

*/

BEGIN TRANSACTION 
	UPDATE titles SET price = price *  1.1
	IF (SELECT AVG(price) FROM titles ) > 17
		COMMIT
	ELSE 
		ROLLBACK

SELECT AVG(price) FROM titles

TEST:
SELECT 'HELLO'

SELECT @@TRANCOUNT



--------------------------------------------------------------------



/* ================================================================
   🔁 بررسی IMPLICIT_TRANSACTIONS و مدیریت تراکنش‌های پنهان
   ================================================================

📌 در این اسکریپت، ویژگی `IMPLICIT_TRANSACTIONS` فعال شده تا بررسی شود که چگونه تراکنش‌ها بدون نیاز به `BEGIN TRANSACTION` به‌طور خودکار شروع می‌شوند.

🎯 سناریو:
- به‌محض اجرای یک کوئری DML (مانند `UPDATE`)، یک تراکنش شروع می‌شود.
- باید صراحتاً با `COMMIT` یا `ROLLBACK` تراکنش را پایان دهیم.
- بدون این دستورات، تراکنش باز می‌ماند که ممکن است باعث قفل یا خطا شود.

🧪 اجرای سه تراکنش:
1. تغییر موفقیت‌آمیز و تأیید (`COMMIT`)
2. تغییر و لغو (`ROLLBACK`)
3. تغییر موفقیت‌آمیز و تأیید (`COMMIT`)

🔧 نکات مهم:
- فعال بودن این ویژگی باعث افزایش کنترل می‌شود، اما برای مبتدیان ممکن است گیج‌کننده باشد.
- در سناریوهای بحرانی (مالی، پزشکی،...) استفاده از این ویژگی باعث کاهش ریسک اشتباه می‌شود.

*/

SET IMPLICIT_TRANSACTIONS ON;
--Transaction 1:
UPDATE authors SET au_lname = 'Black'	
	WHERE au_id = '172-32-1176'; 
COMMIT;

--Transaction 2:
UPDATE authors SET au_lname = 'Voyer'	 
	WHERE au_id = '213-46-8915'; 
ROLLBACK;

--Transaction 3:
UPDATE authors SET au_lname = 'Peterson' 
	WHERE au_id = '238-95-7766';
COMMIT;

SET IMPLICIT_TRANSACTIONS OFF;

-- بررسی نتیجه‌ی تراکنش‌ها:
SELECT au_id , au_fname , au_lname 
	FROM authors 
	WHERE au_id IN ('172-32-1176','213-46-8915','238-95-7766');



-------------------------------------------------------------------------------



/* ================================================================
   🔍 تست سطح ایزولیشن READ UNCOMMITTED و اثرات Phantom/Dirty Read
   ================================================================

📌 در این سناریو، بررسی می‌کنیم که سطح ایزولیشن `READ UNCOMMITTED` چگونه اجازه می‌دهد داده‌هایی را بخوانیم که هنوز در تراکنش تأیید (Commit) نشده‌اند.

🎯 گام‌های کلیدی:
1. اجرای یک تراکنش که در آن مقدار `au_lname` به `'TT'` تغییر می‌کند ولی در نهایت `ROLLBACK` می‌شود.
2. در این بین، از یک نشست دیگر با سطح ایزولیشن `READ UNCOMMITTED` داده خوانده می‌شود.

🧪 هدف:
- اثبات اینکه کوئری خواننده می‌تواند مقدار تغییر یافته را قبل از `ROLLBACK` ببیند، که به آن *Dirty Read* می‌گویند.

⚠️ هشدار:
- این سطح ایزولیشن سریع است ولی ممکن است باعث بروز تناقض داده‌ها شود.
- مناسب برای گزارش‌گیری‌های سریع بدون نیاز به دقت بالا.

*/

BEGIN TRANSACTION
	UPDATE authors SET au_lname = 'TT' WHERE au_id = '172-32-1176'
	WAITFOR DELAY '00:00:10'
ROLLBACK


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SELECT * 
		FROM authors
		WHERE au_id = '172-32-1176'


--------------------------------------------------------------------------------



/* ================================================================
   🔐 تست سطح ایزولیشن READ COMMITTED و جلوگیری از Dirty Read
   ================================================================

📌 این سناریو بررسی می‌کند که چگونه سطح ایزولیشن `READ COMMITTED` مانع خواندن داده‌هایی می‌شود که هنوز Commit نشده‌اند.

🎯 مراحل:
1. در یک تراکنش مقدار `au_lname` برای یک نویسنده خاص تغییر می‌کند و با `WAITFOR DELAY`، تراکنش نگه‌ داشته می‌شود.
2. در یک پنجره‌ی دیگر، کوئری با سطح ایزولیشن `READ COMMITTED` اجرا می‌شود.

🧪 نتیجه مورد انتظار:
- تا زمانی که تراکنش اول `COMMIT` یا `ROLLBACK` نشود، تراکنش دوم داده را نمی‌بیند یا منتظر می‌ماند.
- این مانع از *Dirty Read* می‌شود.

💡 کاربرد:
- مناسب برای کاربردهایی که تعادل بین همزمانی (concurrency) و سازگاری (consistency) لازم دارند.

*/

BEGIN TRANSACTION
	UPDATE authors SET au_lname = 'Black' WHERE au_id = '172-32-1176'
	WAITFOR DELAY '00:00:10'
ROLLBACK


SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	SELECT * 
		FROM authors
		WHERE au_id = '172-32-1176'



--------------------------------------------------------------------------------



/* ================================================================
   🔄 بررسی رفتار RE-READ در سطح ایزولیشن READ COMMITTED
   ================================================================

📌 این بخش رفتار سطح ایزولیشن `READ COMMITTED` را هنگام اجرای چندین بار خواندن روی یک داده در یک تراکنش بررسی می‌کند.

🧪 مراحل آزمایش:
1. آغاز تراکنش با `READ COMMITTED`
2. دو بار خواندن رکورد مشخص (با تأخیر بین آنها)
3. بررسی اینکه آیا مقدار خوانده شده تغییر کرده است یا خیر.

🎯 هدف:
- بررسی وجود یا عدم وجود پدیده‌ای به نام *non-repeatable read* (خواندن غیرقابل تکرار)

💡 نکته:
- در `READ COMMITTED` اگر بین دو بار خواندن، تراکنش دیگری مقدار رکورد را تغییر داده و COMMIT کرده باشد، مقدار دوم ممکن است متفاوت باشد.

*/

SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
		SELECT * FROM authors 
			WHERE au_id = '172-32-1176'
		WAITFOR DELAY '00:00:10'
		SELECT * FROM authors 
			WHERE au_id = '172-32-1176'
ROLLBACK

-- اعمال تغییر نهایی جهت آزمایش مجدد در سناریوهای دیگر
UPDATE authors SET au_lname = 'tt' WHERE au_id = '172-32-1176'



---------------------------------------------------------------------------------



/* ================================================================
   🔒 جلوگیری از Non-Repeatable Read با REPEATABLE READ
   ================================================================

📌 در این کوئری، رفتار سطح ایزولیشن `REPEATABLE READ` بررسی می‌شود تا تضمین کند داده‌ای که یک‌بار خوانده شده، در همان تراکنش بدون تغییر باقی بماند.

🔍 سناریو:
1. اجرای SELECT برای خواندن یک رکورد از جدول authors
2. انتظار با `WAITFOR DELAY` برای شبیه‌سازی تداخل هم‌زمان
3. اجرای دوباره SELECT برای بررسی ثبات مقدار
4. تراکنش ROLLBACK می‌شود

⚠️ سطح ایزولیشن `REPEATABLE READ` اجازه نمی‌دهد رکورد خوانده‌شده توسط تراکنش دیگر **تغییر** یا **حذف** شود تا پایان تراکنش فعلی.

*/

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
BEGIN TRANSACTION
		SELECT * FROM authors 
			WHERE au_id = '172-32-1176'
		WAITFOR DELAY '00:00:10'
		SELECT * FROM authors 
			WHERE au_id = '172-32-1176'
ROLLBACK

-- تنظیم مجدد مقدار فیلد پس از آزمایش
UPDATE authors SET au_lname = 'Black' WHERE au_id = '172-32-1176'



---------------------------------------------------------------------------------



/* ================================================================
   🧱 تست تأثیر سطح ایزولیشن REPEATABLE READ روی انسرت‌ها
   ================================================================

📌 در این سناریو، بررسی می‌شود که آیا در سطح ایزولیشن `REPEATABLE READ`، امکان درج ردیف جدید در جدول مورد نظر (jobs) وجود دارد یا خیر.

🔍 مراحل اجرا:
1. اجرای یک تراکنش با `REPEATABLE READ` برای شمارش ردیف‌های جدول jobs
2. وقفه‌ی ۱۰ ثانیه‌ای برای ایجاد زمان‌بندی جهت آزمایش تداخل
3. اجرای مجدد COUNT جهت بررسی پایداری داده‌ها در طول تراکنش
4. پس از ROLLBACK، یک INSERT در خارج از تراکنش صورت می‌گیرد

📌 سطح ایزولیشن `REPEATABLE READ` تضمین می‌کند ردیف‌های خوانده شده تغییر نکنند، اما **جلوگیری از درج ردیف‌های جدیدی که قبلاً وجود نداشته‌اند** نمی‌کند (برای این منظور باید از SERIALIZABLE استفاده شود).

*/

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
BEGIN TRANSACTION
		SELECT COUNT(*) FROM jobs
		WAITFOR DELAY '00:00:10'
		SELECT COUNT(*) FROM jobs 
ROLLBACK

-- درج ردیف جدید در جدول jobs پس از پایان تراکنش
INSERT INTO jobs VALUES ('DBA' , 150 , 250)



---------------------------------------------------------------------------------



/* ================================================================
   🧊 بررسی سطح ایزولیشن SERIALIZABLE و تأثیر آن بر Phantom Reads
   ================================================================

📌 این اسکریپت تأثیر سطح ایزولیشن `SERIALIZABLE` را بر جلوگیری از درج ردیف‌های جدید در بازه‌ای که تحت تراکنش بررسی شده، ارزیابی می‌کند.

🔍 مراحل:
1. شروع تراکنش با سطح `SERIALIZABLE`
2. اجرای `SELECT COUNT(*)` روی جدول `jobs`
3. ایجاد تأخیر ۱۰ ثانیه‌ای (برای امکان اجرای همزمان دستورات دیگر)
4. اجرای مجدد شمارش برای بررسی ثبات نتایج
5. در نهایت، ROLLBACK برای حفظ وضعیت پایگاه داده

📌 سپس، پس از پایان تراکنش، یک `INSERT` صورت می‌گیرد.

🎯 سطح ایزولیشن `SERIALIZABLE` باعث می‌شود دیگر تراکنش‌ها تا پایان تراکنش فعلی نتوانند ردیف جدیدی در بازه انتخابی درج کنند. این سطح سختگیرانه‌ترین نوع ایزولیشن است.

*/

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
BEGIN TRANSACTION
		SELECT COUNT(*) FROM jobs
		WAITFOR DELAY '00:00:10'
		SELECT COUNT(*) FROM jobs 
ROLLBACK

-- پس از پایان تراکنش، درج ردیف جدید
INSERT INTO jobs VALUES ('DBA' , 150 , 250)



---------------------------------------------------------------------------------



/* ============================================================
   📸 بررسی Snapshot Isolation در SQL Server
   ============================================================

📌 در این بخش، سطح ایزولیشن `SNAPSHOT` مورد بررسی قرار می‌گیرد، که از طریق `ALTER DATABASE` فعال شده است. این سطح ایزولیشن نسخه‌ای از داده‌ها را برای هر تراکنش حفظ می‌کند که از آن به عنوان *Version Store* یاد می‌شود.

🧪 روند اجرا:
1. فعال‌سازی قابلیت `ALLOW_SNAPSHOT_ISOLATION` روی دیتابیس `pubs`
2. تنظیم ایزولیشن تراکنش بر روی `SNAPSHOT`
3. شروع یک تراکنش که دو بار تعداد ردیف‌ها در جدول `jobs` را بررسی می‌کند.
4. بین این دو کوئری تأخیری ایجاد شده تا امکان اجرای تغییرات موازی فراهم شود.
5. در نهایت، تراکنش بازگردانده می‌شود (ROLLBACK).

🎯 ویژگی مهم Snapshot Isolation:
- باعث می‌شود تراکنش در زمان شروع، نمایی ثابت (Consistent View) از داده‌ها داشته باشد.
- از بروز پدیده‌های **Dirty Read** و **Phantom Read** جلوگیری می‌کند، بدون ایجاد قفل روی رکوردهای خوانده‌شده.

*/

ALTER DATABASE pubs
SET ALLOW_SNAPSHOT_ISOLATION ON

SET TRANSACTION ISOLATION LEVEL SNAPSHOT
BEGIN TRANSACTION
		SELECT COUNT(*) FROM jobs
		WAITFOR DELAY '00:00:15'
		SELECT COUNT(*) FROM jobs 
ROLLBACK

-- درج یک ردیف جدید پس از پایان تراکنش snapshot
INSERT INTO jobs VALUES ('DBA' , 150 , 250)



-------------------------------------------------------------------------------------



/* ============================================================
   🔢 درج کنترل‌شده رکورد با استفاده از IDENTITY_INSERT
   ============================================================

📌 در این بخش، نحوه درج رکورد جدید با مقدار خاص برای ستون `IDENTITY` مورد بررسی قرار می‌گیرد. در حالت عادی، مقدار ستون‌های IDENTITY توسط SQL Server تولید می‌شود، اما در صورت نیاز می‌توان با فعال‌سازی `IDENTITY_INSERT`، مقدار آن را به صورت دستی مشخص کرد.

🔍 مراحل:
1. دریافت آخرین `job_id` از جدول `jobs`.
2. ایجاد تأخیر ۱۵ ثانیه‌ای با `WAITFOR DELAY` (جهت شبیه‌سازی تأخیر یا ایجاد همزمانی).
3. فعال‌سازی `IDENTITY_INSERT` برای جدول.
4. درج رکورد جدید با `job_id` دلخواه.
5. غیرفعال‌سازی `IDENTITY_INSERT` پس از پایان درج.

🎯 کاربرد:
- انتقال داده‌ها بین دیتابیس‌ها با حفظ شناسه‌ها
- بازیابی داده‌های حذف‌شده با شناسه اصلی

*/

DECLARE @Id INT 
SET @Id = (SELECT MAX(job_id) FROM jobs)
WAITFOR DELAY '00:00:15'
SET IDENTITY_INSERT jobs ON
INSERT INTO jobs (job_id , job_desc , min_lvl , max_lvl) 
VALUES (@Id + 1 , 'BI Devloper' , 150 , 250 )
SET IDENTITY_INSERT jobs OFF
GO



-------------------------------------



/* ================================================================
   🧾 ساخت پروسیجر با کنترل تراکنش و مدیریت خطا
   ================================================================

📌 این اسکریپت یک stored procedure به نام `spJobsInsert` تعریف می‌کند که هدف آن درج یک شغل جدید در جدول `jobs` و بروزرسانی جدول `titles` برای نوع 'business' است، به‌گونه‌ای که همه این عملیات‌ها در یک تراکنش انجام می‌شوند.

🧩 اجزای اصلی:
- `SET TRANSACTION ISOLATION LEVEL SERIALIZABLE`: بالاترین سطح ایزولیشن برای جلوگیری از تداخل داده‌ها
- `BEGIN TRY ... END TRY` و `BEGIN CATCH ... END CATCH`: برای کنترل خطاها و حفظ انسجام داده‌ها
- استفاده از پارامتر خروجی `@Message` برای ارسال پیام موفقیت یا خطای اجرا

🎯 کاربرد:
- اطمینان از اجرای اتمیک چند عملیات
- مدیریت خطا به شکل ساخت‌یافته در رویه‌های ذخیره‌شده

*/

CREATE PROCEDURE spJobsInsert (@Message NVARCHAR(MAX) OUTPUT)
AS
BEGIN

		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
		BEGIN TRANSACTION 
				BEGIN TRY
					INSERT INTO jobs ( job_desc , min_lvl , max_lvl) VALUES ( 'BI Devloper' , 150 , 250 ) 
					UPDATE titles SET pub_id = '5' WHERE type = 'business'
					SET @Message = 'Done!!'
					COMMIT
				END TRY
				BEGIN CATCH
					SET @Message = CAST( ERROR_LINE() AS nvarchar) + ' ; ' + ERROR_MESSAGE() 
					ROLLBACK
				END CATCH

END
GO

DECLARE @M NVARCHAR(MAX)
EXECUTE spJobsInsert @M OUTPUT
SELECT @M



--------------------------------------------------------------------



/* ================================================================
   🔁 استفاده از CURSOR برای پیمایش رکوردهای جدول
   ================================================================

📌 این بخش از اسکریپت نمونه‌ای از استفاده از CURSOR در T-SQL را نمایش می‌دهد. ابتدا یک شغل جدید در جدول `jobs` درج شده و سپس رکوردهای جدول `authors` با استفاده از CURSOR یکی‌یکی خوانده و نام کامل آن‌ها چاپ می‌شود.

🧩 اجزای اصلی:
- `DECLARE cu CURSOR`: تعریف CURSOR برای گرفتن داده‌ها از جدول `authors`
- `FETCH NEXT ... INTO`: خواندن رکورد بعدی
- `WHILE @@FETCH_STATUS = 0`: اجرای حلقه تا زمانی که داده‌ای برای خواندن وجود دارد
- `PRINT CONCAT(...)`: چاپ خروجی به صورت ترکیب رشته‌ای

🎯 کاربرد:
- پردازش رکوردی (record-wise) در موارد خاصی مانند پردازش پیچیده یا تولید لاگ دقیق

*/

INSERT INTO jobs VALUES ('DBA' , 150 , 250)

DECLARE cu CURSOR FOR SELECT au_id , au_fname , au_lname FROM authors 
OPEN cu
DECLARE @au_id char(11) , @au_fname varchar(50) , @au_lname varchar(50)
FETCH NEXT FROM cu INTO @au_id , @au_fname , @au_lname
WHILE @@FETCH_STATUS = 0 
BEGIN 

	PRINT CONCAT( @au_id , ' ** ' , @au_fname , ' ** ' , @au_lname)
	FETCH NEXT FROM cu INTO @au_id , @au_fname , @au_lname

END

CLOSE cu
DEALLOCATE cu



--------------------------------------------------------------------



/* ================================================================
   🔄 پیمایش پایگاه‌های داده و بررسی اطلاعات با استفاده از CURSOR
   ================================================================

📌 در این بخش، ابتدا اطلاعات پایگاه داده `pubs` نمایش داده شده و سپس با استفاده از CURSOR، اطلاعات تمامی پایگاه‌های داده موجود در سیستم با اجرای `sp_helpdb` بررسی می‌گردد.

📋 اجزای کلیدی:
- `sp_helpdb`: نمایش اطلاعات کلی مربوط به یک پایگاه داده خاص
- CURSOR: برای پیمایش نام پایگاه‌های داده از `sys.databases`
- Dynamic SQL: استفاده از `EXECUTE(@Query)` برای اجرای دستورهای پویا

🎯 کاربرد:
- تهیه گزارشی خودکار از وضعیت پایگاه‌های داده
- استفاده در اسکریپت‌های مانیتورینگ و بررسی وضعیت دیتابیس‌ها

*/

EXECUTE sp_helpdb 'pubs'

DECLARE cuDB CURSOR FOR SELECT name FROM sys.databases
OPEN cuDB

DECLARE @DbName varchar(100) , @Query varchar(max)
FETCH NEXT FROM cuDB INTO @DbName
WHILE @@FETCH_STATUS = 0
BEGIN 
	SET @Query = 'EXECUTE sp_helpdb ' + '''' + @DbName +''''
	EXECUTE (@Query)
	FETCH NEXT FROM cuDB INTO @DbName
END

CLOSE cuDB
DEALLOCATE cuDB
GO



--------------------------------------------------------------------



/* ============================================================
   💾 رویه ذخیره‌سازی پشتیبان از پایگاه‌داده
   ============================================================

📌 در این اسکریپت، یک Stored Procedure به‌نام `spBackup` ایجاد شده که از یک پایگاه داده مشخص بک‌آپ تهیه می‌کند و فایل پشتیبان را در مسیر `C:\Dump\` ذخیره می‌کند.

🧮 پارامتر ورودی:
- `@DB_Name`: نام پایگاه داده موردنظر برای تهیه بک‌آپ

📋 ویژگی‌های بک‌آپ:
- استفاده از تاریخ جاری در نام فایل
- فشرده‌سازی (COMPRESSION)
- اجرای دستور به‌صورت داینامیک SQL

🎯 کاربرد:
- مناسب برای ایجاد فرآیندهای خودکار بک‌آپ‌گیری
- قابلیت استفاده به همراه CURSOR برای بک‌آپ‌گیری گروهی

⚠️ توجه:
- مسیر `C:\Dump\` باید قبلاً در سیستم وجود داشته باشد و SQL Server اجازه نوشتن در آن مسیر را داشته باشد.

*/

CREATE OR ALTER PROCEDURE spBackup @DB_Name varchar(30)
AS
BEGIN 

	DECLARE @Query nvarchar(max) 
	SET @Query = 'BACKUP DATABASE ' + @DB_Name + 
				 ' TO DISK = ''C:\Dump\ ' + @DB_Name + '_' + 
				 CONVERT(varchar , GETDATE() , 112) + '_' + 
				 FORMAT(GETDATE() , 'yyyyMMdd' , 'fa-IR') + 
				 '.bak'' WITH NOFORMAT, NOINIT, NAME = ''pubs-Full Database Backup'', ' +
				 'SKIP, NOREWIND, NOUNLOAD, COMPRESSION, STATS = 10'

	EXECUTE (@Query)
END
GO



--------------------------------------------------------------------



/* ============================================================
   🔁 اجرای بک‌آپ برای چند دیتابیس با استفاده از CURSOR
   ============================================================

📌 این بخش از اسکریپت برای اجرای رویه `spBackup` جهت تهیه نسخه پشتیبان از چند پایگاه داده استفاده می‌شود. 
نام پایگاه داده‌ها از جدول سیستمی `sys.databases` با استفاده از شناسه (ID) فیلتر می‌شود و با CURSOR خوانده می‌شوند.

🧮 مراحل عملکرد:
1. CURSOR باز شده و لیست دیتابیس‌ها با `database_id` خاص انتخاب می‌شوند.
2. با استفاده از Dynamic SQL برای هر دیتابیس دستور بک‌آپ‌گیری اجرا می‌شود.
3. در پایان CURSOR بسته و منابع آزاد می‌شود.

🎯 کاربرد:
- مناسب برای تهیه بک‌آپ گروهی از دیتابیس‌های انتخاب‌شده به‌صورت داینامیک

⚠️ نکات مهم:
- اطمینان حاصل شود که IDهای پایگاه داده (11، 20، 28) به‌درستی تعیین شده‌اند.
- برای جلوگیری از اجرای ناخواسته، می‌توان از شرط‌های دقیق‌تری استفاده کرد (مثلاً براساس نام پایگاه داده).
- در محیط‌های حساس از اجرای دستور بدون LOGGING مناسب خودداری شود.

*/

DECLARE cuDB CURSOR FOR 
	SELECT name 
	FROM sys.databases 
	WHERE database_id IN (11,20,28)

OPEN cuDB

DECLARE @DbName varchar(100), @Query varchar(max)
FETCH NEXT FROM cuDB INTO @DbName

WHILE @@FETCH_STATUS = 0
BEGIN 
	SET @Query = 'EXECUTE spBackup ' + '''' + @DbName + ''''
	--PRINT @Query
	EXECUTE (@Query)
	FETCH NEXT FROM cuDB INTO @DbName
END

CLOSE cuDB
DEALLOCATE cuDB

GO



--------------------------------------------------------------------



/* ============================================================
   🔁 استفاده از CURSOR برای نمایش اطلاعات نویسندگان
   ============================================================

📌 این کوئری با استفاده از CURSOR اطلاعات نویسندگان را از جدول `authors` خوانده و هر رکورد را به صورت متنی چاپ می‌کند.

🧾 فرآیند:
1. تعریف CURSOR برای خواندن فیلدهای `au_id`, `au_fname`, `au_lname` از جدول `authors`.
2. باز کردن CURSOR و گرفتن اولین رکورد.
3. استفاده از حلقه WHILE برای تکرار تا پایان داده‌ها.
4. درون حلقه، چاپ مقادیر ترکیبی از ستون‌ها با استفاده از تابع `CONCAT`.
5. بستن و آزادسازی CURSOR.

🎯 کاربرد:
- مناسب برای نمایش ساده، پردازش خط به خط یا استفاده در فرآیندهای انتقالی.
- نمایش تستی یا بررسی سریع اطلاعات نویسندگان در محیط توسعه.

⚠️ نکات مهم:
- CURSORها در SQL Server منابع بیشتری مصرف می‌کنند و در حجم زیاد کارایی خوبی ندارند.
- برای پردازش دسته‌ای یا انبوه، بهتر است از رویکردهای SET-based استفاده شود.

*/

DECLARE cu CURSOR FOR 
	SELECT au_id, au_fname, au_lname 
	FROM authors 

OPEN cu

DECLARE @au_id char(11), @au_fname varchar(50), @au_lname varchar(50)

FETCH NEXT FROM cu INTO @au_id, @au_fname, @au_lname

WHILE @@FETCH_STATUS = 0 
BEGIN 
	PRINT CONCAT(@au_id, ' ** ', @au_fname, ' ** ', @au_lname)
	FETCH NEXT FROM cu INTO @au_id, @au_fname, @au_lname
END

CLOSE cu
DEALLOCATE cu



--------------------------------------------------------------------



/* ============================================================
   🧠 بررسی وضعیت دیتابیس‌ها با CURSOR و sp_helpdb
   ============================================================

📌 این اسکریپت با استفاده از CURSOR، به صورت داینامیک بر روی لیست تمامی دیتابیس‌ها حلقه زده و برای هر یک از آن‌ها اطلاعات وضعیت دیتابیس را با اجرای دستور `sp_helpdb` دریافت می‌کند.

🧾 فرآیند:
1. تعریف CURSOR برای انتخاب نام تمام دیتابیس‌ها از `sys.databases`.
2. باز کردن CURSOR و گرفتن اولین نام دیتابیس.
3. در حلقه، ایجاد کوئری داینامیک برای اجرای `sp_helpdb` برای هر دیتابیس.
4. اجرای کوئری و گرفتن اطلاعات دیتابیس.
5. بستن و آزادسازی CURSOR.

🎯 کاربرد:
- مناسب برای بررسی سریع وضعیت فنی، اندازه، تنظیمات یا ساختار تمام دیتابیس‌های سرور.

⚠️ نکات مهم:
- `sp_helpdb` فقط برای SQL Server قابل اجرا است.
- اجرای این اسکریپت در سیستم‌هایی با تعداد زیاد دیتابیس ممکن است زمان‌بر باشد.
*/

EXECUTE sp_helpdb 'pubs'

DECLARE cuDB CURSOR FOR 
	SELECT name 
	FROM sys.databases

OPEN cuDB

DECLARE @DbName varchar(100), @Query varchar(max)

FETCH NEXT FROM cuDB INTO @DbName

WHILE @@FETCH_STATUS = 0
BEGIN 
	SET @Query = 'EXECUTE sp_helpdb ''' + @DbName + ''''
	EXECUTE (@Query)
	FETCH NEXT FROM cuDB INTO @DbName
END

CLOSE cuDB
DEALLOCATE cuDB



--------------------------------------------------------------------



/* ============================================================
   💾 ساخت Stored Procedure برای بک‌آپ‌گیری از دیتابیس‌ها
   ============================================================

📌 این رویه ذخیره‌شده (`spBackup`) یک عملیات پشتیبان‌گیری کامل (Full Backup) برای دیتابیس مشخص‌شده توسط پارامتر ورودی انجام می‌دهد و فایل پشتیبان را با فرمت نام‌گذاری مشخص در مسیر تعیین‌شده ذخیره می‌کند.

🧮 پارامتر ورودی:
- `@DB_Name` : نام دیتابیس مورد نظر برای بک‌آپ‌گیری

📋 عملیات:
- تولید رشته داینامیک SQL برای اجرای دستور `BACKUP DATABASE`
- استفاده از فرمت تاریخ فارسی برای نام فایل پشتیبان
- ذخیره فایل در مسیر `C:\Dump\`

📦 ویژگی‌ها:
- فشرده‌سازی (COMPRESSION)
- ارائه وضعیت عملیات (STATS = 10)
- بدون فرمت مجدد یا جایگزینی فایل قبلی (NOFORMAT, NOINIT)

⚠️ نکات مهم:
- مسیر `C:\Dump\` باید وجود داشته و دسترسی نوشتن برای SQL Server در آن برقرار باشد.
- به دلیل استفاده از EXEC داینامیک، خطر تزریق SQL بالقوه وجود دارد و باید با دقت از پارامترها استفاده شود.
*/

CREATE OR ALTER PROCEDURE spBackup @DB_Name varchar(30)
AS
BEGIN 
	DECLARE @Query nvarchar(max) 
	SET @Query = 'BACKUP DATABASE ' + @DB_Name + ' TO  DISK = ''C:\Dump\ ' + 
				  @DB_Name + '_' + CONVERT(varchar , GETDATE() , 112) + '_' + 
				  FORMAT(GETDATE() , 'yyyyMMdd' , 'fa-IR') + 
				  '.bak'' WITH NOFORMAT, NOINIT,  NAME = ''pubs-Full Database Backup'', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10'
	EXECUTE (@Query)
END
GO



--------------------------------------------------------------------



/* ============================================================
   🔁 اجرای بک‌آپ برای چندین دیتابیس با استفاده از CURSOR
   ============================================================

📌 در این اسکریپت از CURSOR برای اجرای پیاپی رویه ذخیره‌شده `spBackup` استفاده شده تا از دیتابیس‌های مشخص‌شده با `database_id`های خاص، به‌صورت داینامیک بک‌آپ گرفته شود.

🎯 هدف:
- پشتیبان‌گیری خودکار و متوالی از چندین دیتابیس مشخص

📋 مراحل:
1. تعریف CURSOR بر اساس دیتابیس‌های موردنظر
2. تولید کوئری EXEC داینامیک برای `spBackup`
3. اجرای حلقه CURSOR برای اجرای بک‌آپ روی هر دیتابیس

⚠️ نکات مهم:
- CURSOR باید پس از استفاده به‌درستی بسته و آزاد شود (CLOSE / DEALLOCATE).
- برای اضافه کردن دیتابیس‌های دیگر، کافی است `database_id` آن‌ها در WHERE clause ذکر شود.
*/

DECLARE cuDB CURSOR FOR 
	SELECT name 
	FROM sys.databases 
	WHERE database_id IN (11,20,28)

OPEN cuDB

DECLARE @DbName varchar(100), @Query varchar(max)

FETCH NEXT FROM cuDB INTO @DbName
WHILE @@FETCH_STATUS = 0
BEGIN 
	SET @Query = 'EXECUTE spBackup ' + '''' + @DbName + ''''
	--PRINT @Query -- برای مشاهده کوئری تولیدی
	EXECUTE (@Query)
	FETCH NEXT FROM cuDB INTO @DbName
END

CLOSE cuDB
DEALLOCATE cuDB

GO
