<div align="center">
  <img src="assets/images/novapay.webp" alt="NovaPay Logo" width="180"/>

  <h1>NovaPay TPV</h1>
  <p>Solución de Punto de Venta multiplataforma desarrollada con Flutter — <strong>Trabajo de Fin de Grado</strong></p>

  <br/>

  ![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?style=flat-square&logo=flutter&logoColor=white)
  ![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=flat-square&logo=dart&logoColor=white)
  ![Windows](https://img.shields.io/badge/Windows-desktop-0078D4?style=flat-square&logo=windows&logoColor=white)
  ![Android](https://img.shields.io/badge/Android-mobile-3DDC84?style=flat-square&logo=android&logoColor=white)
  ![License](https://img.shields.io/badge/licencia-privada-555?style=flat-square&logo=lock&logoColor=white)
</div>

---

## Descripción

NovaPay es una aplicación de Punto de Venta (TPV) profesional construida desde cero con Flutter. El objetivo era crear algo que funcionara de verdad en un negocio real: sin depender de internet, con gestión de inventario, cierre de caja y emisión de tickets fiscales.

Corre tanto en **Windows** (escritorio táctil o con ratón) como en **Android**, compartiendo prácticamente toda la lógica de negocio gracias a Flutter.

---

## Funcionalidades

| Módulo | Descripción |
|---|---|
| ![inv](https://img.shields.io/badge/Inventario-02569B?style=flat-square&logo=databricks&logoColor=white) | Gestión de productos, categorías, stock y precios |
| ![tickets](https://img.shields.io/badge/Tickets_Fiscales-0175C2?style=flat-square&logo=receipt&logoColor=white) | Generación y trazabilidad de tickets de venta |
| ![reports](https://img.shields.io/badge/Informes_Diarios-3DDC84?style=flat-square&logo=googleanalytics&logoColor=white) | Resúmenes de ventas y cierre de caja |
| ![gastos](https://img.shields.io/badge/Gastos-FF6B35?style=flat-square&logo=cashapp&logoColor=white) | Registro y control de gastos operativos |
| ![offline](https://img.shields.io/badge/Offline--First-555?style=flat-square&logo=cloudflare&logoColor=white) | Funciona sin conexión mediante persistencia local con Isar |
| ![video](https://img.shields.io/badge/Splash_con_Video-E91E63?style=flat-square&logo=youtube&logoColor=white) | Splash screen dinámico con reproducción de vídeo nativo |

---

## Stack Tecnológico

<table>
  <tr>
    <td><img src="https://img.shields.io/badge/Flutter-SDK-02569B?style=flat-square&logo=flutter&logoColor=white" /></td>
    <td>Framework principal — UI + lógica multiplataforma</td>
  </tr>
  <tr>
    <td><img src="https://img.shields.io/badge/GetX-estado_y_navegación-8A2BE2?style=flat-square&logo=dart&logoColor=white" /></td>
    <td>Gestión de estado reactivo, rutas e inyección de dependencias</td>
  </tr>
  <tr>
    <td><img src="https://img.shields.io/badge/Isar-base_de_datos-FF6B35?style=flat-square&logo=sqlite&logoColor=white" /></td>
    <td>Base de datos NoSQL local de alto rendimiento</td>
  </tr>
  <tr>
    <td><img src="https://img.shields.io/badge/GetIt-DI-0175C2?style=flat-square&logo=dart&logoColor=white" /></td>
    <td>Service locator para inyección de dependencias</td>
  </tr>
  <tr>
    <td><img src="https://img.shields.io/badge/media__kit-vídeo_nativo-E91E63?style=flat-square&logo=vlcmediaplayer&logoColor=white" /></td>
    <td>Reproducción de vídeo nativa en Windows y Android</td>
  </tr>
  <tr>
    <td><img src="https://img.shields.io/badge/Dartz-manejo_de_errores-3DDC84?style=flat-square&logo=haskell&logoColor=white" /></td>
    <td>Either / Option para manejo funcional de errores</td>
  </tr>
</table>

La arquitectura sigue los principios de **Clean Architecture**: separación en capas data / domain / presentation, con casos de uso explícitos y repositorios abstractos. Esto hace el código testeable y fácil de extender.

---

## Instalación y desarrollo

### Requisitos previos

- Flutter SDK `>= 3.10.0` / Dart `>= 3.0.0`
- **Windows:** Visual Studio 2022 con _Desktop development with C++_
- **Android:** Android SDK con API level 21+

### Puesta en marcha

```bash
# Clonar el repositorio
git clone https://github.com/kabalera82/novapay-frontend.git
cd novapay-frontend

# Instalar dependencias
flutter pub get

# Generar código de Isar (modelos y adaptadores)
dart run build_runner build --delete-conflicting-outputs

# Arrancar en modo desarrollo
flutter run
```

Para arrancar con la base de datos reseteada y datos de prueba (útil en desarrollo):

```bash
flutter run --dart-define=TEST_RESET_ON_START=true
```

---

## Build de producción

### Windows

```bash
flutter build windows --release
```

### Android

```bash
flutter build apk --release --split-per-abi
```

> Los APKs generados con `--split-per-abi` son más ligeros porque cada uno está optimizado para su arquitectura de CPU.

---

## Estructura del proyecto

```
lib/
├── core/           # Utilidades, constantes y manejo de errores
├── data/           # Repositorios, fuentes de datos e implementaciones Isar
├── domain/         # Entidades, interfaces y casos de uso
└── presentation/   # Pantallas, controladores GetX y widgets
```

---

## Autores

Desarrollado por:

[![Aaron Gómez](https://img.shields.io/badge/Aaron_Gómez-GitHub-181717?style=flat-square&logo=github&logoColor=white)](https://github.com/aaronsgomez)
[![kabalera82](https://img.shields.io/badge/kabalera82-GitHub-181717?style=flat-square&logo=github&logoColor=white)](https://github.com/kabalera82)

---

## Licencia

Proyecto de uso privado para la plataforma NovaPay. Todos los derechos reservados.

![License](https://img.shields.io/badge/All_Rights_Reserved-NovaPay-555?style=flat-square)
