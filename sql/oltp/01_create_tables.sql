-- =========================================================
-- Proyecto 3 - Vivanda Asia OLTP
-- 15 tablas, una sola sucursal (Asia)
-- =========================================================

-- ==== Tablas independientes (sin FK) ====

CREATE TABLE Categorias (
    CategoriaID INT IDENTITY(1,1) PRIMARY KEY,
    NombreCategoria VARCHAR(100) NOT NULL
);

CREATE TABLE Marcas (
    MarcaID INT IDENTITY(1,1) PRIMARY KEY,
    NombreMarca VARCHAR(100) NOT NULL
);

CREATE TABLE Proveedores (
    ProveedorID INT IDENTITY(1,1) PRIMARY KEY,
    RazonSocial VARCHAR(150) NOT NULL,
    RUC CHAR(11) NOT NULL,
    Telefono VARCHAR(20),
    Email VARCHAR(100)
);

CREATE TABLE Empleados (
    EmpleadoID INT IDENTITY(1,1) PRIMARY KEY,
    Nombres VARCHAR(100) NOT NULL,
    Apellidos VARCHAR(100) NOT NULL,
    Cargo VARCHAR(50) NOT NULL,     -- Cajero, Reponedor, Supervisor, etc.
    FechaIngreso DATE NOT NULL,
    Activo BIT NOT NULL DEFAULT 1
);

CREATE TABLE Clientes (
    ClienteID INT IDENTITY(1,1) PRIMARY KEY,
    Nombres VARCHAR(100) NOT NULL,
    Apellidos VARCHAR(100) NOT NULL,
    Email VARCHAR(100),
    Telefono VARCHAR(20),
    PuntosFidelizacion INT NOT NULL DEFAULT 0,
    FechaRegistro DATE NOT NULL DEFAULT GETDATE()
);

CREATE TABLE MetodosPago (
    MetodoPagoID INT IDENTITY(1,1) PRIMARY KEY,
    NombreMetodo VARCHAR(50) NOT NULL   -- Efectivo, Tarjeta, Yape/Plin, etc.
);

CREATE TABLE Promociones (
    PromocionID INT IDENTITY(1,1) PRIMARY KEY,
    NombrePromocion VARCHAR(100) NOT NULL,
    TipoDescuento VARCHAR(20) NOT NULL,   -- 'PORCENTAJE' o 'MONTO_FIJO'
    ValorDescuento DECIMAL(10,2) NOT NULL,
    FechaInicio DATE NOT NULL,
    FechaFin DATE NOT NULL
);

-- ==== Tablas con 1 nivel de dependencia ====

CREATE TABLE Subcategorias (
    SubcategoriaID INT IDENTITY(1,1) PRIMARY KEY,
    CategoriaID INT NOT NULL,
    NombreSubcategoria VARCHAR(100) NOT NULL,
    CONSTRAINT FK_Subcategorias_Categorias
        FOREIGN KEY (CategoriaID) REFERENCES Categorias(CategoriaID)
);

-- ==== Productos (depende de Subcategorias y Marcas) ====

CREATE TABLE Productos (
    ProductoID INT IDENTITY(1,1) PRIMARY KEY,
    SKU VARCHAR(20) NOT NULL UNIQUE,
    NombreProducto VARCHAR(150) NOT NULL,
    SubcategoriaID INT NOT NULL,
    MarcaID INT NOT NULL,
    PrecioVenta DECIMAL(10,2) NOT NULL,
    CostoUnitario DECIMAL(10,2) NOT NULL,
    Activo BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_Productos_Subcategorias
        FOREIGN KEY (SubcategoriaID) REFERENCES Subcategorias(SubcategoriaID),
    CONSTRAINT FK_Productos_Marcas
        FOREIGN KEY (MarcaID) REFERENCES Marcas(MarcaID)
);

-- ==== Compras a proveedor ====

CREATE TABLE Compras (
    CompraID INT IDENTITY(1,1) PRIMARY KEY,
    ProveedorID INT NOT NULL,
    EmpleadoID INT NOT NULL,
    FechaCompra DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    MontoTotal DECIMAL(12,2) NOT NULL,
    CONSTRAINT FK_Compras_Proveedores
        FOREIGN KEY (ProveedorID) REFERENCES Proveedores(ProveedorID),
    CONSTRAINT FK_Compras_Empleados
        FOREIGN KEY (EmpleadoID) REFERENCES Empleados(EmpleadoID)
);

