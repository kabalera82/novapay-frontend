PROPUESTA DE SOLUCIÓN Y DISEÑO
1.	Arquitectura del Sistema
	El sistema se estructura bajo el patrón arquitectónico MVVM (Microsoft, s.f.) (Model-View-ViewModel es una arquitectura de software que separa la interfaz de usuario de la lógica de negocio en tres capas diferenciadas: el Model, que gestiona los datos y las reglas de negocio; la View, que representa la interfaz visual con la que interactúa el usuario; y el ViewModel, que actúa como intermediario entre ambas capas, exponiendo los datos del modelo de forma reactiva para que la vista se actualice automáticamente ante cualquier cambio) combinado con el patrón Repository, garantizando una clara separación de responsabilidades entre la interfaz gráfica y la lógica de negocio. La arquitectura se divide en tres capas principales:
La arquitectura se divide en tres capas principales:
Capa de Presentación (Vista/UI). 
	Desarrollada en Flutter, compuesta por las Pages (pantallas completas como LoginPage, SplashPage, AdminShellPage y UserShellPage), las Sections (fragmentos funcionales: SalaSection, InventarioSection, TicketsSection, CajaSection, UsersListSection, PersonalAreaSection y VerifactuSection) y los Widgets reutilizables (TableCardWidget, TicketPanelWidget, ProductPickerWidget, PaymentDialogWidget, ProductFormSheet, ExpenseFormSheet, ProfileFormWidget, entre otros). El estado reactivo se gestiona mediante 10 Controllers que extienden GetxController: AuthController, TicketController, TicketHistoryController, ProductController, ReportController, ExpenseController, ConfigController, UserController, AdminShellController y VerifactuController. Cada controller expone sus datos a la vista mediante variables observables (Rx<T>, RxList<T>, Rxn<T>) del paquete GetX, y la UI se reconstruye selectivamente a través de Obx(() => ...), que redibuja únicamente el widget afectado cuando el observable cambia. Las vistas nunca acceden a la base de datos directamente.
Capa de Servicios (Lógica de Dominio / Repository).
	Contiene los diez servicios del sistema organizados en dos grupos:
	
	Servicios Principales (6): 
	- UserService (autenticación con hash SHA-256, CRUD de usuarios, migración automática de contraseñas en texto plano)
	- TicketService (ciclo de vida completo del ticket: creación con UUID v4, gestión de líneas, cobro total y parcial con paySelectedLines(), corrección de cobros con correctPayment(), descuento automático de stock)
	- ProductService (CRUD y decrementStock())
	- ReportService (estadísticas en tiempo real con getLiveStats() y cierre de jornada con closeDay() que genera un DailyReport inmutable)
	- ExpenseService (registro de gastos con incremento automático de stock en compras)
	- ConfigService (configuración del negocio y seed de datos iniciales)
	
	Servicios de Integración Fiscal y Exportación (4):
	- FiscalTicketTraceService (registro de trazas de tickets fiscales, captura de información de emisión con datos de facturación backend, estado fiscal, códigos de verificación segura y URLs de verificación)
	- VerifactuService (integración con la API de Verifactu del sistema fiscal español, gestión de autenticación con backend fiscal y comunicación de facturas electrónicas)
	- ReceiptPrintService (generación de recibos/tickets en formato PDF con códigos QR fiscales, integración con sistema de impresoras, gestión de información del emisor y campos fiscales)
	- ExportService (exportación de datos completos de tickets y cierres diarios a archivos JSON, con funcionalidades de filtrado por periodos)
	
	Cada servicio recibe las dependencias inyectadas por constructor y encapsula todas las queries nativas a la base de datos. Los servicios principales tienen acceso directo a Isar, mientras que los servicios de integración dependen de otros servicios. Los servicios son la única capa autorizada para leer o escribir en Isar
Capa de Datos (Local NoSQL). 
	Implementada con Isar Database (Isar, s.f.), se encarga de la persistencia local de alto rendimiento. El esquema define 9 colecciones anotadas con @collection (User, Product, Ticket, DailyReport, Config, BusinessConfig, Expense, FiscalTicketTrace y VerifactuModels) y 2 tipos embebidos con @embedded (TicketLine que almacena las líneas dentro de cada Ticket sin colección propia, y FiscalTicketTraceLine que almacena las líneas dentro de los registros de trazas fiscales). Se utilizan 4 enumeraciones persistidas: TicketStatus (abierto/pagado/cancelado), PaymentMethod (efectivo/tarjeta/mixto), TaxRate (exento/superreducido/reducido/general) y ExpenseCategory (compras/facturas/personal/otro). Los índices @Index sobre los campos críticos — createdAt y status en Ticket, date en DailyReport, email (unique) en User, invoiceId en FiscalTicketTrace — garantizan filtros nativos sin cargar colecciones completas en memoria. La instancia Isar se abre como singleton en main.dart mediante openIsar() y se inyecta a todos los servicios y controladores a través de AppBindings, que los registra como permanentes con Get.put(..., permanent: true).
Flujo reactivo completo. 
	El usuario interactúa con un Widget → el Controller invoca el método correspondiente del Service → el Service ejecuta la query Isar dentro de writeTxn() → el Controller actualiza la variable observable → Obx() reconstruye exclusivamente el widget afectado. Los errores se capturan en loques try/catch dentro de cada método del Controller y se notifican al usuario mediante Get.snackbar(), garantizando que el flag isLoading se restablece siempre a false en el bloque finally. Los datos de inicialización (usuario admin, 20 productos de demostración y configuración base) se cargan mediante funciones seed ejecutadas en main() antes de runApp().

## 2. CONFIGURACIÓN PANTALLA COMPLETA (MODO INMERSIVO REAL)
Para garantizar que la aplicación ocupe el 100% de la pantalla física en tablets (especialmente Xiaomi/MIUI) sin franjas de 30px o "huecos" reservados para la barra de estado, se han aplicado los siguientes cambios:

### A. Configuración Nativa de Android (`android/app/src/main/res/values/styles.xml`)
Se debe forzar al sistema a permitir que la ventana use el área de "recorte" (notch/sensores):
```xml
<style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
    <item name="android:windowBackground">?android:colorBackground</item>
    <!-- Fuerza el uso de los bordes cortos (notch) para pantalla completa real -->
    <item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>
</style>
```

### B. Inicialización en `main.dart`
Configurar la transparencia de la barra y el modo inmersivo antes de `runApp`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Transparencia total de la barra de estado
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  
  // Modo inmersivo "pegajoso"
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  // Bloqueo de orientación
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight
  ]);

  runApp(MainApp());
}
```

### C. Ajuste de Widgets (Scaffold y AppBar)
Para recuperar los ~30 píxeles que Flutter reserva por defecto, hay que desactivar la propiedad `primary` en **ambos** componentes:
```dart
Scaffold(
  primary: false, // Evita que el Scaffold reserve espacio arriba
  appBar: AppBar(
    primary: false, // Evita que el AppBar reserve espacio para la barra de estado
    title: Text('Título'),
  ),
  body: ...
)
```

### D. Comandos ADB (Específico para Xiaomi/MIUI)
Si las ventanas flotantes o "handles" de MIUI molestan el diseño, ejecutar estos comandos con la tablet conectada:
```powershell
# Desactivar soporte de ventanas flotantes
adb shell settings put global enable_freeform_support 0
# Ocultar guías visuales de forma libre
adb shell settings put secure show_guide_freeform 0
# Deshabilitar el componente de ventanas flotantes de MIUI
adb shell pm uninstall -k --user 0 com.miui.freeform
```
