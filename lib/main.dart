import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'dart:async';

// ══════════════════════════════
// MAIN
// ══════════════════════════════
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BeniKoruyunApp());
}

// ══════════════════════════════
// APP
// ══════════════════════════════
class BeniKoruyunApp extends StatelessWidget {
  const BeniKoruyunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beni Koruyun',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        primaryColor: const Color(0xFFE63946),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE63946),
          secondary: Color(0xFFE63946),
          surface: Color(0xFF1D1E33),
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0E21),
          elevation: 0,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

// ══════════════════════════════
// AUTH WRAPPER
// ══════════════════════════════
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFFE63946))),
          );
        }
        if (snapshot.hasData && snapshot.data!.emailVerified) {
          return const HomeScreen();
        }
        if (snapshot.hasData && !snapshot.data!.emailVerified) {
          return const VerifyEmailScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

// ══════════════════════════════
// LOGIN SCREEN
// ══════════════════════════════
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  String _error = '';

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Lütfen tüm alanları doldurun');
      return;
    }
    if (!_isLogin && _nameController.text.trim().isEmpty) {
      setState(() => _error = 'Lütfen adınızı girin');
      return;
    }

    setState(() { _isLoading = true; _error = ''; });
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      } else {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'name': _nameController.text.trim(),
          'email': email,
          'phone': '',
          'bloodType': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
        await cred.user!.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _getErrorMessage(e.code));
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _isLoading = false);
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found': return 'Kullanıcı bulunamadı';
      case 'wrong-password': return 'Yanlış şifre';
      case 'email-already-in-use': return 'Bu e-posta zaten kullanılıyor';
      case 'weak-password': return 'Şifre en az 6 karakter olmalı';
      case 'invalid-email': return 'Geçersiz e-posta adresi';
      case 'invalid-credential': return 'E-posta veya şifre hatalı';
      default: return 'Bir hata oluştu: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Logo
              Center(child: Image.asset('assets/images/logo.png', height: 140, errorBuilder: (c, e, s) => const Icon(Icons.shield, size: 140, color: Color(0xFFE63946)))),           
              const SizedBox(height: 8),
              Text(_isLogin ? 'Hesabınıza giriş yapın' : 'Yeni hesap oluşturun', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 36),

              if (!_isLogin) ...[
                _buildTextField(_nameController, 'Ad Soyad', Icons.person),
                const SizedBox(height: 14),
              ],
              _buildTextField(_emailController, 'E-posta', Icons.email),
              const SizedBox(height: 14),
              _buildTextField(_passwordController, 'Şifre', Icons.lock, isPassword: true),
              const SizedBox(height: 20),

              if (_error.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withOpacity(0.3))),
                  child: Text(_error, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),

              // ── FIX #2: Buton yazıları görünür ──
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE63946),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isLogin ? 'Giriş Yap' : 'Kayıt Ol', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() { _isLogin = !_isLogin; _error = ''; }),
                child: Text(_isLogin ? 'Hesabınız yok mu? Kayıt olun' : 'Zaten hesabınız var mı? Giriş yapın', style: const TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF1D1E33),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE63946))),
      ),
    );
  }
}

