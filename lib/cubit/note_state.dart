import '../models/note_model.dart';

abstract class NoteState {}

class NoteInitial extends NoteState {}

class NoteLoading extends NoteState {}

class NoteLoaded extends NoteState {
  final List<NoteModel> notes;
  NoteLoaded(this.notes);
}

class NoteError extends NoteState {
  final String message;
  NoteError(this.message);
}