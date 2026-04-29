# Diagrama actualizado de la base de datos Isar

Este documento refleja el estado actual del esquema de persistencia local en Isar.

## Resumen del esquema

- Colecciones Isar activas (abiertas en `openIsar()`): 8
- Tipos embebidos (`@embedded`): 2
- Enumeraciones persistidas (`@enumerated`): 4
- Modelos de Verifactu (`verifactu_models.dart`): DTOs de transporte, no se persisten en Isar

## Colecciones Isar (`@collection`)

1. User
2. Product
3. Ticket
4. DailyReport
5. Config
6. BusinessConfig
7. Expense
8. FiscalTicketTrace

## Tipos embebidos (`@embedded`)

1. TicketLine (embebido en Ticket.lines)
2. FiscalTicketTraceLine (embebido en FiscalTicketTrace.lines)

## Enumeraciones persistidas

1. TicketStatus: abierto, pagado, cancelado
2. PaymentMethod: efectivo, tarjeta, mixto
3. ExpenseCategory: compras, facturas, personal, otro
4. TaxRate: exento, superReducido, reducido, general

## Índices Isar

- User.email: índice único (`email_index`)
- Ticket.createdAt: índice
- Ticket.status: índice
- Ticket.isParked: índice
- DailyReport.date: índice
- FiscalTicketTrace.invoiceId: índice único

## Diagrama ER (estado actual)

```mermaid
erDiagram
	USER {
		long id PK
		string username
		string lastName
		string password
		string email UK
		string phone
		string ticketDisplayName
		string role
		string companyName
		string taxId
		string address
		string logoPath
		bool backendEditable
	}

	PRODUCT {
		long id PK
		string name
		double price
		double costPrice
		int stock
		string category
		string barcode
		string imagePath
		string taxRate ENUM
	}

	TICKET {
		long id PK
		string uuid
		datetime createdAt INDEX
		string status ENUM_INDEX
		string paymentMethod ENUM
		double totalAmount
		int tableNumber
		string tableOrLabel
		bool isParked INDEX
		string zone
		string parentTicketUuid
	}

	TICKET_LINE {
		string productName
		int productId
		int quantity
		double priceAtMoment
		double totalLine
	}

	DAILY_REPORT {
		long id PK
		datetime date INDEX
		double totalCash
		double totalCard
		double grandTotal
		int ticketCount
		double totalExpenses
		string soldProductsSummary[]
	}

	EXPENSE {
		long id PK
		datetime date
		double amount
		string category ENUM
		string description
		int productId
		string productName
		int quantity
	}

	CONFIG {
		long id PK
		string businessMode
		string businessName
		string printerMacAddress
		bool verifactuRegistered
		bool verifactuIsNewSystem
		string verifactuClientId
		string verifactuClientHash
		datetime verifactuLastAuthAt
	}

	BUSINESS_CONFIG {
		long id PK
		string businessName
		string fiscalName
		string cifNif
		string address
		string logoPath
		string adminPassword
		string phone
		string email
	}

	FISCAL_TICKET_TRACE {
		long id PK
		string invoiceId UK
		datetime createdAt
		string ticketUuid
		string ticketZone
		int ticketTableNumber
		string ticketTableLabel
		string paymentMethod
		string invoiceSeries
		int invoiceNumber
		double totalAmount
		string queueStatus
		string printedFiscalStatus
		string printedQrPayload
		string fiscalStatus
		string secureVerificationCode
		string verificationUrl
		string responseCode
		string responseDescription
	}

	FISCAL_TICKET_TRACE_LINE {
		string productName
		int quantity
		double unitPrice
		double totalLine
	}

	TICKET ||--|{ TICKET_LINE : "embebe lines[]"
	FISCAL_TICKET_TRACE ||--|{ FISCAL_TICKET_TRACE_LINE : "embebe lines[]"

	PRODUCT ||--o{ EXPENSE : "referencia logica por productId"
	TICKET ||--o{ TICKET : "parentTicketUuid -> uuid (pago parcial)"
```

## Notas importantes

1. `TicketLine` y `FiscalTicketTraceLine` no son colecciones separadas; se almacenan dentro del documento padre.
2. No hay `Link`/`IsarLinks` explícitos entre colecciones; las relaciones se resuelven de forma lógica por IDs o UUID.
3. `verifactu_models.dart` define estructuras de API (backend/fiscal) y no forma parte del esquema persistido.






