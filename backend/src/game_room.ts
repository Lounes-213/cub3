import { DurableObject } from "cloudflare:workers";
import { Env, GameState, TeamSlot, Trap } from "./types";

export class GameRoomDO extends DurableObject<Env> {
  private state: GameState;
  private sessions: Set<WebSocket> = new Set();

  constructor(ctx: DurableObjectState, env: Env) {
    super(ctx, env);
    this.state = this.getInitialState();

    // Restore state from durable storage if available
    this.ctx.blockConcurrencyWhile(async () => {
      const stored = await this.ctx.storage.get<GameState>("state");
      if (stored) {
        this.state = stored;
      }
    });
  }

  private getInitialState(): GameState {
    return {
      status: "idle",
      title: "مسابقة باب الزوار 3",
      date: new Date().toISOString().split("T")[0],
      team_size: 3,
      num_teams: 6,
      current_screen: "onboarding",
      current_stage_index: 0,
      current_question_index: 0,
      question_step: 0,
      show_results: false,
      reveal_winner: false,
      is_game_over: false,
      hide_votes: false,
      chrono: {
        status: "stopped",
        remaining: 25,
        duration: 25,
        last_updated: Date.now(),
      },
      teams: {},
      realtime_choices: {},
      active_traps: [],
      trap_usage: {},
      scored_questions: {},
      question_history: {},
      answers: {},
    };
  }

  private async persist() {
    await this.ctx.storage.put("state", this.state);
  }

  // يعيد بناء خريطة الفرق بعد تغيير عدد الفرق:
  // يحافظ على الفرق المسجّلة الموجودة، يضيف الخانات الفارغة،
  // ويميّز الخانات الزائدة عن العدد الجديد.
  private resyncTeamSlots() {
    const current = this.state.teams || {};
    const next: Record<string, TeamSlot> = {};
    for (let i = 1; i <= this.state.num_teams; i++) {
      const id = `team_${i}`;
      if (current[id]) {
        next[id] = { ...current[id], id, slot_index: i };
      } else {
        next[id] = {
          id,
          slot_index: i,
          is_registered: false,
          score: 0,
          qr_code: `musabaqat://join?gameId=USTHB_CUBE3&teamSlot=${i}`,
        };
      }
    }
    this.state.teams = next;
  }

  private broadcast(message: any) {
    const payload = typeof message === "string" ? message : JSON.stringify(message);
    for (const ws of this.sessions) {
      try {
        ws.send(payload);
      } catch {
        this.sessions.delete(ws);
      }
    }
  }

  private broadcastState() {
    this.broadcast({
      type: "state_update",
      state: this.state,
    });
  }

  private async ensureHistoryTable() {
    await this.env.DB.prepare(
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
    ).run();
  }

