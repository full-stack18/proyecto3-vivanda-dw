-- =========================================================
-- Carga de catálogo: Categorias, Subcategorias, Marcas,
-- Productos, Proveedores, Empleados, Clientes,
-- MetodosPago, Promociones
-- =========================================================

-- 1. Categorias (8)
INSERT INTO Categorias (NombreCategoria) VALUES
('Abarrotes'),('Lacteos y Refrigerados'),('Bebidas'),('Frutas y Verduras'),
('Carnes y Pescados'),('Panaderia y Pasteleria'),('Limpieza del Hogar'),
('Cuidado Personal');

-- 2. Subcategorias (19)
INSERT INTO Subcategorias (CategoriaID, NombreSubcategoria)
SELECT c.CategoriaID, v.Subcat
FROM Categorias c
JOIN (VALUES
 ('Abarrotes','Arroz y Menestras'),('Abarrotes','Aceites y Conservas'),
 ('Abarrotes','Snacks y Galletas'),
 ('Lacteos y Refrigerados','Leches y Yogures'),
 ('Lacteos y Refrigerados','Quesos y Embutidos'),
 ('Bebidas','Gaseosas'),('Bebidas','Aguas y Jugos'),
 ('Bebidas','Cervezas y Licores'),
 ('Frutas y Verduras','Frutas'),('Frutas y Verduras','Verduras'),
 ('Carnes y Pescados','Carnes Rojas'),('Carnes y Pescados','Pollo y Aves'),
 ('Carnes y Pescados','Pescados y Mariscos'),
 ('Panaderia y Pasteleria','Pan'),('Panaderia y Pasteleria','Pasteles y Dulces'),
 ('Limpieza del Hogar','Detergentes'),('Limpieza del Hogar','Papel y Desechables'),
 ('Cuidado Personal','Higiene Personal'),('Cuidado Personal','Cuidado Capilar')
) v(CategoriaNombre, Subcat) ON v.CategoriaNombre = c.NombreCategoria;

-- 3. Marcas (20)
INSERT INTO Marcas (NombreMarca) VALUES
('Gloria'),('Laive'),('Alicorp'),('Nestle'),('Backus'),('Ajeper'),
('San Fernando'),('Redondos'),('Ecofresh'),('Costeno'),('Molitalia'),
('Kraft Heinz'),('Procter Gamble'),('Unilever'),('Colgate Palmolive'),
('Loreal'),('Bimbo'),('Don Vittorio'),('Franco'),('Watts');

-- 4. Productos (450) -- combinaciones de subcategoria x marca + precio/costo pseudo-aleatorio
WITH Serie AS (
    SELECT value AS n FROM GENERATE_SERIES(1, 450)
),
Combos AS (
    SELECT s.SubcategoriaID, m.MarcaID, s.NombreSubcategoria,
           ROW_NUMBER() OVER (ORDER BY s.SubcategoriaID, m.MarcaID) AS rn
    FROM Subcategorias s CROSS JOIN Marcas m
),
TotalCombos AS (SELECT COUNT(*) AS Total FROM Combos)
INSERT INTO Productos (SKU, NombreProducto, SubcategoriaID, MarcaID, PrecioVenta, CostoUnitario)
SELECT
    CONCAT('SKU-', FORMAT(n.n, '00000')),
    CONCAT(c.NombreSubcategoria, ' ', n.n),
    c.SubcategoriaID,
    c.MarcaID,
    precio,
    ROUND(precio * (0.55 + (ABS(CHECKSUM(NEWID())) % 21) / 100.0), 2)  -- costo = 55%-75% del precio
FROM Serie n
CROSS JOIN TotalCombos t
JOIN Combos c ON c.rn = ((n.n - 1) % t.Total) + 1
CROSS APPLY (SELECT CAST(3 + (ABS(CHECKSUM(NEWID(), n.n)) % 4700) / 100.0 AS DECIMAL(10,2)) AS precio) p;

-- 5. Proveedores (15, ficticios)
INSERT INTO Proveedores (RazonSocial, RUC, Telefono, Email) VALUES
('Distribuidora San Jose SAC','20123456781','014567890','contacto@sanjose.pe'),
('Comercial Del Sur EIRL','20234567892','014567891','ventas@delsur.pe'),
('Agroindustrias Canete SAC','20345678903','014567892','info@agrocanete.pe'),
('Importadora Pacifico SAC','20456789014','014567893','contacto@pacifico.pe'),
('Distribuciones Lima Norte SAC','20567890125','014567894','ventas@limanorte.pe'),
('Panificadora Central EIRL','20678901236','014567895','pedidos@panicentral.pe'),
('Frigorifico Costa Verde SAC','20789012347','014567896','ventas@costaverde.pe'),
('Bebidas y Mas SAC','20890123458','014567897','contacto@bebidasymas.pe'),
('Limpieza Total Distribuciones SAC','20901234569','014567898','info@limpiezatotal.pe'),
('Cuidado Personal Import SAC','21012345670','014567899','ventas@cuidadopersonal.pe'),
('Verduras Frescas Canete SAC','21123456781','014567900','pedidos@verdurasfrescas.pe'),
('Lacteos del Valle SAC','21234567892','014567901','ventas@lacteosdelvalle.pe'),
('Snacks Nacionales EIRL','21345678903','014567902','contacto@snacksnac.pe'),
('Distribuidora Asia SAC','21456789014','014567903','ventas@distasia.pe'),
('Mayorista Sur Chico SAC','21567890125','014567904','info@surchico.pe');

-- 6. Empleados (40)
WITH Nombres AS (SELECT * FROM (VALUES
    ('Maria'),('Jose'),('Ana'),('Carlos'),('Lucia'),('Miguel'),('Rosa'),
    ('Jorge'),('Carmen'),('Luis')) n(Nombre)),