El diagrama de modelado de datos completo se presenta en la Figura XVI.

Colección User (gestión de acceso y datos de emisor):
● id: Id (clave primaria interna autoincremental de Isar).
● username: String? (nombre de usuario para login o visualización).
● lastName: String? (apellidos del usuario).
● password: String? (hash de contraseña almacenado localmente).
● email: String? (correo para login alternativo; índice único).
● phone: String? (teléfono de contacto del usuario).
● ticketDisplayName: String? (nombre corto mostrado en tickets).
● role: String (rol de acceso: admin o user).
● companyName: String? (razón social asociada al usuario).
● taxId: String? (NIF/CIF del emisor).
● address: String? (dirección fiscal/comercial del emisor).
● logoPath: String? (ruta local del logotipo).
● backendEditable: bool (bloquea o permite edición desde frontend).

Colección Product (catálogo de artículos):
● id: Id (clave primaria interna autoincremental).
● name: String (nombre comercial del producto).
● price: double (PVP usado para venta).
● costPrice: double? (precio de coste para margen y compras).
● stock: int (unidades disponibles en inventario).
● category: String? (categoría funcional del producto).
● barcode: String? (código de barras para escaneo).
● imagePath: String? (ruta local de imagen del producto).
● taxRate: TaxRate (tipo de IVA aplicado al producto).

Colección Ticket (registro operativo de venta):
● id: Id (clave primaria interna).
● uuid: String (identificador global único del ticket).
● createdAt: DateTime (fecha/hora de creación; índice temporal).
● status: TicketStatus (estado del ticket; índice por estado).
● paymentMethod: PaymentMethod (método de cobro principal).
● totalAmount: double (importe total acumulado del ticket).
● tableNumber: int? (número de mesa cuando aplica).
● tableOrLabel: String? (etiqueta libre de mesa o pedido).
● isParked: bool (indica ticket aparcado; índice de consulta rápida).
● zone: String? (zona/sala del establecimiento).
● parentTicketUuid: String? (uuid del ticket padre en cobros parciales).
● lines: List<TicketLine> (líneas embebidas de productos vendidos).

Tipo embebido TicketLine (detalle de línea de venta):
● productName: String (nombre del producto al momento de vender).
● productId: int (referencia lógica a Product.id).
● quantity: int (cantidad de unidades en la línea).
● priceAtMoment: double (precio unitario congelado en esa venta).
● totalLine: double (subtotal de la línea: cantidad x precio).

Colección DailyReport (cierre diario):
● id: Id (clave primaria interna).
● date: DateTime (fecha de cierre; índice de consulta diaria).
● totalCash: double (total cobrado en efectivo).
● totalCard: double (total cobrado con tarjeta).
● grandTotal: double (total neto del cierre).
● ticketCount: int (cantidad de tickets liquidados).
● totalExpenses: double (gastos descontados del día).
● soldProductsSummary: List<String> (resumen textual de ventas por producto).

Colección Expense (gastos operativos):
● id: Id (clave primaria interna).
● date: DateTime (fecha del gasto registrado).
● amount: double (importe monetario del gasto).
● category: ExpenseCategory (tipo de gasto: compras/facturas/personal/otro).
● description: String (detalle descriptivo del gasto).
● productId: int (referencia lógica a producto en gastos de compra).
● productName: String (nombre del producto asociado al gasto).
● quantity: int (cantidad comprada asociada al gasto).

Colección Config (configuración operativa y estado Verifactu):
● id: Id (clave primaria interna).
● businessMode: String (modo funcional del TPV, por defecto bar).
● businessName: String (campo legacy mantenido por compatibilidad).
● printerMacAddress: String? (MAC de impresora térmica configurada).
● verifactuRegistered: bool (indica si el TPV está registrado en backend fiscal).
● verifactuIsNewSystem: bool (marca si la instalación es alta inicial).
● verifactuClientId: String? (identificador de cliente para autenticación fiscal).
● verifactuClientHash: String? (huella/hash de validación del cliente).
● verifactuLastAuthAt: DateTime? (última autenticación realizada con backend).

Colección BusinessConfig (datos fiscales y administrativos del negocio):
● id: Id (clave primaria interna).
● businessName: String (nombre comercial del establecimiento).
● fiscalName: String (razón social para documentos fiscales).
● cifNif: String (identificación fiscal del negocio).
● address: String (domicilio fiscal del negocio).
● logoPath: String? (ruta local del logotipo del negocio).
● adminPassword: String (contraseña de administración local).
● phone: String? (teléfono de contacto del negocio).
● email: String? (correo de contacto del negocio).

