import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import '../cubit/note_cubit.dart';
import '../utils/crypto_helper.dart';
import 'note_list_screen.dart';

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
        if (mounted) _showMasterPasswordDialog();
      }
    } catch (e) {
      debugPrint('Error Autentikasi: $e');
    } finally {
      if (mounted) setState(() { isAuthenticating = false; });
    }
  }

  void _showMasterPasswordDialog() {
    final passwordController = TextEditingController();
    bool isError = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Row(
                  children: [
                    Icon(Icons.key, color: Color(0xFF1E3A8A)),
                    SizedBox(width: 10),
                    Text('Dekripsi Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Masukkan Master Password untuk menyusun kunci AES Anda.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Master Password',
                        errorText: isError ? 'Password tidak boleh kosong' : null,
                        prefixIcon: const Icon(Icons.vpn_key_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () {
                      final pass = passwordController.text;
                      if (pass.isNotEmpty) {
                        CryptoHelper.setMasterPassword(pass);
                        Navigator.pop(dialogContext);
                        this.setState(() { isAuthenticated = true; });
                        context.read<NoteCubit>().loadSecureNotes();
                      } else {
                        setState(() { isError = true; });
                      }
                    },
                    child: const Text('Buka Brankas', style: TextStyle(fontWeight: FontWeight.bold)),
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
    if (isAuthenticated) return const NoteListScreen();

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E3A8A), // Deep Blue
              Color(0xFF3B82F6), // Blue 500
            ],
          ),
        ),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded, size: 80, color: Color(0xFF1E3A8A)),
                ),
                const SizedBox(height: 24),
                const Text('Secure Brankas', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                const SizedBox(height: 8),
                const Text('Verifikasi biometrik diperlukan', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: isAuthenticating
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.fingerprint, size: 24),
                    label: Text(isAuthenticating ? 'Memverifikasi...' : 'Buka Kunci', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isAuthenticating ? null : _authenticate,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}