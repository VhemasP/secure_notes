import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('secure_notes.db'); // Nama file database lokal
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Mengeksekusi DDL untuk pembuatan tabel
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content_data TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // Fungsi Insert (Simpan data baru)
  Future<int> insertNote(NoteModel note) async {
    final db = await instance.database;
    return await db.insert('notes', note.toMap());
  }

  // Fungsi Read (Tarik semua data dari tabel)
  Future<List<NoteModel>> readAllNotes() async {
    final db = await instance.database;
    // Mengurutkan dari catatan terbaru
    final result = await db.query('notes', orderBy: 'created_at DESC'); 
    return result.map((json) => NoteModel.fromMap(json)).toList();
  }
  // Fungsi Update (Perbarui data yang sudah ada)
  Future<int> updateNote(NoteModel note) async {
    final db = await instance.database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  // Fungsi Delete (Hapus data berdasarkan ID)
  Future<int> deleteNote(int id) async {
    final db = await instance.database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}