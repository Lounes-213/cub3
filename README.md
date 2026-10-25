# 🏢 CUBE 3 (تطبيق الإقامة الجامعية باب الزوار 3)

> **CUBE 3** هو تطبيق شامل وخاص بالخدمات والأنشطة الطلابية للإقامة الجامعية **باب الزوار 3 (الجزائر العاصمة)**. يجمع بين منظومة الإدارة الذكية للخدمات الجامعية (الإيواء، الإطعام، النقل، الصحة، الملاعب، الصيانة، سوق الطلبة) ومنصة الألعاب والمسابقات التفاعلية المباشرة (Arena & Multiplayer Quizzes).

---

## 🌟 أبرز ميزات التطبيق (Features)

### 🏆 1. منصة المسابقات والأرينا (Competitions & Live Arena)
- **ساحة التحدي المباشر (Live Multiplayer Arena)**: غرف منافسة جماعية متزامنة في الوقت الفعلي مدعومة بـ Cloudflare Durable Objects و WebSockets.
- **مراحل المسابقة (Stages & Rounds)**: نظام أسئلة تفاعلية، توقيت ذكي، وكشف فوري للنتائج والإحصائيات.
- **لوحة الشرف وتوزيع النقاط**: متصدرو التحديات ونظام المكافآت التنافسي.

### 🏠 2. الخدمات الجامعية والإقامة (Campus & Housing Life)
- **الإيواء والغرف (Housing & Rooms)**: إدارة معلومات الغرفة، الجناح، وخدمات الطلبة المقيمين.
- **مطعم الإقامة والوجبات (Catering & Meals)**: عرض يومي لقوائم وجبات الغداء والعشاء، التقييم، وإبداء الملاحظات.
- **العيادة والخدمات الصحية (Medical Center)**: مواعيد الفحوصات الطبية، الإسعافات الأولية، وأرقام الطوارئ السريعة.
- **حجز الملاعب الرياضية (Field Booking)**: حجز الملاعب الملاعب متعددة الرياضات وجداول المباريات.
- **تنظيم مرافق الدوش (Shower Booking)**: تنظيم مواعيد استخدام المرافق وتفادي الازدحام.
- **النقل الجامعي (Transport & Buses)**: مواعيد ومسارات حافلات النقل الجامعي من وإلى الإقامة والجامعات.
- **المكتبة وقاعات المطالعة (Library & Study Rooms)**: دليل الكتب المتوفرة، حجز أوقات المطالعة، والاستعارة.
- **الصيانة والشكاوى (Maintenance & Support)**: إرسال بلاغات الأعطال في الغرف والأجنحة ومتابعة حالة المعالجة.

### 🛒 3. سوق الطلبة (Student Marketplace)
- **إعلانات البيع والشراء والتبادل**: بيع الكتب، الأدوات الهندسية، الأجهزة، والأغراض الشخصية بين الطلبة.
- **مشاركة المنتجات بروابط ذكية (Deep Links)**: روابط سريعة `/p/<id>` للمشاركة الفورية.
- **تواصل آمن ومباشر**: تسهيل الوصول بين الطلبة داخل الإقامة.

### 📰 4. الأخبار والإعلانات (Announcements & News)
- **كاروسيل الأخبار التفاعلي**: أحدث إعلانات إدارة الإقامة والأنشطة الطلابية.
- **منشورات الإدارة الرسمية**: تغطية الفعاليات والنشاطات الثقافية والرياضية.

### ⚙️ 5. لوحة التحكم والإدارة (Admin Suite)
- **إدارة المسابقات والأرينا**: إنشاء وتعديل الأسئلة والتحكم في الغرف المباشرة.
- **إدارة المنشورات والإعلانات**: التحكم في المنشورات المعروضة في الشاشة الرئيسية.
- **إدارة بيانات الطلبة والخدمات**: متابعة بلاغات الصيانة، الحجوزات، والطلبات.

---

## 🛠️ البنية التقنية (Tech Stack)

### Client (Flutter Mobile & Web)
- **Framework**: Flutter 3.x (Dart 3.x)
- **State Management**: `Provider`
- **Networking & Realtime**: `http`, `web_socket_channel`
- **UI & Animation**: `flutter_animate`, `animated_text_kit`, `google_fonts`
- **Maps & Location**: `flutter_map`, `latlong2`, `geolocator`
- **Scanning & Tools**: `mobile_scanner`, `qr_flutter`, `image_picker`, `url_launcher`
- **Notifications**: `flutter_local_notifications`, `timezone`

### Backend & Cloud Infrastructure
- **Serverless Runtime**: Cloudflare Workers (TypeScript)
- **Real-Time Multiplayer State**: Cloudflare Durable Objects (`GameRoomDO`)
- **Database**: Cloudflare D1 (Serverless Distributed SQLite)
- **Media Storage**: Cloudflare R2
- **Data Integration**: Progres API Gateway

---

## 📁 هيكلة المشروع (Project Architecture)

```text
musabaqat_cube3/
├── android/                   # إعدادات منصة Android
├── ios/                       # إعدادات منصة iOS
├── web/                       # إعدادات منصة Web
├── assets/                    # الشعارات والأيقونات والخطوط
│   ├── cube3_logo.png
│   └── club_logo.png
├── backend/                   # Cloudflare Workers & Durable Objects
│   ├── src/
│   │   ├── index.ts          # API Endpoints & Routes
│   │   └── durable-objects/  # GameRoomDO للعب الجماعي المباشر
│   ├── schema.sql            # جداول قاعدة بيانات D1
│   └── wrangler.toml         # إعدادات Cloudflare
└── lib/                       # كود Flutter الرئيسي
    ├── core/                 # الخدمات الأساسية، الشبكة، وإعدادات Cloudflare
    ├── models/               # نماذج البيانات (Marketplace, Posts, Arena...)
    ├── providers/            # إدارة الحالة (User, Theme, Game, AppConfig...)
    ├── screens/              # واجهات التطبيق
    │   ├── admin/            # لوحة إدارة الإقامة والمسابقات
    │   ├── stages/           # مراحل وتحديات المسابقات
    │   ├── home_screen.dart  # الواجهة الرئيسية
    │   ├── arena_screen.dart # ساحة الأرينا المباشرة
    │   ├── housing_screen.dart
    │   ├── catering_screen.dart
    │   ├── transport_screen.dart
    │   ├── marketplace_screen.dart
    │   └── ...
    ├── services/             # خدمات Firebase, News, Progres, Marketplace
    ├── theme/                # نظام الألوان والثيمات (Dark / Light)
    └── widgets/              # العناصر القابلة لإعادة الاستخدام
```

---

## 🚀 تشغيل المشروع محلياً (Getting Started)

### متطلبات التشغيل
- Flutter SDK (>= 3.11.4)
- Node.js & npm (لتشغيل الباك إند عبر Wrangler)

### خطوات التشغيل
1. **استنساخ المستودع**:
   ```bash
   git clone https://github.com/Lounes-213/cube3.git
   cd cube3
   ```

2. **تثبيت حزم Flutter**:
   ```bash
   flutter pub get
   ```

3. **تشغيل تطبيق Flutter**:
   ```bash
   flutter run
   ```

4. **تشغيل الباك إند (اختياري)**:
   ```bash
   cd backend
   npm install
   npx wrangler dev
   ```

---

## 📄 الترخيص (License)
جميع الحقوق محفوظة © 2026 للإقامة الجامعية باب الزوار 3 (CUBE 3).
