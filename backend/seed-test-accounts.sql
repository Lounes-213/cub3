-- ============================================================
-- TEST ACCOUNTS (one per role) — ملف مؤقت للتجربة فقط
-- احذف هذا الملف لاحقاً + احذف الحسابات من D1 عند الانتهاء:
--   DELETE FROM users WHERE matricule LIKE 'TST-%';
-- ============================================================

-- 1) ADMIN — مدير النظام (دخول محلي: testadmin / TestAdmin123)
INSERT OR IGNORE INTO users (matricule, username, password, full_name_ar, full_name_fr, level_ar, cycle_ar, registration_number, role, is_active)
VALUES ('TST-ADM-01', 'testadmin', 'TestAdmin123', 'حساب تجريبي — مدير', 'Test Admin', 'مدير عام', 'طاقم الإدارة', 'TST-ADM-01', 'admin', 1);

-- 2) STAF — مسؤول الأنشطة (دخول محلي: teststaf / TestStaf123)
INSERT OR IGNORE INTO users (matricule, username, password, full_name_ar, full_name_fr, level_ar, cycle_ar, registration_number, role, is_active)
VALUES ('TST-STF-01', 'teststaf', 'TestStaf123', 'حساب تجريبي — منشط', 'Test Staff', 'منشط ومصلحة الأنشطة', 'طاقم الإدارة', 'TST-STF-01', 'staf', 1);

-- 3) TRAV — عامل الخدمات (دخول محلي: testtrav / TestTrav123)
INSERT OR IGNORE INTO users (matricule, username, password, full_name_ar, full_name_fr, level_ar, cycle_ar, registration_number, role, is_active)
VALUES ('TST-TRV-01', 'testtrav', 'TestTrav123', 'حساب تجريبي — عامل', 'Test Worker', 'مصلحة الخدمات والصيانة', 'طاقم العمال', 'TST-TRV-01', 'trav', 1);

-- 4) ETUD — طالب (testetud / TestEtud123)
-- ملاحظة: حساب الطالب لا يدخل إلا عبر PROGRES الحقيقي (قاعدة الدخول).
-- هذا الصف للعرض في قائمة المستخدمين فقط، وليس للدخول المحلي.
INSERT OR IGNORE INTO users (matricule, username, password, full_name_ar, full_name_fr, level_ar, cycle_ar, registration_number, role, is_active)
VALUES ('TST-ETU-01', 'testetud', 'TestEtud123', 'حساب تجريبي — طالب', 'Test Student', 'السنة الأولى ليسانس', 'ليسانس أكاديمي', 'TST-ETU-01', 'etud', 1);