CREATE TABLE DetalleCompra (
    DetalleCompraID INT IDENTITY(1,1) PRIMARY KEY,
    CompraID INT NOT NULL,
    ProductoID INT NOT NULL,
    Cantidad INT NOT NULL,
    CostoUnitario DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_DetalleCompra_Compras
        FOREIGN KEY (CompraID) REFERENCES Compras(CompraID),
    CONSTRAINT FK_DetalleCompra_Productos
        FOREIGN KEY (ProductoID) REFERENCES Productos(ProductoID)
);

-- ==== Ventas (transaccional - candidata a CDC) ====

CREATE TABLE Ventas (
    VentaID INT IDENTITY(1,1) PRIMARY KEY,
    EmpleadoID INT NOT NULL,
    ClienteID INT NULL,               -- venta sin cliente registrado es válida
    MetodoPagoID INT NOT NULL,
    FechaVenta DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    MontoTotal DECIMAL(12,2) NOT NULL,
    CONSTRAINT FK_Ventas_Empleados
        FOREIGN KEY (EmpleadoID) REFERENCES Empleados(EmpleadoID),
    CONSTRAINT FK_Ventas_Clientes
        FOREIGN KEY (ClienteID) REFERENCES Clientes(ClienteID),
    CONSTRAINT FK_Ventas_MetodosPago
        FOREIGN KEY (MetodoPagoID) REFERENCES MetodosPago(MetodoPagoID)
);

-- ==== DetalleVenta (transaccional - candidata a CDC, tabla grande) ====

CREATE TABLE DetalleVenta (
    DetalleVentaID INT IDENTITY(1,1) PRIMARY KEY,
    VentaID INT NOT NULL,
    ProductoID INT NOT NULL,
    PromocionID INT NULL,             -- NULL si no tuvo promoción
    Cantidad INT NOT NULL,
    PrecioUnitario DECIMAL(10,2) NOT NULL,
    Descuento DECIMAL(10,2) NOT NULL DEFAULT 0,
    MontoLinea DECIMAL(12,2) NOT NULL,
    CONSTRAINT FK_DetalleVenta_Ventas
        FOREIGN KEY (VentaID) REFERENCES Ventas(VentaID),
    CONSTRAINT FK_DetalleVenta_Productos
        FOREIGN KEY (ProductoID) REFERENCES Productos(ProductoID),
    CONSTRAINT FK_DetalleVenta_Promociones
        FOREIGN KEY (PromocionID) REFERENCES Promociones(PromocionID)
);

-- ==== Inventario (transaccional - candidata a CDC) ====

CREATE TABLE Inventario (
    InventarioID INT IDENTITY(1,1) PRIMARY KEY,
    ProductoID INT NOT NULL UNIQUE,   -- 1 fila de stock actual por producto
    StockActual INT NOT NULL,
    StockMinimo INT NOT NULL,
    UltimaActualizacion DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Inventario_Productos
        FOREIGN KEY (ProductoID) REFERENCES Productos(ProductoID)
);

-- ==== MovimientosInventario (transaccional - candidata a CDC) ====

CREATE TABLE MovimientosInventario (
    MovimientoID INT IDENTITY(1,1) PRIMARY KEY,
    ProductoID INT NOT NULL,
    TipoMovimiento VARCHAR(10) NOT NULL,  -- 'ENTRADA' o 'SALIDA'
    Cantidad INT NOT NULL,
    FechaMovimiento DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    RefCompraID INT NULL,
    RefVentaID INT NULL,
    CONSTRAINT FK_MovInv_Productos
        FOREIGN KEY (ProductoID) REFERENCES Productos(ProductoID),
    CONSTRAINT FK_MovInv_Compras
        FOREIGN KEY (RefCompraID) REFERENCES Compras(CompraID),
    CONSTRAINT FK_MovInv_Ventas
        FOREIGN KEY (RefVentaID) REFERENCES Ventas(VentaID),
    CONSTRAINT CHK_MovInv_Tipo
        CHECK (TipoMovimiento IN ('ENTRADA','SALIDA'))
);