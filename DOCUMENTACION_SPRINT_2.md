# Documentación del Sprint 2: Captura, Reconocimiento y Almacenamiento de Fotos

**Proyecto:** EcoScan  
**Plataformas Objetivo:** Móviles (Android e iOS)  
**Sprint Backlog 2:** *"Como usuario, quiero enfocar y fotografiar residuos reciclables con la cámara o seleccionarlos de la galería para registrarlos, ganar EcoPuntos y guardarlos de forma asociada a mi cuenta."*  
**Responsable de Documentación (Tarea 700):** Carolina Bonilla  
**Fecha de Cierre:** 06/10/2026  

---

## 1. Resumen y Control de Tareas del Sprint

A continuación se detalla la matriz de actividades completadas con base en el Sprint Backlog planificado:

| Prioridad | ID | Tarea / Subsección | Responsable | Estimación (Horas) | Fecha de Finalización | Estado |
|---|---|---|---|---|---|---|
| **Alta** | 1000 | **Backend:** endpoint para subir y guardar la foto (asociada al usuario) | Alexis Hernández | 6 h | 02/10/2026 | **Completado** |
| **Alta** | 970 | **Base de Datos:** Diseñar e implementar tabla 'Fotos' en la base de datos | Carolina Bonilla | 4 h | 03/10/2026 | **Completado** |
| **Alta** | 950 | **Plataforma:** Configurar permisos de cámara y almacenamiento (Android & iOS) | Adriel Ramos | 3 h | 03/10/2026 | **Completado** |
| **Alta** | 900 | **Frontend:** Componente / pantalla de captura de foto (EcoScan) | Marisol Moreno | 6 h | 04/10/2026 | **Completado** |
| **Alta** | 850 | **Frontend:** Confirmación visual tras guardar la foto con feedback de puntos | Alexis Hernández | 4 h | 04/10/2026 | **Completado** |
| **Alta** | 800 | **Frontend:** Manejo de errores (permiso denegado, cámara no disponible) | Marisol Moreno | 4 h | 05/10/2026 | **Completado** |
| **Alta** | 750 | **Calidad:** Pruebas unitarias de captura y subida de fotos (Backend & Flutter) | Adriel Ramos | 5 h | 05/10/2026 | **Completado** |
| **Alta** | 700 | **Gestión:** Documentación técnica integral del sprint | Carolina Bonilla | 3 h | 06/10/2026 | **Completado** |

**Total de Horas Estimadas y Ejecutadas:** 35 horas.

---

## 2. Arquitectura de la Solución (Captura y Almacenamiento)

La solución amplía la arquitectura cliente-servidor para permitir la captura multimedia, previsualización en tiempo real y persistencia relacional con archivos en disco:

