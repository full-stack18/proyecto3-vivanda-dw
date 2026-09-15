# Fase 4 — Captura CDC hacia Bronze (Azure Data Factory)

## Recursos creados
- Data Factory: adf-vivanda-asia
- Linked Services:
  - LS_SQL_VivandaAsia (Azure SQL Database, origen)
  - LS_ADLS_VivandaAsia (Azure Data Lake Storage Gen2, destino,
    autenticado via Managed Identity con rol Storage Blob Data
    Contributor)
- Recurso Change Data Capture (preview): CDCVivandaAsiaBronze

## Configuracion
- Origen: 4 tablas con CDC nativo habilitado en Azure SQL
  (Ventas, DetalleVenta, Inventario, MovimientosInventario)
- Destino: contenedor bronze/, una carpeta por tabla
  (bronze/dbo.Ventas, bronze/dbo.DetalleVenta, etc.)
- Formato: Parquet
- Latencia: Real-time (streaming continuo, no microlote programado)
- Mapeo de columnas: automatico (Auto map) 1:1 origen-destino

## Notas tecnicas
- Requirio migrar la base OLTP a tier vCore (General Purpose
  Serverless) porque CDC no es compatible con tiers Standard S0-S2
- La credencial de SQL en el linked service se maneja localmente
  (excluida de Git); en un entorno productivo real se usaria
  Azure Key Vault en su lugar

## Synapse (preparacion para Fase 5)
- Workspace: synw-vivanda-asia
- SQL Pool: Serverless (Built-in, incluido por defecto, sin costo
  de aprovisionamiento)
- Storage asociado: contenedor synapsefs en stvivandaasia