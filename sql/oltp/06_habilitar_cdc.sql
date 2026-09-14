-- =========================================================
-- Habilitar Change Data Capture (CDC)
-- Solo en las 4 tablas transaccionales de alta frecuencia
-- =========================================================

-- 1. Habilitar CDC a nivel de base de datos (una sola vez)
EXEC sys.sp_cdc_enable_db;

-- 2. Habilitar CDC en cada tabla transaccional
EXEC sys.sp_cdc_enable_table
    @source_schema = 'dbo',
    @source_name   = 'Ventas',
    @role_name     = NULL,
    @supports_net_changes = 1;

EXEC sys.sp_cdc_enable_table
    @source_schema = 'dbo',
    @source_name   = 'DetalleVenta',
    @role_name     = NULL,
    @supports_net_changes = 1;

EXEC sys.sp_cdc_enable_table
    @source_schema = 'dbo',
    @source_name   = 'Inventario',
    @role_name     = NULL,
    @supports_net_changes = 1;

EXEC sys.sp_cdc_enable_table
    @source_schema = 'dbo',
    @source_name   = 'MovimientosInventario',
    @role_name     = NULL,
    @supports_net_changes = 1;