import { Hono } from "hono";
import { cors } from "hono/cors";
import { Env, UserProfile, Question } from "./types";
import { GameRoomDO } from "./game_room";

export { GameRoomDO };

const app = new Hono<{ Bindings: Env }>();

// Enable CORS for all origins (Flutter Web, Android, iOS, Windows, macOS)
app.use(
  "*",
  cors({
    origin: "*",
    allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowHeaders: ["Content-Type", "Authorization", "X-Custom-Header"],
  })
);

// Helper to get global GameRoomDO instance
function getGameRoom(env: Env) {
  const id = env.GAME_ROOM.idFromName("cube_iii_match");
  return env.GAME_ROOM.get(id);
}

// ----------------------------------------------------
// REALTIME WEBSOCKET & GAME DO ENDPOINTS
// ----------------------------------------------------

app.get("/ws/game", async (c) => {
  const room = getGameRoom(c.env);
  return room.fetch(c.req.raw);
});

app.get("/api/game/ws", async (c) => {
  const room = getGameRoom(c.env);
  return room.fetch(c.req.raw);
});

app.get("/api/game/state", async (c) => {
  const room = getGameRoom(c.env);
  return room.fetch(new Request("https://internal/state", { method: "GET" }));
});

app.post("/api/game/action", async (c) => {
  const body = await c.req.text();
  const room = getGameRoom(c.env);
  return room.fetch(
    new Request("https://internal/action", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body,
    })
  );
});

// ----------------------------------------------------
// D1: USERS & PROFILES ENDPOINTS
// ----------------------------------------------------

