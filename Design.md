# Design System: Saber Academy App

## 1. Design Principles
- **Serene & Islamic:** Visuals should evoke calmness and focus, utilizing deep greens and gold accents inspired by traditional Islamic art and the brand logo.
- **Bilingual First:** Complete symmetry and seamless transition between LTR (English) and RTL (Arabic). UI elements must flip correctly without breaking layout constraints.
- **Focus on Progress:** The student's journey (Levels, Attendance, Homework) should be visually rewarding and easy to track.
- **Legibility:** High contrast for educational reading, especially for the custom Mushaf viewer.

## 2. Design Tokens

### 2.1. Color Palette (Derived from Logo)
- **Primary (Brand Green):** `#154734` (Used for AppBars, primary buttons, bottom navigation).
- **Secondary (Brand Gold):** `#D4AF37` (Used for active icons, progress bars, highlights, and primary text accents).
- **Background (Light):** `#F9F7F2` (Warm, off-white/beige tone for app background to reduce eye strain).
- **Surface:** `#FFFFFF` (For cards, dialogue boxes, and input fields).
- **Text Primary:** `#2D2821` (Very dark warm grey for main text/headings).
- **Text Secondary:** `#736B5E` (Muted grey-brown for subtitles, dates, and placeholders).
- **Status Colors:**
  - Success/Present: `#28A745`
  - Error/Absent: `#DC3545`
  - Pending/Warning: `#FFC107`

### 2.2. Typography
- **Primary Font (Arabic):** `Cairo` or `Tajawal` (Clean, modern, highly readable for UI).
- **Primary Font (English):** `Outfit` or `Inter` (Complements the Arabic font's geometric curves).
- **Quranic Font (Mushaf Viewer):** `Amiri` or `KFGQPC Uthman Taha Naskh` (Strictly for Quran verses).
- **Text Styles:**
  - `Display-Large`: 28sp, Bold, Color: Primary
  - `Heading-1`: 22sp, Semi-Bold, Color: Text Primary
  - `Body-Text`: 16sp, Regular, Color: Text Primary
  - `Caption`: 12sp, Medium, Color: Text Secondary

### 2.3. Spacing & Radius
- **Spacing:**
  - Small (S): 8dp
  - Medium (M): 16dp
  - Large (L): 24dp
  - Extra Large (XL): 32dp
- **Border Radius:**
  - Cards & Buttons: 12dp (Soft, modern rounded corners).
  - Chat Bubbles: 16dp (With one flat corner depending on sender/RTL/LTR context).

---

## 3. Component Rules

### 3.1. Buttons
- **Primary Button:**
  - Background: Primary (`#154734`)
  - Text: Surface (`#FFFFFF`), 16sp, Bold
  - Border-Radius: 12dp
  - Elevation: 2 (Subtle shadow)
- **Secondary/Outline Button:**
  - Border: 2px solid Secondary (`#D4AF37`)
  - Text: Primary (`#154734`)
  - Background: Transparent

### 3.2. Cards (Homework & Sessions)
- **Background:** Surface (`#FFFFFF`)
- **Padding:** 16dp inside.
- **Margin:** 8dp vertical, 16dp horizontal.
- **Shadow:** `BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 4))`
- **Status Badges (Inside Cards):**
  - "Pending": Light yellow background with dark yellow text.
  - "Corrected": Light green background with dark green text.

### 3.3. Chat Interface (`ChatService`)
- **Teacher Bubble:**
  - Background: Primary (`#154734`)
  - Text Color: `#FFFFFF`
  - Alignment: Depends on directionality (Start for RTL if Teacher, etc.).
- **Student Bubble:**
  - Background: `#EAE6DF` (Soft beige)
  - Text Color: Text Primary
- **Timestamps:** 10sp, Text Secondary, aligned to the bottom corner of the bubble.

### 3.4. Progress Indicators (Levels System)
- **Percent Indicator widget:**
  - Track Color: `#E0DCD3`
  - Progress Color: Secondary (`#D4AF37`)
  - Line Width: 8dp
  - Circular Radius (if circular): 60dp

### 3.5. Custom Mushaf Viewer
- **Background Mode:** Must include a toggle for a "Sepia/Eye-care" mode (Background: `#F4EFE6`, Text: `#1A1A1A`) and a "Dark Mode" (Background: `#121212`, Text: `#E0E0E0`).
- **Zooming:** Interactive Viewer enabled for PDFs/Images with double-tap to zoom.

---

## 4. Layout & Localization Architecture
- **Bi-Directional Support:** All UI elements using `Row` must use `MainAxisAlignment` correctly. Icons must use `Directionality` widgets or `autoMirrored` properties where applicable (e.g., back arrows).
- **State Changes:** When the localization toggle is hit via `Provider`, the `MaterialApp` must rebuild its `locale` and trigger an immediate visual flip.