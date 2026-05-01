# 💳 NovaPay TPV — Solution

![NovaPay Logo](assets/images/novapay.webp)

NovaPay es una solución de Punto de Venta (TPV) profesional, moderna y multiplataforma desarrollada con **Flutter**. Diseñada para ofrecer una experiencia fluida tanto en dispositivos móviles (Android) como en escritorio (Windows), con un enfoque en el rendimiento offline, estética premium y facilidad de uso.

---

## 🚀 Características Principales

- **Gestión de Inventario:** Control total de productos, categorías, stock y precios.
- **Emisión de Tickets Fiscales:** Generación automática de tickets de venta con trazabilidad fiscal.
- **Informes Diarios:** Resúmenes de ventas detallados para el cierre de caja.
- **Control de Gastos:** Registro y gestión de gastos operativos desde la misma interfaz.
- **Multimedia Experience:** Splash screen dinámico con reproducción de vídeo nativo.
- **Offline-First:** Funcionamiento garantizado sin conexión gracias a la persistencia local robusta con Isar.
- **Diseño Moderno:** Interfaz optimizada para pantallas táctiles y uso con ratón, siguiendo estándares de UX actuales.

---

## 🛠️ Stack Tecnológico

- **Frontend:** [Flutter SDK](https://flutter.dev) (Dart)
- **Estado & Navegación:** [GetX](https://pub.dev/packages/get)
- **Base de Datos Local:** [Isar Database](https://isar.dev) (NoSQL de alto rendimiento)
- **Multimedia:** [media_kit](https://pub.dev/packages/media_kit) para reproducción de vídeo nativo.
- **Inyección de Dependencias:** [GetIt](https://pub.dev/packages/get_it)
- **Arquitectura:** Clean Architecture con manejo funcional de errores ([Dartz](https://pub.dev/packages/dartz)).

---

## 💻 Instalación y Desarrollo

### Requisitos
- Flutter SDK >= 3.10.0
- Dart >= 3.0.0

### Pasos para ejecución local
```bash
# 1. Clonar el proyecto
git clone https://github.com/kabalera82/novapay-frontend.git

# 2. Instalar dependencias
flutter pub get

# 3. Generar modelos de Isar
dart run build_runner build --delete-conflicting-outputs

# 4. Ejecutar en modo desarrollo
flutter run
```

### Comandos de Utilidad
Para arrancar la aplicación con una base de datos limpia y semillas de prueba:
```bash
flutter run --dart-define=TEST_RESET_ON_START=true
```

---

## 📦 Despliegue (Build)

### Windows
```bash
flutter build windows --dart-define=TEST_RESET_ON_START=true
```

### Android
```bash
flutter build apk --release --dart-define=TEST_RESET_ON_START=true
```

---

## 👥 Autores

Este proyecto ha sido desarrollado por:

* **Aaron Gómez** — [GitHub](https://github.com/aaronsgomez)
* **kabalera82** — [GitHub](https://github.com/kabalera82)

---

## 📄 Licencia

Este proyecto es de uso privado para la plataforma NovaPay. Todos los derechos reservados.
