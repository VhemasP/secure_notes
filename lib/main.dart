import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubit/note_cubit.dart';
import 'cubit/note_state.dart';
import 'models/note_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Memuat seluruh catatan terenkripsi secara otomatis saat aplikasi pertama kali terbuka
      create: (context) => NoteCubit()..loadSecureNotes(),
      child: MaterialApp(
        title: 'Secure Notes MVP',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const NoteListScreen(),
      ),
    );
  }
}

class NoteListScreen extends StatelessWidget {
  const NoteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Notes MVP', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade100,
        centerTitle: true,
      ),
      body: BlocBuilder<NoteCubit, NoteState>(
        builder: (context, state) {
          if (state is NoteLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is NoteError) {
            return Center(
              child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
              ),
            );
          } else if (state is NoteLoaded) {
            if (state.notes.isEmpty) {
              return const Center(
                child: Text('Belum ada catatan rahasia.', style: TextStyle(color: Colors.grey)),
              );
            }
            return ListView.builder(
              itemCount: state.notes.length,
              itemBuilder: (context, index) {
                final note = state.notes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  child: ListTile(
                    title: Text(
                      note.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      note.contentData, // Menampilkan teks asli hasil dekripsi di UI
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showDeleteConfirmDialog(context, note.id!),
                        ),
                      ],
                    ),
                    onTap: () => _showEditNoteDialog(context, note), // Ketuk kartu untuk mengubah data
                  ),
                );
              },
            );
          }
          return const Center(child: Text('Memulai...'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- 1. DIALOG TAMBAH CATATAN ---
  void _showAddNoteDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    // Fungsi internal untuk Stress Test tanpa membebani TextField UI
    void runStressTest(int bytesCount, String label, BuildContext dialogContext) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      Future.delayed(const Duration(milliseconds: 100), () {
        final dummyText = List.filled(bytesCount, 'A').join('');
        context.read<NoteCubit>().addSecureNote('Eksperimen $label', dummyText);
        Navigator.pop(context); // Tutup loading spinner
        Navigator.pop(dialogContext); // Tutup form dialog
      });
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Tambah Catatan / Uji Performa'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Judul Catatan'),
                ),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: 'Isi Catatan Rahasia'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const Text('Alat Uji Jurnal (Stress Test)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const Text('Data diproduksi langsung di background thread', style: TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => runStressTest(10 * 1024, '10 KB', dialogContext),
                      child: const Text('10 KB'),
                    ),
                    OutlinedButton(
                      onPressed: () => runStressTest(100 * 1024, '100 KB', dialogContext),
                      child: const Text('100 KB'),
                    ),
                    OutlinedButton(
                      onPressed: () => runStressTest(1024 * 1024, '1 MB', dialogContext),
                      child: const Text('1 MB'),
                    ),
                  ],
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text;
                final content = contentController.text;
                if (title.isNotEmpty && content.isNotEmpty) {
                  context.read<NoteCubit>().addSecureNote(title, content);
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  // --- 2. DIALOG EDIT CATATAN ---
  void _showEditNoteDialog(BuildContext context, NoteModel note) {
    // Mengisi otomatis form dengan data lama yang sudah didekripsi
    final titleController = TextEditingController(text: note.title);
    final contentController = TextEditingController(text: note.contentData);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Catatan Rahasia'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Judul Baru'),
              ),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Isi Catatan Baru'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text;
                final content = contentController.text;
                if (title.isNotEmpty && content.isNotEmpty) {
                  // Memasukkan data baru untuk dienkripsi ulang di level Cubit
                  context.read<NoteCubit>().updateSecureNote(
                    note.id!,
                    title,
                    content,
                    note.createdAt,
                  );
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Perbarui'),
            ),
          ],
        );
      },
    );
  }

  // --- 3. DIALOG KONFIRMASI HAPUS ---
  void _showDeleteConfirmDialog(BuildContext context, int noteId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Catatan?'),
          content: const Text('Teks ciphertext di database lokal akan dihapus secara permanen.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                context.read<NoteCubit>().deleteSecureNote(noteId);
                Navigator.pop(dialogContext);
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}