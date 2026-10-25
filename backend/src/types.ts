// Types for Cube III Cloudflare Worker

export interface Env {
  DB: D1Database;
  MEDIA_BUCKET: R2Bucket;
  GAME_ROOM: DurableObjectNamespace;
  PROGRES_TUNNEL?: string; // optional tunnel URL (Algerian egress fallback)
}

export interface UserProfile {
  matricule: string;
  username: string;
  password?: string | null;
  fullNameAr?: string;
  fullNameFr?: string;
  firstNameAr?: string;
  lastNameAr?: string;
  levelAr?: string;
  cycleAr?: string;
  registrationNumber?: string;
  role?: string;
  isActive?: boolean | number;
  photo?: string | null;
  created_at?: string;
  updated_at?: string;
}

export interface Question {
  id: string;
  title?: string;
  category?: string;
  question_text: string;
  type: string;
  options: string[]; // JSON parsed
  correct_answer?: string;
  description?: string;
  media_url?: string;
  media_type?: string;
  points?: number;
  created_at?: string;
}

export interface TeamSlot {
  id: string;
  slot_index: number;
  name?: string;
  members?: string[];
  team_color?: string;
  is_registered: boolean;
  score: number;
  qr_code: string;
}

export interface ChronoState {
  status: 'stopped' | 'running' | 'paused';
  remaining: number;
  duration: number;
  last_updated: number;
}

export interface Trap {
  id?: string;
  by: string;
  target: string;
  question_index: number;
  type: 'freeze' | 'scramble' | 'bet';
  fake_vote?: string;
  timestamp: number;
}

export interface GameState {
  status: string; // 'none' | 'idle' | 'playing' | 'finished'
  competition_uid?: string; // unique id of the current competition (archived in history)
  creator_id?: string; // matricule/id of the admin who created/launched it
  creator_name?: string; // name of the admin who created/launched it
  title?: string;
  date?: string;
  team_size: number;
  num_teams: number;
  current_screen: string;
  current_stage_index: number;
  current_question_index: number;
  question_step: number;
  show_results: boolean;
  reveal_winner: boolean;
  is_game_over: boolean;
  hide_votes: boolean;
  stages?: any[];
  chrono: ChronoState;
  teams: Record<string, TeamSlot>;
  realtime_choices: Record<string, string>;
  active_traps: Trap[];
  trap_usage: Record<string, Record<string, number>>;
  scored_questions: Record<string, boolean>;
  question_history: Record<string, any>;
  answers: Record<string, Record<string, any>>;
}
