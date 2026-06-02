import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/note_model.dart';
import '../repositories/database_helper.dart';
import '../utils/crypto_helper.dart';
import 'note_state.dart';

class NoteCubit extends Cubit<NoteState> {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  NoteCubit() : super(NoteInitial());

  Future<void> loadSecureNotes() async {
    try {
      emit(NoteLoading());
      final notes = await dbHelper.readAllNotes();

      List<NoteModel> decryptedNotes = [];
      // Mendekripsi catatan satu per satu secara asinkron di background
      for (var note in notes) {
        final plainText = await CryptoHelper.decryptDataAsync(note.contentData);
        decryptedNotes.add(
            NoteModel(
              id: note.id,
              title: note.title,
              contentData: plainText,
              createdAt: note.createdAt,
            )
        );
      }

      emit(NoteLoaded(decryptedNotes));
    } catch (e) {
      // CEK JIKA ERROR DISEBABKAN OLEH ARGUMEN/PADDING DEKRIPSI YANG SALAH
      if (e.toString().contains('Invalid argument') || e.toString().contains('pad block')) {
        CryptoHelper.clearKey(); // Hapus key dari memori karena tidak valid
        emit(NoteError('Master Password yang Anda masukkan salah. Silakan coba lagi.'));
      } else {
        emit(NoteError('Gagal memuat catatan: $e'));
      }
    }
  }

  Future<void> addSecureNote(String title, String plainTextContent) async {
    try {
      emit(NoteLoading());

      // MULAI MENGHITUNG WAKTU PERFORMA (BENCHMARK)
      final stopwatch = Stopwatch()..start();

      // Memanggil fungsi background
      final encryptedContent = await CryptoHelper.encryptDataAsync(plainTextContent);

      stopwatch.stop();
      print('==================================================');
      print('⏱️ HASIL UJI COBA: ${plainTextContent.length} Karakter');
      print('⏱️ WAKTU ENKRIPSI: ${stopwatch.elapsedMilliseconds} milidetik (ms)');
      print('==================================================');

      final newNote = NoteModel(
        title: title,
        contentData: encryptedContent,
        createdAt: DateTime.now().toIso8601String(),
      );

      await dbHelper.insertNote(newNote);
      await loadSecureNotes();
    } catch (e) {
      emit(NoteError('Gagal menyimpan catatan: $e'));
    }
  }

  Future<void> updateSecureNote(int id, String title, String plainTextContent, String createdAt) async {
    try {
      emit(NoteLoading());
      final encryptedContent = await CryptoHelper.encryptDataAsync(plainTextContent);

      final updatedNote = NoteModel(
        id: id,
        title: title,
        contentData: encryptedContent,
        createdAt: createdAt,
      );

      await dbHelper.updateNote(updatedNote);
      await loadSecureNotes();
    } catch (e) {
      emit(NoteError('Gagal memperbarui catatan: $e'));
    }
  }

  Future<void> deleteSecureNote(int id) async {
    try {
      emit(NoteLoading());
      await dbHelper.deleteNote(id);
      await loadSecureNotes();
    } catch (e) {
      emit(NoteError('Gagal menghapus catatan: $e'));
    }
  }
}