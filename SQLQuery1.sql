use Store;

create proc endOfDay @incoming decimal(8,2) output as

select @incoming = SUM(totalCost) from Invoices where CAST(purchaseDate as date) = CAST(getdate() as date)
if @incoming is null
	print 'There is no purchases for today'
else
begin
	select P.prudoctid, I.invoiceId, Pr.productName,P.categoryName ,P.amount as soldUnits,PR.costPerUnit ,PR.costPerUnit * P.amount as totalCost from Purchases as P inner join Invoices as I on P.invoicingId = I.invoiceId
	inner join Product as PR on PR.productId = P.prudoctid
	where CAST(I.purchaseDate as date) = CAST(GETDATE() as date) 
	group by P.prudoctid,Pr.productName,P.categoryName ,I.invoiceId,P.amount,PR.costPerUnit ,PR.costPerUnit * P.amount order by I.invoiceId
end



--
create proc topSale as

declare @productid int,
@newPrice decimal (8,2)

	declare DiscountCursor cursor for
	select top 10 productid from Product where totalSoldUnits > 0 GROUP BY productId order by MAX(totalSoldUnits) DESC

	OPEN DiscountCursor
	FETCH NEXT FROM DiscountCursor INTO @productid
		while @@FETCH_STATUS = 0 
		BEGIN
			select @newPrice = costPerUnit from Product where productId = @productid
			if @newPrice < 200 
			set @newPrice = @newPrice * 0.85
			else
			begin
				if @newPrice >= 200 and @newPrice < 500
					set @newPrice = @newPrice * 0.9
				else
					set @newPrice = @newPrice * 0.95
			end

			UPDATE Product SET costPerUnit = @newPrice WHERE productId = @productid
			FETCH NEXT FROM DiscountCursor INTO @productid
		END
		CLOSE DiscountCursor
		DEALLOCATE DiscountCursor
		select top 10 productid,productName,MAX(totalSoldUnits) as soldUnits , costPerUnit from Product where totalSoldUnits > 0 GROUP BY productId,productName,totalSoldUnits,costPerUnit order by totalSoldUnits DESC

--
create proc updateProductAmount @pid int , @num int ,@msg nvarchar(300) output as
declare @oldProductCapacity int,
@newProductCapacity int,
@productMaxCap int,
@warehouseCurrentCapacity int, 
@warehousMaxCap int,
@warehouseName nvarchar(40),
@oldWarehouse nvarchar(40)

select @productMaxCap = ProductMaximunCapacity from Product where productId = @pid
select @oldProductCapacity = ProductCurrentCapacity from Product where productId = @pid
select @warehouseCurrentCapacity = currentCapacity from Warehouse where warehouseName in ( select warehouseName from Product where productId = @pid )
select @warehousMaxCap =  maximunCapacity from Warehouse where warehouseName in ( select warehouseName from Product where productId = @pid )
set @newProductCapacity = @oldProductCapacity + @num
select @oldWarehouse = warehouseName from Product where productId = @pid

if @newProductCapacity <= @productMaxCap
BEGIN
	if @warehouseCurrentCapacity + @newProductCapacity > @warehousMaxCap
	BEGIN
		select TOP 1 @warehouseName = warehouseName from Warehouse as W where (W.maximunCapacity >= W.currentCapacity + @newProductCapacity) order by warehouseId ASC;
		if @warehouseName is null
		begin
			set @msg = 'there is no place for this product capacity in any warehouse'
		end
		else
		begin
			UPDATE Warehouse set currentCapacity = currentCapacity - @oldProductCapacity where warehouseName = @oldWarehouse
			UPDATE Product set ProductCurrentCapacity = @newProductCapacity, warehouseName = @warehouseName WHERE productId = @pid
			UPDATE Warehouse set currentCapacity = currentCapacity + @newProductCapacity where warehouseName = @warehouseName
			set @msg = 'product have been successfully update and have been remove from: ' + @oldWarehouse + ' warehouse to: ' + @warehouseName + ' warehouse'
		end
	END
	ELSE
	BEGIN
		select @warehouseName = warehouseName from Product where productId = @pid
		UPDATE Product set ProductCurrentCapacity = @newProductCapacity WHERE productId = @pid
		UPDATE Warehouse set currentCapacity = currentCapacity + @num where warehouseName = @warehouseName
		set @msg = 'Product amount update successfully!'
	END
END
ELSE
	set @msg = 'the new capacity is over then the maximum capacity of this product. insert smallest capacity'


--
create proc top10 @catName nvarchar(40) as

	select TOP 10 cast(purchaseDate as date),customerName , totalCost, categoryName from (
								select I.purchaseDate, I.customerName, I.totalCost, P.categoryName from Invoices as I inner join Purchases as P on I.invoiceId = P.invoicingId) 
								derived_table where derived_table.categoryName = @catName

--
create proc userGraphPie @userName varchar(40) as
declare @totalPurchases DECIMAL(5,2)
	
	select @totalPurchases = SUM(amount)  from Purchases as P inner join Invoices as I on I.invoiceId = P.invoicingId where I.customerName = @userName
					 

					 select categoryName,CAST((SUM(amount)*100 / @totalPurchases)  AS decimal(5,2)) as precent from Purchases as P inner join Invoices as I on P.invoicingId = I.invoiceId where exists (
								select invoiceId from Invoices as I2 inner join Users as U on  I2.customerId = U.personalId where U.userName = @userName)
								GROUP BY categoryName order by SUM(amount)

