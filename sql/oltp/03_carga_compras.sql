-- =========================================================
-- Carga de Compras, DetalleCompra e Inventario inicial
-- =========================================================

-- 1. Compras (300), concentradas en pre/post temporada de verano
WITH Serie AS (SELECT value AS n FROM GENERATE_SERIES(1, 300))
INSERT INTO Compras (ProveedorID, EmpleadoID, FechaCompra, MontoTotal)
SELECT
    prov.ProveedorID,
    emp.EmpleadoID,
    fecha.FechaCompra,
    0   -- se recalcula en el paso 3
FROM Serie s
CROSS APPLY (SELECT TOP 1 ProveedorID FROM Proveedores ORDER BY NEWID()) prov
CROSS APPLY (SELECT TOP 1 EmpleadoID FROM Empleados ORDER BY NEWID()) emp
CROSS APPLY (
    SELECT CAST(
        DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 28,
            CASE (ABS(CHECKSUM(NEWID())) % 4)
                WHEN 0 THEN '2024-10-01'   -- pre-verano 2024
                WHEN 1 THEN '2024-04-01'   -- post-verano 2024
                WHEN 2 THEN '2025-10-01'   -- pre-verano 2025
                ELSE '2025-04-01'          -- post-verano 2025
            END
        ) AS DATETIME2)
    AS FechaCompra
) fecha;

-- 2. DetalleCompra: 5 a 15 productos distintos por compra, cantidades 20-200
INSERT INTO DetalleCompra (CompraID, ProductoID, Cantidad, CostoUnitario)
SELECT
    c.CompraID,
    p.ProductoID,
    20 + ABS(CHECKSUM(NEWID())) % 181,
    p.CostoUnitario
FROM Compras c
CROSS APPLY (SELECT 5 + ABS(CHECKSUM(NEWID())) % 11 AS NumProductos) np
CROSS APPLY (
    SELECT TOP (np.NumProductos) ProductoID, CostoUnitario
    FROM Productos
    ORDER BY NEWID()
) p;

-- 3. Actualizar MontoTotal de Compras segun el detalle real
UPDATE c
SET c.MontoTotal = t.Total
FROM Compras c
JOIN (
    SELECT CompraID, SUM(Cantidad * CostoUnitario) AS Total
    FROM DetalleCompra
    GROUP BY CompraID
) t ON t.CompraID = c.CompraID;

-- 4. Inventario inicial: stock = total comprado por producto
--    (productos sin compras registradas parten con 100 unidades por defecto)
INSERT INTO Inventario (ProductoID, StockActual, StockMinimo, UltimaActualizacion)
SELECT
    p.ProductoID,
    ISNULL(t.TotalComprado, 100),
    20,
    SYSDATETIME()
FROM Productos p
LEFT JOIN (
    SELECT ProductoID, SUM(Cantidad) AS TotalComprado
    FROM DetalleCompra
    GROUP BY ProductoID
) t ON t.ProductoID = p.ProductoID;

-- 5. MovimientosInventario: una entrada por cada linea de compra
INSERT INTO MovimientosInventario (ProductoID, TipoMovimiento, Cantidad, FechaMovimiento, RefCompraID, RefVentaID)
SELECT
    dc.ProductoID,
    'ENTRADA',
    dc.Cantidad,
    c.FechaCompra,
    dc.CompraID,
    NULL
FROM DetalleCompra dc
JOIN Compras c ON c.CompraID = dc.CompraID;