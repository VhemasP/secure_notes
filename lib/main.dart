import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import 'cubit/note_cubit.dart';
import 'cubit/note_state.dart';
import 'models/note_model.dart';
import 'utils/crypto_helper.dart'; // Import modul crypto yang baru

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NoteCubit(),
      child: MaterialApp(
        title: 'Secure Notes MVP',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const LockScreen(),
      ),
    );
  }
}

// --- LAYAR KUNCI (LOCK SCREEN) ---
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool isAuthenticated = false;
  bool isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    try {
      setState(() { isAuthenticating = true; });

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Pindai sidik jari atau masukkan PIN perangkat',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (didAuthenticate) {
        // Jika biometrik lolos, minta Master Password sebelum membuka akses data
        if (mounted) {
          _showMasterPasswordDialog();
        }
      }
    } catch (e) {
      print('Error Autentikasi: $e');
    } finally {
      if (mounted) {
        setState(() { isAuthenticating = false; });
      }
    }
  }

  // --- FITUR BARU: Dialog Input Master Password ---
  void _showMasterPasswordDialog() {
    final passwordController = TextEditingController();
    bool isError = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Tidak bisa ditutup sembarangan
      builder: (dialogContext) {
        return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Dekripsi Data'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Masukkan Master Password untuk menyusun kunci AES Anda.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passwordController,
                      obscureText: true, // Sembunyikan teks password
                      decoration: InputDecoration(
                        labelText: 'Master Password',
                        errorText: isError ? 'Password tidak boleh kosong' : null,
                        prefixIcon: const Icon(Icons.vpn_key),
                      ),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
                    onPressed: () {
                      final pass = passwordController.text;
                      if (pass.isNotEmpty) {
                        // 1. Olah input menjadi Kunci AES di CryptoHelper
                        CryptoHelper.setMasterPassword(pass);

                        Navigator.pop(dialogContext); // Tutup dialog

                        // 2. Izinkan masuk ke UI utama dan load data
                        this.setState(() { isAuthenticated = true; });
                        context.read<NoteCubit>().loadSecureNotes();
                      } else {
                        setState(() { isError = true; });
                      }
                    },
                    child: const Text('Buka Brankas'),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isAuthenticated) {
      return const NoteListScreen();
    }

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 100, color: Colors.blue.shade800),
            const SizedBox(height: 20),
            const Text('Aplikasi Terkunci', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Verifikasi biometrik & kata sandi diperlukan.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: isAuthenticating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.fingerprint),
              label: Text(isAuthenticating ? 'Memverifikasi...' : 'Buka Kunci'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              onPressed: isAuthenticating ? null : _authenticate,
            ),
          ],
        ),
      ),
    );
  }
}

// --- LAYAR DAFTAR CATATAN (Tidak ada perubahan logika, persis seperti sebelumnya) ---
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
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)));
          } else if (state is NoteLoaded) {
            if (state.notes.isEmpty) {
              return const Center(child: Text('Belum ada catatan rahasia.', style: TextStyle(color: Colors.grey)));
            }
            return ListView.builder(
              itemCount: state.notes.length,
              itemBuilder: (context, index) {
                final note = state.notes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  child: ListTile(
                    title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(note.contentData, maxLines: 2, overflow: TextOverflow.ellipsis),
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
                    onTap: () => _showEditNoteDialog(context, note),
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
          title: const Text('Tambah Catatan / Uji Performa'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Judul Catatan')),
                TextField(controller: contentController, decoration: const InputDecoration(labelText: 'Isi Catatan Rahasia'), maxLines: 3),
                const SizedBox(height: 16),
                const Divider(),
                const Text('Alat Uji Jurnal (Stress Test)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(onPressed: () => runStressTest(10 * 1024, '10 KB', dialogContext), child: const Text('10 KB')),
                    OutlinedButton(onPressed: () => runStressTest(100 * 1024, '100 KB', dialogContext), child: const Text('100 KB')),
                    OutlinedButton(onPressed: () => runStressTest(1024 * 1024, '1 MB', dialogContext), child: const Text('1 MB')),
                  ],
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
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

  void _showEditNoteDialog(BuildContext context, NoteModel note) {
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
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Judul Baru')),
              TextField(controller: contentController, decoration: const InputDecoration(labelText: 'Isi Catatan Baru'), maxLines: 3),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
            ElevatedButton(
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
          title: const Text('Hapus Catatan?'),
          content: const Text('Teks ciphertext di database lokal akan dihapus secara permanen.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
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