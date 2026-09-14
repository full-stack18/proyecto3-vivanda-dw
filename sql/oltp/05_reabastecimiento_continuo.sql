-- =========================================================
-- Reabastecimiento continuo (semanal) durante los 2 años
-- Corrige el stock para reflejar reposicion real de supermercado
-- =========================================================

DROP TABLE IF EXISTS #ComprasSemanales;

WITH Semanas AS (
    SELECT CAST('2024-01-01' AS DATE) AS FechaSemana
    UNION ALL
    SELECT DATEADD(WEEK, 1, FechaSemana) FROM Semanas WHERE FechaSemana < '2025-12-25'
)
SELECT FechaSemana, ROW_NUMBER() OVER (ORDER BY FechaSemana) AS NumSemana
INTO #ComprasSemanales
FROM Semanas
OPTION (MAXRECURSION 200);

DECLARE @UltimaCompraOriginal INT = 300;   -- confirmado con MAX(CompraID)

-- 1. Compras semanales adicionales (104 semanas)
INSERT INTO Compras (ProveedorID, EmpleadoID, FechaCompra, MontoTotal)
SELECT
    prov.ProveedorID,
    emp.EmpleadoID,
    DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 5, CAST(cs.FechaSemana AS DATETIME2)),
    0
FROM #ComprasSemanales cs
CROSS APPLY (SELECT TOP 1 ProveedorID FROM Proveedores ORDER BY NEWID()) prov
CROSS APPLY (SELECT TOP 1 EmpleadoID FROM Empleados ORDER BY NEWID()) emp;

-- 2. DetalleCompra: cada compra nueva reabastece 30-50 productos aleatorios
INSERT INTO DetalleCompra (CompraID, ProductoID, Cantidad, CostoUnitario)
SELECT
    c.CompraID,
    p.ProductoID,
    20 + ABS(CHECKSUM(NEWID())) % 81,   -- 20-100 unidades
    p.CostoUnitario
FROM Compras c
CROSS APPLY (SELECT 30 + ABS(CHECKSUM(NEWID())) % 21 AS NumProductos) np
CROSS APPLY (
    SELECT TOP (np.NumProductos) ProductoID, CostoUnitario
    FROM Productos ORDER BY NEWID()
) p
WHERE c.CompraID > @UltimaCompraOriginal;

-- 3. Actualizar MontoTotal de las compras nuevas
UPDATE c
SET c.MontoTotal = t.Total
FROM Compras c
JOIN (SELECT CompraID, SUM(Cantidad * CostoUnitario) AS Total FROM DetalleCompra GROUP BY CompraID) t
    ON t.CompraID = c.CompraID
WHERE c.MontoTotal = 0;

-- 4. Registrar las entradas de inventario correspondientes
INSERT INTO MovimientosInventario (ProductoID, TipoMovimiento, Cantidad, FechaMovimiento, RefCompraID, RefVentaID)
SELECT dc.ProductoID, 'ENTRADA', dc.Cantidad, c.FechaCompra, dc.CompraID, NULL
FROM DetalleCompra dc
JOIN Compras c ON c.CompraID = dc.CompraID
WHERE c.CompraID > @UltimaCompraOriginal;

-- 5. Sumar el nuevo stock comprado a Inventario
UPDATE i
SET i.StockActual = i.StockActual + t.NuevoStock,
    i.UltimaActualizacion = SYSDATETIME()
FROM Inventario i
JOIN (
    SELECT dc.ProductoID, SUM(dc.Cantidad) AS NuevoStock
    FROM DetalleCompra dc
    JOIN Compras c ON c.CompraID = dc.CompraID
    WHERE c.CompraID > @UltimaCompraOriginal
    GROUP BY dc.ProductoID
) t ON t.ProductoID = i.ProductoID;

DROP TABLE IF EXISTS #ComprasSemanales;