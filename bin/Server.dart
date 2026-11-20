import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:sqlite3/sqlite3.dart';

late final Database db;

Response _json(Object? data, {int status = 200}) => Response(
      status,
      body: jsonEncode(data),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

List<Map<String, dynamic>> _rows(ResultSet rs) =>
    rs.map((r) => Map<String, dynamic>.from(r)).toList();

Future<Map<String, dynamic>?> _readJson(Request req) async {
  try {
    final data = jsonDecode(await req.readAsString());
    return data is Map<String, dynamic> ? data : null;
  } on FormatException {
    return null;
  }
}

const _foodSql = '''
SELECT f.id, f.name, c.name AS category, f.description,
       f.calories, f.protein, f.carbs, f.fat, f.origin
FROM foods f JOIN categories c ON c.id = f.category_id
''';

Future<void> main() async {
  db = sqlite3.open('food.db');
  db.execute(File('db/schema.sql').readAsStringSync());

  final api = Router()
    ..get('/api/categories', (Request req) {
      return _json(_rows(db.select('SELECT id, name FROM categories ORDER BY name')));
    })
    ..get('/api/foods', (Request req) {
      final category = req.url.queryParameters['category'];
      final rs = (category == null || category.isEmpty)
          ? db.select('$_foodSql ORDER BY f.name')
          : db.select('$_foodSql WHERE c.name = ? ORDER BY f.name', [category]);
      return _json(_rows(rs));
    })
    ..get('/api/posts', (Request req) {
      return _json(_rows(db.select(
        'SELECT id, title, author, created_at, substr(body, 1, 180) AS excerpt '
        'FROM posts ORDER BY id DESC',
      )));
    })
    ..get('/api/posts/<id|[0-9]+>', (Request req, String id) {
      final rs = db.select(
        'SELECT id, title, author, body, created_at FROM posts WHERE id = ?',
        [int.parse(id)],
      );
      if (rs.isEmpty) return _json({'error': 'Post not found'}, status: 404);
      return _json(Map<String, dynamic>.from(rs.first));
    })
    ..post('/api/posts', (Request req) async {
      final data = await _readJson(req);
      if (data == null) return _json({'error': 'Send a JSON object'}, status: 400);

      final title = (data['title'] ?? '').toString().trim();
      final author = (data['author'] ?? '').toString().trim();
      final body = (data['body'] ?? '').toString().trim();

      if (title.isEmpty || author.isEmpty || body.isEmpty) {
        return _json({'error': 'Title, author and post text are all required'}, status: 400);
      }
      if (title.length > 150 || author.length > 60 || body.length > 10000) {
        return _json({'error': 'One of the fields is too long'}, status: 400);
      }

      db.execute(
        'INSERT INTO posts (title, author, body) VALUES (?, ?, ?)',
        [title, author, body],
      );
      return _json({'id': db.lastInsertRowId}, status: 201);
    });

  final web = createStaticHandler('web', defaultDocument: 'index.html');
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(Cascade().add(api.call).add(web).handler);

  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('Food site running at http://localhost:${server.port}');
}
