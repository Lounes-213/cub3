-- Cube III D1 Database Schema

-- Users / Profiles Table
CREATE TABLE IF NOT EXISTS users (
    matricule TEXT PRIMARY KEY,
    username TEXT UNIQUE,
    password TEXT,
    full_name_ar TEXT,
    full_name_fr TEXT,
    first_name_ar TEXT,
    last_name_ar TEXT,
    level_ar TEXT,
    cycle_ar TEXT,
    registration_number TEXT,
    role TEXT DEFAULT 'etud',
    is_active INTEGER DEFAULT 1,
    photo TEXT,
    room_number TEXT,
    resident_since TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- Questions Bank Table
CREATE TABLE IF NOT EXISTS questions (
    id TEXT PRIMARY KEY,
    title TEXT,
    category TEXT,
    question_text TEXT NOT NULL,
    type TEXT DEFAULT 'multiple_choice',
    options TEXT, -- JSON array of strings: '["A", "B", "C", "D"]'
    correct_answer TEXT,
    description TEXT,
    media_url TEXT,
    media_type TEXT,
    points INTEGER DEFAULT 1,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_questions_category ON questions(category);

-- Competitions Library Table
CREATE TABLE IF NOT EXISTS competitions_library (
    id TEXT PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    config TEXT NOT NULL, -- JSON config
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Competition History Table (نتائج المسابقات المنتهية — أرشيف دائم)
CREATE TABLE IF NOT EXISTS competition_history (
    id TEXT PRIMARY KEY,
    title TEXT,
    date TEXT,
    status TEXT, -- finished | closed
    finished_at TEXT,
    num_teams INTEGER,
    team_size INTEGER,
    winner_name TEXT,
    question_count INTEGER DEFAULT 0,
    ranking_json TEXT,    -- JSON array: [{slot,name,members,score,color}] مرتّبة تنازلياً
    question_history_json TEXT, -- JSON object: نتائج الأسئلة المسجّلة
    stages_json TEXT       -- JSON array: مراحل المسابقة
);

-- Daily Field Program (برنامج الملاعب — يبرمجه الأدمين، الطلبة يشوفونه)
CREATE TABLE IF NOT EXISTS field_program (
    id TEXT PRIMARY KEY,
    play_date TEXT,   -- YYYY-MM-DD
    time TEXT,        -- HH:MM
    field TEXT,       -- football | basketball
    team_a TEXT,
    team_b TEXT,
    note TEXT DEFAULT '',
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Facebook / Campus News Cache Table
CREATE TABLE IF NOT EXISTS facebook_news (
    id TEXT PRIMARY KEY,
    title TEXT,
    text TEXT,
    type TEXT DEFAULT 'text',
    media_urls TEXT, -- JSON array
    video_url TEXT,
    date TEXT,
    is_repost INTEGER DEFAULT 0,
    original_page_name TEXT,
    post_url TEXT,
    -- 1 = shows in the home auto-scrolling carousel, 0 = hidden from home
    in_carousel INTEGER DEFAULT 1,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Key-Value App Settings Table
CREATE TABLE IF NOT EXISTS app_config (
    key TEXT PRIMARY KEY,
    value TEXT
);

-- Admin Pubs / Advertisements Table (managed from admin panel)
CREATE TABLE IF NOT EXISTS pubs (
    id TEXT PRIMARY KEY,
    title TEXT,
    text TEXT,
    image_url TEXT,
    link TEXT,
    start_date TEXT,
    end_date TEXT,
    is_active INTEGER DEFAULT 1,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Medical appointments ordered by students (visible in admin panel)
CREATE TABLE IF NOT EXISTS medical_orders (
    id TEXT PRIMARY KEY,
    matricule TEXT,
    name TEXT,
    specialty TEXT,
    date TEXT,
    notes TEXT,
    status TEXT DEFAULT 'pending',
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_medical_orders_matricule ON medical_orders(matricule);
CREATE INDEX IF NOT EXISTS idx_medical_orders_status ON medical_orders(status);

-- Catering reservations synced from students (visible in admin panel)
CREATE TABLE IF NOT EXISTS catering_reservations (
    matricule TEXT PRIMARY KEY,
    name TEXT,
    reserved_at TEXT,
    expires_at TEXT,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Student Marketplace (Troc / Vente interne - Max 3 items per student)
CREATE TABLE IF NOT EXISTS marketplace_items (
    id TEXT PRIMARY KEY,
    matricule TEXT NOT NULL,
    seller_name TEXT NOT NULL,
    seller_phone TEXT NOT NULL,
    pavilion TEXT,
    room_number TEXT,
    title TEXT NOT NULL,
    description TEXT,
    price REAL DEFAULT 0,
    is_free INTEGER DEFAULT 0,
    category TEXT DEFAULT 'books', -- 'books', 'appliances', 'electronics', 'other'
    images TEXT, -- JSON array of up to 3 image URLs
    status TEXT DEFAULT 'available', -- 'available', 'sold'
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_marketplace_matricule ON marketplace_items(matricule);
CREATE INDEX IF NOT EXISTS idx_marketplace_category ON marketplace_items(category);
CREATE INDEX IF NOT EXISTS idx_marketplace_status ON marketplace_items(status);


-- Initial Seed: Default Users
INSERT OR IGNORE INTO users (matricule, username, password, full_name_ar, full_name_fr, role, level_ar, cycle_ar, registration_number, is_active)
VALUES 
('ADM-001', 'admin', 'admin123', 'مدير النظام المركزي', 'Administrateur Central', 'admin', 'مدير عام', 'طاقم الإدارة', 'ADM-001', 1),
('STF-102', 'staf', 'staff123', 'منشط الأنشطة والفعاليات', 'Responsable des Activités', 'staf', 'منشط ومصلحة الأنشطة', 'طاقم الإدارة', 'STF-102', 1),
('TRV-305', 'trav', 'trav123', 'عامل الصيانة والخدمات', 'Agent de Service', 'trav', 'مصلحة الخدمات والصيانة', 'طاقم العمال', 'TRV-305', 1),
('2020310456', 'etud', 'etud123', 'أمين بن أحمد', 'Amine Ben Ahmed', 'etud', 'السنة الثانية ليسانس', 'ليسانس أكاديمي', '2020310456', 1);
