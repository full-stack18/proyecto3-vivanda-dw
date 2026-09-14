# Fase 1 — Diseño de negocio y modelo de datos
## Proyecto 3 — Data Warehouse en la Nube (Azure) — Vivanda Asia

## Caso de negocio
Vivanda Asia es la tienda insignia de la cadena Vivanda (Supermercados Peruanos /
Intercorp), ubicada en el km 97.3 de la Panamericana Sur, distrito de Asia, Cañete.
Su demanda es fuertemente estacional: se dispara en temporada de verano
(diciembre-marzo, por el balneario) y cae el resto del año.

**Problema de negocio:** esta volatilidad extrema hace que el control de
inventario y ventas casi en tiempo real sea crítico — un quiebre de stock en
temporada alta es mucho más costoso que en una tienda urbana estable.
**Esto justifica la arquitectura streaming/CDC** del proyecto (vs. un batch nocturno).

## Modelo OLTP (15 tablas, una sola sucursal)
Catálogo: Categorias, Subcategorias, Marcas, Productos, Proveedores
Compras: Compras, DetalleCompra
Personas: Empleados (incluye Cargo), Clientes (incluye PuntosFidelizacion)
Soporte: MetodosPago, Promociones
Transaccional (con CDC habilitado): Ventas, DetalleVenta, Inventario, MovimientosInventario

Tabla principal para volumen: DetalleVenta (objetivo 150,000-250,000 filas,
simulando 2 años con picos de temporada alta en Asia).

## Modelo dimensional (capa Gold) — esquema estrella
- Fact_Ventas (grano: producto vendido por línea de venta)
- Fact_Inventario (grano: producto x fecha/hora del evento de stock)
- Dim_Producto (categoria/subcategoria/marca denormalizadas)
- Dim_Cliente, Dim_Empleado, Dim_Tiempo, Dim_MetodoPago, Dim_Promocion

**Justificación estrella (no copo de nieve):** el dashboard se refresca cada
pocos minutos, menos joins = queries más rápidas en Synapse; la jerarquía de
producto es de solo 3 niveles y estática, no justifica el costo de mantenimiento
de un copo de nieve.

## Alcance de CDC
- Con CDC: Ventas, DetalleVenta, Inventario, MovimientosInventario
- Sin CDC (batch periódico vía dbt normal): Productos, Clientes, catálogos

## Infraestructura Azure (Fase 2)
Región: Brazil South (plan B: East US 2)
- Resource Group: rg-vivanda-asia-dw
- SQL Server: sql-vivanda-asia
- SQL Database (OLTP): VivandaAsia_OLTP
- Storage Account (ADLS Gen2): stvivandaasia
- Data Factory: adf-vivanda-asia
- Synapse Workspace: synw-vivanda-asia