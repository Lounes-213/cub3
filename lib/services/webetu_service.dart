import 'package:http/http.dart' as http;

/// التحقق من وجود حساب الطالب عبر صفحة PROGRES الرسمية نفسها:
/// https://progres.mesrs.dz/webetu/login.xhtml
/// (اسم المستخدم = سنة البكالوريا + رقم التسجيل، وكلمة السر = كلمة سر كشف النقاط)
///
/// Fail-closed: أي شك = الحساب غير موجود = لا دخول.
class WebetuService {
  static const String loginUrl =
      'https://progres.mesrs.dz/webetu/login.xhtml';

  static const Map<String, String> _browserHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'fr-FR,fr;q=0.9,ar-DZ;q=0.8,en;q=0.7',
    'Referer': 'https://progres.mesrs.dz/webetu/login.xhtml',
  };

  /// Returns true ONLY if the official page accepts the credentials.
  Future<bool> verifyAccount(String username, String password) async {
    final client = http.Client();
    try {
      // 1) GET the login page (walk redirects, collect session cookies).
      final session = await _loadLoginPage(client);
      final viewState = session['viewState'];
      final cookie = session['cookie'];
      if (viewState == null || viewState.isEmpty) return false;

      // 2) POST the full JSF form (same fields as the real page).
      final form = {
        'loginFrm': 'loginFrm',
        'loginFrm:j_username': username.trim(),
        'loginFrm:j_password': password,
        'loginFrm:loginBtn': 'Se connecter',
        'javax.faces.ViewState': viewState,
      };
      final req = http.Request('POST', Uri.parse(loginUrl))
        ..headers.addAll({
          ..._browserHeaders,
          'Content-Type': 'application/x-www-form-urlencoded',
          if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
        })
        ..body = _encodeForm(form)
        ..followRedirects = false;

      final streamed =
          await client.send(req).timeout(const Duration(seconds: 25));
      final status = streamed.statusCode;

      // Success = server redirects us AWAY from the login page.
      if (_isRedirect(status)) {
        final loc = streamed.headers['location'] ?? '';
        await streamed.stream.drain();
        return !loc.contains('login');
      }
      if (status != 200) return false;

      final body = await streamed.stream.bytesToString();
      return _isSuccessBody(body);
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  /// GET login page: follow redirects manually to keep session cookies
  /// (without JSESSIONID the server answers 500 ViewExpired).
  Future<Map<String, String?>> _loadLoginPage(http.Client client) async {
    var uri = Uri.parse(loginUrl);
    final jar = <String, String>{};
    for (int i = 0; i < 5; i++) {
      final req = http.Request('GET', uri)
        ..headers.addAll(_browserHeaders)
        ..followRedirects = false;
      if (jar.isNotEmpty) {
        req.headers['Cookie'] =
            jar.entries.map((e) => '${e.key}=${e.value}').join('; ');
      }
      final res = await client.send(req).timeout(const Duration(seconds: 20));
      _collectCookies(jar, res.headers['set-cookie']);
      if (_isRedirect(res.statusCode)) {
        final loc = res.headers['location'];
        await res.stream.drain();
        if (loc == null || loc.isEmpty) break;
        uri = uri.resolve(loc);
        continue;
      }
      final body = await res.stream.bytesToString();
      return {
        'viewState': _extractViewState(body),
        'cookie': jar.entries.map((e) => '${e.key}=${e.value}').join('; '),
      };
    }
    return {'viewState': null, 'cookie': null};
  }

  bool _isRedirect(int status) =>
      status == 301 ||
      status == 302 ||
      status == 303 ||
      status == 307 ||
      status == 308;

  void _collectCookies(Map<String, String> jar, String? setCookie) {
    if (setCookie == null) return;
    for (final name in ['JSESSIONID', 'SRV']) {
      final m = RegExp('$name=[^;,]+').firstMatch(setCookie);
      if (m != null) {
        jar[name] = m.group(0)!.substring(name.length + 1);
      }
    }
  }

  String? _extractViewState(String html) {
    final m = RegExp(r'name="javax\.faces\.ViewState"[^>]*value="([^"]+)"')
        .firstMatch(html);
    final v = m?.group(1);
    return (v == null || v.isEmpty) ? null : v;
  }

  bool _isSuccessBody(String body) {
    final lower = body.toLowerCase();
    // Proven failure marker on wrong credentials.
    if (lower.contains("nom d'utilisateur invalide") ||
        lower.contains('mot de passe ou nom') ||
        lower.contains('incorrect') ||
        lower.contains('inexistant')) {
      return false;
    }
    // Still showing the login form => not authenticated (fail closed).
    if (body.contains('loginFrm:j_username')) return false;
    // Logged-in pages carry logout markers.
    if (lower.contains('éconnexion') ||
        lower.contains('deconnexion') ||
        lower.contains('logout') ||
        lower.contains('j_spring_security_logout')) {
      return true;
    }
    return false; // any doubt => no entry
  }

  String _encodeForm(Map<String, String> m) => m.entries
      .map((e) =>
          '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
      .join('&');
}
