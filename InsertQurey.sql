use Store;
exec addNewUser 'Gal','gal123456','Gal Amram',305253965,'06-05-1991','0542524290','m','y'	

INSERT INTO Warehouse(warehouseName,maximunCapacity) VALUES('flower',100);
INSERT INTO Warehouse(warehouseName,maximunCapacity) VALUES('cap',80);
INSERT INTO Warehouse(warehouseName,maximunCapacity) VALUES('bee',120);
INSERT INTO Warehouse(warehouseName,maximunCapacity) VALUES('big mac',800);

select * from warehouse

INSERT INTO Category(categoryName) VALUES('Electronics');
INSERT INTO Category(categoryName) VALUES('Home & Garden');
INSERT INTO Category(categoryName) VALUES('Cars');
INSERT INTO Category(categoryName) VALUES('Kitchen');

select * from Category;

exec addNewProduct 'chef knife','Kitchen', 9.99, 20, 5;
exec addNewProduct 'kitchen knife','Kitchen', 4.99, 30, 10;
exec addNewProduct 'wooden cutting board','Kitchen',20, 250, 5;

exec addNewProduct 'microwave','Electronics', 30, 30, 10;
exec addNewProduct 'television','Electronics', 1200, 50, 15;
exec addNewProduct 'toster','Electronics', 300, 50, 20;
exec addNewProduct 'remote control','Electronics', 67.98, 50, 30;

exec addNewProduct 'airpods','Electronics', 700, 30, 15;
exec addNewProduct 'xbox','Electronics', 900, 20, 6;
exec addNewProduct 'xbox remotes','Electronics', 130, 300, 80;

exec addNewProduct 'carft','Home & Garden', 200, 40, 10;
exec addNewProduct 'door tapet','Home & Garden', 136.67, 20, 5;
exec addNewProduct 'sintatic grass 1x1 meters','Home & Garden', 150, 100, 80;
exec addNewProduct '10 plates','Home & Garden', 3.5, 200, 60;

exec addNewProduct 'indoor left door plastic','Cars', 100, 30, 15;
exec addNewProduct 'indoor right door plastic','Cars', 100, 30, 15;
exec addNewProduct 'smell tree','Cars', 5.5, 200, 100;
exec addNewProduct 'per of car wipers','Cars', 69.6, 100, 50;

select * from Product
select * from Invoices

declare @invoiceIdOut int
exec addNewPurchase 'Gal','sintatic grass 1x1 meters','Home & Garden', 5,null, @invoiceIdOut output
exec addNewPurchase 'Gal','toster','Kitchen', 3,@invoiceIdOut, @invoiceIdOut  output

exec addNewPurchase 'Gal','chef knife','Electronics', 3,@invoiceIdOut, @invoiceIdOut output
print @invoiceIdOut

select * from purchases

select * from returnUserProductsByDate('Gal' , 100)
--6
exec makeDiscount 10,40,10,'Gal'

--7 
exec showProductByDate '10-14-2021'

--8
exec userGraphPie 'Gal'

--9 a
exec top10 'Home & Garden'

--9 b
declare @msg nvarchar(300)
exec updateProductAmount 50,30,@msg output
print @msg

--9 c 

exec topSale
--9 d 
declare @incoming decimal(8,2)
exec endOfDay @incoming output
print @incoming
