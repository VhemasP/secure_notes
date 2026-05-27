import 'package:flutter_bloc/flutter_bloc.dart';
import 'note_state.dart';
import '../models/note_model.dart';
import '../repositories/database_helper.dart';
import '../utils/crypto_helper.dart';

class NoteCubit extends Cubit<NoteState> {
  NoteCubit() : super(NoteInitial());

  final dbHelper = DatabaseHelper.instance;

  // Fungsi untuk menyimpan catatan (Proses Write + Enkripsi)
  Future<void> addSecureNote(String title, String plainTextContent) async {
    try {
      emit(NoteLoading());

      // --- AWAL PENGUKURAN PERFORMA ENKRIPSI ---
      final stopwatch = Stopwatch()..start();
      
      // Mengubah teks terang menjadi teks acak (ciphertext)
      final encryptedContent = CryptoHelper.encryptData(plainTextContent);
      
      stopwatch.stop();
      // DATA UNTUK JURNAL: Catat angka milidetik ini untuk dianalisis di artikel
      print('⏱️ [Eksperimen] Waktu Enkripsi: ${stopwatch.elapsedMilliseconds} ms');
      // -----------------------------------------

      // Memasukkan data ke dalam model (yang disimpan adalah teks terenkripsi)
      final newNote = NoteModel(
        title: title,
        contentData: encryptedContent,
        createdAt: DateTime.now().toIso8601String(),
      );

      // Simpan ke SQLite
      await dbHelper.insertNote(newNote);

      // Muat ulang daftar catatan agar UI terbarui
      await loadSecureNotes();
    } catch (e) {
      emit(NoteError('Gagal menyimpan data: $e'));
    }
  }

  // Fungsi untuk membaca catatan (Proses Read + Dekripsi)
  Future<void> loadSecureNotes() async {
    try {
      emit(NoteLoading());
      
      // Menarik semua data (yang masih terenkripsi) dari SQLite
      final encryptedNotes = await dbHelper.readAllNotes();
      
      // --- AWAL PENGUKURAN PERFORMA DEKRIPSI ---
      final stopwatch = Stopwatch()..start();
      
      List<NoteModel> decryptedNotes = [];
      
      for (var note in encryptedNotes) {
        // Mengembalikan teks acak menjadi teks terang agar bisa dibaca di UI
        final plainText = CryptoHelper.decryptData(note.contentData);
        
        decryptedNotes.add(
          NoteModel(
            id: note.id,
            title: note.title,
            contentData: plainText, // Menggunakan teks hasil dekripsi
            createdAt: note.createdAt,
          )
        );
      }

      stopwatch.stop();
      // DATA UNTUK JURNAL: Catat angka ini untuk membandingkan mana yang lebih berat (Enkripsi vs Dekripsi)
      print('⏱️ [Eksperimen] Waktu Dekripsi ${encryptedNotes.length} data: ${stopwatch.elapsedMilliseconds} ms');
      // -----------------------------------------

      emit(NoteLoaded(decryptedNotes));
    } catch (e) {
      emit(NoteError('Gagal memuat data: $e'));
    }
  }
}