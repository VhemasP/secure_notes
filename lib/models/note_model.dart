class NoteModel {
  final int? id;
  final String title;
  final String contentData;
  final String createdAt;

  NoteModel({
    this.id, 
    required this.title, 
    required this.contentData, 
    required this.createdAt
  });

  // Konversi dari Model ke Map (format yang dibaca oleh SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content_data': contentData, // Kolom ini yang menjadi target utama enkripsi
      'created_at': createdAt,
    };
  }

  // Konversi dari Map ke Model (saat data ditarik dari SQLite ke aplikasi)
  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'],
      title: map['title'],
      contentData: map['content_data'],
      createdAt: map['created_at'],
    );
  }
}