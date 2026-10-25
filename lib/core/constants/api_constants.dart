/// Cloudflare API & WebSocket Endpoints for Cube III
class ApiConstants {
  static const String baseUrl = "https://cube-iii.cube-iii-backend.workers.dev";
  static const String wsUrl = "wss://cube-iii.cube-iii-backend.workers.dev/ws/game";

  // D1 Endpoints
  static const String users = "$baseUrl/api/users";
  static const String userByUsername = "$baseUrl/api/users/by-username";
  static const String userByMatricule = "$baseUrl/api/users/by-matricule";
  static const String questions = "$baseUrl/api/questions";
  static const String questionsSeed = "$baseUrl/api/questions/seed";
  static const String library = "$baseUrl/api/library";
  static const String competitionHistory = "$baseUrl/api/competition-history";
  static const String fieldProgram = "$baseUrl/api/field-program";
  static const String news = "$baseUrl/api/news";
  static const String newsBatch = "$baseUrl/api/news/batch";
  static const String pubs = "$baseUrl/api/pubs";
  static const String appConfig = "$baseUrl/api/app-config";
  static const String medicalOrders = "$baseUrl/api/medical-orders";
  static const String cateringReservations = "$baseUrl/api/catering-reservations";
  static const String marketplace = "$baseUrl/api/marketplace";

  // PROGRES proxy (via our Worker: avoids browser CORS, verifies real accounts)
  static const String progresLogin = "$baseUrl/api/progres/login";
  static const String progresVerifyPage = "$baseUrl/api/progres/verify-page";
  static const String progresIndividu = "$baseUrl/api/progres/individu";
  static const String progresDias = "$baseUrl/api/progres/dias";
  static const String progresDia = "$baseUrl/api/progres/dia";
  static const String progresImage = "$baseUrl/api/progres/image";
  static const String progresBac = "$baseUrl/api/progres/bac";
  static const String progresBacNotes = "$baseUrl/api/progres/bac-notes";
  static const String progresGroups = "$baseUrl/api/progres/groups";
  static const String progresBilans = "$baseUrl/api/progres/bilans";
  static const String progresBilan = "$baseUrl/api/progres/bilan";
  static const String progresNotesCc = "$baseUrl/api/progres/notes-cc";
  static const String progresNotesExam = "$baseUrl/api/progres/notes-exam";
  static const String progresCoefficients = "$baseUrl/api/progres/coefficients";
  static const String progresConge = "$baseUrl/api/progres/conge";

  // Durable Object Endpoints
  static const String gameState = "$baseUrl/api/game/state";
  static const String gameAction = "$baseUrl/api/game/action";

  // R2 Storage
  static const String mediaUpload = "$baseUrl/api/media/upload";
  static const String mediaDelete = "$baseUrl/api/media/delete";
  static const String mediaBase = "$baseUrl/media";
}

