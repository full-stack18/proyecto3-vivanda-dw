# Fase 2 — Recursos Azure aprovisionados

Región: Brazil South
Suscripción: Azure for Students (2d77f138-b08f-4d52-be73-3331bab1a442)

| Recurso | Nombre | Tipo |
|---|---|---|
| Resource Group | rg-vivanda-asia-dw | - |
| Storage Account (ADLS Gen2) | stvivandaasia | StorageV2, hierarchical namespace habilitado |
| Contenedores | bronze, silver, gold | Arquitectura Medallion |
| SQL Server | sql-vivanda-asia | Admin: vivandadmin |
| SQL Database (OLTP) | VivandaAsia_OLTP | General Purpose Serverless (GP_S_Gen5_1), 0.5-1 vCore, autopause 60min. Migrado desde Standard S0 porque CDC no es compatible con tiers DTU por debajo de S3. |
| Firewall | AllowMyIP, AllowAzureServices | Reglas de acceso |

## Notas
- Providers registrados manualmente: Microsoft.Storage, Microsoft.Sql,
  Microsoft.DataFactory, Microsoft.Synapse (necesario en suscripciones
  nuevas de Azure for Students, no vienen registrados por defecto).
- Login de Azure CLI requirió `--tenant` explícito por bloqueo de
  Security Defaults (AADSTS530035) en el flujo estándar.
- Data Factory y Synapse se crean en la Fase 4 y Fase 7 respectivamente,
  no antes, para no pagar recursos ociosos mientras se construye el OLTP.