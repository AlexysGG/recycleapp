# Preparación de Supabase para EcoScan

Esta guía detalla los pasos para completar la conexión con **Supabase** en la aplicación EcoScan.

---

## 1. Crear el Proyecto en Supabase
1. Ingresa a [supabase.com](https://supabase.com) e inicia sesión o regístrate.
2. Crea una nueva organización y un nuevo proyecto (por ejemplo `ecoscan-app`).
3. Elige la región más cercana a tus usuarios (ej. `us-east-1` o `sa-east-1`).
4. Guarda tu contraseña de base de datos en un lugar seguro.

---

## 2. Ejecutar el Esquema de Base de Datos
1. En tu panel de Supabase, ve a la sección **SQL Editor** en el menú lateral izquierdo.
2. Abre o copia el contenido de [`supabase/schema.sql`](schema.sql).
3. Pega el script y haz clic en **Run**.
4. Esto creará:
   - Tabla `public.profiles` con sincronización automática desde `auth.users`.
   - Tabla `public.fotos` para almacenar las fotos escaneadas y sus puntos ecológicos.
   - Políticas de seguridad a nivel de fila (Row Level Security - RLS).
   - Bucket en Supabase Storage llamado `residues-photos`.

---

## 3. Obtener tus Credenciales
1. En el panel de Supabase, dirígete a **Project Settings** (ícono de engranaje) > **API**.
2. Copia:
   - **Project URL** (ejemplo: `https://xyzcompany.supabase.co`)
   - **anon public API Key** (ejemplo: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`)

---

## 4. Configurar en la Aplicación Flutter

Puedes configurar las credenciales de dos formas:

### Opción A: Directamente en `lib/services/supabase_service.dart`
Actualiza las constantes:
```dart
static const String supabaseUrl = 'https://TU-PROYECTO.supabase.co';
static const String supabaseAnonKey = 'TU-ANON-KEY-AQUI';
```

### Opción B: Mediante banderas de compilación (`--dart-define`)
Sin modificar el código fuente:
```bash
flutter run --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co --dart-define=SUPABASE_ANON_KEY=TU-ANON-KEY-AQUI
```

---

## 5. Arquitectura del Servicio (`SupabaseService`)
El archivo [`lib/services/supabase_service.dart`](../lib/services/supabase_service.dart) ya cuenta con:
- Autenticación: `signUp()`, `signInWithPassword()`, `signOut()`, `currentUser`.
- Storage: `uploadPhoto()` para subir capturas al bucket `residues-photos`.
- Database: `insertPhotoRecord()`, `getUserPhotos()`.
