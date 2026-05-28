import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/note_cubit.dart';
import '../cubit/note_state.dart';
import '../models/note_model.dart';
import '../utils/crypto_helper.dart';
import 'lock_screen.dart';

class NoteListScreen extends StatefulWidget {
  const NoteListScreen({super.key});

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      debugPrint("🚨 PERINGATAN: Aplikasi dipindahkan! Mengunci brankas otomatis...");

      CryptoHelper.clearKey();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LockScreen()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Catatan Rahasia', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_clock, color: Colors.white),
            tooltip: 'Log Out / Kunci Ulang',
            onPressed: () {
              CryptoHelper.clearKey();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LockScreen()));
            },
          )
        ],
      ),
      body: BlocBuilder<NoteCubit, NoteState>(
        builder: (context, state) {
          if (state is NoteLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is NoteError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)));
          } else if (state is NoteLoaded) {
            if (state.notes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined, size: 100, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('Brankas Masih Kosong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    Text('Klik tombol + untuk menambah catatan aman.', style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(top: 12, bottom: 80),
              itemCount: state.notes.length,
              itemBuilder: (context, index) {
                final note = state.notes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showEditNoteDialog(context, note),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: const Icon(Icons.lock, color: Color(0xFF1E3A8A), size: 20),
                        ),
                        title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(note.contentData, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade700)),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _showDeleteConfirmDialog(context, note.id!),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: Text('Memulai...'));
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddNoteDialog(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Catatan Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF10B981),
        elevation: 4,
      ),
    );
  }

  InputDecoration _customInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    void runStressTest(int bytesCount, String label, BuildContext dialogContext) {
      showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
      Future.delayed(const Duration(milliseconds: 100), () {
        final dummyText = List.filled(bytesCount, 'A').join('');
        context.read<NoteCubit>().addSecureNote('Eksperimen $label', dummyText);
        Navigator.pop(context);
        Navigator.pop(dialogContext);
      });
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Tambah Catatan / Uji', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: titleController, decoration: _customInputDecoration('Judul Catatan')),
                const SizedBox(height: 12),
                TextField(controller: contentController, decoration: _customInputDecoration('Isi Catatan Rahasia'), maxLines: 3),
                const SizedBox(height: 20),
                const Text('Alat Uji Jurnal (Stress Test)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(label: const Text('10 KB'), onPressed: () => runStressTest(10 * 1024, '10 KB', dialogContext)),
                    ActionChip(label: const Text('100 KB'), onPressed: () => runStressTest(100 * 1024, '100 KB', dialogContext)),
                    ActionChip(label: const Text('1 MB'), onPressed: () => runStressTest(1024 * 1024, '1 MB', dialogContext)),
                  ],
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
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

  void _showEditNoteDialog(BuildContext context, NoteModel note) {
    final titleController = TextEditingController(text: note.title);
    final contentController = TextEditingController(text: note.contentData);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Catatan Rahasia', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: _customInputDecoration('Judul Baru')),
              const SizedBox(height: 12),
              TextField(controller: contentController, decoration: _customInputDecoration('Isi Catatan Baru'), maxLines: 3),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                final title = titleController.text;
                final content = contentController.text;
                if (title.isNotEmpty && content.isNotEmpty) {
                  context.read<NoteCubit>().updateSecureNote(note.id!, title, content, note.createdAt);
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

  void _showDeleteConfirmDialog(BuildContext context, int noteId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.red), SizedBox(width: 8), Text('Hapus Catatan?')]),
          content: const Text('Teks ciphertext di database lokal akan dihapus secara permanen.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                context.read<NoteCubit>().deleteSecureNote(noteId);
                Navigator.pop(dialogContext);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}