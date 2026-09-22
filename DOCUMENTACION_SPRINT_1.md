# Documentación del Sprint 1: Autenticación y Registro de Usuarios

**Proyecto:** EcoScan  
**Plataformas Objetivo:** Móviles (Android e iOS)  
**Sprint Backlog 1:** *"Como usuario, quiero poder registrarme e iniciar sesión en la app para acceder de forma segura a mis datos."*  
**Responsable de Documentación (Tarea 700):** Carolina Bonilla  
**Fecha de Cierre:** 20/09/2026  

---

## 1. Resumen y Control de Tareas del Sprint

A continuación se detalla la matriz de actividades completadas con base en el Sprint Backlog planificado:

| Prioridad | ID | Tarea / Subsección | Responsable | Estimación (Horas) | Fecha de Finalización | Estado |
|---|---|---|---|---|---|---|
| **Alta** | 1000 | **Backend:** endpoint de registro con validación de datos | Alexis Hernandez | 6 h | 09/09/2026 | **Completado** |
| **Alta** | 970 | **Backend:** endpoint de login + manejo de sesión/token (JWT) | Marisol Moreno | 6 h | 10/09/2026 | **Completado** |
| **Alta** | 950 | **Backend:** encriptado de contraseñas (bcrypt o similar) | Adriel Ramos | 3 h | 12/09/2026 | **Completado** |
| **Alta** | 900 | **Base de Datos:** Diseñar e implementar tabla 'Usuario' | Carolina Bonilla | 4 h | 13/09/2026 | **Completado** |
| **Alta** | 850 | **Frontend:** pantalla de login con manejo de errores | Alexis Hernandez | 5 h | 15/09/2026 | **Completado** |
| **Alta** | 800 | **Frontend:** pantalla de registro con validaciones de formulario | Marisol Moreno | 5 h | 17/09/2026 | **Completado** |
| **Alta** | 750 | **Calidad:** Pruebas unitarias de autenticación | Adriel Ramos | 4 h | 18/09/2026 | **Completado** |
| **Alta** | 700 | **Gestión:** Documentación del sprint | Carolina Bonilla | 2 h | 20/09/2026 | **Completado** |

**Total de Horas Estimadas y Ejecutadas:** 35 horas.

---

## 2. Arquitectura de la Solución (Mobile-First)

El sistema está concebido bajo una arquitectura cliente-servidor orientada a dispositivos móviles (Android & iOS):

```
┌────────────────────────────────────────────────────────┐
│                   ECOSCAN MOBILE APP                   │
│                    (Flutter SDK)                       │
│  ┌───────────────────┐  ┌─────────────┐  ┌──────────┐  │
│  │   WelcomeScreen   │  │ LoginScreen │  │ Register │  │
│  │  (iconapp.jpeg)   │  │ (Validation)│  │ (Waves)  │  │
│  └─────────┬─────────┘  └──────┬──────┘  └────┬─────┘  │
│            │                   │              │        │
│            └─────────────┬─────┴──────────────┘        │
│                          ▼                             │
│                  AuthService (Dart)                    │
│            (Adaptive HttpClient & Fallback)            │
└──────────────────────────┬─────────────────────────────┘
                           │
                 HTTPS / REST JSON
         (Android: 10.0.2.2 | iOS: localhost)
                           │
┌──────────────────────────▼─────────────────────────────┐
│                 ECOSCAN BACKEND API                    │
│                   (Node.js / Express)                  │
│  ┌──────────────────────────────────────────────────┐  │
│  │  POST /api/auth/register                         │  │
│  │  POST /api/auth/login                            │  │
│  │  GET  /api/auth/verify                           │  │
│  └───────────────┬──────────────────┬───────────────┘  │
│                  │                  │                  │
│           ┌──────▼──────┐    ┌──────▼──────┐           │
│           │   Bcrypt    │    │  JWT Engine │           │
│           │ (Salt = 10) │    │  (HMAC-256) │           │
│           └──────┬──────┘    └─────────────┘           │
│                  │                                     │
│           ┌──────▼────────────────────────┐            │
│           │  SQLite Database: Usuario     │            │
│           └───────────────────────────────┘            │
└────────────────────────────────────────────────────────┘
```

---

## 3. Base de Datos: Tabla 'Usuario' (Tarea 900 - Carolina Bonilla)

Se diseñó e implementó la tabla `Usuario` en SQLite (`backend/src/database.js`) para garantizar integridad referencial, unicidad de correos y persistencia atómica:

