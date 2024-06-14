CREATE TABLE Product(
    maker CHAR(1),
    model INT,
    type CHAR(7)
);

	
CREATE TABLE PC (
    model INT,
    speed DECIMAL,
    ram INT,
    hd INT,
    price INT
);

CREATE TABLE Laptop (
    model INT,
    speed DECIMAL,
    ram INT,
    hd INT,
    screen DECIMAL,
    price INT
);

CREATE TABLE Printer (
    model INT,
    color BOOLEAN,
    type CHAR(7),
    price INT
);

INSERT INTO Product (maker, model, type)
VALUES
    ('A', 1001, 'pc'),
    ('A', 1002, 'pc'),
    ('A', 1003, 'pc'),
    ('A', 2004, 'laptop'),
    ('A', 2005, 'laptop'),
    ('A', 2006, 'laptop'),
    ('B', 1004, 'pc'),
    ('B', 1005, 'pc'),
    ('B', 1006, 'pc'),
    ('B', 2007, 'laptop'),
    ('C', 1007, 'pc'),
    ('D', 1008, 'pc'),
    ('D', 1009, 'pc'),
    ('D', 1010, 'pc'),
    ('D', 3004, 'printer'),
    ('D', 3005, 'printer'),
    ('E', 1011, 'pc'),
    ('E', 1012, 'pc'),
    ('E', 1013, 'pc'),
    ('E', 2001, 'laptop'),
    ('E', 2002, 'laptop'),
    ('E', 2003, 'laptop'),
    ('E', 3001, 'printer'),
    ('E', 3002, 'printer'),
    ('E', 3003, 'printer'),
    ('F', 2008, 'laptop'),
    ('F', 2009, 'laptop'),
    ('G', 2010, 'laptop'),
    ('H', 3006, 'printer'),
    ('H', 3007, 'printer');

INSERT INTO PC (model, speed, ram, hd, price)
VALUES 
    (1001, 2.66, 1024, 250, 2114),
    (1002, 2.10, 512, 250, 995),
    (1003, 1.42, 512, 80, 478),
    (1004, 2.80, 1024, 250, 649),
    (1005, 3.20, 512, 250, 630),
    (1006, 3.20, 1024, 320, 1049),
    (1007, 2.20, 1024, 200, 510),
    (1008, 2.20, 2048, 250, 770),
    (1009, 2.00, 1024, 250, 650),
    (1010, 2.80, 2048, 300, 770),
    (1011, 1.86, 2048, 160, 959),
    (1012, 2.80, 1024, 160, 649),
    (1013, 3.06, 512, 80, 529);

INSERT INTO Laptop (model, speed, ram, hd, screen, price)
VALUES 
    (2001, 2.00, 2048, 240, 20.1, 3673),
    (2002, 1.73, 1024, 80, 17.0, 949),
    (2003, 1.80, 512, 60, 15.4, 549),
    (2004, 2.00, 512, 60, 13.3, 1150),
    (2005, 2.16, 1024, 120, 17.0, 2500),
    (2006, 2.00, 2048, 80, 15.4, 1700),
    (2007, 1.83, 1024, 120, 13.3, 1429),
    (2008, 1.60, 1024, 100, 15.4, 900),
    (2009, 1.60, 512, 80, 14.1, 680),
    (2010, 2.00, 2048, 160, 15.4, 2300);

INSERT INTO Printer (model, color, type, price)
VALUES
    (3001, true, 'ink-jet', 99),
    (3002, false, 'laser', 239),
    (3003, true, 'laser', 899),
    (3004, true, 'ink-jet', 120),
    (3005, false, 'laser', 120),
    (3006, true, 'ink-jet', 100),
    (3007, true, 'laser', 200);

-- 2.4.14 Exercises for Section 2.4

-- Exercise 2.4.1
-- a) Find those manufacturers that sell printers, but not PC's.
SELECT maker FROM product
WHERE type = 'pc'
EXCEPT 
SELECT maker FROM product
WHERE type = 'laptop';
-- b) What PC models have a speed of at least 2.50?
SELECT * FROM PC WHERE speed >= 2.50;
-- c) Which manufacturers make laptops with a hard disk of at least
-- 120GB?
-- SELECT Product.model
--     FROM Product, Laptop
--     WHERE Product.model = Laptop.model AND Laptop.hd >= 120;
SELECT product.maker FROM product 
    JOIN laptop  ON product.model = laptop.model
    WHERE laptop.hd >= 120;
-- d) Find the model number and price of all products (of any type)
-- by manufacturer C. 
SELECT product.maker, product.model, 
	pc.price AS pc_price,
	laptop.price AS laptop_price,
	printer.price AS printer_price
FROM product
LEFT JOIN pc ON product.model = pc.model
LEFT JOIN laptop ON product.model = laptop.model
LEFT JOIN printer ON product.model = printer.model
WHERE product.maker = 'C';
-- e) Find the model nubmers of all block-and-white laser printers.
SELECT model FROM Printer WHERE color = FALSE AND  type = 'laser';
-- f) Find those hard-disk sizes that occur in two or more PC's.
SELECT hd
FROM pc
GROUP BY hd
HAVING COUNT(hd) >= 2;


