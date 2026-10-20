-- ==============================================================================
-- EcoScan: Esquema de Base de Datos y Políticas de Seguridad (RLS) para Supabase
-- ==============================================================================
-- Puedes ejecutar este script directamente en el editor SQL de tu panel de Supabase:
-- https://supabase.com/dashboard/project/<tu-proyecto>/sql

-- 1. Tabla de Perfiles de Usuario (vinculada con auth.users de Supabase)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nombre_completo TEXT,
  correo_electronico TEXT UNIQUE NOT NULL,
  puntos_totales INTEGER DEFAULT 0,
  terminos_aceptados BOOLEAN DEFAULT TRUE,
  fecha_creacion TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Habilitar Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Políticas de RLS para profiles
CREATE POLICY "Los usuarios pueden ver su propio perfil"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Los usuarios pueden actualizar su propio perfil"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- 2. Trigger para crear automáticamente el perfil al registrarse en Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, correo_electronico, nombre_completo)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 3. Tabla de Fotos y Residuos Escaneados
CREATE TABLE IF NOT EXISTS public.fotos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  photo_url TEXT NOT NULL,
  tipo_residuo TEXT DEFAULT 'Plástico PET',
  puntos_otorgados INTEGER DEFAULT 50,
  created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Habilitar RLS en fotos
ALTER TABLE public.fotos ENABLE ROW LEVEL SECURITY;

-- Políticas RLS para fotos
CREATE POLICY "Los usuarios pueden ver sus fotos escaneadas"
  ON public.fotos FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Los usuarios pueden registrar nuevas fotos"
  ON public.fotos FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Los usuarios pueden eliminar sus propias fotos"
  ON public.fotos FOR DELETE
  USING (auth.uid() = user_id);

-- 4. Bucket de Almacenamiento en Supabase Storage para fotos de residuos
-- (Asegúrate de habilitar el bucket 'residues-photos' en Storage > Buckets si no se crea por SQL)
INSERT INTO storage.buckets (id, name, public)
VALUES ('residues-photos', 'residues-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Políticas de Storage para el bucket residues-photos
CREATE POLICY "Permitir subida de fotos a usuarios autenticados"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'residues-photos' AND auth.role() = 'authenticated');

CREATE POLICY "Permitir lectura pública de fotos de residuos"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'residues-photos');