### DDL de la Tabla
```sql
CREATE TABLE IF NOT EXISTS Usuario (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre_completo TEXT NOT NULL,
  correo_electronico TEXT UNIQUE NOT NULL COLLATE NOCASE,
  password_hash TEXT NOT NULL,
  terminos_aceptados INTEGER NOT NULL DEFAULT 1,
  fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### Diccionario de Datos
| Campo | Tipo | Nulo | Descripción |
|---|---|---|---|
| `id` | INTEGER | No | Identificador único autoincremental de usuario. |
| `nombre_completo` | TEXT | No | Nombre y apellidos del usuario registrado. |
| `correo_electronico` | TEXT | No | Correo único (insensible a mayúsculas/minúsculas). |
| `password_hash` | TEXT | No | Hash criptográfico unidireccional generado con bcrypt. |
| `terminos_aceptados` | INTEGER | No | Bandera booleana (1/0) de aceptación de términos legales. |
| `fecha_creacion` | DATETIME | No | Marca temporal UTC generada automáticamente. |

---

## 4. Seguridad y Encriptación (Tarea 950 - Adriel Ramos)

- **Algoritmo:** `bcrypt` (implementado mediante la biblioteca `bcryptjs`).
- **Factor de Costo / Salt Rounds:** `10 rondas`.
- **Características:**
  - Protección contra ataques de diccionario y *rainbow tables* mediante salt criptográfico único por cada registro.
  - La contraseña en texto plano **jamás** se almacena en base de datos ni se envía de regreso en las respuestas JSON del backend.

```javascript
// Generación segura del hash
const saltRounds = 10;
const passwordHash = await bcrypt.hash(plainPassword, saltRounds);

// Verificación al iniciar sesión
const esValido = await bcrypt.compare(plainPassword, usuario.password_hash);
```

---

## 5. Manejo de Sesión y Tokens JWT (Tarea 970 - Marisol Moreno)

- **Estándar:** RFC 7519 (JSON Web Tokens).
- **Algoritmo de Firma:** HMAC con SHA-256 (`HS256`).
- **Tiempo de Validez:** 24 horas (`24h`).
- **Estructura del Payload:**
  ```json
  {
    "id": 1,
    "nombreCompleto": "Alexis Hernandez",
    "correoElectronico": "alexis@ecoscan.com",
    "iat": 1726950000,
    "exp": 1727036400
  }
  ```
- **Flujo de Autorización:** El cliente móvil envía el encabezado `Authorization: Bearer <token>` para validar la sesión activa de forma stateless.

---

## 6. Especificación de Endpoints del Backend (Tareas 1000 y 970)

### 6.1. `POST /api/auth/register` (Tarea 1000 - Alexis Hernandez)
Registra a un nuevo usuario, valida formato de correo, longitud de contraseña (mínimo 6 caracteres), aceptación de términos y genera el token de sesión.

- **Request Body:**
  ```json
  {
    "nombreCompleto": "Alexis Hernandez",
    "correoElectronico": "alexis@ecoscan.com",
    "password": "password123",
    "terminosAceptados": true
  }
  ```
- **Respuesta Exitosa (201 Created):**
  ```json
  {
    "success": true,
    "message": "Usuario registrado exitosamente en EcoScan.",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "nombreCompleto": "Alexis Hernandez",
      "correoElectronico": "alexis@ecoscan.com"
    }
  }
  ```
- **Respuestas de Error:**
  - `400 Bad Request`: Datos incompletos, correo con formato inválido o términos no aceptados.
  - `409 Conflict`: Correo electrónico ya registrado en el sistema.

### 6.2. `POST /api/auth/login` (Tarea 970 - Marisol Moreno)
Autentica al usuario contra las credenciales encriptadas en la base de datos y emite token JWT.

- **Request Body:**
  ```json
  {
    "correoElectronico": "alexis@ecoscan.com",
    "password": "password123"
  }
  ```
- **Respuesta Exitosa (200 OK):**
  ```json
  {
    "success": true,
    "message": "Inicio de sesión exitoso.",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "nombreCompleto": "Alexis Hernandez",
      "correoElectronico": "alexis@ecoscan.com",
      "fechaCreacion": "2026-09-21T23:15:00.000Z"
    }
  }
  ```
- **Respuestas de Error:**
  - `400 Bad Request`: Campos requeridos faltantes.
  - `401 Unauthorized`: Correo no registrado o contraseña incorrecta.

### 6.3. `GET /api/auth/verify`
Valida la vigencia y autenticidad del token JWT desde el encabezado `Authorization`.

---

## 7. Frontend Móvil (Android & iOS) y Fidelidad Visual

Se construyó la interfaz en Flutter con enfoque estricto para dispositivos móviles, implementando con exactitud los elementos de las referencias visuales:

### 7.1. Pantalla de Bienvenida (`lib/screens/welcome_screen.dart` - Ref. 3)
- **Logotipo:** Tipografía bold en color `#1B6B27` acompañada del icono de hoja (`Icons.eco`).
- **Eslogan:** *"Escanea, recicla y cuida el planeta"*.
- **Imagen Central:** Integración nativa de la imagen `assets/images/iconapp.jpeg` con la mascota del planeta Tierra y contenedor de reciclaje.
- **Acciones:**
  - Botón primario *"Iniciar Sesion"* en verde sólido `#1B6B27` con bordes redondeados (`BorderRadius.circular(30)`).
  - Botón secundario *"Registrarse"* con contorno negro y fondo blanco.

