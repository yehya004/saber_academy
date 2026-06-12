-- ============================================================
-- Migration 031 — Create academy_info table for guest panel
-- ============================================================
-- Run this in: Supabase Dashboard → SQL Editor → New query
-- ============================================================

CREATE TABLE IF NOT EXISTS public.academy_info (
  id INT PRIMARY KEY DEFAULT 1,
  sheikh_bio TEXT,
  sheikh_bio_en TEXT,
  sheikh_bio_tr TEXT,
  program_desc TEXT,
  program_desc_en TEXT,
  program_desc_tr TEXT,
  youtube_urls TEXT[] DEFAULT '{}'::TEXT[],
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Insert default row
INSERT INTO public.academy_info (
  id,
  sheikh_bio,
  sheikh_bio_en,
  sheikh_bio_tr,
  program_desc,
  program_desc_en,
  program_desc_tr,
  youtube_urls
) VALUES (
  1,
  'الشيخ صابر هو معلم ومحفظ معتمد للقرآن الكريم، يتمتع بخبرة واسعة في تعليم التجويد والقراءات ومساعدة الطلاب من كافة المستويات على تحسين تلاوتهم وحفظ كتاب الله.',
  'Sheikh Saber is a certified Quran teacher and memorization tutor, with extensive experience in teaching Tajweed and Qira''at, helping students of all levels correct their recitation and memorize the Holy Quran.',
  'Şeyh Saber, tecvid ve kıraat öğretiminde geniş deneyime sahip, her seviyeden öğrencinin tilavetini düzeltmesine ve Kur''an-ı Kerim''i ezberlemesine yardımcı olan sertifikalı bir Kur''an öğretmenidir.',
  'برنامج تعليمي متكامل يعتمد على الحصص الفردية والمتابعة المستمرة. يمكنك اختيار نظام الساعات أو نظام الحصص وتلقي تعليقات مباشرة وتصحيح التلاوات.',
  'A comprehensive educational program based on one-on-one sessions and continuous follow-up. You can choose the hours or classes system, get direct feedback, and correct your recitation.',
  'Birebir derslere ve sürekli takibe dayalı kapsamlı bir eğitim programı. Saat veya ders sistemini seçebilir, doğrudan geri bildirim alabilir ve tilavetinizi düzeltebilirsiniz.',
  ARRAY['https://www.youtube.com/watch?v=dQw4w9WgXcQ']
) ON CONFLICT (id) DO NOTHING;

-- Enable RLS
ALTER TABLE public.academy_info ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read
DROP POLICY IF EXISTS "anyone_can_read_academy_info" ON public.academy_info;
CREATE POLICY "anyone_can_read_academy_info"
  ON public.academy_info
  FOR SELECT
  USING (true);

-- Allow teachers to update
DROP POLICY IF EXISTS "teachers_can_update_academy_info" ON public.academy_info;
CREATE POLICY "teachers_can_update_academy_info"
  ON public.academy_info
  FOR UPDATE
  TO authenticated
  USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'teacher');