Colección FiscalTicketTrace (trazabilidad fiscal de emisiones):
● id: Id (clave primaria interna).
● invoiceId: String (id de factura fiscal; índice único).
● createdAt: DateTime (fecha/hora de creación de la traza).
● ticketUuid: String? (uuid del ticket origen vinculado).
● ticketZone: String? (zona del ticket origen).
● ticketTableNumber: int? (número de mesa del ticket origen).
● ticketTableLabel: String? (etiqueta textual de mesa/origen).
● paymentMethod: String? (método de pago serializado para auditoría).
● invoiceSeries: String (serie fiscal asignada por backend).
● invoiceNumber: int (número fiscal correlativo).
● totalAmount: double (importe total informado fiscalmente).
● queueStatus: String (estado de cola de emisión fiscal).
● printedFiscalStatus: String? (estado fiscal impreso en ticket).
● printedQrPayload: String? (contenido QR impreso en ticket).
● fiscalStatus: String? (estado fiscal recibido de backend/AEAT).
● secureVerificationCode: String? (CSV/código seguro de verificación).
● verificationUrl: String? (URL de verificación fiscal oficial).
● responseCode: String? (código de respuesta técnica del backend).
● responseDescription: String? (descripción de respuesta técnica).
● lines: List<FiscalTicketTraceLine> (líneas embebidas del ticket fiscalizado).

Tipo embebido FiscalTicketTraceLine (detalle de línea fiscal):
● productName: String (nombre del producto enviado a fiscalización).
● quantity: int (cantidad fiscalizada en la línea).
● unitPrice: double (precio unitario reportado fiscalmente).
● totalLine: double (subtotal fiscal de la línea).

## Justificación de la replicación de campos de empresa (BusinessConfig y User)

En el estado actual del sistema, algunos datos de empresa (nombre comercial, CIF/NIF, dirección, logo) aparecen tanto en la colección BusinessConfig como en el usuario administrador (User). Esta duplicación es intencional por motivos operativos y de compatibilidad.

### Motivo principal

Se mantienen dos fuentes porque cada una cumple un rol distinto:

1. BusinessConfig actúa como configuración global del negocio.
2. User (admin) actúa como identidad operativa usada en flujos de sesión, perfil y sincronización con Verifactu.

### Evidencia funcional en la aplicación

1. Cadena de fallback en impresión de ticket:
El servicio de impresión resuelve los datos del emisor en este orden:
parametros explicitos -> BusinessConfig -> User admin -> valores por defecto.

Este comportamiento permite seguir imprimiendo aunque una de las dos fuentes esté incompleta.

2. Escritura sincronizada desde perfil:
Cuando se guardan datos de empresa desde la UI de perfil, se actualizan tanto User como BusinessConfig. Esta doble escritura busca mantener consistencia entre ambas estructuras.

3. Sincronización desde Verifactu:
Cuando Verifactu devuelve identidad fiscal validada, el sistema actualiza campos en el usuario admin y puede bloquear edición local mediante backendEditable. Esto refuerza el uso del User admin como identidad operativa de runtime.

4. Campos de naturaleza global en BusinessConfig:
BusinessConfig incluye datos de configuración transversal (por ejemplo, adminPassword) que no corresponden a un perfil de usuario estándar, por lo que sigue siendo necesario como entidad separada.

### Beneficios de mantener la replicación actualmente

1. Resiliencia: si falta un dato en una fuente, la otra puede actuar como respaldo.
2. Compatibilidad: evita romper flujos ya existentes mientras conviven módulos antiguos y nuevos.
3. Continuidad operativa: impresión, perfil y fiscalidad pueden funcionar sin depender de una única ruta de datos.

### Coste y riesgo técnico

El principal riesgo es la desalineación temporal entre BusinessConfig y User cuando un flujo actualiza solo uno de los dos lados. Esta desalineación puede reflejar datos diferentes en pantalla, impresión o emisión fiscal según qué fuente se consulte primero.

### Conclusión

La repetición de campos no responde a un error de modelado puntual, sino a una decisión de transición y robustez operacional. Mientras exista fallback y sincronización cruzada entre módulos, ambas estructuras deben convivir. La mejora futura natural sería consolidar una fuente canónica única y dejar la otra como vista derivada o cache de compatibilidad.