### 7.2. Pantalla de Login (`lib/screens/login_screen.dart` - Tarea 850 & Ref. 4)
- **Navegación:** Flecha de retroceso `←` superior izquierda.
- **Título:** **EcoScan** centrado en verde oscuro.
- **Entradas:** Campos con borde redondeado suave para *Correo electrónico* y *Contraseña* (con botón interactivo para mostrar/ocultar texto).
- **Enlace:** *"¿Olvidaste tu contraseña?"*.
- **Acceso Social:** Botones de Google y Facebook estilizados en tarjetas con esquinas redondeadas.
- **Manejo de Errores (Tarea 850):**
  - Validación reactiva en formulario (correo no vacío, regex de correo).
  - Mensaje contextual y SnackBar flotante ante credenciales erróneas (`401`).
  - Indicador de progreso (`CircularProgressIndicator`) durante la petición.

### 7.3. Pantalla de Registro / Crear Cuenta (`lib/screens/register_screen.dart` - Tarea 800 & Ref. 5)
- **Cabecera Ondeada:** Implementación con `CustomPainter` (`TopWavePainter`) reproduciendo la curva orgánica verde y el botón de cierre `"X"` en la esquina superior derecha.
- **Campos con Iconos:**
  - Icono de usuario verde (`Icons.person`) + *"Nombre Completo"*.
  - Icono de correo verde (`Icons.mail`) + *"Correo Electrónico"*.
  - Icono de candado verde (`Icons.lock`) + *"Contraseña"*.
- **Términos Legales:** Checkbox interactivo con el texto *"Acepto los **Términos y Condiciones**"*, que despliega un diálogo con las políticas.
- **Botón:** *"CREAR CUENTA"* en verde sólido con feedback visual.
- **Enlace:** *"¿Ya tienes una cuenta? **Iniciar Sesión**"*.
- **Decoración Inferior:** Curva suave verde en la esquina inferior izquierda (`BottomWavePainter`).

### 7.4. Dashboard Post-Login (`lib/screens/home_screen.dart`)
- Confirma el acceso seguro a los datos del usuario logueado.
- Muestra el nombre completo, correo y la insignia de sesión activa con JWT.
- Botón de cierre de sesión seguro que invalida el estado y regresa a la bienvenida.

---

## 8. Resultados de Pruebas Unitarias de Autenticación (Tarea 750 - Adriel Ramos)

Se ejecutó la suite automatizada de pruebas sobre el backend (`npm test`):

```text
> ecoscan-backend@1.0.0 test
> node --test tests/auth.test.js

[Base de Datos] Conectado exitosamente a SQLite (ecoscan.sqlite)
[Base de Datos] Tabla "Usuario" inicializada correctamente.
▶ Pruebas Unitarias de Autenticación - EcoScan (Sprint 1)
  ✔ 1. [BD] La tabla Usuario debe existir y permitir inserción de registros válidos (3.02ms)
  ✔ 2. [Seguridad] Debe encriptar contraseñas usando bcrypt con hash seguro (219.25ms)
  ✔ 3. [Sesión] Debe generar y verificar tokens JWT con payload de usuario (4.51ms)
  ✔ 4. [Registro] Registro exitoso con datos válidos y contraseña encriptada (75.48ms)
  ✔ 5. [Registro] Debe impedir el registro con correo duplicado (0.82ms)
  ✔ 6. [Login] Login exitoso con credenciales correctas (73.43ms)
  ✔ 7. [Login] Debe rechazar credenciales con contraseña incorrecta (72.76ms)
  ✔ 8. [Login] Debe rechazar inicio de sesión con correo no registrado (1.72ms)
  ✔ 9. [Sesión] Debe rechazar tokens manipulados o inválidos (1.31ms)
✔ Pruebas Unitarias de Autenticación - EcoScan (Sprint 1) (463.23ms)

ℹ tests 9
ℹ suites 1
ℹ pass 9
ℹ fail 0
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
```

**Resultado:** 100% de pruebas aprobadas exitosamente (9/9).

---

## 9. Instrucciones de Ejecución para Dispositivos Móviles

### 9.1. Iniciar el Servidor Backend
```powershell
cd d:\flutterapp\app1\backend
npm start
```
El servidor escuchará en el puerto `3000` en todas las interfaces de red (`0.0.0.0:3000`).

### 9.2. Ejecutar la Aplicación en Móvil
- **Emulador Android:**
  La app se comunicará automáticamente con `http://10.0.2.2:3000/api`.
  ```powershell
  flutter run -d android
  ```
- **Simulador iOS:**
  La app se comunicará automáticamente con `http://localhost:3000/api`.
  ```powershell
  flutter run -d ios
  ```
- **Dispositivo Físico:**
  Configurar la IP local de la computadora en `lib/services/api_config.dart` (`ApiConfig.customServerHost = '192.168.x.x'`).

---

**Conclusión del Sprint:** Todas las metas y tareas de prioridad alta del Sprint Backlog 1 han sido concluidas, validadas y documentadas con éxito.