Apellidos AS (SELECT * FROM (VALUES
    ('Garcia'),('Rodriguez'),('Perez'),('Sanchez'),('Flores'),('Ramirez'),
    ('Torres'),('Diaz')) a(Apellido)),
Cargos AS (SELECT * FROM (VALUES
    ('Cajero'),('Reponedor'),('Supervisor'),('Atencion al Cliente')) c(Cargo)),
Serie AS (SELECT value AS n FROM GENERATE_SERIES(1, 40))
INSERT INTO Empleados (Nombres, Apellidos, Cargo, FechaIngreso)
SELECT
    (SELECT Nombre FROM (SELECT Nombre, ROW_NUMBER() OVER (ORDER BY Nombre) rn FROM Nombres) x WHERE rn = ((s.n - 1) % 10) + 1),
    (SELECT Apellido FROM (SELECT Apellido, ROW_NUMBER() OVER (ORDER BY Apellido) rn FROM Apellidos) x WHERE rn = ((s.n * 3 - 1) % 8) + 1),
    (SELECT Cargo FROM (SELECT Cargo, ROW_NUMBER() OVER (ORDER BY Cargo) rn FROM Cargos) x WHERE rn = ((s.n - 1) % 4) + 1),
    DATEADD(DAY, -(ABS(CHECKSUM(NEWID())) % 730), '2026-01-01')
FROM Serie s;

-- 7. Clientes (2000)
WITH Nombres AS (SELECT * FROM (VALUES
    ('Maria'),('Jose'),('Ana'),('Carlos'),('Lucia'),('Miguel'),('Rosa'),
    ('Jorge'),('Carmen'),('Luis'),('Patricia'),('Fernando'),('Diana'),
    ('Ricardo'),('Sofia')) n(Nombre)),
Apellidos AS (SELECT * FROM (VALUES
    ('Garcia'),('Rodriguez'),('Perez'),('Sanchez'),('Flores'),('Ramirez'),
    ('Torres'),('Diaz'),('Castillo'),('Vargas'),('Chavez'),('Rojas')) a(Apellido)),
Serie AS (SELECT value AS n FROM GENERATE_SERIES(1, 2000))
INSERT INTO Clientes (Nombres, Apellidos, Email, Telefono, PuntosFidelizacion, FechaRegistro)
SELECT
    nom.Nombre,
    ape.Apellido,
    CONCAT('cliente', s.n, '@correo.com'),
    CONCAT('9', RIGHT('00000000' + CAST(ABS(CHECKSUM(NEWID())) % 99999999 AS VARCHAR), 8)),
    ABS(CHECKSUM(NEWID())) % 500,
    DATEADD(DAY, -(ABS(CHECKSUM(NEWID())) % 730), '2026-01-01')
FROM Serie s
CROSS APPLY (SELECT Nombre FROM (SELECT Nombre, ROW_NUMBER() OVER (ORDER BY Nombre) rn FROM Nombres) x WHERE rn = ((s.n - 1) % 15) + 1) nom
CROSS APPLY (SELECT Apellido FROM (SELECT Apellido, ROW_NUMBER() OVER (ORDER BY Apellido) rn FROM Apellidos) x WHERE rn = ((s.n * 7 - 1) % 12) + 1) ape;

-- 8. MetodosPago (5)
INSERT INTO MetodosPago (NombreMetodo) VALUES
('Efectivo'),('Tarjeta Debito'),('Tarjeta Credito'),('Yape'),('Plin');

-- 9. Promociones (20, concentradas en temporada de verano dic-mar)
INSERT INTO Promociones (NombrePromocion, TipoDescuento, ValorDescuento, FechaInicio, FechaFin) VALUES
('Verano Vivanda 2024','PORCENTAJE',15.00,'2024-12-01','2024-03-15'),
('Semana del Bloqueador','PORCENTAJE',20.00,'2024-12-15','2024-12-31'),
('Playa y Parrilla','PORCENTAJE',10.00,'2025-01-05','2025-01-31'),
('Aniversario Vivanda','MONTO_FIJO',10.00,'2024-11-01','2024-11-15'),
('Regreso a Clases','PORCENTAJE',12.00,'2024-03-01','2024-03-20'),
('Verano Vivanda 2025','PORCENTAJE',18.00,'2025-12-01','2025-12-31'),
('Ofertas de Invierno','PORCENTAJE',8.00,'2024-06-01','2024-06-30'),
('Fiestas Patrias','PORCENTAJE',10.00,'2024-07-15','2024-07-30'),
('Semana del Bebe','MONTO_FIJO',15.00,'2024-08-01','2024-08-15'),
('Dia de la Madre','PORCENTAJE',15.00,'2024-05-01','2024-05-14'),
('Fin de Ano Verano','PORCENTAJE',20.00,'2025-01-01','2025-01-15'),
('Carnaval Playero','PORCENTAJE',10.00,'2025-02-01','2025-02-28'),
('Semana Santa','PORCENTAJE',8.00,'2024-04-01','2024-04-10'),
('Halloween Snacks','MONTO_FIJO',5.00,'2024-10-25','2024-10-31'),
('Navidad Vivanda','PORCENTAJE',12.00,'2024-12-20','2024-12-25'),
('Ano Nuevo','PORCENTAJE',10.00,'2024-12-28','2025-01-02'),
('Verano Vivanda 2026','PORCENTAJE',18.00,'2026-01-01','2026-03-15'),
('Ofertas Otono','PORCENTAJE',8.00,'2025-04-01','2025-04-30'),
('Dia del Padre','PORCENTAJE',12.00,'2024-06-15','2024-06-21'),
('Cyber Vivanda','PORCENTAJE',25.00,'2024-09-15','2024-09-18');