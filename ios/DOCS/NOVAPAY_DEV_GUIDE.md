# NovaPay TPV — Guía de Desarrollo

> Flutter · Isar · GetX · Material Design 3  
> Estado actual: **MVP funcional** — Auth + CRUD usuarios + Splash animado

---

## 1. Stack tecnológico

| Capa | Tecnología |
|---|---|
| UI | Flutter + Material Design 3 |
| Estado | GetX (`get: ^4.6.5`) |
| BD local | Isar 3.1 |
| Video | media_kit |
| DI | get_it |
| Utilidades | equatable, dartz, intl |

---

## 2. Estructura de carpetas

```
lib/
├── config/
│   └── theme.dart               ✅ AppTheme completo (colores, tipografía, componentes)
├── core/
│   ├── constants.dart           ⚠️  Vacío — pendiente de rutas y keys globales
│   └── utils/
│       ├── formatters.dart      ⚠️  Vacío
│       └── validators.dart      ⚠️  Vacío
├── data/
│   ├── local/
│   │   ├── isar.dart            ✅ openIsar() — singleton
│   │   └── isar.service.dart    ⚠️  Duplicado de isar.dart — unificar
│   └── models/
│       ├── user.dart            ✅ Modelo User con Isar
│       ├── user.g.dart          ✅ Generado — NO editar
│       └── entities.dart        ⚠️  Solo re-exporta isar — poco útil
├── presentation/
│   ├── controllers/
│   │   ├── aut.controller.dart  ⚠️  Vacío
│   │   ├── user.controller.dart ⚠️  Vacío
│   │   └── product.controller.dart ⚠️  Vacío
│   ├── pages/
│   │   ├── splash.page.dart     ✅ Video intro → Login
│   │   ├── login.page.dart      ✅ Auth email/username + password
│   │   ├── dashboard.users.page.dart ✅ CRUD completo de usuarios (solo admin)
│   │   ├── dashboard.caja.page.dart  ⚠️  Placeholder vacío
│   │   └── profile.page.dart    ✅ Perfil editable para rol 'user'
│   └── widgets/
│       ├── common/
│       │   ├── button.dart      ⚠️  Vacío
│       │   └── testfield.dart   ⚠️  Vacío
│       └── dashboard/
│           └── user.list.title.dart ⚠️  Vacío
├── services/
│   └── userServices.dart        ✅ CRUD + login + seedAdmin
└── main.dart                    ✅ Inicialización + rutas nombradas
```

---

## 3. Flujo actual de la app

```
App start
  └── openIsar() + seedAdmin('admin'/'1234')
        └── SplashPage  [video novapay.mp4]
              └── LoginPage
                    ├── role == 'admin'  →  DashboardUsersPage  (CRUD usuarios)
                    └── role == 'user'   →  ProfilePage          (ver/editar perfil)
```

---

## 4. Step-by-step — Lo que ya está hecho ✅

### Paso 1 — Proyecto base
- `pubspec.yaml` — dependencias declaradas  
- `main.dart` — entry point, rutas, seedAdmin  

### Paso 2 — Tema visual
- `lib/config/theme.dart` — pega AppTheme completo  

### Paso 3 — Modelo de datos
- `lib/data/models/user.dart` — pega el modelo  
- Ejecutar: `dart run build_runner build --delete-conflicting-outputs`  
- Resultado: `user.g.dart` generado automáticamente  

### Paso 4 — Base de datos local
- `lib/data/local/isar.dart` — pega openIsar()  

### Paso 5 — Servicios de usuario
- `lib/services/userServices.dart` — pega CRUD + seedAdmin  

### Paso 6 — Pantallas
- `lib/presentation/pages/splash.page.dart` — video intro  
- `lib/presentation/pages/login.page.dart` — formulario auth  
- `lib/presentation/pages/dashboard.users.page.dart` — panel admin  
- `lib/presentation/pages/profile.page.dart` — perfil usuario  
- `lib/presentation/pages/dashboard.caja.page.dart` — placeholder  

---

## 5. Checklist — Lo que falta ❌

### Arquitectura / Código
- [ ] Eliminar `isar.service.dart` (duplicado de `isar.dart`)
- [ ] Eliminar o usar `entities.dart`
- [ ] Implementar `aut.controller.dart` (GetX — estado de sesión)
- [ ] Implementar `user.controller.dart` (GetX — lista usuarios reactiva)
- [ ] Implementar `product.controller.dart` (GetX — productos/caja)
- [ ] Rellenar `core/constants.dart` (rutas como constantes)
- [ ] Rellenar `validators.dart` (email, contraseña, teléfono)
- [ ] Rellenar `formatters.dart` (moneda, fecha, teléfono)
- [ ] Widget reutilizable `button.dart`
- [ ] Widget reutilizable `textfield.dart`
- [ ] Widget `user.list.title.dart` (extraer del dashboard)