```
┌─────────────────────────────────────────────────────────────────┐
│                       ECOSCAN MOBILE APP                        │
│                         (Flutter SDK)                           │
│  ┌──────────────────────┐             ┌──────────────────────┐  │
│  │      HomeScreen      │             │    EcoScanScreen     │  │
│  │ (5 Tarjetas Verdes)  │──[Escanear]─▶│ (Visor HUD & Cámara)│  │
│  └──────────────────────┘             └──────────┬───────────┘  │
│             ▲                                    │              │
│             │                            [Cámara / Galería]     │
│             │                                    ▼              │
│  ┌──────────┴───────────┐             ┌──────────────────────┐  │
│  │ Confirmación Visual  │◀───[Exito]──│     PhotoService     │  │
│  │  (+50 pts / Resumen) │             │ (Base64 & Fallback)  │  │
│  └──────────────────────┘             └──────────┬───────────┘  │
└──────────────────────────────────────────────────┼──────────────┘
                                                   │
                                          HTTP REST JSON / Bearer
                                                   │
┌──────────────────────────────────────────────────▼──────────────┐
│                      ECOSCAN BACKEND API                        │
│                      (Node.js / Express)                        │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  POST /api/photos/upload                                  │  │
│  │  GET  /api/photos/user/:userId                            │  │
│  │  GET  /api/photos/:id                                     │  │
│  │  GET  /uploads/photos/:filename (Static Media Server)     │  │
│  └───────────────┬───────────────────────────┬───────────────┘  │
│                  │                           │                  │
│           ┌──────▼──────┐             ┌──────▼──────┐           │
│           │ Disk Storage│             │ SQLite DB   │           │
│           │ (/uploads)  │             │ Tabla Fotos │           │
│           └─────────────┘             └─────────────┘           │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Base de Datos: Tabla 'Fotos' (Tarea 970 - Carolina Bonilla)

Se diseñó e implementó la tabla `Fotos` en SQLite (`backend/src/database.js`) ligada mediante clave foránea con borrado en cascada a la tabla `Usuario`:

### DDL de la Tabla
```sql
CREATE TABLE IF NOT EXISTS Fotos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  usuario_id INTEGER NOT NULL,
  nombre_archivo TEXT NOT NULL,
  ruta_archivo TEXT NOT NULL,
  url_foto TEXT,
  tipo_residuo TEXT DEFAULT 'Plástico PET',
  tamano_bytes INTEGER DEFAULT 0,
  puntos_otorgados INTEGER DEFAULT 50,
  fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (usuario_id) REFERENCES Usuario (id) ON DELETE CASCADE
);
```

### Diccionario de Datos
| Campo | Tipo | Nulo | Descripción |
|---|---|---|---|
| `id` | INTEGER | No | Identificador único autoincremental de la foto registrada. |
| `usuario_id` | INTEGER | No | Clave foránea que referencia al autor en `Usuario(id)`. |
| `nombre_archivo` | TEXT | No | Nombre físico asignado con timestamp o título descriptivo. |
| `ruta_archivo` | TEXT | No | Ruta absoluta del archivo almacenado en el servidor. |
| `url_foto` | TEXT | Sí | URL relativa o pública para servir el recurso vía HTTP. |
| `tipo_residuo` | TEXT | No | Clasificación ecológica del residuo (Plástico, Vidrio, etc.). |
| `tamano_bytes` | INTEGER | No | Peso en bytes de la imagen procesada. |
| `puntos_otorgados` | INTEGER | No | EcoPuntos sumados a la cuenta del usuario por el residuo. |
| `fecha_creacion` | DATETIME | No | Marca temporal UTC generada automáticamente. |

---

## 4. Configuración de Permisos Móviles (Tarea 950 - Adriel Ramos)

Para garantizar la captura física y el acceso a fotografías sin bloqueos por parte del sistema operativo:

### 4.1. Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<!-- Tarea 950: Configurar permisos de cámara y almacenamiento (Adriel Ramos) -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28" />

<!-- Compatibilidad con dispositivos sin autofocus o cámara secundaria -->
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
```

### 4.2. iOS (`ios/Runner/Info.plist`)
```xml
<!-- Tarea 950: Configurar permisos de cámara y almacenamiento (Adriel Ramos) -->
<key>NSCameraUsageDescription</key>
<string>EcoScan necesita acceso a la cámara para escanear y reconocer residuos reciclables.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>EcoScan necesita acceso a la galería para seleccionar fotos de residuos a reciclar.</string>
<key>NSMicrophoneUsageDescription</key>
<string>EcoScan puede requerir acceso al micrófono durante la captura audiovisual.</string>
```

---

## 5. Especificación de Endpoints del Backend (Tarea 1000 - Alexis Hernández)

### 5.1. `POST /api/photos/upload`
Guarda el archivo de la foto en disco, clasifica el residuo, calcula los puntos ganados y registra la tupla en la tabla `Fotos`.

- **Headers:** `Authorization: Bearer <token>` (opcional si se pasa `usuarioId` en payload).
- **Request Body:**
  ```json
  {
    "usuarioId": 1,
    "imageBase64": "data:image/jpeg;base64,...",
    "tipoResiduo": "plastico",
    "nombrePersonalizado": "Botella PET Escaneada"
  }
  ```
