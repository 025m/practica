SELECT maker AS manufacturers FROM Product
WHERE type = 'printer' AND type != 'pc';

SELECT model FROM pc WHERE speed >= 2.50;

SELECT product.maker FROM product, laptop
WHERE product.model = laptop.model AND laptop.hd >= 120;

SELECT product.maker FROM product JOIN laptop
ON product.model = laptop.model
WHERE laptop.hd >= 120;

SELECT product.maker, product.model, 
	pc.price AS pc_price,
	laptop.price AS laptop_price,
	printer.price AS printer_price
FROM product
LEFT JOIN pc ON product.model = pc.model
LEFT JOIN laptop ON product.model = laptop.model
LEFT JOIN printer ON product.model = printer.model
WHERE product.maker = 'C';

SELECT model FROM printer WHERE color = FALSE AND type = 'laser';

SELECT hd
FROM pc
GROUP BY hd
HAVING COUNT(hd) >= 2;

SELECT * FROM pc WHERE speed < 3.00 AND price > 800;

CREATE FUNCTION has_low_speed () RETURNS BOOLEAN AS $$
BEGIN
    EXISTS(
        SELECT * FROM pc WHERE speed < 3.00 AND price > 800;
    )
END
$$ LANGUAGE PLPGSQL;
ALTER TABLE pc ADD CONSTRAINT price_for_low_processor_speed 
CHECK(has_low_speed());

SELECT * FROM laptop 
    WHERE screen < 15.4 AND
    (hd < 120 AND price >= 1000);

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

ALTER TABLE product ADD CONSTRAINT no_pc_and_printers
CHECK((type ='printer' AND maker NOT IN (
    SELECT * FROM product WHERE type = 'pc')) OR 
    (type = 'pc' AND maker NOT IN (
        SELECT * FROM products WHERE type = 'printer'
    ))
);

WITH ty AS (SELECT COUNT(*) FROM product
            WHERE type = 'pc' AND maker = 'C'),
            total AS (SELECT COUNT(*) FROM product
            WHERE maker = 'C' AND (type = 'pc' OR type = 'printer'))
        SELECT * FROM ty, total WHERE ty.count < total.count;

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


WITH p AS (SELECT * FROM pc),
                l AS (SELECT * FROM laptop)
            SELECT l.price AS l_price, l.hd AS l_hd, p.price AS p_price, p.hd AS p_hd FROM l, p WHERE l.ram > p.ram AND l.price <= p.price;

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

WITH man AS (SELECT maker, model FROM product WHERE maker = 'A')
SELECT man.maker, pc.model FROM pc, man WHERE man.model = pc.model;

WITH m_pc AS (
    SELECT MIN(pc.speed) FROM product  AS p
    INNER JOIN pc
    ON pc.model = p.model
    WHERE p.maker = 'A'),
m_laptop AS (
	SELECT * FROM product AS p
	INNER JOIN laptop AS l
	ON l.model = p.model
	WHERE p.maker = ('A')
)
SELECT * FROM m_pc, m_laptop
WHERE m_laptop.speed >= m_pc.min;

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
CHECK(min_speed(model));