-- 2.5.5 Exercises for Section 2.5

-- Exercise 2.5.1
-- a) A PC with a processor speed less than 3.00 must not sell for 
-- more than $800.
CREATE FUNCTION has_low_speed () RETURNS BOOLEAN AS $$
BEGIN
    RETURN
        NOT EXISTS(
            SELECT * FROM pc WHERE speed < 3.00 AND price > 800
        );
END
$$ LANGUAGE PLPGSQL;
ALTER TABLE pc ADD CONSTRAINT price_for_low_processor_speed 
CHECK(has_low_speed());

ALTER TABLE pc DROP CONSTRAINT price_for_low_processor_speed;

-- b) A laptop with a screen size less than 15.4 inches must have
-- at least a 120 gigabye hard disk or sell for less than $1000.
CREATE FUNCTION has_screen_size_less_15_4 () RETURNS BOOLEAN AS $$
BEGIN
    RETURN
        NOT EXISTS (
            SELECT * FROM laptop 
                WHERE screen < 15.4 AND
                (hd < 120 AND price >= 1000)
        );
END
$$ LANGUAGE PLPGSQL;
ALTER TABLE laptop ADD CONSTRAINT min_screen_size_storage_or_price
CHECK(has_screen_size_less_15_4());


ALTER TABLE pc DROP CONSTRAINT min_screen_size_storage_or_price; 

-- c) No manufacturer of PC's may also make printers.
CREATE FUNCTION makes_pc_and_makes_printers (_maker CHAR(1), _type CHAR(7))
RETURNS BOOLEAN AS $$
BEGIN
    RETURN 
        NOT EXISTS(
            WITH ty AS (SELECT COUNT(*) FROM product
                WHERE type = _type AND maker = _maker),
                total AS (SELECT COUNT(*) FROM product
                WHERE maker = _maker AND (type = 'pc' OR type = 'printer'))
            SELECT * FROM ty, total WHERE ty.count < total.count
        );
END
$$ LANGUAGE PLPGSQL;
ALTER TABLE product ADD CONSTRAINT no_pc_and_printers
CHECK(makes_pc_and_makes_printers(maker, type));

-- d) If a laptop has a larger main memory than a PC, then the laptop
-- must also have a higher price than the PC.
CREATE FUNCTION laptop_has_higher_mem_and_price_than_pc ()
RETURNS BOOLEAN AS $$
BEGIN 
    RETURN
        NOT EXISTS(
            WITH p AS (SELECT * FROM pc),
                l AS (SELECT * FROM laptop)
            SELECT * FROM l, p WHERE l.ram > p.ram AND l.price <= p.price
        );
END
$$ LANGUAGE PLPGSQL;
ALTER TABLE laptop ADD CONSTRAINT mem_and_price
CHECK(laptop_has_higher_mem_and_price_than_pc());
-- e) A manufacturer of a PC msut also make a laptop with at least
-- as great a processor speed.
CREATE FUNCTION min_speed (_model INT)
RETURNS BOOLEAN AS $$
DECLARE _maker CHAR(1) := (SELECT p.maker FROM product AS p WHERE p.model = _model LIMIT 1);
BEGIN
    RETURN
        NOT EXISTS(
            WITH m_pc AS (
                SELECT MIN(pc.speed) FROM product  AS p
                INNER JOIN pc
                ON pc.model = p.model
                WHERE p.maker = _maker),
            m_laptop AS (
                SELECT * FROM product AS p
                INNER JOIN laptop AS l
                ON l.model = p.model
                WHERE p.maker = _maker 
            )
            SELECT * FROM m_pc, m_laptop
            WHERE m_laptop.speed > m_pc.min
        );
END
$$ LANGUAGE PLPGSQL;
ALTER TABLE laptop ADD CONSTRAINT mmm
CHECK(min_speed());

-- Exercise 6.1.3

-- a) Find the model number, memory size, and screen size for
-- laptops costing more than $1200.
SELECT model, hd, screen FROM laptop
WHERE price > 1200;
-- b) Find all the tuples in the Printer relation for color
-- Remember that color is a boolean-valued attribute.
SELECT * FROM printer
WHERE color IS TRUE;
-- c) Find the model number and hard-disk size for those PC's
-- that have a speed of 3.0 and a price less than $1000.
SELECT model, hd FROM pc
WHERE speed = 3.0 AND price < 1000;
-- d) Find the model number, speed, and hard-disk size for all
-- PC's whose price is under $800.
SELECT model, speed, hd FROM pc
WHERE price < 800;
-- e) Do the same as (a), but rename the speed column gigahertz
-- and the ram column gigabytes.
SELECT model, hd, screen, 
	speed AS gigahertz,
	ram AS gigabytes
FROM laptop
WHERE price > 1200;
-- f) Find the manufacturers of laptops
SELECT DISTINCT maker FROM product
WHERE type = 'laptop';