app.get("/api/users", async (c) => {
  try {
    const { results } = await c.env.DB.prepare(
      "SELECT matricule, username, full_name_ar as fullNameAr, full_name_fr as fullNameFr, first_name_ar as firstNameAr, last_name_ar as lastNameAr, level_ar as levelAr, cycle_ar as cycleAr, registration_number as registrationNumber, role, is_active as isActive, photo, room_number as roomNumber, resident_since as residentSince, created_at FROM users"
    ).all();

    const formatted = results.map((u: any) => ({
      ...u,
      isActive: u.isActive === 1 || u.isActive === true,
    }));
    return c.json({ success: true, users: formatted });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

app.get("/api/users/by-username/:username", async (c) => {
  const username = c.req.param("username");
  try {
    const user = await c.env.DB.prepare(
      "SELECT matricule, username, password, full_name_ar as fullNameAr, full_name_fr as fullNameFr, first_name_ar as firstNameAr, last_name_ar as lastNameAr, level_ar as levelAr, cycle_ar as cycleAr, registration_number as registrationNumber, role, is_active as isActive, photo, room_number as roomNumber, resident_since as residentSince FROM users WHERE username = ? OR matricule = ?"
    )
      .bind(username, username)
      .first<any>();

    if (!user) {
      return c.json({ success: false, message: "User not found" }, 404);
    }
    user.isActive = user.isActive === 1 || user.isActive === true;
    return c.json({ success: true, profile: user });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

app.get("/api/users/by-matricule/:matricule", async (c) => {
  const matricule = c.req.param("matricule");
  try {
    const user = await c.env.DB.prepare(
      "SELECT matricule, username, password, full_name_ar as fullNameAr, full_name_fr as fullNameFr, first_name_ar as firstNameAr, last_name_ar as lastNameAr, level_ar as levelAr, cycle_ar as cycleAr, registration_number as registrationNumber, role, is_active as isActive, photo, room_number as roomNumber, resident_since as residentSince FROM users WHERE matricule = ? OR username = ?"
    )
      .bind(matricule, matricule)
      .first<any>();

    if (!user) {
      return c.json({ success: false, message: "Profile not found" }, 404);
    }
    user.isActive = user.isActive === 1 || user.isActive === true;
    return c.json({ success: true, profile: user });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

app.post("/api/users", async (c) => {
  try {
    const body = await c.req.json<any>();
    const matricule = body.matricule || body.registrationNumber || body.username;
    if (!matricule) {
      return c.json({ success: false, message: "Matricule or Username required" }, 400);
    }

    const username = body.username || matricule;
    const password = body.password ?? null;
    const fullNameAr = body.fullNameAr ?? body.firstNameAr ?? null;
    const fullNameFr = body.fullNameFr ?? body.firstNameFr ?? null;
    const firstNameAr = body.firstNameAr ?? null;
    const lastNameAr = body.lastNameAr ?? null;
    const levelAr = body.levelAr ?? null;
    const cycleAr = body.cycleAr ?? null;
    const registrationNumber = body.registrationNumber ?? matricule;
    const role = body.role ?? "etud";
    const isActive = body.isActive !== undefined ? (body.isActive ? 1 : 0) : 1;
    const photo = body.photo ?? null;
    const roomNumber = body.roomNumber ?? body.room_number ?? null;
    const residentSince = body.residentSince ?? body.resident_since ?? null;

    await c.env.DB.prepare(
      `INSERT INTO users (matricule, username, password, full_name_ar, full_name_fr, first_name_ar, last_name_ar, level_ar, cycle_ar, registration_number, role, is_active, photo, room_number, resident_since, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
       ON CONFLICT(matricule) DO UPDATE SET
         username = COALESCE(excluded.username, users.username),
         password = COALESCE(excluded.password, users.password),
         full_name_ar = COALESCE(excluded.full_name_ar, users.full_name_ar),
         full_name_fr = COALESCE(excluded.full_name_fr, users.full_name_fr),
         first_name_ar = COALESCE(excluded.first_name_ar, users.first_name_ar),
         last_name_ar = COALESCE(excluded.last_name_ar, users.last_name_ar),
         level_ar = COALESCE(excluded.level_ar, users.level_ar),
         cycle_ar = COALESCE(excluded.cycle_ar, users.cycle_ar),
         registration_number = COALESCE(excluded.registration_number, users.registration_number),
         role = COALESCE(excluded.role, users.role),
         is_active = COALESCE(excluded.is_active, users.is_active),
         photo = COALESCE(excluded.photo, users.photo),
         room_number = COALESCE(excluded.room_number, users.room_number),
         resident_since = COALESCE(excluded.resident_since, users.resident_since),
         updated_at = CURRENT_TIMESTAMP`
    )
      .bind(
        matricule,
        username,
        password,
        fullNameAr,
        fullNameFr,
        firstNameAr,
        lastNameAr,
        levelAr,
        cycleAr,
        registrationNumber,
        role,
        isActive,
        photo,
        roomNumber,
        residentSince
      )
      .run();

    return c.json({ success: true, message: "Profile saved successfully" });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

app.put("/api/users/:matricule/role", async (c) => {
  const matricule = c.req.param("matricule");
  const { role } = await c.req.json();
  try {
    await c.env.DB.prepare("UPDATE users SET role = ?, updated_at = CURRENT_TIMESTAMP WHERE matricule = ?")
      .bind(role, matricule)
      .run();
    return c.json({ success: true });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

app.put("/api/users/:matricule/active", async (c) => {
  const matricule = c.req.param("matricule");
  const { isActive } = await c.req.json();
  try {
    await c.env.DB.prepare("UPDATE users SET is_active = ?, updated_at = CURRENT_TIMESTAMP WHERE matricule = ?")
      .bind(isActive ? 1 : 0, matricule)
      .run();
    return c.json({ success: true });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

// ----------------------------------------------------
// D1: QUESTIONS BANK ENDPOINTS
// ----------------------------------------------------

app.get("/api/questions", async (c) => {
  try {
    const { results } = await c.env.DB.prepare(
      "SELECT id, title, category, question_text, type, options, correct_answer, explanation, hint1, hint2, hint3, description, media_url, media_type, points, created_at FROM questions"
    ).all();

    const questions = results.map((row: any) => ({
      id: row.id,
      title: row.title,
      category: row.category,
      questionText: row.question_text,
      type: row.type,
      options: row.options ? JSON.parse(row.options) : [],
      correctAnswer: row.correct_answer,
      explanation: row.explanation || "",
      hint1: row.hint1 || "",
      hint2: row.hint2 || "",
      hint3: row.hint3 || "",
      description: row.description || "",
      mediaUrl: row.media_url,
      mediaType: row.media_type,
      points: row.points ?? 1,
      createdAt: row.created_at,
    }));

    return c.json({ success: true, questions });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

app.post("/api/questions", async (c) => {
  try {
    const q = await c.req.json<any>();
    const id = q.id || `q_${Date.now()}_${Math.random().toString(36).substr(2, 5)}`;
    const optionsJson = JSON.stringify(q.options || []);

    await c.env.DB.prepare(
      `INSERT INTO questions (id, title, category, question_text, type, options, correct_answer, explanation, hint1, hint2, hint3, description, media_url, media_type, points)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
      .bind(
        id,
        q.title || "",
        q.category || "",
        q.questionText || q.question_text || "",
        q.type || "multiple_choice",
        optionsJson,
        q.correctAnswer || q.correct_answer || "",
        q.explanation || "",
        q.hint1 || "",
        q.hint2 || "",
        q.hint3 || "",
        q.description || "",
        q.mediaUrl || q.media_url || "",
        q.mediaType || q.media_type || "",
        q.points ?? 1
      )
      .run();

    return c.json({ success: true, id });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

app.put("/api/questions/:id", async (c) => {
  const id = c.req.param("id");
  try {
    const q = await c.req.json<any>();
    const optionsJson = JSON.stringify(q.options || []);

    await c.env.DB.prepare(
      `UPDATE questions SET
         title = ?,
         category = ?,
         question_text = ?,
         type = ?,
         options = ?,
         correct_answer = ?,
         explanation = ?,
         hint1 = ?,
         hint2 = ?,
         hint3 = ?,
         description = ?,
         media_url = ?,
         media_type = ?,
         points = ?
       WHERE id = ?`
    )
      .bind(
        q.title || "",
        q.category || "",
        q.questionText || q.question_text || "",
        q.type || "multiple_choice",
        optionsJson,
        q.correctAnswer || q.correct_answer || "",
        q.explanation || "",
        q.hint1 || "",
        q.hint2 || "",
        q.hint3 || "",
        q.description || "",
        q.mediaUrl || q.media_url || "",
        q.mediaType || q.media_type || "",
        q.points ?? 1,
        id
      )
      .run();

    return c.json({ success: true });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

app.delete("/api/questions/:id", async (c) => {
  const id = c.req.param("id");
  try {
    await c.env.DB.prepare("DELETE FROM questions WHERE id = ?").bind(id).run();
    return c.json({ success: true });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

// Seed full questions bank
app.post("/api/questions/seed", async (c) => {
  try {
    const questions = await c.req.json<any[]>();
    if (!Array.isArray(questions)) {
      return c.json({ success: false, message: "Expected an array of questions" }, 400);
    }

    // Clear existing
    await c.env.DB.prepare("DELETE FROM questions").run();

    // Insert all
    for (const q of questions) {
      const id = q.id || `q_${Date.now()}_${Math.random().toString(36).substr(2, 5)}`;
      const optionsJson = JSON.stringify(q.options || []);
      await c.env.DB.prepare(
        `INSERT INTO questions (id, title, category, question_text, type, options, correct_answer, explanation, hint1, hint2, hint3, description, media_url, media_type, points)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
      )
        .bind(
          id,
          q.title || "",
          q.category || "",
          q.questionText || q.question_text || "",
          q.type || "multiple_choice",
          optionsJson,
          q.correctAnswer || q.correct_answer || "",
          q.explanation || "",
          q.hint1 || "",
          q.hint2 || "",
          q.hint3 || "",
          q.description || "",
          q.mediaUrl || q.media_url || "",
          q.mediaType || q.media_type || "",
          q.points ?? 1
        )
        .run();
    }

    return c.json({ success: true, count: questions.length });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

// ----------------------------------------------------
// D1: COMPETITIONS LIBRARY ENDPOINTS
// ----------------------------------------------------

app.get("/api/library", async (c) => {
  try {
    const { results } = await c.env.DB.prepare("SELECT name, config FROM competitions_library").all();
    const map: Record<string, any> = {};
    for (const row of results as any[]) {
      map[row.name] = JSON.parse(row.config);
    }
    return c.json({ success: true, library: map });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

app.post("/api/library/:name", async (c) => {
  const name = c.req.param("name");
  try {
    const config = await c.req.json();
    const configStr = JSON.stringify(config);
    const id = `lib_${Date.now()}`;

    await c.env.DB.prepare(
      `INSERT INTO competitions_library (id, name, config) VALUES (?, ?, ?)
       ON CONFLICT(name) DO UPDATE SET config = excluded.config`
    )
      .bind(id, name, configStr)
      .run();

    return c.json({ success: true });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

app.delete("/api/library/:name", async (c) => {
  const name = c.req.param("name");
  try {
    await c.env.DB.prepare("DELETE FROM competitions_library WHERE name = ?").bind(name).run();
    return c.json({ success: true });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

// ----------------------------------------------------
// D1: COMPETITION HISTORY (نتائج المسابقات المنتهية)
// يُملأ تلقائياً عند إنهاء المسابقة أو إغلاقها (من الـ Durable Object).
// ----------------------------------------------------

async function ensureCompetitionHistoryTable(db: D1Database) {
  await db
    .prepare(
      `CREATE TABLE IF NOT EXISTS competition_history (
        id TEXT PRIMARY KEY,
        title TEXT,
        date TEXT,
        status TEXT,
        finished_at TEXT,
        num_teams INTEGER,
        team_size INTEGER,
        winner_name TEXT,
        question_count INTEGER DEFAULT 0,
        ranking_json TEXT,
        question_history_json TEXT,
        stages_json TEXT
      )`
    )
    .run();
}

function safeParseArray(value: unknown): any[] {
  if (Array.isArray(value)) return value;
  if (typeof value !== "string" || !value) return [];
  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

app.get("/api/competition-history", async (c) => {
  try {
    await ensureCompetitionHistoryTable(c.env.DB);
    const { results } = await c.env.DB.prepare(
      `SELECT id, title, date, status, finished_at, num_teams, team_size,
              winner_name, question_count, ranking_json
       FROM competition_history
       ORDER BY finished_at DESC
       LIMIT 200`
    ).all();
    const list = (results as any[]).map((row) => ({
      id: row.id,
      title: row.title,
      date: row.date,
      status: row.status,
      finishedAt: row.finished_at,
      numTeams: row.num_teams,
      teamSize: row.team_size,
      winnerName: row.winner_name,
      questionCount: row.question_count,
      ranking: safeParseArray(row.ranking_json),
    }));
    return c.json({ success: true, history: list });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

app.get("/api/competition-history/:id", async (c) => {
  try {
    await ensureCompetitionHistoryTable(c.env.DB);
    const row = await c.env.DB.prepare(
      "SELECT * FROM competition_history WHERE id = ?"
    )
      .bind(c.req.param("id"))
      .first<any>();
    if (!row) return c.json({ success: false, message: "السجل غير موجود" }, 404);
    return c.json({
      success: true,
      item: {
        id: row.id,
        title: row.title,
        date: row.date,
        status: row.status,
        finishedAt: row.finished_at,
        numTeams: row.num_teams,
        teamSize: row.team_size,
        winnerName: row.winner_name,
        questionCount: row.question_count,
        ranking: safeParseArray(row.ranking_json),
        questionHistory: (() => {
          try {
            return row.question_history_json ? JSON.parse(row.question_history_json) : {};
          } catch {
            return {};
          }
        })(),
        stages: safeParseArray(row.stages_json),
      },
    });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

app.delete("/api/competition-history/:id", async (c) => {
  try {
    await ensureCompetitionHistoryTable(c.env.DB);
    await c.env.DB.prepare("DELETE FROM competition_history WHERE id = ?")
      .bind(c.req.param("id"))
      .run();
    return c.json({ success: true });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

// ----------------------------------------------------
// D1: DAILY FIELD PROGRAM (برنامج الملاعب)
// الأدمين يبرمج المباراة (شكون يلعب + الساعة + الملعب + النهار)
// والطلبة يشوفو الجدول اليومي فقط.
// ----------------------------------------------------

async function ensureFieldProgramTable(db: D1Database) {
  await db
    .prepare(
      `CREATE TABLE IF NOT EXISTS field_program (
        id TEXT PRIMARY KEY,
        play_date TEXT,
        time TEXT,
        field TEXT,
        team_a TEXT,
        team_b TEXT,
        note TEXT DEFAULT '',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )`
    )
    .run();
}

function mapFieldProgram(row: any) {
  return {
    id: row.id,
    playDate: row.play_date,
    time: row.time,
    field: row.field,
    teamA: row.team_a,
    teamB: row.team_b,
    note: row.note || "",
  };
}

app.get("/api/field-program", async (c) => {
  try {
    await ensureFieldProgramTable(c.env.DB);
    const date = c.req.query("date");
    const { results } = date
      ? await c.env.DB
          .prepare(
            "SELECT * FROM field_program WHERE play_date = ? ORDER BY time ASC"
          )
          .bind(date)
          .all()
      : await c.env.DB
          .prepare(
            "SELECT * FROM field_program ORDER BY play_date ASC, time ASC LIMIT 500"
          )
          .all();
    return c.json({
      success: true,
      program: (results as any[]).map(mapFieldProgram),
    });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

app.post("/api/field-program", async (c) => {
  try {
    await ensureFieldProgramTable(c.env.DB);
    const body = await c.req.json<any>();
    const playDate = String(body?.playDate ?? "").trim();
    const time = String(body?.time ?? "").trim();
    const field = String(body?.field ?? "football").trim();
    const teamA = String(body?.teamA ?? "").trim();
    const teamB = String(body?.teamB ?? "").trim();
    const note = String(body?.note ?? "").trim();

    if (!playDate || !time || !teamA || !teamB) {
      return c.json(
        { success: false, message: "البيانات ناقصة (النهار، الساعة، الفريقان)" },
        400
      );
    }
    if (!/^\d{2}:\d{2}$/.test(time)) {
      return c.json(
        { success: false, message: "الساعة يجب أن تكون بالصيغة HH:MM" },
        400
      );
    }

    const id = `fp_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
    await c.env.DB.prepare(
      `INSERT INTO field_program (id, play_date, time, field, team_a, team_b, note)
       VALUES (?, ?, ?, ?, ?, ?, ?)`
    )
      .bind(id, playDate, time, field, teamA, teamB, note)
      .run();

    return c.json({
      success: true,
      item: { id, playDate, time, field, teamA, teamB, note },
    });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

app.delete("/api/field-program/:id", async (c) => {
  try {
    await ensureFieldProgramTable(c.env.DB);
    await c.env.DB.prepare("DELETE FROM field_program WHERE id = ?")
      .bind(c.req.param("id"))
      .run();
    return c.json({ success: true });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

// ----------------------------------------------------
// D1: FACEBOOK / CAMPUS NEWS ENDPOINTS
// Posts are programmed by the admin panel. Hard cap: 100 posts.
// Images only (no video) to keep R2 storage small.
// ----------------------------------------------------

const MAX_NEWS_POSTS = 100;

/// Optional external link attached to a post (normalized, max 500 chars).
function sanitizePostUrl(raw: unknown): string | null {
  if (typeof raw !== "string") return null;
  const url = raw.trim();
  if (!url) return null;
  if (!/^https?:\/\//i.test(url)) return null;
  return url.slice(0, 500);
}

/// Post ends up in the home carousel only if the admin did not opt out.
function sanitizeInCarousel(raw: unknown, fallback = 1): number {
  if (raw === undefined || raw === null) return fallback;
  if (typeof raw === "boolean") return raw ? 1 : 0;
  const n = Number(raw);
  return Number.isFinite(n) ? (n ? 1 : 0) : fallback;
}

/// Delete R2 objects referenced by a post (only our own /media/* keys).
async function deletePostMedia(env: Env, mediaUrlsJson: string | null) {
  if (!mediaUrlsJson) return;
  try {
    const urls: unknown = JSON.parse(mediaUrlsJson);
    if (!Array.isArray(urls)) return;
    for (const u of urls) {
      if (typeof u !== 'string') continue;
      const idx = u.indexOf('/media/');
      if (idx === -1) continue; // external URL, not our storage
      const key = u.slice(idx + '/media/'.length).split('?')[0];
      if (key) {
        try {
          await env.MEDIA_BUCKET.delete(key);
        } catch {}
      }
    }
  } catch {}
}

/// Keep only the newest MAX_NEWS_POSTS rows (also frees their R2 images).
async function pruneOldNews(env: Env) {
  try {
    const { results } = await env.DB.prepare(
      'SELECT id, media_urls FROM facebook_news ORDER BY created_at DESC LIMIT -1 OFFSET ?'
    )
      .bind(MAX_NEWS_POSTS)
      .all<any>();
    for (const row of results) {
      await deletePostMedia(env, row.media_urls ?? null);
      await env.DB.prepare('DELETE FROM facebook_news WHERE id = ?')
        .bind(row.id)
        .run();
    }
  } catch {}
}

async function countNews(env: Env): Promise<number> {
  try {
    const row = await env.DB.prepare('SELECT COUNT(*) as n FROM facebook_news').first<any>();
    return Number(row?.n ?? 0);
  } catch {
    return 0;
  }
}

app.get("/api/news", async (c) => {
  try {
    const { results } = await c.env.DB.prepare(
      "SELECT id, title, text, type, media_urls, video_url, date, is_repost, original_page_name, post_url, in_carousel, created_at FROM facebook_news ORDER BY created_at DESC"
    ).all();

    const posts = results.map((row: any) => ({
      id: row.id,
      title: row.title,
      text: row.text,
      type: row.type,
      mediaUrls: row.media_urls ? JSON.parse(row.media_urls) : [],
      videoUrl: row.video_url,
      date: row.date,
      isRepost: row.is_repost === 1,
      originalPageName: row.original_page_name,
      postUrl: row.post_url,
      inCarousel: row.in_carousel === null || row.in_carousel === undefined ? true : row.in_carousel === 1,
      createdAt: row.created_at,
    }));

    return c.json({ success: true, posts });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

app.post("/api/news/batch", async (c) => {
  try {
    const posts = await c.req.json<any[]>();
    if (!Array.isArray(posts)) {
      return c.json({ success: false, message: "Expected array of posts" }, 400);
    }

    for (const post of posts) {
      const mediaJson = JSON.stringify(post.mediaUrls || []);
      await c.env.DB.prepare(
        `INSERT INTO facebook_news (id, title, text, type, media_urls, video_url, date, is_repost, original_page_name, post_url, in_carousel)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
         ON CONFLICT(id) DO UPDATE SET
           title = excluded.title,
           text = excluded.text,
           type = excluded.type,
           media_urls = excluded.media_urls,
           video_url = excluded.video_url,
           date = excluded.date,
           is_repost = excluded.is_repost,
           original_page_name = excluded.original_page_name,
           post_url = excluded.post_url,
           in_carousel = excluded.in_carousel`
      )
        .bind(
          post.id,
          post.title || "",
          post.text || "",
          post.type || "text",
          mediaJson,
          post.videoUrl || null,
          post.date || "",
          post.isRepost ? 1 : 0,
          post.originalPageName || null,
          sanitizePostUrl(post.postUrl),
          sanitizeInCarousel(post.inCarousel)
        )
        .run();
    }

    // Enforce storage cap: newest 100 posts only (frees R2 images of the rest)
    await pruneOldNews(c.env);

    return c.json({ success: true, count: posts.length });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

// Create ONE admin post (images only, max 100 posts)
app.post("/api/news", async (c) => {
  try {
    const post = await c.req.json<any>();
    if (!post || typeof post !== 'object') {
      return c.json({ success: false, message: "Invalid post body" }, 400);
    }

    const total = await countNews(c.env);
    if (total >= MAX_NEWS_POSTS) {
      return c.json(
        { success: false, code: "MAX_POSTS_REACHED", message: `Storage cap reached (${MAX_NEWS_POSTS} posts). Delete an old post first.` },
        409
      );
    }

    const title = (post.title || "").toString().slice(0, 200);
    const text = (post.text || "").toString().slice(0, 2000);
    if (!title && !text && !(post.mediaUrls?.length)) {
      return c.json({ success: false, message: "Empty post" }, 400);
    }

    const id = post.id || `n_${Date.now()}_${Math.random().toString(36).substr(2, 5)}`;
    const mediaJson = JSON.stringify(post.mediaUrls || []);
    const date = post.date || new Date().toISOString().slice(0, 16).replace("T", " ");

    await c.env.DB.prepare(
      `INSERT INTO facebook_news (id, title, text, type, media_urls, video_url, date, is_repost, original_page_name, post_url, in_carousel)
       VALUES (?, ?, ?, ?, ?, NULL, ?, 0, NULL, ?, ?)
       ON CONFLICT(id) DO UPDATE SET
         title = excluded.title,
         text = excluded.text,
         type = excluded.type,
         media_urls = excluded.media_urls,
         date = excluded.date,
         post_url = excluded.post_url,
         in_carousel = excluded.in_carousel`
    )
      .bind(id, title, text, post.type || "photo", mediaJson, date, sanitizePostUrl(post.postUrl), sanitizeInCarousel(post.inCarousel))
      .run();

    return c.json({ success: true, id });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

// Update ONE admin post (title / text / image)
app.put("/api/news/:id", async (c) => {
  const id = c.req.param("id");
  try {
    const post = await c.req.json<any>();
    if (!post || typeof post !== "object") {
      return c.json({ success: false, message: "Invalid post body" }, 400);
    }
    const row = await c.env.DB.prepare("SELECT id, media_urls, post_url, in_carousel FROM facebook_news WHERE id = ?")
      .bind(id)
      .first<any>();
    if (!row) {
      return c.json({ success: false, message: "Post not found" }, 404);
    }

    const title = (post.title ?? "").toString().slice(0, 200);
    const text = (post.text ?? "").toString().slice(0, 2000);
    const mediaUrls = Array.isArray(post.mediaUrls) ? post.mediaUrls : [];
    const mediaJson = JSON.stringify(mediaUrls);

    // Omitted fields keep their stored value (only an explicit ""/false clears).
    const postUrl =
      post.postUrl === undefined ? row.post_url ?? null : sanitizePostUrl(post.postUrl);
    const inCarousel =
      post.inCarousel === undefined
        ? sanitizeInCarousel(row.in_carousel)
        : sanitizeInCarousel(post.inCarousel);

    await c.env.DB.prepare(
      "UPDATE facebook_news SET title = ?, text = ?, type = ?, media_urls = ?, post_url = ?, in_carousel = ? WHERE id = ?"
    )
      .bind(title, text, mediaUrls.length ? "photo" : "text", mediaJson, postUrl, inCarousel, id)
      .run();

    // الصور القديمة اللي ما عادت مذكورة: نحذفها من R2 (ما نخلّيوش صور يتيمة)
    try {
      const oldUrls: unknown = row.media_urls ? JSON.parse(row.media_urls) : [];
      if (Array.isArray(oldUrls)) {
        for (const old of oldUrls) {
          if (typeof old !== "string") continue;
          if (mediaUrls.includes(old)) continue;
          await deletePostMedia(c.env, JSON.stringify([old]));
        }
      }
    } catch {}

    return c.json({ success: true, id });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

// Delete ONE post + its R2 images (frees storage space)
app.delete("/api/news/:id", async (c) => {
  const id = c.req.param("id");
  try {
    const row = await c.env.DB.prepare(
      "SELECT media_urls FROM facebook_news WHERE id = ?"
    )
      .bind(id)
      .first<any>();
    if (!row) {
      return c.json({ success: false, message: "Post not found" }, 404);
    }

    await deletePostMedia(c.env, row.media_urls ?? null);
    await c.env.DB.prepare("DELETE FROM facebook_news WHERE id = ?").bind(id).run();

    return c.json({ success: true });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

// ----------------------------------------------------
// ADMIN PUBS / ADVERTISEMENTS (programmed from admin panel)
// ----------------------------------------------------

app.get("/api/pubs", async (c) => {
  try {
    const { results } = await c.env.DB.prepare(
      "SELECT id, title, text, image_url as imageUrl, link, start_date as startDate, end_date as endDate, is_active as isActive, created_at as createdAt FROM pubs ORDER BY created_at DESC"
    ).all();
    const pubs = results.map((row: any) => ({
      ...row,
      isActive: row.isActive === 1 || row.isActive === true,
    }));
    return c.json({ success: true, pubs });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

app.post("/api/pubs", async (c) => {
  try {
    const p = await c.req.json<any>();
    const title = (p.title || "").toString().slice(0, 200);
    const text = (p.text || "").toString().slice(0, 2000);
    if (!title && !text && !p.imageUrl) {
      return c.json({ success: false, message: "Empty pub" }, 400);
    }
    const id = p.id || `pub_${Date.now()}_${Math.random().toString(36).substr(2, 5)}`;
    await c.env.DB.prepare(
      `INSERT INTO pubs (id, title, text, image_url, link, start_date, end_date, is_active)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)
       ON CONFLICT(id) DO UPDATE SET
         title = excluded.title,
         text = excluded.text,
         image_url = excluded.image_url,
         link = excluded.link,
         start_date = excluded.start_date,
         end_date = excluded.end_date,
         is_active = excluded.is_active`
    )
      .bind(
        id,
        title,
        text,
        p.imageUrl || null,
        p.link || null,
        p.startDate || null,
        p.endDate || null,
        p.isActive === false ? 0 : 1
      )
      .run();
    return c.json({ success: true, id });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

// Delete pub + its R2 image (frees storage space)
app.delete("/api/pubs/:id", async (c) => {
  const id = c.req.param("id");
  try {
    const row = await c.env.DB.prepare(
      "SELECT image_url FROM pubs WHERE id = ?"
    )
      .bind(id)
      .first<any>();
    if (!row) {
      return c.json({ success: false, message: "Pub not found" }, 404);
    }
    if (row.image_url) {
      await deletePostMedia(c.env, JSON.stringify([row.image_url]));
    }
    await c.env.DB.prepare("DELETE FROM pubs WHERE id = ?").bind(id).run();
    return c.json({ success: true });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

// ----------------------------------------------------
// GLOBAL APP CONFIG SYNC (admin programs once -> all devices)
// ----------------------------------------------------

app.get("/api/app-config", async (c) => {
  try {
    const row = await c.env.DB.prepare(
      "SELECT value FROM app_config WHERE key = 'global'"
    ).first<any>();
    if (!row?.value) return c.json({ success: true, config: null });
    return c.json({ success: true, config: JSON.parse(row.value) });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

app.post("/api/app-config", async (c) => {
  try {
    const body = await c.req.json<any>();
    if (!body?.config || typeof body.config !== "object") {
      return c.json({ success: false, message: "Invalid config" }, 400);
    }
    await c.env.DB.prepare(
      `INSERT INTO app_config (key, value) VALUES ('global', ?)
       ON CONFLICT(key) DO UPDATE SET value = excluded.value`
    )
      .bind(JSON.stringify(body.config))
      .run();
    return c.json({ success: true });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

// ----------------------------------------------------
// MEDICAL ORDERS (students book -> admin panel lists)
// ----------------------------------------------------

app.get("/api/medical-orders", async (c) => {
  try {
    const { results } = await c.env.DB.prepare(
      "SELECT id, matricule, name, specialty, date, notes, status, created_at as createdAt FROM medical_orders ORDER BY created_at DESC"
    ).all();
    return c.json({ success: true, orders: results });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

app.get("/api/medical-orders/by-matricule/:m", async (c) => {
  try {
    const { results } = await c.env.DB.prepare(
      "SELECT id, matricule, name, specialty, date, notes, status, created_at as createdAt FROM medical_orders WHERE matricule = ? ORDER BY created_at DESC"
    )
      .bind(c.req.param("m"))
      .all();
    return c.json({ success: true, orders: results });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

app.post("/api/medical-orders", async (c) => {
  try {
    const b = await c.req.json<any>();
    if (!b?.matricule || !b?.specialty || !b?.date) {
      return c.json({ success: false, message: "Missing fields" }, 400);
    }
    const id =
      b.id || `med_${Date.now()}_${Math.random().toString(36).substr(2, 5)}`;
    await c.env.DB.prepare(
      `INSERT INTO medical_orders (id, matricule, name, specialty, date, notes, status)
       VALUES (?, ?, ?, ?, ?, ?, 'pending')`
    )
      .bind(
        id,
        b.matricule,
        (b.name || "").toString().slice(0, 200),
        b.specialty.toString().slice(0, 100),
        b.date.toString().slice(0, 20),
        (b.notes || "").toString().slice(0, 1000)
      )
      .run();
    return c.json({ success: true, id });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

app.put("/api/medical-orders/:id", async (c) => {
  try {
    const b = await c.req.json<any>();
    const status = (b.status || "pending").toString();
    if (!["pending", "confirmed", "done", "cancelled"].includes(status)) {
      return c.json({ success: false, message: "Invalid status" }, 400);
    }
    await c.env.DB.prepare("UPDATE medical_orders SET status = ? WHERE id = ?")
      .bind(status, c.req.param("id"))
      .run();
    return c.json({ success: true });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

// ----------------------------------------------------
// CATERING RESERVATIONS SYNC (students reserve -> admin panel lists)
// ----------------------------------------------------

app.get("/api/catering-reservations", async (c) => {
  try {
    const { results } = await c.env.DB.prepare(
      "SELECT matricule, name, reserved_at as reservedAt, expires_at as expiresAt FROM catering_reservations ORDER BY expires_at DESC"
    ).all();
    return c.json({ success: true, reservations: results });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

app.post("/api/catering-reservations", async (c) => {
  try {
    const b = await c.req.json<any>();
    if (!b?.matricule || !b?.expiresAt) {
      return c.json({ success: false, message: "Missing fields" }, 400);
    }
    await c.env.DB.prepare(
      `INSERT INTO catering_reservations (matricule, name, reserved_at, expires_at, updated_at)
       VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
       ON CONFLICT(matricule) DO UPDATE SET
         name = excluded.name,
         reserved_at = excluded.reserved_at,
         expires_at = excluded.expires_at,
         updated_at = CURRENT_TIMESTAMP`
    )
      .bind(
        b.matricule,
        (b.name || "").toString().slice(0, 200),
        (b.reservedAt || "").toString().slice(0, 40),
        b.expiresAt.toString().slice(0, 40)
      )
      .run();
    return c.json({ success: true });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

// ----------------------------------------------------
// D1: STUDENT MARKETPLACE (Troc & Vente - Max 3 items/student)
// ----------------------------------------------------

async function ensureMarketplaceTable(db: D1Database) {
  await db.prepare(`
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
        category TEXT DEFAULT 'books',
        images TEXT,
        status TEXT DEFAULT 'available',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
  `).run();
}

app.get("/api/marketplace", async (c) => {
  try {
    await ensureMarketplaceTable(c.env.DB);
    const category = c.req.query("category");
    const matricule = c.req.query("matricule");
    const status = c.req.query("status");

    let query = "SELECT * FROM marketplace_items WHERE 1=1";
    const bindings: any[] = [];

    if (category && category !== "all") {
      query += " AND category = ?";
      bindings.push(category);
    }
    if (matricule) {
      query += " AND matricule = ?";
      bindings.push(matricule);
    }
    if (status) {
      query += " AND status = ?";
      bindings.push(status);
    }

    query += " ORDER BY created_at DESC LIMIT 100";

    const stmt = c.env.DB.prepare(query);
    const { results } = await (bindings.length ? stmt.bind(...bindings) : stmt).all();

    const formatted = results.map((item: any) => {
      let imagesList: string[] = [];
      try {
        if (item.images) {
          imagesList = typeof item.images === "string" ? JSON.parse(item.images) : item.images;
        }
      } catch {}
      return {
        id: item.id,
        matricule: item.matricule,
        sellerName: item.seller_name,
        sellerPhone: item.seller_phone,
        pavilion: item.pavilion || "",
        roomNumber: item.room_number || "",
        title: item.title,
        description: item.description || "",
        price: Number(item.price || 0),
        isFree: item.is_free === 1 || item.is_free === true,
        category: item.category || "books",
        images: Array.isArray(imagesList) ? imagesList : [],
        status: item.status || "available",
        createdAt: item.created_at,
      };
    });

    return c.json({ success: true, items: formatted });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

// جلب غرض واحد حسب المعرّف (تُستعمله صفحة المشاركة المستقلة /p/<id>)
app.get("/api/marketplace/:id", async (c) => {
  const id = c.req.param("id");
  try {
    await ensureMarketplaceTable(c.env.DB);
    const item = await c.env.DB.prepare("SELECT * FROM marketplace_items WHERE id = ?")
      .bind(id)
      .first<any>();
    if (!item) {
      return c.json({ success: false, message: "الغرض غير موجود" }, 404);
    }
    let imagesList: string[] = [];
    try {
      if (item.images) {
        imagesList = typeof item.images === "string" ? JSON.parse(item.images) : item.images;
      }
    } catch {}
    return c.json({
      success: true,
      item: {
        id: item.id,
        matricule: item.matricule,
        sellerName: item.seller_name,
        sellerPhone: item.seller_phone,
        pavilion: item.pavilion || "",
        roomNumber: item.room_number || "",
        title: item.title,
        description: item.description || "",
        price: Number(item.price || 0),
        isFree: item.is_free === 1 || item.is_free === true,
        category: item.category || "books",
        images: Array.isArray(imagesList) ? imagesList : [],
        status: item.status || "available",
        createdAt: item.created_at,
      },
    });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

app.post("/api/marketplace", async (c) => {
  try {
    await ensureMarketplaceTable(c.env.DB);
    const body = await c.req.json<any>();

    const matricule = (body.matricule || "").toString().trim();
    const title = (body.title || "").toString().trim();
    const sellerPhone = (body.sellerPhone || "").toString().trim();
    const sellerName = (body.sellerName || "طالب").toString().trim();

    if (!matricule || !title || !sellerPhone) {
      return c.json({ success: false, message: "بيانات الإعلان غير مكتملة" }, 400);
    }

    // شرط 3 أشياء كحد أقصى لكل طالب:
    const activeRow = await c.env.DB.prepare(
      "SELECT COUNT(*) as count FROM marketplace_items WHERE matricule = ? AND status = 'available'"
    ).bind(matricule).first<any>();

    if (activeRow && Number(activeRow.count) >= 3) {
      return c.json({
        success: false,
        code: "LIMIT_REACHED",
        message: "عذراً! الحد الأقصى هو 3 أغراض معروضة لكل طالب. قم بحذف أو وسم غرض سابق كـ 'مباع'.",
      }, 400);
    }

    const id = body.id || `item_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const price = Number(body.price || 0);
    const isFree = body.isFree ? 1 : (price === 0 ? 1 : 0);
    const category = (body.category || "books").toString();
    const pavilion = (body.pavilion || "").toString();
    const roomNumber = (body.roomNumber || "").toString();
    const description = (body.description || "").toString();

    let imagesList: string[] = [];
    if (Array.isArray(body.images)) {
      imagesList = body.images.slice(0, 3);
    }

    await c.env.DB.prepare(
      `INSERT INTO marketplace_items 
       (id, matricule, seller_name, seller_phone, pavilion, room_number, title, description, price, is_free, category, images, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'available')`
    ).bind(
      id,
      matricule,
      sellerName,
      sellerPhone,
      pavilion,
      roomNumber,
      title,
      description,
      price,
      isFree,
      category,
      JSON.stringify(imagesList)
    ).run();

    return c.json({ success: true, id });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

app.put("/api/marketplace/:id/status", async (c) => {
  const id = c.req.param("id");
  try {
    await ensureMarketplaceTable(c.env.DB);
    const body = await c.req.json<any>();
    const status = body.status === "sold" ? "sold" : "available";
    await c.env.DB.prepare("UPDATE marketplace_items SET status = ? WHERE id = ?").bind(status, id).run();
    return c.json({ success: true, status });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

app.put("/api/marketplace/:id", async (c) => {
  const id = c.req.param("id");
  try {
    await ensureMarketplaceTable(c.env.DB);
    const existing = await c.env.DB.prepare("SELECT id, images FROM marketplace_items WHERE id = ?").bind(id).first<any>();
    if (!existing) {
      return c.json({ success: false, message: "الغرض غير موجود" }, 404);
    }
    const body = await c.req.json<any>();

    const title = (body.title || "").toString().trim();
    const sellerPhone = (body.sellerPhone || "").toString().trim();
    const sellerName = (body.sellerName || "طالب").toString().trim();
    if (!title || !sellerPhone) {
      return c.json({ success: false, message: "بيانات الإعلان غير مكتملة" }, 400);
    }

    const price = Number(body.price ?? 0);
    const isFree = body.isFree ? 1 : (price === 0 ? 1 : 0);
    const category = (body.category || "books").toString();
    const pavilion = (body.pavilion || "").toString();
    const roomNumber = (body.roomNumber || "").toString();
    const description = (body.description || "").toString();
    const status = (body.status === "sold" ? "sold" : "available").toString();

    let imagesList: string[] = [];
    if (Array.isArray(body.images)) {
      imagesList = body.images.slice(0, 3);
    }

    await c.env.DB.prepare(
      `UPDATE marketplace_items SET
         seller_name = ?,
         seller_phone = ?,
         pavilion = ?,
         room_number = ?,
         title = ?,
         description = ?,
         price = ?,
         is_free = ?,
         category = ?,
         images = ?,
         status = ?
       WHERE id = ?`
    ).bind(
      sellerName,
      sellerPhone,
      pavilion,
      roomNumber,
      title,
      description,
      price,
      isFree,
      category,
      JSON.stringify(imagesList),
      status,
      id
    ).run();

    // الصور المحذوفة من الإعلان: نحذفها من R2 حتى لا تبقى يتيمة
    try {
      const oldImages: unknown = existing.images ? JSON.parse(existing.images) : [];
      if (Array.isArray(oldImages)) {
        for (const old of oldImages) {
          if (typeof old !== "string") continue;
          if (imagesList.includes(old)) continue;
          await deletePostMedia(c.env, JSON.stringify([old]));
        }
      }
    } catch {}

    return c.json({ success: true, id });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

app.delete("/api/marketplace/:id", async (c) => {
  const id = c.req.param("id");
  try {
    await ensureMarketplaceTable(c.env.DB);
    const item = await c.env.DB.prepare("SELECT images FROM marketplace_items WHERE id = ?").bind(id).first<any>();
    if (item?.images) {
      try {
        const urls = JSON.parse(item.images);
        if (Array.isArray(urls)) {
          for (const u of urls) {
            const idx = u.indexOf("/media/");
            if (idx !== -1) {
              const key = u.slice(idx + "/media/".length).split("?")[0];
              if (key) {
                try { await c.env.MEDIA_BUCKET.delete(key); } catch {}
              }
            }
          }
        }
      } catch {}
    }
    await c.env.DB.prepare("DELETE FROM marketplace_items WHERE id = ?").bind(id).run();
    return c.json({ success: true });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

// ----------------------------------------------------
// R2: MEDIA STORAGE (Images, Videos, Avatars)
// ----------------------------------------------------


app.post("/api/media/upload", async (c) => {
  try {
    const contentType = c.req.header("content-type") || "";
    const MAX_IMAGE_BYTES = 5 * 1024 * 1024; // 5 MB cap per image

    // Multipart Form Upload (images only)
    if (contentType.includes("multipart/form-data")) {
      const formData = await c.req.formData();
      const file = formData.get("file") as unknown as File;
      if (!file) {
        return c.json({ success: false, message: "No file provided" }, 400);
      }
      if (!file.type.startsWith("image/")) {
        return c.json({ success: false, code: "IMAGES_ONLY", message: "Only images are allowed" }, 400);
      }
      if (file.size > MAX_IMAGE_BYTES) {
        return c.json({ success: false, code: "FILE_TOO_LARGE", message: "Image must be under 5 MB" }, 413);
      }

      const extension = file.name.split(".").pop() || "bin";
      const key = `uploads/${Date.now()}_${Math.random().toString(36).substr(2, 6)}.${extension}`;

      await c.env.MEDIA_BUCKET.put(key, await file.arrayBuffer(), {
        httpMetadata: { contentType: file.type || "application/octet-stream" },
      });

      const origin = new URL(c.req.url).origin;
      return c.json({
        success: true,
        key,
        url: `${origin}/media/${key}`,
      });
    }

    // Direct JSON / Base64 upload (images only)
    const body = await c.req.json<any>();
    if (body.base64) {
      const mime: string = body.mime || "image/jpeg";
      if (!mime.startsWith("image/")) {
        return c.json({ success: false, code: "IMAGES_ONLY", message: "Only images are allowed" }, 400);
      }
      const base64Data = body.base64.replace(/^data:image\/\w+;base64,/, "");
      const buffer = Uint8Array.from(atob(base64Data), (c) => c.charCodeAt(0));
      if (buffer.length > MAX_IMAGE_BYTES) {
        return c.json({ success: false, code: "FILE_TOO_LARGE", message: "Image must be under 5 MB" }, 413);
      }
      const ext = mime.includes("png") ? "png" : mime.includes("webp") ? "webp" : "jpg";
      const key = `avatars/${Date.now()}_${Math.random().toString(36).substr(2, 6)}.${ext}`;

      await c.env.MEDIA_BUCKET.put(key, buffer, {
        httpMetadata: { contentType: mime },
      });

      const origin = new URL(c.req.url).origin;
      return c.json({
        success: true,
        key,
        url: `${origin}/media/${key}`,
      });
    }

    return c.json({ success: false, message: "Unsupported upload format" }, 400);
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

app.get("/media/*", async (c) => {
  const key = c.req.path.replace("/media/", "");
  if (!key) return c.text("Key missing", 400);

  const object = await c.env.MEDIA_BUCKET.get(key);
  if (!object) return c.text("File Not Found", 404);

  const headers = new Headers();
  object.writeHttpMetadata(headers);
  headers.set("etag", object.httpEtag);
  headers.set("Cache-Control", "public, max-age=31536000, immutable");

  return new Response(object.body, { headers });
});

app.delete("/api/media/*", async (c) => {
  try {
    const key = c.req.path.replace("/api/media/", "");
    if (!key) return c.json({ success: false, message: "Key missing" }, 400);
    await c.env.MEDIA_BUCKET.delete(key);
    return c.json({ success: true, deletedKey: key });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

app.post("/api/media/delete", async (c) => {
  try {
    const body = await c.req.json<{ url?: string; key?: string }>();
    let key = body?.key;
    if (!key && body?.url) {
      const idx = body.url.indexOf("/media/");
      if (idx !== -1) {
        key = body.url.slice(idx + "/media/".length).split("?")[0];
      }
    }
    if (key) {
      await c.env.MEDIA_BUCKET.delete(key);
      return c.json({ success: true, deletedKey: key });
    }
    return c.json({ success: false, message: "No key or url provided" }, 400);
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});


// ----------------------------------------------------
// PROGRES proxy (server-side: avoids browser CORS).
// Verifies REAL student credentials against progres.mesrs.dz.
// The Worker never stores credentials — it only forwards.
// Fixed paths only (no open proxy).
// ----------------------------------------------------

const PROGRES_BASE = "https://progres.mesrs.dz/api";
const WEBETU_LOGIN_URL = `${"https://progres.mesrs.dz"}/webetu/login.xhtml`;

const BROWSER_HEADERS: Record<string, string> = {
  Accept: "application/json, text/plain, */*",
  "Accept-Language": "fr-FR,fr;q=0.9,ar-DZ;q=0.8,en;q=0.7",
  "User-Agent":
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36",
  Origin: "https://progres.mesrs.dz",
  Referer: "https://progres.mesrs.dz/webetu/",
};

/// Statuses that mean "misrouted/blocked egress" (NOT a real answer):
/// the same paths provably exist (401 from Algeria), so 403/404/52x
/// from worker egress must trigger the tunnel fallback, never surface.
const FALLBACK_STATUSES = [403, 404, 502, 520, 521, 522, 523, 524, 530];

function tunnelBase(env: Env): string | null {
  const u = (env as any).PROGRES_TUNNEL as string | undefined;
  return u && u.startsWith("http") ? u.replace(/\/$/, "") : null;
}

/// Smart fetch: direct first, tunnel (Algerian egress) fallback on block.
/// Used by ALL PROGRES routes so web + mobile share the same verification.
async function smartFetch(
  env: Env,
  url: string,
  init?: RequestInit,
  timeoutMs = 25000
): Promise<Response> {
  const run = (u: string): Promise<Response> => {
    const ctrl = new AbortController();
    const t = setTimeout(() => ctrl.abort(), timeoutMs);
    return fetch(u, {
      ...init,
      headers: { ...BROWSER_HEADERS, ...((init?.headers as any) || {}) },
      signal: ctrl.signal,
    }).finally(() => clearTimeout(t));
  };

  try {
    const res = await run(url);
    if (!FALLBACK_STATUSES.includes(res.status)) return res;
    await res.arrayBuffer().catch(() => {});
  } catch (_) {
    // network error -> try tunnel
  }

  // Tunnel fallback: same FULL path (host swapped, path preserved 1:1).
  // NOTE: keep the /api prefix — the tunnel mirrors the origin paths exactly.
  const PROGRES_HOST = "https://progres.mesrs.dz";
  let turl: string | null = null;
  if (url.startsWith(PROGRES_HOST)) {
    const base = tunnelBase(env);
    if (base) turl = base + url.slice(PROGRES_HOST.length);
  }
  if (!turl) throw new Error("PROGRES_UNREACHABLE");
  return run(turl);
}

async function progresFetch(
  env: Env,
  path: string,
  init?: RequestInit,
  timeoutMs = 25000
) {
  return smartFetch(env, `${PROGRES_BASE}${path}`, init, timeoutMs);
}

function progresAuth(c: any): string | null {
  const h = c.req.header("authorization");
  return h && h.length > 0 ? h : null;
}

// POST {username, password} -> {success, token, uuid, userName} or 401
app.post("/api/progres/login", async (c) => {
  try {
    const body = await c.req.json<any>();
    const username = (body?.username ?? "").toString().trim();
    const password = (body?.password ?? "").toString();
    if (!username || !password) {
      return c.json({ success: false, message: "Missing credentials" }, 400);
    }
    let res: Response;
    try {
      res = await progresFetch(c.env, "/authentication/v1/", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username, password }),
      });
    } catch {
      return c.json({ success: false, message: "تعذر الاتصال بسيرفر PROGRES" }, 502);
    }
    if (res.status === 401) {
      return c.json({ success: false, message: "اسم المستخدم أو كلمة المرور غير صحيحة" }, 401);
    }
    if (!res.ok) {
      return c.json({ success: false, message: `خطأ في سيرفر PROGRES: ${res.status}` }, 502);
    }
    const data = await res.json<any>();
    if (!data?.token || !data?.uuid) {
      return c.json({ success: false, message: "رد غير صالح من PROGRES" }, 502);
    }
    return c.json({ success: true, token: data.token, uuid: data.uuid, userName: data.userName });
  } catch (e: any) {
    return c.json({ success: false, error: e.message }, 500);
  }
});

// POST {username, password} -> {success, valid} — verifies the account on the
// OFFICIAL WebEtu page (login.xhtml): full JSF form + session cookies.
// valid=true ONLY with real proof. Fail-closed otherwise.
app.post("/api/progres/verify-page", async (c) => {
  const LOGIN_URL = WEBETU_LOGIN_URL;

  const isRedirect = (s: number) =>
    s === 301 || s === 302 || s === 303 || s === 307 || s === 308;

  const isSuccessBody = (html: string): boolean => {
    const lower = html.toLowerCase();
    if (
      lower.includes("nom d'utilisateur invalide") ||
      lower.includes("mot de passe ou nom") ||
      lower.includes("incorrect") ||
      lower.includes("inexistant")
    ) {
      return false;
    }
    if (html.includes("loginFrm:j_username")) return false;
    if (
      lower.includes("éconnexion") ||
      lower.includes("deconnexion") ||
      lower.includes("logout") ||
      lower.includes("j_spring_security_logout")
    ) {
      return true;
    }
    return false;
  };

  try {
    const body = await c.req.json<any>();
    const username = (body?.username ?? "").toString().trim();
    const password = (body?.password ?? "").toString();
    if (!username || !password) {
      return c.json({ success: false, valid: false, message: "Missing credentials" }, 400);
    }

    // 1) GET page: walk redirects manually, keep session cookies
    // (without JSESSIONID the server answers 500 ViewExpired).
    let uri = LOGIN_URL;
    const jar = new Map<string, string>();
    let viewState: string | null = null;
    for (let i = 0; i < 5; i++) {
      // smartFetch: direct, tunnel fallback on block (Algerian egress).
      const res = await smartFetch( c.env,
        uri,
        {
          headers: {
            Accept: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            Referer: LOGIN_URL,
            ...(jar.size
              ? {
                  Cookie: [...jar.entries()]
                    .map(([k, v]) => `${k}=${v}`)
                    .join("; "),
                }
              : {}),
          },
          redirect: "manual",
        },
        20000
      );
      const getSet: string[] =
        (res.headers as any).getSetCookie?.() ??
        (res.headers.get("set-cookie") ? [res.headers.get("set-cookie") as string] : []);
      for (const s of getSet) {
        for (const name of ["JSESSIONID", "SRV"]) {
          const m = s.match(new RegExp(`${name}=[^;,]+`));
          if (m && !jar.has(name)) jar.set(name, m[0].slice(name.length + 1));
        }
      }
      if (isRedirect(res.status)) {
        await res.arrayBuffer().catch(() => {});
        const loc = res.headers.get("location");
        if (!loc) break;
        uri = new URL(loc, uri).toString();
        continue;
      }
      const html = await res.text();
      const m = html.match(/name="javax\.faces\.ViewState"[^>]*value="([^"]+)"/);
      viewState = m?.[1] ?? null;
      break;
    }
    if (!viewState) {
      return c.json({ success: false, valid: false, message: "تعذر تحميل صفحة PROGRES" }, 502);
    }

    // 2) POST the full JSF form (same fields as the real page).
    const params = new URLSearchParams({
      loginFrm: "loginFrm",
      "loginFrm:j_username": username,
      "loginFrm:j_password": password,
      "loginFrm:loginBtn": "Se connecter",
      "javax.faces.ViewState": viewState,
    });
    const post = await smartFetch( c.env,
      LOGIN_URL,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          Referer: LOGIN_URL,
          ...(jar.size
            ? {
                Cookie: [...jar.entries()]
                  .map(([k, v]) => `${k}=${v}`)
                  .join("; "),
              }
            : {}),
        },
        body: params.toString(),
        redirect: "manual",
      },
      25000
    );

    if (isRedirect(post.status)) {
      const loc = post.headers.get("location") ?? "";
      await post.arrayBuffer().catch(() => {});
      return c.json({ success: true, valid: !loc.includes("login"), method: "webetu-page" });
    }
    if (post.status !== 200) {
      return c.json({ success: true, valid: false, method: "webetu-page" });
    }
    const text = await post.text();
    return c.json({ success: true, valid: isSuccessBody(text), method: "webetu-page" });
  } catch {
    return c.json({ success: false, valid: false, message: "تعذر الاتصال بسيرفر PROGRES" }, 502);
  }
});

// GET diagnostics: which PROGRES path works from the Worker (no credentials needed).
app.get("/api/progres/diag", async (c) => {
  const tryPost = async (base: string) => {
    try {
      const ctrl = new AbortController();
      const t = setTimeout(() => ctrl.abort(), 20000);
      try {
        const r = await fetch(`${base}/api/authentication/v1/`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "User-Agent": "Mozilla/5.0",
          },
          body: JSON.stringify({ username: "0000000000", password: "wrongpass123" }),
          signal: ctrl.signal,
        });
        const txt = await r.text().catch(() => "");
        return { status: r.status, sample: txt.slice(0, 100) };
      } finally {
        clearTimeout(t);
      }
    } catch (e: any) {
      return { status: -1, sample: `ERR:${e?.message ?? e}` };
    }
  };
  const tunnel = tunnelBase(c.env);
  return c.json({
    direct: await tryPost(PROGRES_BASE),
    tunnel: tunnel ? await tryPost(tunnel) : "NO_TUNNEL_VAR",
    tunnelVarSet: !!tunnel,
  });
});

// GET basic student info (name, DOB...) — needs Authorization header
app.get("/api/progres/individu/:uuid", async (c) => {
  const token = progresAuth(c);
  if (!token) return c.json({ success: false, message: "Unauthorized" }, 401);
  try {
    const res = await progresFetch(c.env, `/infos/bac/${c.req.param("uuid")}/individu`, {
      headers: { authorization: token },
    });
    if (!res.ok) return c.json({ success: false, message: `PROGRES error: ${res.status}` }, 502);
    return c.json({ success: true, data: await res.json() });
  } catch {
    return c.json({ success: false, message: "تعذر الاتصال بسيرفر PROGRES" }, 502);
  }
});

// GET enrollments (find current academic year)
app.get("/api/progres/dias/:uuid", async (c) => {
  const token = progresAuth(c);
  if (!token) return c.json({ success: false, message: "Unauthorized" }, 401);
  try {
    const res = await progresFetch(c.env, `/infos/bac/${c.req.param("uuid")}/dias`, {
      headers: { authorization: token },
    });
    if (!res.ok) return c.json({ success: false, message: `PROGRES error: ${res.status}` }, 502);
    return c.json({ success: true, data: await res.json() });
  } catch {
    return c.json({ success: false, message: "تعذر الاتصال بسيرفر PROGRES" }, 502);
  }
});

// GET detailed info for an academic year (level, cycle, specialty...)
app.get("/api/progres/dia/:uuid/:year", async (c) => {
  const token = progresAuth(c);
  if (!token) return c.json({ success: false, message: "Unauthorized" }, 401);
  try {
    const res = await progresFetch(
      c.env,
      `/infos/bac/${c.req.param("uuid")}/anneeAcademique/${c.req.param("year")}/dia`,
      { headers: { authorization: token } }
    );
    if (!res.ok) return c.json({ success: false, message: `PROGRES error: ${res.status}` }, 502);
    return c.json({ success: true, data: await res.json() });
  } catch {
    return c.json({ success: false, message: "تعذر الاتصال بسيرفر PROGRES" }, 502);
  }
});

// GET student photo as base64
app.get("/api/progres/image/:uuid", async (c) => {
  const token = progresAuth(c);
  if (!token) return c.json({ success: false, message: "Unauthorized" }, 401);
  try {
    const res = await progresFetch(c.env, `/infos/image/${c.req.param("uuid")}`, {
      headers: { authorization: token },
    });
    if (!res.ok) return c.json({ success: false, message: `PROGRES error: ${res.status}` }, 502);
    const text = (await res.text()).replaceAll('"', '').trim();
    return c.json({ success: true, base64: text });
  } catch {
    return c.json({ success: false, message: "تعذر الاتصال بسيرفر PROGRES" }, 502);
  }
});

// ----------------------------------------------------
// PROGRES proxy — extra endpoints (full student data).
// Paths are built server-side only (no open proxy).
// ----------------------------------------------------

async function progresProxyGet(c: any, path: string) {
  const token = progresAuth(c);
  if (!token) return c.json({ success: false, message: "Unauthorized" }, 401);
  try {
    const res = await progresFetch(c.env, path, { headers: { authorization: token } }, 30000);
    if (!res.ok) {
      return c.json({ success: false, message: `PROGRES error: ${res.status}` }, 502);
    }
    return c.json({ success: true, data: await res.json() });
  } catch {
    return c.json({ success: false, message: "تعذر الاتصال بسيرفر PROGRES" }, 502);
  }
}

// Complete baccalaureate record (identity, bac info, assignment, photos)
app.get("/api/progres/bac/:uuid", (c) =>
  progresProxyGet(c, `/infos/bac/${c.req.param("uuid")}/`)
);

// Baccalaureate grades
app.get("/api/progres/bac-notes/:uuid", (c) =>
  progresProxyGet(c, `/infos/bac/${c.req.param("uuid")}/notes`)
);

// Pedagogical groups (section + group) of an administrative registration
app.get("/api/progres/groups/:idDia", (c) =>
  progresProxyGet(c, `/infos/dia/${c.req.param("idDia")}/groups`)
);

// Academic reports / cursus (all years) of an administrative registration
app.get("/api/progres/bilans/:uuid/:idDia", (c) =>
  progresProxyGet(
    c,
    `/infos/bac/${c.req.param("uuid")}/dias/${c.req.param("idDia")}/periode/bilans`
  )
);

// Semester report (single period)
app.get("/api/progres/bilan/:uuid/:idDia/:idPeriode", (c) =>
  progresProxyGet(
    c,
    `/infos/bac/${c.req.param("uuid")}/dia/${c.req.param("idDia")}/periode/${c.req.param("idPeriode")}/bilan`
  )
);

// Continuous assessment grades (TD/TP/CC)
app.get("/api/progres/notes-cc/:idDia", (c) =>
  progresProxyGet(c, `/infos/controleContinue/dia/${c.req.param("idDia")}/notesCC`)
);

// Exam grades
app.get("/api/progres/notes-exam/:idDia", (c) =>
  progresProxyGet(c, `/infos/planningSession/dia/${c.req.param("idDia")}/noteExamens`)
);

// Module coefficients (used to detect TP/CC modules)
app.get("/api/progres/coefficients/:offerId/:levelId", (c) =>
  progresProxyGet(
    c,
    `/infos/offreFormation/${c.req.param("offerId")}/niveau/${c.req.param("levelId")}/Coefficients`
  )
);

// Academic leave (congé académique) for one academic year
app.get("/api/progres/conge/:uuid/:year", (c) =>
  progresProxyGet(
    c,
    `/infos/bac/${c.req.param("uuid")}/anneeAcademique/${c.req.param("year")}/congeacademique`
  )
);

// Root & Health check
app.get("/", (c) => {
  return c.json({
    status: "online",
    name: "Cube III Backend",
    version: "1.0.0",
    services: {
      database: "Cloudflare D1 (cube_iii)",
      realtime: "Cloudflare Durable Objects (GameRoomDO)",
      storage: "Cloudflare R2 (cube-iii-media)",
    },
  });
});

export default app;