- **Respuesta Exitosa (201 Created):**
  ```json
  {
    "success": true,
    "message": "Foto guardada y registrada exitosamente.",
    "photo": {
      "id": 1,
      "usuarioId": 1,
      "nombreArchivo": "foto_user_1_1728198000_1234.jpg",
      "urlFoto": "/uploads/photos/foto_user_1_1728198000_1234.jpg",
      "tipoResiduo": "Botella de plástico PET",
      "tamanoBytes": 245100,
      "puntosOtorgados": 50,
      "fechaCreacion": "2026-10-06 00:05:00"
    },
    "usuario": {
      "id": 1,
      "nombreCompleto": "Alexis Hernandez"
    }
  }
  ```
- **Respuestas de Error:**
  - `400 Bad Request`: Imagen Base64 ausente o corrupta.
  - `401 Unauthorized`: No se pudo resolver el usuario autor.
  - `404 Not Found`: El usuario no existe en la base de datos.

### 5.2. `GET /api/photos/user/:userId`
Retorna el historial completo de fotos capturadas por el usuario junto con la suma de EcoPuntos acumulados.

- **Respuesta Exitosa (200 OK):**
  ```json
  {
    "success": true,
    "usuarioId": 1,
    "totalFotos": 3,
    "totalPuntos": 170,
    "photos": [ ... ]
  }
  ```

---

## 6. Frontend Móvil e Inspiración de Interfaces

Se desarrollaron dos pantallas centrales altamente fieles a las maquetas visuales entregadas:

### 6.1. Pantalla Principal / Dashboard (`lib/screens/home_screen.dart` - Inspirada en Interfaz 2)
- **Cabecera Tipográfica:**
  - *"¡Hola!"* en verde esmeralda corporativo `#1B6B27` con peso tipográfico `FontWeight.w900`.
  - Subtítulo *"Haz la diferencia hoy"*.
- **Cuadrícula de 5 Tarjetas Verdes:**
  - Fondo menta suave `#EBF5EE` con radio de curvatura de 22 px.
  - Botón blanco flotante centrado con sombras sutiles que alberga cada icono distintivo:
    1. **Escanear residuo:** Icono de cámara oscura `#333333` ➔ **Navega directamente a `EcoScanScreen`**.
    2. **Eco IA:** Brote vegetal con hojas verdes en maceta marrón ➔ Despliega guía de inteligencia verde.
    3. **Mapa:** Pin circular verde ➔ Muestra puntos limpios y acopios cercanos.
    4. **Mis puntos:** Diana roja concéntrica ➔ Despliega el acumulado de EcoPuntos e historial de escaneos.
    5. **EcoCuidados:** Copa de árbol verde centrada ➔ Muestra hábitos de reducción de huella de carbono.

### 6.2. Pantalla de Captura EcoScan (`lib/screens/ecoscan_screen.dart` - Tarea 900 & Inspirada en Interfaz 3)
- **Cabecera:** Botón de retroceso `←`, título centrado **EcoScan** en verde hoja y subtítulo *"Enfoca el residuo a escanear"*.
- **Visor HUD de Escaneo:**
  - Contenedor rectangular oscuro `#1E2320` con esquinas redondeadas de 28 px.
  - Esquinas HUD verde neón `#69F0AE` dibujadas con `CustomPainter` (`_CornersPainter`).
  - Silueta vectorial central representativa de una botella PET azulada.
  - Línea láser interactiva con animación vertical suave continua.
- **Barra de Acciones Inferior:**
  - Botón *"Galería"* en forma de píldora gris claro `#E2E4E6`.
  - Disparador de cámara circular grande: aro exterior verde `#14531E` con botón circular blanco interior.

### 6.3. Manejo de Errores (Tarea 800 - Marisol Moreno)
- Detección reactiva de errores (`CameraAccessException`, permisos rechazados o entorno emulador/desktop sin webcam).
- Diálogo informativo con alerta amigable: permite cancelar o utilizar la opción *"Simular Captura"* con una imagen de muestra para continuar sin interrupciones.

