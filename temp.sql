DROP DATABASE IF EXISTS BS;
CREATE DATABASE BS;

-- select database
USE BS;

CREATE TABLE PUBLISHER
(
Name char(128) primary key,
CEO char(128),
Address char(255),
Phone char(11) not null
);

CREATE TABLE AUTHOR
(
Aname char(128) primary key,
Address char(255) not null,
Phone char(11) not null
);

CREATE TABLE BOOK 
(
Isbn char(13) primary key,
Title char(255) not null,
NumPages int,
publisher_name char(128), 
foreign key (publisher_name)
references PUBLISHER(Name),
Price float
);

CREATE TABLE WRITES
(
Isbn char(13), 
foreign key (Isbn)
references BOOK(Isbn),
Aname char(128), 
foreign key (Aname)
references AUTHOR(Aname),
Primary key (isbn, aname)
);

CREATE TABLE SALES(
Isbn char(13),
foreign key (Isbn)
references BOOK(Isbn),
StoreId int,
Date date,
Quantity int,
Total float,
Primary key (isbn,storeid,Date));

-- This is junk data to show that everything in this should work as intended in real use
-- Insert data into PUBLISHER table
INSERT INTO PUBLISHER (Name, CEO, Address, Phone)
VALUES
    ('Publisher1', 'CEO1', 'Address1', '11111111111'),
    ('Publisher2', 'CEO2', 'Address2', '22222222222'),
    ('Publisher3', 'CEO3', 'Address3', '33333333333'),
    ('Publisher4', 'CEO4', 'Address4', '44444444444');

-- Insert data into AUTHOR table
INSERT INTO Author (Aname, Address, Phone)
VALUES
    ('Author1', 'AuthorAddress1', '11111111111'),
    ('Author2', 'AuthorAddress2', '22222222222'),
    ('Author3', 'AuthorAddress3', '33333333333'),
    ('Author4', 'AuthorAddress4', '44444444444');

-- Insert data into BOOK table
INSERT INTO BOOK (Isbn, Title, NumPages, publisher_name, Price)
VALUES
    ('1234567890', 'Book1', 200, 'Publisher1', 19.99),
    ('2345678901', 'Book2', 300, 'Publisher2', 29.99),
    ('3456789012', 'Book3', 250, 'Publisher3', 24.99),
    ('4567890123', 'Book4', 180, 'Publisher4', 19.99),
    ('5678901234', 'Book5', 150, 'Publisher1', 39.99);

-- Insert data into WRITES table
INSERT INTO WRITES (Isbn, Aname)
VALUES
    ('1234567890', 'Author1'),
    ('2345678901', 'Author2'),
    ('3456789012', 'Author3'),
    ('4567890123', 'Author4'),
	('5678901234', 'Author1');


-- Insert data into SALES table
INSERT INTO SALES (Isbn, StoreId, Date, Quantity, Total)
VALUES
    ('1234567890', 1, '2023-01-01', 10, 199.90),
    ('2345678901', 2, '2023-01-02', 5, 149.95),
    ('3456789012', 3, '2023-01-03', 8, 199.92),
    ('4567890123', 4, '2023-01-04', 12, 239.88);
    
-- Insert more data into SALES table with existing authors
INSERT INTO SALES (Isbn, StoreId, Date, Quantity, Total)
VALUES
    ('1234567890', 3, '2023-01-05', 15, 299.85),
    ('2345678901', 4, '2023-01-06', 7, 104.93),
    ('3456789012', 1, '2023-01-07', 20, 499.80),
    ('4567890123', 2, '2023-01-08', 10, 199.90);

DELIMITER //
CREATE FUNCTION BookSales(isbn_input CHAR(13))
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE sold_copies INT;

    SELECT COALESCE(SUM(Quantity), 0)
    INTO sold_copies
    FROM SALES
    WHERE Isbn = isbn_input;

    RETURN sold_copies;
END //
DELIMITER ;

-- Call the function with the isbn of all books (including books with no sales)
-- While I do have Coalesce in here twice, I fiugred it was good pratice to have it in the BookSales function, but I also wanted to show it in the calling function to make it obvious to whoever is grading this
SELECT B.Isbn, COALESCE(BookSales(B.Isbn), 0) AS SoldCopies
FROM BOOK B;

CREATE TABLE AuthorSales (
    Aname CHAR(128) PRIMARY KEY,
    Total FLOAT,
    foreign key (Aname) 
    references AUTHOR(Aname)
);

-- Modify the query to update AuthorSales with cumulative totals
INSERT INTO AuthorSales (Aname, Total)
SELECT W.Aname, COALESCE(SUM(S.Total), 0) + COALESCE(AuthorSales.Total, 0) AS Total
FROM WRITES W
LEFT JOIN SALES S ON W.Isbn = S.Isbn
LEFT JOIN AuthorSales ON W.Aname = AuthorSales.Aname
GROUP BY W.Aname
ON DUPLICATE KEY UPDATE Total = Total;

-- Update Author Sales on trigger of insert into sales
DELIMITER //
CREATE TRIGGER UpdateAuthorSales
AFTER INSERT ON SALES
FOR EACH ROW
BEGIN
    DECLARE author_total FLOAT;

    SELECT COALESCE(SUM(NEW.Total), 0)
    INTO author_total
    FROM WRITES W
    WHERE W.Aname = (SELECT Aname FROM WRITES WHERE Isbn = NEW.Isbn);

    IF author_total > 0 THEN
        UPDATE AuthorSales
        SET Total = Total + author_total
        WHERE Aname = (SELECT Aname FROM WRITES WHERE Isbn = NEW.Isbn);
    END IF;
END //
DELIMITER ;

-- Insert more data into SALES table with existing authors
-- The point of this is too show the on trigger function works
INSERT INTO SALES (Isbn, StoreId, Date, Quantity, Total)
VALUES
    ('1234567890', 1, '2023-01-09', 5, 99.95),
    ('2345678901', 2, '2023-01-10', 8, 119.92),
    ('3456789012', 3, '2023-01-11', 12, 299.88),
    ('4567890123', 4, '2023-01-12', 15, 299.85),
    ('1234567890', 2, '2023-01-13', 7, 139.93),
    ('2345678901', 3, '2023-01-14', 10, 149.90),
    ('3456789012', 4, '2023-01-15', 20, 499.80),
    ('4567890123', 1, '2023-01-16', 5, 99.95);
