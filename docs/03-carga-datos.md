# Fase 3 — Construccion del OLTP y carga de datos

## Resultado final
- 15 tablas creadas segun diseño de Fase 1
- Catalogo: 8 categorias, 19 subcategorias, 20 marcas, 450 productos,
  15 proveedores, 40 empleados, 2000 clientes, 5 metodos de pago, 20 promociones
- Historico simulado: 2 años (2024-2025), ~31,000 ventas, ~138,000 lineas
  de detalle de venta
- Estacionalidad: temporada alta (dic-mar) genera ~2.6x mas ventas y
  ~2.5x mas ingresos que temporada baja (22,215 vs 8,545 ventas)
- Reabastecimiento: carga inicial (300 compras) + reabastecimiento
  semanal continuo (105 compras adicionales) para simular reposicion
  real de supermercado
- Resultado de negocio: 89 de 450 productos (19.8%) presentan quiebre
  de stock en algun punto del periodo -- justifica la necesidad de
  monitoreo casi en tiempo real via CDC/streaming
- CDC habilitado en: Ventas, DetalleVenta, Inventario, MovimientosInventario