### Seguridad
- [ ] Hash de contraseñas (bcrypt / crypto)
- [ ] Sesión persistente (SharedPreferences o Isar)
- [ ] Guard de rutas (redirigir si no hay sesión)

### Funcionalidad — Caja (core del TPV)
- [ ] Modelo `Product` (nombre, precio, stock, categoría)
- [ ] Modelo `Sale` / `SaleItem`
- [ ] CRUD de productos
- [ ] `DashboardCajaPage` real (carrito, cobro, ticket)
- [ ] Historial de ventas

### UX / UI
- [ ] Pantalla de error / 404 para rutas inválidas
- [ ] Confirmación antes de eliminar usuario
- [ ] Feedback visual al guardar (loading state)
- [ ] Responsive para tablet / desktop (TPV suele usarse en pantalla grande)

### Testing
- [ ] Tests unitarios de `userServices`
- [ ] Tests de widget en `LoginPage`

---

## 6. Revisión de código — Alertas ⚠️

| Archivo | Issue | Solución |
|---|---|---|
| `isar.service.dart` | Duplica `isar.dart` | Eliminar o unificar |
| `userServices.dart` | Contraseñas en texto plano | Añadir hash |
| `dashboard.users.page.dart` | Lógica Isar directa en la vista | Mover a controller |
| `login.page.dart` | Sin guard si ya hay sesión activa | Añadir check en initState |
| `splash.page.dart` | Volumen se setea en cada evento `playing` | Setear solo una vez con `.first` |
| `profile.page.dart` | Recibe User por arguments — frágil | Pasar por controller/DI |
| `constants.dart` | Rutas duplicadas como strings en cada Page | Centralizar aquí |

---

## 7. Próximos pasos recomendados

### Sprint 1 — Estabilizar arquitectura (1–2 días)
1. Crear `AuthController` con GetX (usuario logueado, logout, sesión persistente)
2. Mover lógica Isar de las vistas a los controllers
3. Centralizar rutas en `constants.dart`
4. Implementar validators y formatters básicos

### Sprint 2 — Módulo de productos (2–3 días)
1. Modelo `Product` + generación Isar
2. CRUD de productos (pantalla admin)
3. Controller de productos

### Sprint 3 — Caja / TPV (3–4 días)
1. `DashboardCajaPage` real con carrito
2. Modelo `Sale` + `SaleItem`
3. Flujo de cobro (efectivo / tarjeta)
4. Ticket / recibo básico

### Sprint 4 — Seguridad y UX (1–2 días)
1. Hash de contraseñas
2. Confirmaciones de borrado
3. Loading states
4. Responsive layout

---

## 8. Estructura recomendada para el developer

```
Nueva estructura objetivo:

lib/
├── config/
│   ├── theme.dart
│   └── routes.dart              ← NUEVO: todas las rutas aquí
├── core/
│   ├── constants.dart           ← keys, strings globales
│   └── utils/
│       ├── formatters.dart      ← moneda, fecha
│       └── validators.dart      ← email, pass, phone
├── data/
│   ├── local/
│   │   └── isar.dart            ← único punto de apertura BD
│   ├── models/
│   │   ├── user.dart
│   │   ├── product.dart         ← NUEVO
│   │   └── sale.dart            ← NUEVO
│   └── repositories/            ← NUEVO: abstracción sobre services
│       ├── user.repository.dart
│       └── product.repository.dart
├── presentation/
│   ├── bindings/                ← NUEVO: GetX bindings por ruta
│   │   ├── auth.binding.dart
│   │   └── caja.binding.dart
│   ├── controllers/
│   │   ├── auth.controller.dart
│   │   ├── user.controller.dart
│   │   └── product.controller.dart
│   ├── pages/
│   │   ├── splash.page.dart
│   │   ├── login.page.dart
│   │   ├── dashboard.users.page.dart
│   │   ├── dashboard.caja.page.dart ← implementar
│   │   └── profile.page.dart
│   └── widgets/
│       ├── common/
│       │   ├── app_button.dart
│       │   └── app_textfield.dart
│       └── dashboard/
│           ├── user_list_tile.dart
│           └── product_card.dart    ← NUEVO
└── services/                    ← renombrar a más semántico
    ├── auth.service.dart
    └── user.service.dart
```

---

*Generado para NovaPay TPV — v0.1.0 · Flutter 3.x · Isar 3.1*
