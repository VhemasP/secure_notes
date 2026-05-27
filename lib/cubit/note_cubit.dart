import 'package:flutter_bloc/flutter_bloc.dart';
import 'note_state.dart';
import '../models/note_model.dart';
import '../repositories/database_helper.dart';
import '../utils/crypto_helper.dart';

class NoteCubit extends Cubit<NoteState> {
  NoteCubit() : super(NoteInitial());

  final dbHelper = DatabaseHelper.instance;

  // 1. FUNGSI LOAD/READ NOTES
  Future<void> loadSecureNotes() async {
    try {
      emit(NoteLoading());

      final encryptedNotes = await dbHelper.readAllNotes();
      final stopwatch = Stopwatch()..start();

      List<NoteModel> decryptedNotes = [];

      for (var note in encryptedNotes) {
        final plainText = CryptoHelper.decryptData(note.contentData);

        decryptedNotes.add(
            NoteModel(
              id: note.id,
              title: note.title,
              contentData: plainText,
              createdAt: note.createdAt,
            )
        );
      }

      stopwatch.stop();
      print('⏱️ [Eksperimen] Waktu Dekripsi ${encryptedNotes.length} data: ${stopwatch.elapsedMilliseconds} ms');

      emit(NoteLoaded(decryptedNotes));
    } catch (e) {
      emit(NoteError('Gagal memuat data: $e'));
    }
  }

  // 2. FUNGSI CREATE/ADD NOTE
  Future<void> addSecureNote(String title, String plainTextContent) async {
    try {
      emit(NoteLoading());

      final stopwatch = Stopwatch()..start();
      final encryptedContent = CryptoHelper.encryptData(plainTextContent);
      stopwatch.stop();
      print('⏱️ [Eksperimen] Waktu Enkripsi: ${stopwatch.elapsedMilliseconds} ms');

      final newNote = NoteModel(
        title: title,
        contentData: encryptedContent,
        createdAt: DateTime.now().toIso8601String(),
      );

      await dbHelper.insertNote(newNote);
      await loadSecureNotes();
    } catch (e) {
      emit(NoteError('Gagal menyimpan data: $e'));
    }
  }

  // 3. FUNGSI UPDATE SECURE NOTE (Pastikan nama ini sama persis dengan di main.dart)
  Future<void> updateSecureNote(int id, String title, String plainTextContent, String createdAt) async {
    try {
      emit(NoteLoading());

      // Teks baru dienkripsi ulang sebelum masuk database
      final encryptedContent = CryptoHelper.encryptData(plainTextContent);

      final updatedNote = NoteModel(
        id: id,
        title: title,
        contentData: encryptedContent,
        createdAt: createdAt,
      );

      await dbHelper.updateNote(updatedNote);
      await loadSecureNotes();
    } catch (e) {
      emit(NoteError('Gagal memperbarui data: $e'));
    }
  }

  // 4. FUNGSI DELETE SECURE NOTE (Pastikan nama ini sama persis dengan di main.dart)
  Future<void> deleteSecureNote(int id) async {
    try {
      emit(NoteLoading());
      await dbHelper.deleteNote(id);
      await loadSecureNotes();
    } catch (e) {
      emit(NoteError('Gagal menghapus data: $e'));
    }
  }
}