-- Exercise 6.2.2
-- a) Find those manufacturers that sell PC's but not Laptops.
SELECT maker FROM product
WHERE type = 'pc'
EXCEPT 
SELECT maker FROM product
WHERE type = 'laptop';
-- b) Give the manufacturer and speed of laptops with a hard disk
-- of at least 100 gigabytes.
SELECT p.maker AS model,
	l.speed AS speed
FROM product AS p
INNER JOIN laptop AS l
    ON p.model = l.model
WHERE l.hd >= 100;
-- c) Find the model number and price of all products (of any type)
-- made by manufacturer C.
SELECT pr.model, l.price
FROM product AS pr
INNER JOIN laptop AS l
	ON pr.model = l.model
WHERE pr.maker = 'C'
UNION
SELECT pr.model, pc.price
FROM product AS pr
INNER JOIN pc AS pc
	ON pr.model = pc.model
WHERE pr.maker = 'C'
UNION
SELECT pr.model, pri.price
FROM product AS pr
INNER JOIN printer AS pri
	ON pr.model = pri.model
WHERE pr.maker = 'C';
-- d) find those pairs of PC models that have both the same RAM
-- and hard disk. A pair should be listed only once; e.g.,
-- list(i, j) but not (j, i).
SELECT pc1.model AS pc1_model, 
	pc2.model AS pc2_model
	FROM pc AS pc1
INNER JOIN pc AS pc2
ON pc1.ram = pc2.ram AND pc1.hd = pc2.hd
WHERE pc1.model != pc2.model AND pc1.model > pc2.model;
-- e) Find those processor speeds that occur in two or more PC's.
SELECT speed, COUNT(*) FROM pc
GROUP BY speed
HAVING COUNT(*) >= 2;
-- f) Find those manufacturers of at least two different
-- computers (PC's or laptops) with speeds of at least 2.0.
SELECT maker FROM product as prod
JOIN pc as pc
ON prod.model = pc.model AND pc.speed >= 2.0
GROUP BY maker
HAVING COUNT(*) >= 2
UNION
SELECT maker FROM product as prod
JOIN laptop as l
ON prod.model = l.model AND l.speed >= 2.0
GROUP BY maker
HAVING COUNT(*) >= 2;


-- Exercise 6.3.1
-- Use at least one subquery in each of the answers and write
-- each query in two significantly different ways (e.g. using
-- different sets of operators EXISTS, IN, ALL, ANY).

-- a) Find the makers of laptops with a speed of at least 2.0
SELECT maker FROM product as prod
JOIN laptop as l
ON prod.model = l.model AND l.speed >= 2.0
GROUP BY maker;
-- b) Find the printers with the highest price.
SELECT MAX(price) FROM printer;

SELECT type, MAX(price) FROM printer
GROUP BY type;
-- c) Find the laptops whose speed is slower than that of the
-- fastest PC
SELECT * FROM laptop
WHERE speed < (SELECT MAX(price) FROM pc);
-- d) Find the model number of the item (PC, laptop, or printer)
-- with the lowest price.
SELECT MIN(price) FROM (
	SELECT price FROM pc
	UNION
	SELECT price FROM laptop
	UNION
	SELECT price FROM printer
) AS combined_prices;
-- e) Find the maker of the color printer with the highest price.
SELECT maker FROM product
    WHERE model = (
        SELECT model FROM printer
            WHERE price = (
                SELECT MAX(price) FROM printer) 
        AND color = TRUE);
-- f) find the maker(s)_of the PC(s) with the fastest processor
-- among all those PC's that have the greatest amount of RAM.
SELECT DISTINCT maker FROM product
	WHERE model IN (
		SELECT model FROM pc
			WHERE ram IN (
	 			SELECT MAX(ram) FROM pc)
	);

-- Exercise 6.4.6

-- a) Find the average hard-disk size of PC's.
SELECT AVG(hd) FROM pc;
-- b) Find the average price of laptops with speed of at least 3.0.
SELECT AVG(price) FROM laptop
WHERE speed >= 3.0;
-- c) Find the average price of PC's made by manufacturer "A".
SELECT AVG(pc.price) FROM pc
JOIN product  AS p ON
pc.model = p.model
WHERE p.maker = 'A';
-- d) Find the average price of PC's and laptops made by manufacturer
-- "D"
SELECT AVG(pc.price) FROM product 
JOIN pc ON
pc.model = product.model
WHERE product.maker = 'D'
UNION
SELECT AVG(laptop.price) FROM product 
JOIN laptop ON
laptop.model = product.model
WHERE product.maker = 'D';

SELECT AVG(pc.price), AVG(laptop.price) FROM product 
JOIN pc ON
pc.model = product.model
FULL JOIN laptop ON
laptop.model = product.model
WHERE product.maker = 'D';
-- e) Find, for each different price, the average speed of a PC.
SELECT price, AVG(speed) AS avg_speed FROM pc GROUP BY price;

-- Exercise 6.5.1

-- a) Delete all PC's with less than 20 gigabyte of hard disk.

-- b) Using two INSERT statements, stoer in the database the fact
-- that PC model