--
create proc showProductByDate @date date as
create table #ProductByDate
(
dates date
)
while @date <= CAST(GETDATE() AS date) 
	BEGIN
		INSERT INTO #ProductByDate VALUES (@date)
		set @date = DATEADD(DAY,1,@date)
	END
select productName , categoryName , warehouseName, ProductCurrentCapacity from Product as P inner join #ProductByDate as PBD on P.entryDate = PBD.dates
group by productName , categoryName , warehouseName, ProductCurrentCapacity order by ProductCurrentCapacity ASC



--
create proc makeDiscount @discount tinyint, @capacity int, @numofdays int, @userName nvarchar (40) as
declare @productid int,
@newCost decimal(6,2)

	declare DiscountCursor cursor for
	select productid from returnUserProductsByDate(@userName,@numofdays) where warehouseName in (
							select warehouseName from Warehouse where (currentCapacity * 100 / maximunCapacity) >= @discount)
	OPEN DiscountCursor
	FETCH NEXT FROM DiscountCursor INTO @productid
		while @@FETCH_STATUS = 0 
		BEGIN
			select @newCost = costPerUnit from Product where productId = @productid
			set @newCost = @newCost * (100-@discount)/100

			UPDATE Product SET costPerUnit =  @newCost where productId = @productid;
			FETCH NEXT FROM DiscountCursor INTO @productid
		END
		CLOSE DiscountCursor
		DEALLOCATE DiscountCursor


--
create function returnUserProductsByDate(@userName nvarchar (40), @numOfDays int) returns table as
return
	(select * from Product as P where P.productId in( 
					select prudoctid from Purchases where invoicingId in (
								select invoiceId from Invoices as I where I.customerName = @userName and datediff(day,purchaseDate,getdate()) <= @numOfDays)))




--
create trigger updateInvoice on Purchases after insert as
declare @costPerUnit decimal(6,2),
@totalUnits int,
@productId int

select @productId = prudoctid from inserted;
select @totalUnits = amount from inserted;
select @costPerUnit = costPerUnit from Product as P where P.productId = @productId;

UPDATE Invoices SET totalPrudocts = totalPrudocts+ @totalUnits , totalCost = totalCost + (@totalUnits * @costPerUnit) where invoiceId = (select invoiceId from inserted);
UPDATE Product SET ProductCurrentCapacity = ProductCurrentCapacity - @totalUnits, totalSoldUnits = totalSoldUnits + @totalUnits where productId = @productId;
UPDATE Warehouse SET currentCapacity = currentCapacity - @totalUnits where warehouseName = (select warehouseName from Product where productId = @productId);



--
create trigger updatesForNewProduct on Product after insert as
declare @warehouseName nvarchar(40),
@productCapacity int,
@productId int,
@category nvarchar(40)

select @productCapacity = P.ProductCurrentCapacity from inserted as P
select TOP 1 @warehouseName = warehouseName from Warehouse where (maximunCapacity - currentCapacity >= @productCapacity) order by warehouseId ASC;
select @productId = productId from inserted;
select @category = categoryName from inserted;

	if @warehouseName is null
		begin
			print 'There is no free warehouse for this capacity of product'
			rollback
		end
	else
		begin
			UPDATE Warehouse SET currentCapacity = currentCapacity + @productCapacity where warehouseName = @warehouseName;
			UPDATE Product SET warehouseName = @warehouseName where productId =  @productId;
			UPDATE Category SET totalProducts = totalProducts + 1 where categoryName = @category;
		end



--
create proc addNewPurchase @userName nvarchar(40), @prodName nvarchar(40), @catName nvarchar(40), @totalUnites int,@invoiceId smallint = null, @invoiceIdOut smallint output as
DECLARE @productId smallint,
@totalCost decimal(8,2),
@costPerUnit decimal(6,2),
@customerId int

select @productId = productId from Product where productName = @prodName;
select @costPerUnit = costPerUnit from Product where productId = @productId;
select @customerId = personalid from Users where userName = @userName;
set @totalCost = @totalUnites * @costPerUnit;


	if @invoiceId is null
		BEGIN
			INSERT INTO Invoices (customerId,customerName) VALUES(@customerId,@userName);
			set @invoiceId = SCOPE_IDENTITY();
		END
	INSERT INTO Purchases (invoicingId,prudoctid,categoryName,amount,totalCost) VALUES (@invoiceId,@productId,@catName,@totalUnites,@totalCost);
	set @invoiceIdOut = @invoiceId;


--
create proc addNewProduct @prodName nvarchar(40), @catName nvarchar(40), @costPerUnit decimal(6,2), @max int = 20 , @current int = 0 as
	INSERT INTO Product(productName,categoryName,warehouseName,entryDate,costPerUnit,ProductMaximunCapacity,ProductCurrentCapacity)
	VALUES(@prodName,@catName,null,getdate(),@costPerUnit,@max,@current)
--
create proc addNewUser @username nvarchar(30), @password nvarchar(30), @fullname nvarchar(30),@id int, @dob date, @phone char(10), @gender char(1), @isAdmin char(1) = 'n' as
INSERT INTO Users (userName, userPassword, fullName, personalId, dateOfBirth, phone, gender, isAdmin)
VALUES (@username,@password,@fullname,@id,@dob,@phone,UPPER(@gender), LOWER(@isAdmin));


--éöéøú çùáåðéú çãùä øé÷ä åäçæøú äîñôø äñéãåøé ùìä
create proc addNewInvoice @id smallint output as
INSERT INTO Invoices (customerId,customerName,totalPrudocts,totalCost) OUTPUT INSERTED.invoiceId VALUES(null,null,1,1);

declare @idd smallint
exec addNewInvoice @idd output
print @idd


