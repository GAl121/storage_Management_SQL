--CREATE DATABASE Store;
use Store;

CREATE TABLE Warehouse
(
warehouseId smallint identity(1,1) primary key,
warehouseName nvarchar(40) unique not null,
maximunCapacity int default 20 check(maximunCapacity >= 20),
currentCapacity int check(currentCapacity >= 0) default 0,
CONSTRAINT capacity_check CHECK (currentCapacity <= maximunCapacity)
);

CREATE TABLE Category
(
categoryId smallint identity(1,1) ,
categoryName nvarchar(40) unique not null check(len(categoryName) >= 3) ,
totalProducts int default 0 check(totalProducts >=0),
primary key (categoryId,categoryName)
);

CREATE TABLE Product
(
productId smallint identity(1,1) primary key,
productName nvarchar(40) unique not null,
categoryName nvarchar(40) references Category(categoryName) not null,
warehouseName nvarchar(40) references Warehouse(warehouseName),
entryDate Date not null,
costPerUnit decimal(6,2) check(costPerUnit > 0),
ProductMaximunCapacity int default 20 check(ProductMaximunCapacity >= 20),
ProductCurrentCapacity int check(ProductCurrentCapacity >= 0) default 0,
totalSoldUnits int check(totalSoldUnits >=0) default 0,
CONSTRAINT capacity_chk CHECK (ProductCurrentCapacity <= ProductMaximunCapacity)
);

CREATE TABLE Users
(
userId smallint identity(1,1),
userName nvarchar(30) unique not null,
userPassword nvarchar(30) check(len(userPassword) >= 8 and len(userPassword) <= 30),
fullName nvarchar(30) check(len(fullname) > 3),
personalId int unique not null,
dateOfBirth date not null check(datediff(year,dateOfBirth,getdate()) >= 15),
phone char(10)  check(phone like '05'+replicate('[0-9]',8) or phone like '0'+replicate('[0-9]',8)),
gender char(1) check(gender in ('M','F')) not null,
joinDate Date default getdate(),
isAdmin char(1) check(isAdmin like 'y' or isadmin like 'n')
primary key (userId,personalId)
);

CREATE TABLE Invoices
(
invoiceId smallint identity(1,1) primary key,
customerName nvarchar(30) references Users(userName) not null,
customerId int references Users(personalId) not null,
purchaseDate datetime default getdate(),
totalPrudocts smallint check(totalPrudocts >= 0) default 0,
totalCost decimal(8,2) check(totalCost >= 0) default 0
);

CREATE TABLE Purchases
(
purechaseId smallint identity(1,1),
invoicingId smallint references Invoices(invoiceId) not null,
prudoctid smallint references Product(productId) not null,
categoryName nvarchar(40) references Category(categoryName) ,
amount smallint check(amount > 0),
totalCost decimal(6,2) check(totalCost > 0),
primary key(purechaseId,invoicingId,prudoctid)
);