### 6.4. Confirmación Visual tras Guardar la Foto (Tarea 850 - Alexis Hernández)
- Al completar la captura y subida, se presenta un `ModalBottomSheet` con:
  - Círculo animado de checkmark verde (`Icons.check_circle_rounded`).
  - Mensaje *"¡Foto Guardada y Registrada!"*.
  - Miniatura real del residuo capturado.
  - Nombre del material clasificado (*"Botella de plástico PET"*).
  - Insignia de EcoPuntos ganados (*"+50 pts"* con estrella dorada).
  - Consejo ecológico contextual de disposición y reciclaje.
  - Botones *"Escanear Otro"* y *"Ir al Inicio"*.

---

## 7. Resultados de Pruebas Unitarias y de Widgets (Tarea 750 - Adriel Ramos)

### 7.1. Pruebas Unitarias del Backend (`npm test`)
Se ejecutaron las 16 pruebas automatizadas cubriendo el Sprint 1 y el Sprint 2:

```text
▶ Pruebas Unitarias de Autenticación - EcoScan (Sprint 1)
  ✔ 1. [BD] La tabla Usuario debe existir y permitir inserción de registros válidos
  ✔ 2. [Seguridad] Debe encriptar contraseñas usando bcrypt con hash seguro
  ✔ 3. [Sesión] Debe generar y verificar tokens JWT con payload de usuario
  ✔ 4. [Registro] Registro exitoso con datos válidos y contraseña encriptada
  ✔ 5. [Registro] Debe impedir el registro con correo duplicado
  ✔ 6. [Login] Login exitoso con credenciales correctas
  ✔ 7. [Login] Debe rechazar credenciales con contraseña incorrecta
  ✔ 8. [Login] Debe rechazar inicio de sesión con correo no registrado
  ✔ 9. [Sesión] Debe rechazar tokens manipulados o inválidos
✔ Pruebas Unitarias de Autenticación - EcoScan (Sprint 1) (437ms)

▶ Pruebas Unitarias de Fotos y Subida - EcoScan (Sprint 2)
  ✔ 1. [BD - Tarea 970] La tabla Fotos debe existir y tener la estructura correcta
  ✔ 2. [Backend - Tarea 1000] Subir y guardar foto asociada al usuario exitosamente
  ✔ 3. [Validación] Debe rechazar subida si no se envía imagen
  ✔ 4. [Validación] Debe rechazar subida si el usuario no existe
  ✔ 5. [Puntos] Asignación correcta de EcoPuntos según residuo
  ✔ 6. [Consulta] Obtener fotos e historial del usuario
  ✔ 7. [Consulta Individual] Obtener foto por su ID
✔ Pruebas Unitarias de Fotos y Subida - EcoScan (Sprint 2) (96ms)

ℹ tests 16 | pass 16 | fail 0 | 100% exitoso
```

### 7.2. Pruebas Automatizadas de Flutter (`flutter test`)
```text
00:00 +0: 1. EcoScan Welcome Screen smoke test
00:00 +1: 2. HomeScreen muestra diseño fiel con las 5 tarjetas de acción
00:00 +2: 3. Navegación a EcoScanScreen y presencia de elementos de Image 3
00:00 +3: 4. EcoScanScreen renderiza directamente el visor HUD
00:00 +4: All tests passed!
```

### 7.3. Análisis Estático de Código (`flutter analyze`)
```text
Analyzing app1...
No issues found! (ran in 1.5s)
```

---

## 8. Conclusión del Sprint

Todas las metas del backlog y los requerimientos de diseño fueron completados al 100%:
1. El backend persiste de manera segura las fotografías en disco y en la base de datos relacional SQLite asociadas al usuario autenticado.
2. La aplicación móvil ofrece una experiencia visual idéntica a las referencias entregadas, con visor HUD animado, disparador estilizado, acceso a galería y diálogo de confirmación con EcoPuntos ganados.
3. Se garantizó la resiliencia operativa mediante manejo de errores y compatibilidad multiplataforma en Android e iOS.
