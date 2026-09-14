-- =========================================================
-- Carga de Ventas, DetalleVenta y salidas de Inventario
-- Simula estacionalidad: temporada alta dic-mar en Asia
-- =========================================================

-- 1. Calendario de dias con ventas: cada dia entre 2024-01-01 y 2025-12-31
--    tiene entre N y M transacciones segun temporada
DROP TABLE IF EXISTS #CalendarioVentas;

WITH Fechas AS (
    SELECT CAST('2024-01-01' AS DATE) AS Fecha
    UNION ALL
    SELECT DATEADD(DAY, 1, Fecha) FROM Fechas WHERE Fecha < '2025-12-31'
)
SELECT
    Fecha,
    MONTH(Fecha) AS Mes,
    CASE WHEN MONTH(Fecha) IN (12,1,2,3) THEN 1 ELSE 0 END AS EsTemporadaAlta,
    CASE
        WHEN MONTH(Fecha) IN (12,1,2,3) THEN 60 + ABS(CHECKSUM(NEWID())) % 61   -- 60-120 ventas/dia en verano
        ELSE 10 + ABS(CHECKSUM(NEWID())) % 16                                    -- 10-25 ventas/dia resto del año
    END AS NumVentasDia
INTO #CalendarioVentas
FROM Fechas
OPTION (MAXRECURSION 800);

-- 2. Expandir el calendario: una fila por cada venta a generar, con su fecha/hora
DROP TABLE IF EXISTS #VentasAGenerar;

SELECT
    cv.Fecha,
    DATEADD(SECOND,
        (8*3600) + ABS(CHECKSUM(NEWID())) % (13*3600),  -- horario 8am-9pm
        CAST(cv.Fecha AS DATETIME2)
    ) AS FechaHoraVenta,
    ROW_NUMBER() OVER (ORDER BY cv.Fecha, s.value) AS VentaTemp
INTO #VentasAGenerar
FROM #CalendarioVentas cv
CROSS APPLY GENERATE_SERIES(1, cv.NumVentasDia) s;

-- 3. Insertar encabezados de Ventas
INSERT INTO Ventas (EmpleadoID, ClienteID, MetodoPagoID, FechaVenta, MontoTotal)
SELECT
    emp.EmpleadoID,
    CASE WHEN ABS(CHECKSUM(NEWID())) % 100 < 70 THEN cli.ClienteID ELSE NULL END,  -- 70% con cliente identificado
    mp.MetodoPagoID,
    v.FechaHoraVenta,
    0   -- se recalcula despues
FROM #VentasAGenerar v
CROSS APPLY (SELECT TOP 1 EmpleadoID FROM Empleados ORDER BY NEWID()) emp
CROSS APPLY (SELECT TOP 1 ClienteID FROM Clientes ORDER BY NEWID()) cli
CROSS APPLY (SELECT TOP 1 MetodoPagoID FROM MetodosPago ORDER BY NEWID()) mp;

-- 4. Mapear VentaID real generado con el orden temporal (para el detalle)
DROP TABLE IF EXISTS #VentasConID;

SELECT
    VentaID,
    FechaVenta,
    ROW_NUMBER() OVER (ORDER BY VentaID) AS VentaTemp
INTO #VentasConID
FROM Ventas;

-- 5. DetalleVenta: 1 a 8 lineas por venta, con promocion si aplica
INSERT INTO DetalleVenta (VentaID, ProductoID, PromocionID, Cantidad, PrecioUnitario, Descuento, MontoLinea)
SELECT
    vc.VentaID,
    p.ProductoID,
    promo.PromocionID,
    cant.Cantidad,
    p.PrecioVenta,
    CASE
        WHEN promo.PromocionID IS NULL THEN 0
        WHEN promo.TipoDescuento = 'PORCENTAJE' THEN ROUND(p.PrecioVenta * cant.Cantidad * promo.ValorDescuento / 100.0, 2)
        ELSE promo.ValorDescuento
    END AS Descuento,
    (p.PrecioVenta * cant.Cantidad) -
        CASE
            WHEN promo.PromocionID IS NULL THEN 0
            WHEN promo.TipoDescuento = 'PORCENTAJE' THEN ROUND(p.PrecioVenta * cant.Cantidad * promo.ValorDescuento / 100.0, 2)
            ELSE promo.ValorDescuento
        END AS MontoLinea
FROM #VentasConID vc
CROSS APPLY (SELECT 1 + ABS(CHECKSUM(NEWID())) % 8 AS NumLineas) nl
CROSS APPLY (
    SELECT TOP (nl.NumLineas) ProductoID, PrecioVenta
    FROM Productos ORDER BY NEWID()
) p
CROSS APPLY (SELECT 1 + ABS(CHECKSUM(NEWID())) % 5 AS Cantidad) cant
OUTER APPLY (
    SELECT TOP 1 PromocionID, TipoDescuento, ValorDescuento
    FROM Promociones
    WHERE vc.FechaVenta BETWEEN FechaInicio AND FechaFin
    ORDER BY NEWID()
) promo;

-- 6. Actualizar MontoTotal de Ventas segun el detalle real
UPDATE v
SET v.MontoTotal = t.Total
FROM Ventas v
JOIN (
    SELECT VentaID, SUM(MontoLinea) AS Total
    FROM DetalleVenta
    GROUP BY VentaID
) t ON t.VentaID = v.VentaID;

-- 7. MovimientosInventario: una salida por cada linea de venta
INSERT INTO MovimientosInventario (ProductoID, TipoMovimiento, Cantidad, FechaMovimiento, RefCompraID, RefVentaID)
SELECT
    dv.ProductoID,
    'SALIDA',
    dv.Cantidad,
    v.FechaVenta,
    NULL,
    dv.VentaID
FROM DetalleVenta dv
JOIN Ventas v ON v.VentaID = dv.VentaID;

-- 8. Descontar stock en Inventario segun el total vendido por producto
UPDATE i
SET i.StockActual = i.StockActual - t.TotalVendido,
    i.UltimaActualizacion = SYSDATETIME()
FROM Inventario i
JOIN (
    SELECT ProductoID, SUM(Cantidad) AS TotalVendido
    FROM DetalleVenta
    GROUP BY ProductoID
) t ON t.ProductoID = i.ProductoID;

-- 9. Limpieza de tablas temporales
DROP TABLE IF EXISTS #CalendarioVentas;
DROP TABLE IF EXISTS #VentasAGenerar;
DROP TABLE IF EXISTS #VentasConID;