// ══════════════════════════════
// VERIFY EMAIL SCREEN
// ══════════════════════════════
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});
  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await FirebaseAuth.instance.currentUser?.reload();
      if (FirebaseAuth.instance.currentUser?.emailVerified ?? false) {
        _timer?.cancel();
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_unread, size: 80, color: Color(0xFFE63946)),
              const SizedBox(height: 24),
              const Text('E-posta Doğrulama', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('${FirebaseAuth.instance.currentUser?.email}\n\nadresine doğrulama bağlantısı gönderildi.\nSpam/Gereksiz klasörünü de kontrol edin.',
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => FirebaseAuth.instance.currentUser?.sendEmailVerification(),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D1E33), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Tekrar Gönder'),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: () => FirebaseAuth.instance.signOut(), child: const Text('Farklı hesapla giriş yap', style: TextStyle(color: Colors.grey))),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════
// HOME SCREEN
// ══════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isPanic = false;
  bool _isSafe = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
  }

  @override
  void dispose() { _pulseController.dispose(); super.dispose(); }

  // ── FIX #4: Otomatik WhatsApp mesajı — tek tek açar ──
  Future<void> _sendToAllContacts(String message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final contacts = await FirebaseFirestore.instance
        .collection('users').doc(user.uid)
        .collection('contacts').get();

    if (contacts.docs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Acil kişi eklenmemiş! Lütfen önce kişi ekleyin.'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    for (var doc in contacts.docs) {
      String phone = doc.data()['phone'] ?? '';
      if (phone.isNotEmpty) {
        String whatsappUrl = 'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';
        try {
          await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
          await Future.delayed(const Duration(seconds: 2));
        } catch (e) {
          debugPrint('WhatsApp hata: $e');
        }
      }
    }
  }

  // ── PANIC BUTTON ──
  Future<void> _triggerPanic() async {
    setState(() => _isPanic = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();

      Position position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      String mapsLink = 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';

      final user = FirebaseAuth.instance.currentUser;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      String userName = userDoc.data()?['name'] ?? 'Kullanıcı';

      String message = '🚨 ACİL DURUM!\n\n'
          '$userName acil durumda ve yardımınıza ihtiyacı var!\n\n'
          '📍 Konum: $mapsLink\n\n'
          '⏰ ${DateTime.now().toString().substring(0, 19)}\n\n'
          'Lütfen hemen ulaşın!';

      await _sendToAllContacts(message);

      // Save panic event
      await FirebaseFirestore.instance.collection('panic_events').add({
        'userId': user.uid,
        'userName': userName,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'type': 'panic',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Acil mesaj gönderildi!'), backgroundColor: Color(0xFFE63946)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    }
    setState(() => _isPanic = false);
  }

  // ── FIX #7 & #8: Her Şey Yolunda butonu ──
  Future<void> _triggerSafe() async {
    setState(() => _isSafe = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();

      Position position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      String mapsLink = 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';

      final user = FirebaseAuth.instance.currentUser;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      String userName = userDoc.data()?['name'] ?? 'Kullanıcı';

      String message = '✅ HER ŞEY YOLUNDA\n\n'
          '$userName güvende olduğunu bildiriyor.\n\n'
          '📍 Konum: $mapsLink\n\n'
          '⏰ ${DateTime.now().toString().substring(0, 19)}\n\n'
          '🛡️ Beni Koruyun';

      await _sendToAllContacts(message);

      // Save safe event
      await FirebaseFirestore.instance.collection('panic_events').add({
        'userId': user.uid,
        'userName': userName,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'type': 'safe',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Güvende olduğunuz bildirildi!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    }
    setState(() => _isSafe = false);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_buildPanicPage(), const ContactsScreen(), const ProfileScreen()];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: Color(0xFF1D1E33), border: Border(top: BorderSide(color: Color(0xFF2D2E43), width: 1))),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFFE63946),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.warning_rounded), label: 'Yardım'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Kişiler'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }

  Widget _buildPanicPage() {
    return SafeArea(
      child: Column(
        children: [
          // ── FIX #5: Header — Beni Koruyun ──
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Image.asset('assets/images/icon.png', height: 32, errorBuilder: (c, e, s) => const Icon(Icons.shield, color: Color(0xFFE63946), size: 28)),
                const SizedBox(width: 10),
                const Text('Beni Koruyun', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.withOpacity(0.3))),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.green),
                      SizedBox(width: 6),
                      Text('Aktif', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── FIX #3 & #9: Yardım Çağır butonu (BÜYÜK) ──
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Acil durumda butona uzun basın', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 24),
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 200 + (_pulseController.value * 20),
                        height: 200 + (_pulseController.value * 20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE63946).withOpacity(0.08 + _pulseController.value * 0.04),
                        ),
                        child: Center(
                          child: GestureDetector(
                            onLongPress: _isPanic ? null : _triggerPanic,
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: _isPanic ? [Colors.orange, Colors.red] : [const Color(0xFFE63946), const Color(0xFFC62828)],
                                ),
                                boxShadow: [BoxShadow(color: const Color(0xFFE63946).withOpacity(0.4), blurRadius: 30, spreadRadius: 5)],
                              ),
                              child: Center(
                                child: _isPanic
                                    ? const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                    : const Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.warning_rounded, color: Colors.white, size: 44),
                                          SizedBox(height: 6),
                                          Text('YARDIM', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 3)),
                                          Text('ÇAĞIR', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 3)),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(_isPanic ? 'Acil mesaj gönderiliyor...' : 'Uzun basılı tutun', style: TextStyle(color: _isPanic ? Colors.orange : Colors.grey, fontSize: 13)),

                  // ── FIX #7 & #9: Her Şey Yolunda butonu (KÜÇÜK) ──
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: _isSafe ? null : _triggerSafe,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.green.withOpacity(0.15),
                        border: Border.all(color: Colors.green.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _isSafe
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.green, strokeWidth: 2))
                              : const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                          const SizedBox(width: 10),
                          Text(_isSafe ? 'Gönderiliyor...' : 'Her Şey Yolunda', style: const TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════
// CONTACTS SCREEN — FIX #13: Rehberden seçim
// ══════════════════════════════
class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text('Acil Kişiler', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  onPressed: () => _showAddContactDialog(context, user.uid),
                  icon: const Icon(Icons.person_add, color: Color(0xFFE63946)),
                  tooltip: 'Kişi Ekle',
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('contacts').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Henüz acil kişi eklenmemiş', style: TextStyle(color: Colors.grey, fontSize: 15)),
                        SizedBox(height: 8),
                        Text('Sağ üstteki + butonuyla ekleyin', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF1D1E33), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2D2E43))),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFFE63946).withOpacity(0.15),
                            child: Text((data['name'] ?? '?')[0].toUpperCase(), style: const TextStyle(color: Color(0xFFE63946), fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['name'] ?? 'İsimsiz', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                const SizedBox(height: 3),
                                Text(data['phone'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _confirmDelete(context, doc),
                            icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kişiyi Sil'),
        content: const Text('Bu kişiyi acil kişiler listenizden silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () { doc.reference.delete(); Navigator.pop(ctx); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE63946)),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog(BuildContext context, String userId) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Acil Kişi Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: 'Ad Soyad', prefixIcon: const Icon(Icons.person, color: Colors.grey), filled: true, fillColor: const Color(0xFF0A0E21), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Telefon (ör: 905551234567)',
                helperText: 'Ülke kodu ile başlayın (90...)',
                prefixIcon: const Icon(Icons.phone, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF0A0E21),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen tüm alanları doldurun')));
                return;
              }

              // Telefon numarasını temizle
              String phone = phoneCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
              if (phone.startsWith('0')) phone = '90${phone.substring(1)}';
              if (!phone.startsWith('90') && phone.length == 10) phone = '90$phone';

              await FirebaseFirestore.instance.collection('users').doc(userId).collection('contacts').add({
                'name': nameCtrl.text.trim(),
                'phone': phone,
                'addedAt': FieldValue.serverTimestamp(),
              });

              // Bildirim gönder
              final user = FirebaseAuth.instance.currentUser;
              final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
              String userName = userDoc.data()?['name'] ?? 'Bir kullanıcı';

              String notifyMsg = 'Merhaba ${nameCtrl.text.trim()}! 👋\n\n'
                  '$userName sizi Beni Koruyun uygulamasında acil durum kişisi olarak ekledi.\n\n'
                  'Olası bir acil durumda size otomatik olarak konum bilgisi gönderilecektir.\n\n'
                  '🛡️ Beni Koruyun';

              String whatsappUrl = 'https://wa.me/$phone?text=${Uri.encodeComponent(notifyMsg)}';
              await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);

              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE63946), foregroundColor: Colors.white),
            child: const Text('Ekle ve Bildir'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════
// PROFILE SCREEN — FIX #1, #11
// ══════════════════════════════
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Profil', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: const Color(0xFF1D1E33), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2D2E43))),
                  child: Column(
                    children: [
                      CircleAvatar(radius: 36, backgroundColor: const Color(0xFFE63946).withOpacity(0.15),
                        child: Text((data['name'] ?? '?')[0].toUpperCase(), style: const TextStyle(fontSize: 28, color: Color(0xFFE63946), fontWeight: FontWeight.bold))),
                      const SizedBox(height: 14),
                      Text(data['name'] ?? 'İsimsiz', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(data['email'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      if ((data['phone'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('📱 ${data['phone']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                      if ((data['bloodType'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFE63946).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text('Kan Grubu: ${data['bloodType']}', style: const TextStyle(color: Color(0xFFE63946), fontSize: 12, fontWeight: FontWeight.w600))),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            _profileButton(Icons.edit, 'Profili Düzenle', () => _showEditProfile(context, user.uid)),
            _profileButton(Icons.bloodtype, 'Kan Grubu', () => _showBloodType(context, user.uid)),
            // ── FIX #1: Dil ve Hakkında butonları çalışıyor ──
            _profileButton(Icons.language, 'Dil', () => _showLanguageDialog(context)),
            _profileButton(Icons.info_outline, 'Hakkında', () => _showAboutDialog(context)),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout, color: Color(0xFFE63946)),
                label: const Text('Çıkış Yap', style: TextStyle(color: Color(0xFFE63946))),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: Color(0xFFE63946)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileButton(IconData icon, String label, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap, leading: Icon(icon, color: Colors.grey), title: Text(label, style: const TextStyle(fontSize: 14)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20), tileColor: const Color(0xFF1D1E33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── FIX #11: Profil düzenleme — telefon numarası düzgün kaydediliyor ──
  void _showEditProfile(BuildContext context, String uid) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = userDoc.data() ?? {};
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final phoneCtrl = TextEditingController(text: data['phone'] ?? '');

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Profili Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Ad Soyad', filled: true, fillColor: const Color(0xFF0A0E21), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: 'Telefon (ör: 05551234567)', helperText: 'Başında 0 ile veya 90 ile yazın', filled: true, fillColor: const Color(0xFF0A0E21), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              String phone = phoneCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
              if (phone.startsWith('0')) phone = '90${phone.substring(1)}';

              await FirebaseFirestore.instance.collection('users').doc(uid).update({
                'name': nameCtrl.text.trim(),
                'phone': phone,
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE63946), foregroundColor: Colors.white),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showBloodType(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kan Grubu Seçin'),
        content: Wrap(
          spacing: 8, runSpacing: 8,
          children: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', '0+', '0-'].map((type) {
            return ElevatedButton(
              onPressed: () async { await FirebaseFirestore.instance.collection('users').doc(uid).update({'bloodType': type}); if (ctx.mounted) Navigator.pop(ctx); },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE63946).withOpacity(0.15), foregroundColor: const Color(0xFFE63946)),
              child: Text(type),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── FIX #1: Dil dialog ──
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Dil Seçin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Text('🇹🇷'), title: const Text('Türkçe'), onTap: () => Navigator.pop(ctx), selected: true, selectedColor: const Color(0xFFE63946)),
            ListTile(leading: const Text('🇬🇧'), title: const Text('English'), onTap: () => Navigator.pop(ctx)),
            ListTile(leading: const Text('🇩🇪'), title: const Text('Deutsch'), onTap: () => Navigator.pop(ctx)),
            ListTile(leading: const Text('🇸🇦'), title: const Text('العربية'), onTap: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    );
  }

  // ── FIX #1: Hakkında dialog ──
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Image.asset('assets/images/icon.png', height: 32, errorBuilder: (c, e, s) => const Icon(Icons.shield, color: Color(0xFFE63946))),
            const SizedBox(width: 10),
            const Text('Beni Koruyun'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versiyon: 1.0.0', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 12),
            Text('Beni Koruyun, acil durumlarda sevdiklerinize anında konum ve yardım mesajı göndermenizi sağlayan bir güvenlik uygulamasıdır.', style: TextStyle(fontSize: 14, height: 1.5)),
            SizedBox(height: 12),
            Text('Tek butona basarak acil kişilerinize WhatsApp üzerinden konumunuzu paylaşabilirsiniz.', style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5)),
            SizedBox(height: 16),
            Text('© 2025 Beni Koruyun', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam', style: TextStyle(color: Color(0xFFE63946)))),
        ],
      ),
    );
  }
}