  // يحفظ نتائج المسابقة في سجل دائم (D1) حتى يقدر الأدمين يشوفها ويحذفها بعد
  private async archiveCompetition(status: string) {
    try {
      const registered = Object.values(this.state.teams || {})
        .filter((t) => t.is_registered && (t.name || "").trim().length > 0)
        .map((t) => ({
          slot: t.slot_index,
          name: t.name || "",
          members: t.members || [],
          score: Number(t.score || 0),
          color: (t as any).color || t.team_color || "",
        }))
        .sort((a, b) => b.score - a.score || a.slot - b.slot);
      if (registered.length === 0) return;

      const uid =
        this.state.competition_uid || `comp_${Date.now()}`;
      const questionHistory = this.state.question_history || {};
      const questionCount = Object.keys(questionHistory).length;

      await this.ensureHistoryTable();
      await this.env.DB.prepare(
        `INSERT INTO competition_history
           (id, title, date, status, finished_at, num_teams, team_size,
            winner_name, question_count, ranking_json, question_history_json, stages_json)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
         ON CONFLICT(id) DO UPDATE SET
           status = excluded.status,
           finished_at = excluded.finished_at,
           winner_name = excluded.winner_name,
           question_count = excluded.question_count,
           ranking_json = excluded.ranking_json,
           question_history_json = excluded.question_history_json,
           stages_json = excluded.stages_json`
      )
        .bind(
          uid,
          this.state.title || "مسابقة",
          this.state.date || "",
          status,
          new Date().toISOString(),
          this.state.num_teams,
          this.state.team_size,
          registered[0].name,
          questionCount,
          JSON.stringify(registered),
          JSON.stringify(questionHistory),
          JSON.stringify(this.state.stages || [])
        )
        .run();
    } catch (e) {
      console.error("archiveCompetition failed:", e);
    }
  }

  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);

    // WebSocket Upgrade
    if (request.headers.get("Upgrade") === "websocket") {
      const pair = new WebSocketPair();
      const [client, server] = Object.values(pair);

      server.accept();
      this.sessions.add(server);

      // Send initial state immediately
      server.send(
        JSON.stringify({
          type: "init",
          state: this.state,
        })
      );

      server.addEventListener("message", async (event) => {
        try {
          const raw = typeof event.data === "string" ? event.data : new TextDecoder().decode(event.data as ArrayBuffer);
          const data = JSON.parse(raw);
          await this.handleAction(data);
        } catch (err: any) {
          server.send(JSON.stringify({ type: "error", message: err.message }));
        }
      });

      server.addEventListener("close", () => {
        this.sessions.delete(server);
      });

      server.addEventListener("error", () => {
        this.sessions.delete(server);
      });

      return new Response(null, { status: 101, webSocket: client });
    }

    // HTTP Endpoints
    if (url.pathname.endsWith("/state")) {
      return Response.json({ success: true, state: this.state });
    }

    if (url.pathname.endsWith("/action") && request.method === "POST") {
      const data = await request.json();
      const result = await this.handleAction(data);
      return Response.json({ success: true, result, state: this.state });
    }

    return new Response("Not Found", { status: 404 });
  }

  async handleAction(data: any): Promise<any> {
    const action = data.action;

    // Admin-only actions authorization check:
    // If competition is owned by an admin, another admin cannot control it
    const adminActions = new Set([
      "start_game", "finish_game", "close_competition", "delete_active_competition",
      "go_to_next_question", "go_to_next_stage", "set_question_step", "set_show_results",
      "update_chrono", "pause_chrono", "resume_chrono", "update_game_settings",
      "update_team_score", "remove_team"
    ]);
    if (adminActions.has(action) && this.state.creator_id && data.admin_id && data.admin_id !== this.state.creator_id) {
      throw new Error(`Unauthorized: This competition is managed by ${this.state.creator_name || this.state.creator_id}`);
    }

    switch (action) {
      case "ping":
        return { pong: Date.now() };

      case "get_state":
        return this.state;

      case "update_game_state": {
        const { status, teamSize, numTeams, title, date, stages, creator_id, creator_name, admin_id, admin_name } = data;
        this.state.status = status || "idle";
        // كل مسابقة جديدة تأخذ معرف خاص بيها (يدخل به في سجل النتائج)
        this.state.competition_uid = crypto.randomUUID();
        this.state.creator_id = creator_id || admin_id || this.state.creator_id;
        this.state.creator_name = creator_name || admin_name || this.state.creator_name;
        this.state.team_size = teamSize ?? 3;
        this.state.num_teams = numTeams ?? 6;
        this.state.current_screen = "onboarding";
        this.state.current_question_index = 0;
        this.state.current_stage_index = 0;
        this.state.question_step = 0;
        this.state.show_results = false;
        this.state.reveal_winner = false;
        this.state.is_game_over = false;
        this.state.hide_votes = false;
        this.state.chrono = {
          status: "stopped",
          remaining: 25,
          duration: 25,
          last_updated: Date.now(),
        };
        if (title) this.state.title = title;
        if (date) this.state.date = date;
        if (stages) this.state.stages = stages;

        // Initialize teams
        this.state.teams = {};
        for (let i = 1; i <= this.state.num_teams; i++) {
          const id = `team_${i}`;
          this.state.teams[id] = {
            id,
            slot_index: i,
            is_registered: false,
            score: 0,
            qr_code: `musabaqat://join?gameId=USTHB_CUBE3&teamSlot=${i}`,
          };
        }
        this.state.realtime_choices = {};
        this.state.active_traps = [];
        this.state.trap_usage = {};
        this.state.scored_questions = {};
        this.state.question_history = {};
        this.state.answers = {};

        await this.persist();
        this.broadcastState();
        return this.state;
      }

      case "update_game_settings": {
        if (data.title !== undefined) this.state.title = data.title;
        if (data.date !== undefined) this.state.date = data.date;
        if (data.numTeams !== undefined) {
          this.state.num_teams = Math.max(1, Math.min(10, Number(data.numTeams) || 1));
          // نعيد ضبط خريطة الفرق حسب العدد الجديد
          this.resyncTeamSlots();
        }
        if (data.teamSize !== undefined) {
          this.state.team_size = Math.max(1, Math.min(10, Number(data.teamSize) || 1));
        }
        await this.persist();
        this.broadcastState();
        return this.state;
      }

      case "update_game_info_field": {
        const { key, value } = data;
        (this.state as any)[key] = value;
        await this.persist();
        this.broadcastState();
        return this.state;
      }

      case "update_chrono": {
        const { status, remaining, duration } = data;
        this.state.chrono.status = status;
        this.state.chrono.last_updated = Date.now();
        if (remaining !== undefined) this.state.chrono.remaining = remaining;
        if (duration !== undefined) this.state.chrono.duration = duration;
        await this.persist();
        this.broadcastState();
        return this.state.chrono;
      }

      case "pause_chrono":
      case "pause_chrono_on_reconnect": {
        if (this.state.chrono.status === "running") {
          const now = Date.now();
          const elapsed = (now - this.state.chrono.last_updated) / 1000;
          const currentRemaining = Math.max(0, Math.floor(this.state.chrono.remaining - elapsed));
          this.state.chrono.status = "paused";
          this.state.chrono.remaining = currentRemaining;
          this.state.chrono.last_updated = now;
          await this.persist();
          this.broadcastState();
        }
        return this.state.chrono;
      }

      case "resume_chrono": {
        if (this.state.chrono.status === "paused" || this.state.chrono.status === "stopped") {
          this.state.chrono.status = "running";
          this.state.chrono.last_updated = Date.now();
          await this.persist();
          this.broadcastState();
        }
        return this.state.chrono;
      }

      case "change_screen": {
        this.state.current_screen = data.screenName;
        await this.persist();
        this.broadcastState();
        return this.state;
      }

      case "start_game": {
        this.state.status = "playing";
        // إعادة ضبط مؤشرات البداية: حتى لو أُعيد تشغيل نفس المسابقة،
        // الجميع يبداو من المرحلة والسؤال الأول وما يبقاش شاشة "النهاية" قديمة
        this.state.current_stage_index = 0;
        this.state.current_question_index = 0;
        this.state.is_game_over = false;
        this.state.reveal_winner = false;
        this.state.show_results = false;
        this.state.realtime_choices = {};
        this.state.chrono = {
          status: "stopped",
          remaining: 25,
          duration: 25,
          last_updated: Date.now(),
        };
        // نفتح مباشرة بواجهة المرحلة الأولى (إلا كانت مواجهة عادية)
        const firstStage =
          Array.isArray(this.state.stages) && this.state.stages.length > 0
            ? this.state.stages[0]
            : null;
        this.state.current_screen =
          firstStage && firstStage.type ? String(firstStage.type) : "arena";
        this.state.question_step = -2;
        await this.persist();
        this.broadcastState();
        return this.state;
      }

      case "finish_game": {
        this.state.status = "finished";
        this.state.is_game_over = true;
        // زر "إعلان النتائج" = نهاية الحدث: الكشف عن الفائز يمشي للجميع دفعة وحدة
        // (اللاعبين والجمهور) — data.reveal يجي من الزر، والأنهي التلقائي يبقي بدون كشف.
        this.state.reveal_winner = data.reveal === true;
        await this.persist();
        await this.archiveCompetition("finished");
        this.broadcastState();
        return this.state;
      }

      case "reveal_winner": {
        this.state.reveal_winner = true;
        await this.persist();
        this.broadcastState();
        return this.state;
      }

      case "close_competition": {
        // نحفظ النتائج في السجل قبل ما نمسح الفرق
        await this.archiveCompetition("closed");
        this.state.status = "idle";
        this.state.teams = {};
        await this.persist();
        this.broadcastState();
        return this.state;
      }

      case "delete_active_competition": {
        this.state.status = "none";
        this.state.teams = {};
        await this.persist();
        this.broadcastState();
        return this.state;
      }

      case "set_team_choice": {
        const { teamId, choice } = data;
        this.state.realtime_choices[teamId] = choice;
        await this.persist();
        this.broadcastState();
        return this.state.realtime_choices;
      }

      case "clear_realtime_choices": {
        this.state.realtime_choices = {};
        await this.persist();
        this.broadcastState();
        return this.state.realtime_choices;
      }

      case "use_trap": {
        const { type, teamId, targetTeamId, questionIndex, fakeVote } = data;
        if (!this.state.trap_usage[teamId]) {
          this.state.trap_usage[teamId] = {};
        }
        const used = this.state.trap_usage[teamId][type] || 0;
        if (used >= 2) return false;

        this.state.trap_usage[teamId][type] = used + 1;
        const trap: Trap = {
          id: `${Date.now()}_${Math.random().toString(36).substr(2, 5)}`,
          by: teamId,
          target: targetTeamId,
          question_index: questionIndex,
          type,
          fake_vote: fakeVote,
          timestamp: Date.now(),
        };
        this.state.active_traps.push(trap);
        await this.persist();
        this.broadcastState();
        return true;
      }

      case "clear_active_traps": {
        this.state.active_traps = [];
        await this.persist();
        this.broadcastState();
        return true;
      }

      case "score_question": {
        const { questionId, correctAnswerLetter } = data;
        if (this.state.scored_questions[questionId]) return;
        this.state.scored_questions[questionId] = true;

        const currentQIndex = this.state.current_question_index;
        const traps = this.state.active_traps.filter((t) => t.question_index === currentQIndex);

        const frozenTeams = new Set(traps.filter((t) => t.type === "freeze").map((t) => t.target));
        const bets = traps.filter((t) => t.type === "bet");

        // Map team name to slotId
        const nameToSlotId: Record<string, string> = {};
        for (const [slotId, team] of Object.entries(this.state.teams)) {
          if (team.is_registered && team.name) {
            nameToSlotId[team.name] = slotId;
          }
        }

        const choices = { ...this.state.realtime_choices };

        for (const [teamName, choice] of Object.entries(choices)) {
          if (frozenTeams.has(teamName)) continue;
          if (choice === correctAnswerLetter) {
            const slotId = nameToSlotId[teamName];
            if (slotId && this.state.teams[slotId]) {
              this.state.teams[slotId].score = (this.state.teams[slotId].score || 0) + 1;
            }
          }
        }

        // Save history
        this.state.question_history[questionId] = {
          correct_answer: correctAnswerLetter,
          choices,
          timestamp: Date.now(),
        };

        // Bets: if target team answered wrong, bettor gets +1
        for (const bet of bets) {
          const targetChoice = choices[bet.target];
          if (frozenTeams.has(bet.target)) continue;
          if (!targetChoice || targetChoice !== correctAnswerLetter) {
            const slotId = nameToSlotId[bet.by];
            if (slotId && this.state.teams[slotId]) {
              this.state.teams[slotId].score = (this.state.teams[slotId].score || 0) + 1;
            }
          }
        }

        await this.persist();
        this.broadcastState();
        return true;
      }

      case "go_to_next_question": {
        const { index } = data;
        this.state.realtime_choices = {};
        this.state.active_traps = [];
        this.state.current_question_index = index;
        this.state.show_results = false;
        this.state.question_step = 0;
        this.state.chrono = {
          status: "stopped",
          remaining: 25,
          duration: 25,
          last_updated: Date.now(),
        };
        await this.persist();
        this.broadcastState();
        return this.state;
      }

      case "go_to_next_stage": {
        const { stageIndex, screenType } = data;
        this.state.realtime_choices = {};
        this.state.active_traps = [];
        this.state.current_stage_index = stageIndex;
        this.state.current_screen = screenType;
        this.state.current_question_index = 0;
        this.state.show_results = false;
        this.state.question_step = -1;
        this.state.chrono = {
          status: "stopped",
          remaining: 25,
          duration: 25,
          last_updated: Date.now(),
        };
        await this.persist();
        this.broadcastState();
        return this.state;
      }

      case "set_show_results": {
        this.state.show_results = !!data.show;
        await this.persist();
        this.broadcastState();
        return this.state;
      }

      case "set_question_step": {
        this.state.question_step = data.step;
        await this.persist();
        this.broadcastState();
        return this.state;
      }

      case "update_team_slot": {
        const { slotId, teamData } = data;
        if (!this.state.teams[slotId]) {
          const slotIndex = parseInt(slotId.split("_").pop() || "1", 10);
          this.state.teams[slotId] = {
            id: slotId,
            slot_index: slotIndex,
            is_registered: false,
            score: 0,
            qr_code: `musabaqat://join?gameId=USTHB_CUBE3&teamSlot=${slotIndex}`,
          };
        }
        Object.assign(this.state.teams[slotId], teamData);
        await this.persist();
        this.broadcastState();
        return this.state.teams[slotId];
      }

      case "remove_team": {
        const { slotId } = data;
        const slotIndex = parseInt(slotId.split("_").pop() || "1", 10);
        this.state.teams[slotId] = {
          id: slotId,
          slot_index: slotIndex,
          is_registered: false,
          score: 0,
          qr_code: `musabaqat://join?gameId=USTHB_CUBE3&teamSlot=${slotIndex}`,
        };
        await this.persist();
        this.broadcastState();
        return this.state.teams[slotId];
      }

      case "update_team_score": {
        const { slotId, delta } = data;
        if (this.state.teams[slotId]) {
          this.state.teams[slotId].score = (this.state.teams[slotId].score || 0) + delta;
          await this.persist();
          this.broadcastState();
          return this.state.teams[slotId];
        }
        return null;
      }

      case "submit_answer": {
        const { stage, teamId, answerData } = data;
        if (!this.state.answers[stage]) {
          this.state.answers[stage] = {};
        }
        this.state.answers[stage][teamId] = answerData;
        await this.persist();
        this.broadcastState();
        return this.state.answers;
      }

      default:
        throw new Error(`Unknown action: ${action}`);
    }
  }
}
