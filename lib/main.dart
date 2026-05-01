import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

// ══════════════════════════════
// ══════════════════════════════
// ADMOB BANNER WIDGET
// ══════════════════════════════
// AdMob ID'leri — Debug'da test, Release'de gerçek
const bool _isDebug = bool.fromEnvironment('dart.vm.product') == false;

const String _profileBannerAdId = _isDebug
    ? 'ca-app-pub-3940256099942544/6300978111' // Test banner ID
    : 'ca-app-pub-4733411214953557/3519465842'; // Gerçek profil banner

const String _historyBannerAdId = _isDebug
    ? 'ca-app-pub-3940256099942544/6300978111' // Test banner ID
    : 'ca-app-pub-4733411214953557/3090107501'; // Gerçek geçmiş banner

class BannerAdWidget extends StatefulWidget {
  final String adUnitId;
  const BannerAdWidget({super.key, required this.adUnitId});
  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: widget.adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();
    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await MobileAds.instance.initialize();
  
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  await _initNotifications();

  runApp(const BeniKoruyunApp());
}

Future<void> _initNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
  );
  
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Bildirim kanallarını oluştur
  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.createNotificationChannel(
    const AndroidNotificationChannel(
      'acil',
      'Acil Durum',
      description: 'Acil durum bildirimleri',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('acil'),
    ),
  );

  await androidPlugin?.createNotificationChannel(
    const AndroidNotificationChannel(
      'guvendeyim',
      'Güvendeyim',
      description: 'Güvendeyim bildirimleri',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('guvendeyim'),
    ),
  );

  await androidPlugin?.createNotificationChannel(
    const AndroidNotificationChannel(
      'seskaydi',
      'Ses Kaydı',
      description: 'Ses kaydı bildirimleri',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('seskaydi'),
    ),
  );

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
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
        home: const SplashScreen(),
      );
  }
}

// ══════════════════════════════
// SPLASH SCREEN
// ══════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );
    _controller.repeat(reverse: true);

    Future.delayed(const Duration(seconds: 3), () async {
      // Konum izni iste
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE63946).withOpacity(0.15),
                        border: Border.all(color: const Color(0xFFE63946).withOpacity(0.3), width: 2),
                      ),
                      child: Center(
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/icon.png',
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(Icons.shield, color: Color(0xFFE63946), size: 70),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Beni Koruyun',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Güvenliğin her zaman yanında',
                      style: TextStyle(fontSize: 14, color: Colors.grey, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
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
        if (snapshot.hasData && (snapshot.data!.emailVerified || snapshot.data!.providerData.any((p) => p.providerId == 'google.com'))) {
          return const ProfileCheckWrapper();
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
  bool _rememberMe = false;
  bool _acceptTerms = false;
  bool _acceptKvkk = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  @override
void initState() {
  super.initState();
  _loadSavedCredentials();
}

Future<void> _loadSavedCredentials() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _rememberMe = prefs.getBool('rememberMe') ?? false;
    if (_rememberMe) {
      _emailController.text = prefs.getString('savedEmail') ?? '';
      _passwordController.text = prefs.getString('savedPassword') ?? '';
    }
  });
}

Future<void> _saveCredentials() async {
  final prefs = await SharedPreferences.getInstance();
  if (_rememberMe) {
    await prefs.setBool('rememberMe', true);
    await prefs.setString('savedEmail', _emailController.text);
    await prefs.setString('savedPassword', _passwordController.text);
  } else {
    await prefs.setBool('rememberMe', false);
    await prefs.remove('savedEmail');
    await prefs.remove('savedPassword');
  }
}

Future<void> _signInWithGoogle() async {
  setState(() { _isLoading = true; _error = ''; });
  try {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      setState(() { _isLoading = false; });
      return;
    }
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
	final user = FirebaseAuth.instance.currentUser;
if (user != null) {
  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
    'name': user.displayName ?? '',
    'email': user.email ?? '',
    'telefon': '',
    'bloodType': '',
    'fcmToken': '',
  }, SetOptions(merge: true));
}
  } catch (e) {
    setState(() { _error = 'Google ile giriş başarısız: $e'; _isLoading = false; });
  }
}

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
    if (!_isLogin && (!_acceptTerms || !_acceptKvkk)) {
      setState(() => _error = 'Devam etmek için sözleşmeleri kabul etmelisiniz');
      return;
    }
	await _saveCredentials();

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
          'termsAccepted': true,
          'termsAcceptedAt': FieldValue.serverTimestamp(),
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

  void _showAgreementDialog(BuildContext context, String type) {
    final isTerms = type == 'terms';
    final title = isTerms ? 'Kullanıcı Sözleşmesi ve Gizlilik Politikası' : 'Açık Rıza Metni';
    final content = isTerms ? _termsText : _kvkkText;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1D1E33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const Divider(color: Colors.white12),
            SizedBox(
              height: 400,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Text(content, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.6)),
              ),
            ),
            const Divider(color: Colors.white12),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Kapat', style: TextStyle(color: Color(0xFFE63946))),
            ),
          ],
        ),
      ),
    );
  }

  static const String _termsText = '''
KULLANICI SÖZLEŞMESİ VE GİZLİLİK POLİTİKASI

Son Güncelleme: Nisan 2026

1. TARAFLAR
Bu sözleşme, "Beni Koruyun" mobil uygulamasını ("Uygulama") kullanan kişi ("Kullanıcı") ile uygulama geliştiricisi arasında akdedilmiştir.

2. UYGULAMANIN AMACI
Beni Koruyun, acil durumlarda kullanıcıların kayıtlı kişilerine anlık konum bilgisi ve acil durum bildirimi göndermesini sağlayan bir güvenlik uygulamasıdır.

3. TOPLANAN VERİLER
Uygulama aşağıdaki verileri toplamaktadır:
• Ad, soyad ve e-posta adresi
• Telefon numarası
• Anlık ve canlı konum bilgisi
• Kan grubu bilgisi
• Acil durumlarda ortam ses kaydı (yalnızca Premium kullanıcılar, yalnızca acil butonuna basıldığında)
• Firebase Cloud Messaging (FCM) token bilgisi

4. VERİLERİN KULLANIMI
Toplanan veriler yalnızca şu amaçlarla kullanılmaktadır:
• Acil durum bildirimlerinin gönderilmesi
• Canlı konum paylaşımı
• Uygulama işlevselliğinin sağlanması

5. VERİ PAYLAŞIMI
Verileriniz yalnızca sizin tarafınızdan uygulamaya eklenen acil kişilerle paylaşılmaktadır. Üçüncü şahıslarla ticari amaçla paylaşılmamaktadır.

6. VERİ SAKLAMA SÜRESİ
• Konum verileri: Yalnızca acil durum süresince (10 dakika)
• Ses kayıtları: 24 saat sonra otomatik olarak silinir
• Hesap verileri: Hesap silinene kadar saklanır

7. GÜVENLİK
Tüm veriler Firebase güvenlik altyapısı üzerinde şifrelenmiş olarak saklanmaktadır.

8. KULLANICI HAKLARI
KVKK kapsamında kullanıcılar; verilerine erişme, düzeltme, silme ve işlenmesine itiraz etme haklarına sahiptir.

9. ÇOCUKLARIN GİZLİLİĞİ
18 yaş altındaki bireyler bu uygulamayı ebeveyn gözetimi ve onayı ile kullanabilir. Ebeveynler, çocukları adına hesap oluşturabilir ve uygulamayı yönetebilir.

10. DEĞİŞİKLİKLER
Sözleşmede yapılacak değişlikler uygulama üzerinden bildirilecektir.

GİZLİLİK POLİTİKASI

Uygulamayı kullanarak bu gizlilik politikasını kabul etmiş sayılırsınız. Verileriniz Google Firebase altyapısında Avrupa sunucularında güvenli şekilde saklanmaktadır. Verilerinize yetkisiz erişim engellemek için endüstri standardı güvenlik önlemleri alınmaktadır.
''';

  static const String _kvkkText = '''
AÇIK RIZA METNİ

6698 Sayılı Kişisel Verilerin Korunması Kanunu ("KVKK") kapsamında, aşağıda belirtilen kişisel verilerimin işlenmesine özgür iradem ile açıkça rıza gösteriyorum.

VERİ SORUMLUSU
Beni Koruyun Uygulaması

İŞLENECEK KİŞİSEL VERİLER VE İŞLENME AMAÇLARI

1. KİMLİK VE İLETİŞİM BİLGİLERİ
Ad-soyad, e-posta adresi ve telefon numarasının; kullanıcı hesabı oluşturulması ve acil durum bildirimlerinin iletilmesi amacıyla işlenmesine rıza gösteriyorum.

2. KONUM BİLGİSİ
Anlık ve canlı konum bilgimin; acil durumlarda kayıtlı kişilerime iletilmesi amacıyla işlenmesine rıza gösteriyorum. Canlı konum paylaşımının acil durum süresince (10 dakika) aktif olacağını kabul ediyorum.

3. SAĞLIK VERİSİ
Kan grubu bilgimin; olası acil tıbbi müdahalelerde kullanılmak üzere acil kişilerime iletilmesi amacıyla işlenmesine rıza gösteriyorum.

4. SES KAYDI (YALNIZCA PREMİUM KULLANICILAR)
Acil durum butonuna bastığımda 15 saniyelik ortam ses kaydının alınmasına ve acil kişilerime iletilmesine rıza gösteriyorum. Bu kaydın 24 saat sonra otomatik olarak silineceğini kabul ediyorum.

HAKLARIM
KVKK'nın 11. maddesi kapsamında; kişisel verilerimin işlenip işlenmediğini öğrenme, işlenmişse buna ilişkin bilgi talep etme, işlenme amacını ve amacına uygun kullanılıp kullanılmadığını öğrenme, yurt içinde veya yurt dışında aktarıldığı üçüncü kişileri bilme, eksik veya yanlış işlenmiş olması hâlinde bunların düzeltilmesini isteme ve silinmesini veya yok edilmesini isteme haklarına sahip olduğumu biliyorum.

İşbu açık rıza beyanı, özgür iradem ile ve bilgilendirilerek verilmiştir.
''';

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
              Center(child: Image.asset('assets/images/logo.png', height: 250, errorBuilder: (c, e, s) => const Icon(Icons.shield, size: 80, color: Color(0xFFE63946)))),
              const SizedBox(height: 16),
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
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() { _rememberMe = value ?? false; });
                    },
                    activeColor: const Color(0xFFE63946),
                  ),
                  const Text('Beni Hatırla', style: TextStyle(color: Colors.white70)),
                ],
              ),
              if (!_isLogin) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                      activeColor: const Color(0xFFE63946),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showAgreementDialog(context, 'terms'),
                        child: const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text.rich(
                            TextSpan(children: [
                              TextSpan(text: 'Kullanıcı Sözleşmesi', style: TextStyle(color: Color(0xFFE63946), decoration: TextDecoration.underline)),
                              TextSpan(text: ' ve ', style: TextStyle(color: Colors.white70)),
                              TextSpan(text: 'Gizlilik Politikası', style: TextStyle(color: Color(0xFFE63946), decoration: TextDecoration.underline)),
                              TextSpan(text: '\'nı okudum ve kabul ediyorum.', style: TextStyle(color: Colors.white70)),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptKvkk,
                      onChanged: (value) => setState(() => _acceptKvkk = value ?? false),
                      activeColor: const Color(0xFFE63946),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showAgreementDialog(context, 'kvkk'),
                        child: const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text.rich(
                            TextSpan(children: [
                              TextSpan(text: 'Açık Rıza Metni', style: TextStyle(color: Color(0xFFE63946), decoration: TextDecoration.underline)),
                              TextSpan(text: '\'ni okudum, kişisel verilerimin işlenmesine açıkça rıza gösteriyorum.', style: TextStyle(color: Colors.white70)),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

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
			  const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 28),
                label: const Text(
                  'Google ile Giriş Yap',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white30),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
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

// ==========================
// PROFILE CHECK WRAPPER
// ==========================
class ProfileCheckWrapper extends StatefulWidget {
  const ProfileCheckWrapper({super.key});
  @override
  State<ProfileCheckWrapper> createState() => _ProfileCheckWrapperState();
}

class _ProfileCheckWrapperState extends State<ProfileCheckWrapper> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const LoginScreen();
    return FutureBuilder(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final data = snapshot.data!.data();
        final termsAccepted = data?['termsAccepted'] ?? false;
        final telefon = data?['telefon'] ?? '';

        if (!termsAccepted) {
          return TermsAcceptanceScreen(userId: user.uid);
        }
        if (telefon.toString().isEmpty) {
          return const CompleteProfileScreen();
        }
        return const HomeScreen();
      },
    );
  }
}

// ==========================
// TERMS ACCEPTANCE SCREEN
// ==========================
class TermsAcceptanceScreen extends StatefulWidget {
  final String userId;
  const TermsAcceptanceScreen({super.key, required this.userId});
  @override
  State<TermsAcceptanceScreen> createState() => _TermsAcceptanceScreenState();
}

class _TermsAcceptanceScreenState extends State<TermsAcceptanceScreen> {
  bool _acceptTerms = false;
  bool _acceptKvkk = false;
  bool _isLoading = false;

  Future<void> _accept() async {
    if (!_acceptTerms || !_acceptKvkk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Devam etmek için tüm sözleşmeleri kabul etmelisiniz'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    await FirebaseFirestore.instance.collection('users').doc(widget.userId).set({
      'termsAccepted': true,
      'termsAcceptedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileCheckWrapper()));
    }
  }

  void _showText(String type) {
    final isTerms = type == 'terms';
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1D1E33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(isTerms ? 'Kullanıcı Sözleşmesi' : 'Açık Rıza Metni',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const Divider(color: Colors.white12),
            SizedBox(
              height: 400,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Text(
                  isTerms ? _LoginScreenState._termsText : _LoginScreenState._kvkkText,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
                ),
              ),
            ),
            const Divider(color: Colors.white12),
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Kapat', style: TextStyle(color: Color(0xFFE63946)))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.description, color: Color(0xFFE63946), size: 48),
              const SizedBox(height: 16),
              const Text('Sözleşme Güncelleme', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Uygulamayı kullanmaya devam etmek için güncellenmiş sözleşmelerimizi kabul etmeniz gerekmektedir.',
                  style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5)),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _acceptTerms,
                    onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                    activeColor: const Color(0xFFE63946),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showText('terms'),
                      child: const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text.rich(TextSpan(children: [
                          TextSpan(text: 'Kullanıcı Sözleşmesi', style: TextStyle(color: Color(0xFFE63946), decoration: TextDecoration.underline)),
                          TextSpan(text: ' ve ', style: TextStyle(color: Colors.white70)),
                          TextSpan(text: 'Gizlilik Politikası', style: TextStyle(color: Color(0xFFE63946), decoration: TextDecoration.underline)),
                          TextSpan(text: '\'nı okudum ve kabul ediyorum.', style: TextStyle(color: Colors.white70)),
                        ])),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _acceptKvkk,
                    onChanged: (v) => setState(() => _acceptKvkk = v ?? false),
                    activeColor: const Color(0xFFE63946),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showText('kvkk'),
                      child: const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text.rich(TextSpan(children: [
                          TextSpan(text: 'Açık Rıza Metni', style: TextStyle(color: Color(0xFFE63946), decoration: TextDecoration.underline)),
                          TextSpan(text: '\'ni okudum, kişisel verilerimin işlenmesine rıza gösteriyorum.', style: TextStyle(color: Colors.white70)),
                        ])),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _accept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE63946),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Kabul Et ve Devam Et', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  child: const Text('Kabul etmiyorum, çıkış yap', style: TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================
// COMPLETE PROFILE SCREEN
// ==========================
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});
  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _selectedBloodType = 'A+';
  bool _isLoading = false;

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    String phone = '0${_phoneCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '')}';
    phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith('0')) phone = '90${phone.substring(1)}';
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
      'name': _nameCtrl.text.trim(),
      'telefon': phone,
      'bloodType': _selectedBloodType,
    }, SetOptions(merge: true));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text('Profilini Tamamla', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 8),
              const Text('Güvenliğin için bilgilerini gir', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 40),
              TextField(
                controller: _nameCtrl,
				style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Ad Soyad',
				  labelStyle: TextStyle(color: Colors.black87),
                  filled: true,
                  fillColor: const Color(0xFFF0F0F0),
				  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneCtrl,
				style: const TextStyle(color: Colors.black87),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Telefon (5xx xxx xx xx)',
				  labelStyle: TextStyle(color: Colors.black87),
                  prefixText: '0',
                  filled: true,
                  fillColor: const Color(0xFFF0F0F0),				  
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedBloodType,
                decoration: InputDecoration(
                  labelText: 'Kan Grubu',
				  labelStyle: TextStyle(color: Colors.black87),
                  filled: true,
                  fillColor: const Color(0xFFF0F0F0),				  
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', '0+', '0-']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedBloodType = val!),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE63946),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Kaydet ve Devam Et', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
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
  bool _isRecording = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _saveFCMToken();
    _listenFCMMessages();
  }
Future<void> _saveFCMToken() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    
    final savedToken = userDoc.data()?['fcmToken'] ?? '';
    
    if (savedToken != token) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': token});
    }
  }
  
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'fcmToken': newToken});
  });
}

void _listenFCMMessages() {
    // Uygulama tamamen kapalıyken bildirime tıklanınca
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        final type = message.data['type'] ?? '';
        final senderUserId = message.data['senderUserId'] ?? '';
        final senderName = message.data['senderName'] ?? 'Birisi';
        if (type == 'panic' && senderUserId.isNotEmpty && mounted) {
          Future.delayed(const Duration(milliseconds: 500), () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LiveLocationScreen(
                  targetUserId: senderUserId,
                  targetUserName: senderName,
                ),
              ),
            );
          });
        }
      }
    });

    // Uygulama açıkken gelen bildirim
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final type = message.data['type'] ?? '';
    final senderUserId = message.data['senderUserId'] ?? '';
    final senderName = message.data['senderName'] ?? 'Birisi';
    _showLocalNotification(
      title: message.notification?.title ?? 'Beni Koruyun',
      body: message.notification?.body ?? '',
      sound: type == 'panic' ? 'acil' : (type == 'audio' ? 'seskaydi' : 'guvendeyim'),
    );
    // Acil durumda haritayı otomatik aç
    if (type == 'panic' && senderUserId.isNotEmpty && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveLocationScreen(
            targetUserId: senderUserId,
            targetUserName: senderName,
          ),
        ),
      );
    }
  });

  // Uygulama arka plandayken bildirime tıklanınca
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final type = message.data['type'] ?? '';
    final senderUserId = message.data['senderUserId'] ?? '';
    final senderName = message.data['senderName'] ?? 'Birisi';
    if (type == 'panic' && senderUserId.isNotEmpty && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveLocationScreen(
            targetUserId: senderUserId,
            targetUserName: senderName,
          ),
        ),
      );
    } else if (type == 'audio' && mounted) {
      // Ses kaydı bildirimine tıklanınca geçmiş ekranı ses kayıtları sekmesine git
      setState(() => _currentIndex = 2); // Geçmiş sekmesi
      Future.delayed(const Duration(milliseconds: 300), () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AudioNotificationScreen()),
        );
      });
    }
  });

  // getInitialMessage - uygulama kapalıyken
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      final type = message.data['type'] ?? '';
      final senderUserId = message.data['senderUserId'] ?? '';
      final senderName = message.data['senderName'] ?? 'Birisi';
      if (type == 'panic' && senderUserId.isNotEmpty && mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LiveLocationScreen(
                targetUserId: senderUserId,
                targetUserName: senderName,
              ),
            ),
          );
        });
      } else if (type == 'audio' && mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AudioNotificationScreen()),
          );
        });
      }
    }
  });
}

Future<void> _showLocalNotification({
  required String title,
  required String body,
  required String sound,
}) async {
  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    sound,
    sound,
    channelDescription: 'Beni Koruyun Bildirimleri',
    importance: Importance.max,
    priority: Priority.high,
    sound: RawResourceAndroidNotificationSound(sound),
    playSound: true,
  );
  final NotificationDetails details = NotificationDetails(android: androidDetails);
  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    details,
  );
}
  @override
  void dispose() { 
    _pulseController.dispose(); 
    super.dispose(); 
  }

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

      Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));

      final user = FirebaseAuth.instance.currentUser;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      String userName = userDoc.data()?['name'] ?? 'Kullanıcı';
      final isPremium = userDoc.data()?['isPremium'] ?? false;

      // Premium kullanıcılar için ses kaydını başlat
      AudioRecorder? recorder;
      String? audioPath;
      if (isPremium) {
        recorder = AudioRecorder();
        final hasPermission = await recorder.hasPermission();
        if (hasPermission) {
          final dir = await getTemporaryDirectory();
          audioPath = '${dir.path}/acil_ses_${user.uid}.m4a';
          await recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: audioPath);
        }
      }

      // Bildirimi hemen gönder
      await _sendPanicNotification(userName: userName, userId: user.uid, audioUrl: null);

      // Panic event kaydet
      final panicRef = await FirebaseFirestore.instance.collection('panic_events').add({
        'userId': user.uid,
        'userName': userName,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'type': 'panic',
        'audioUrl': null,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Canlı konum — Premium 1 saat, Ücretsiz 10 dk
      _startLiveLocation(user.uid, position.latitude, position.longitude, isPremium: isPremium);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Acil mesaj gönderildi!'), backgroundColor: Color(0xFFE63946)),
        );
      }

      // 15 sn ses kaydı bekliyorsa tamamla ve yükle
      if (recorder != null && audioPath != null) {
        setState(() => _isRecording = true);
        await Future.delayed(const Duration(seconds: 15));
        await recorder.stop();
        setState(() => _isRecording = false);
        final file = File(audioPath);
        if (await file.exists()) {
          final ref = FirebaseStorage.instance
              .ref('audio/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.m4a');
          await ref.putFile(file);
          final url = await ref.getDownloadURL();
          // Dosyayı güvenli şekilde sil
          try { await file.delete(); } catch (_) {}

          // Panic event'i güncelle
          await panicRef.update({'audioUrl': url});

          // Ses kaydı tamamlandı bildirimi gönder
          await _sendAudioReadyNotification(userName: userName, userId: user.uid, audioUrl: url);

          // Premium 24 saat, Ücretsiz 6 saat sonra sil
          final deleteDuration = isPremium ? const Duration(hours: 24) : const Duration(hours: 6);
          Future.delayed(deleteDuration, () async {
            try { await ref.delete(); } catch (_) {}
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    }
    setState(() => _isPanic = false);
  }
  Future<void> _sendAudioReadyNotification({required String userName, required String userId, required String audioUrl}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final contacts = await FirebaseFirestore.instance
        .collection('users').doc(user.uid).collection('contacts').get();
    for (var doc in contacts.docs) {
      final contactUserId = doc.data()['userId'] ?? '';
      if (contactUserId.isEmpty) continue;
      final tokenDoc = await FirebaseFirestore.instance.collection('users').doc(contactUserId).get();
      final token = tokenDoc.data()?['fcmToken'] ?? '';
      if (token.isEmpty) continue;

      // Ses kaydını alıcının koleksiyonuna kaydet
      await FirebaseFirestore.instance
          .collection('users').doc(contactUserId).collection('received_audio').add({
        'audioUrl': audioUrl,
        'senderName': userName,
        'senderId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Bildirim gönder
      await _sendFCMNotification(
        token: token,
        title: '🎵 Ses Kaydı Hazır',
        body: '$userName\'ın acil ses kaydı mevcut, dinlemek için tıkla.',
        type: 'audio',
        senderUserId: userId,
        senderName: userName,
      );
    }
  }

  Future<void> _sendPanicNotification({required String userName, required String userId, String? audioUrl}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  
  final contacts = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('contacts')
      .get();

  for (var doc in contacts.docs) {
    final contactUserId = doc.data()['userId'] ?? '';
    if (contactUserId.isEmpty) continue;
    
    final tokenDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(contactUserId)
        .get();
    
    final token = tokenDoc.data()?['fcmToken'] ?? '';
    if (token.isEmpty) continue;
    
    await _sendFCMNotification(
      token: token,
      title: '🚨 ACİL DURUM!',
      body: audioUrl != null
          ? '$userName yardım istiyor! Ses kaydı ve konumu görmek için tıkla.'
          : '$userName yardım istiyor! Konumunu görmek için tıkla.',
      type: 'panic',
      senderUserId: userId,
      senderName: userName,
    );
  }
}

Future<void> _sendFCMNotification({
  required String token,
  required String title,
  required String body,
  required String type,
  String senderUserId = '',
  String senderName = '',
}) async {
  try {
    await FirebaseFirestore.instance.collection('notifications').add({
      'token': token,
      'title': title,
      'body': body,
      'type': type,
      'senderUserId': senderUserId,
      'senderName': senderName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    debugPrint('Bildirim hatası: $e');
  }
}

  // ── FIX #7 & #8: Her Şey Yolunda butonu ──
  Future<void> _triggerSafe() async {
    setState(() => _isSafe = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      String userName = userDoc.data()?['name'] ?? 'Kullanıcı';

      await _sendSafeNotification();

      // Save safe event
      await FirebaseFirestore.instance.collection('panic_events').add({
        'userId': user.uid,
        'userName': userName,
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
  Future<void> _sendSafeNotification() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  
  final contacts = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('contacts')
      .get();

  for (var doc in contacts.docs) {
    final contactUserId = doc.data()['userId'] ?? '';
    if (contactUserId.isEmpty) continue;
    
    final tokenDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(contactUserId)
        .get();
    
    final token = tokenDoc.data()?['fcmToken'] ?? '';
    if (token.isEmpty) continue;
    
    await _sendFCMNotification(
      token: token,
      title: '✅ GÜVENDEYİM!',
      body: '${user.displayName ?? "Birisi"} güvende olduğunu bildiriyor!',
      type: 'safe',
    );
  }
}

  Future<void> _startLiveLocation(String uid, double lat, double lng, {bool isPremium = false}) async {
    final duration = isPremium ? const Duration(hours: 1) : const Duration(minutes: 10);
    final iterations = isPremium ? 120 : 20; // 1 saat = 120 x 30sn, 10dk = 20 x 30sn
    final endTime = DateTime.now().add(duration);
    await FirebaseFirestore.instance.collection('live_locations').doc(uid).set({
      'latitude': lat,
      'longitude': lng,
      'updatedAt': FieldValue.serverTimestamp(),
      'expiresAt': endTime,
      'isActive': true,
    });
    for (int i = 0; i < iterations; i++) {
      await Future.delayed(const Duration(seconds: 30));
      if (DateTime.now().isAfter(endTime)) break;
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        await FirebaseFirestore.instance.collection('live_locations').doc(uid).update({
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        break;
      }
    }
    await FirebaseFirestore.instance.collection('live_locations').doc(uid).update({
      'isActive': false,
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_buildPanicPage(), const ContactsScreen(), const HistoryScreen(), const ProfileScreen()];

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
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Geçmiş'),
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
          // Ses kaydı banner
          if (_isRecording)
            _RecordingBanner(),
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
                          ElevatedButton.icon(
                            onPressed: () => _confirmDelete(context, doc),
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text('Sil', style: TextStyle(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE63946),
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<Map<String, String>?> _pickContactFromPhone() async {
  try {
    if (await FlutterContacts.requestPermission()) {
      final contact = await FlutterContacts.openExternalPick();
      if (contact != null) {
        final fullContact = await FlutterContacts.getContact(
  contact.id,
  withProperties: true,
);
        String name = fullContact?.displayName ?? '';
        String phone = '';
        if (fullContact?.phones.isNotEmpty ?? false) {
          phone = fullContact!.phones.first.number
              .replaceAll(' ', '')
              .replaceAll('-', '')
              .replaceAll('+', '');
          if (phone.startsWith('90') && phone.length == 12) {
            // zaten doğru format, dokunma
          } else if (phone.startsWith('0') && phone.length == 11) {
            phone = '90${phone.substring(1)}';
          } else if (phone.length == 10) {
            phone = '90$phone';
          }
        }
        return {'name': name, 'phone': phone};
      }
    }
  } catch (e) {
    debugPrint('Rehber hatası: $e');
  }
  return null;
}
  void _showAddContactDialog(BuildContext context, String userId) async {
    // Ücretsiz plan limiti kontrolü
    final existingContacts = await FirebaseFirestore.instance
        .collection('users').doc(userId).collection('contacts').get();
    
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final isPremium = userDoc.data()?['isPremium'] ?? false;
    
    if (!isPremium && existingContacts.docs.length >= 1) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1D1E33),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.star, color: Color(0xFFFFD700)),
                SizedBox(width: 8),
                Text('Premium Gerekli'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Ücretsiz planda sadece 1 acil kişi ekleyebilirsiniz.', style: TextStyle(fontSize: 14)),
                SizedBox(height: 12),
                Text('Sınırsız kişi eklemek için Premium\'a geçin!', style: TextStyle(fontSize: 14, color: Color(0xFFFFD700))),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                onPressed: () { Navigator.pop(ctx); },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: Colors.black),
                child: const Text('Premium\'a Geç', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
      return;
    }

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
           ElevatedButton.icon(
  onPressed: () async {
    final contact = await _pickContactFromPhone();
    if (contact != null) {
      nameCtrl.text = contact['name'] ?? '';
      String phone = contact['phone'] ?? '';
      // prefixText '90' olduğu için başındaki 90'ı kırp
      if (phone.startsWith('90')) phone = phone.substring(2);
      phoneCtrl.text = phone;
    }
  },
  icon: const Icon(Icons.contacts, color: Colors.white),
  label: const Text('Rehberden Seç', style: TextStyle(color: Colors.white)),
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFE63946),
    minimumSize: const Size(double.infinity, 45),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
),
const SizedBox(height: 12),
		   TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: 'Ad Soyad', prefixIcon: const Icon(Icons.person, color: Colors.grey), filled: true, fillColor: const Color(0xFF0A0E21), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Telefon (5xx xxx xx xx)',
                prefixText: '90',
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
              if (phone.startsWith('90')) {
                // zaten 90 ile başlıyor, dokunma
              } else if (phone.startsWith('0')) {
                phone = '90${phone.substring(1)}';
              } else {
                phone = '90$phone';
              }

              await FirebaseFirestore.instance.collection('users').doc(userId).collection('contacts').add({
  'name': nameCtrl.text.trim(),
  'phone': phone,
  'addedAt': FieldValue.serverTimestamp(),
  'userId': await _findUserIdByPhone(phone),
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
Future<String> _findUserIdByPhone(String phone) async {
  try {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('telefon', isEqualTo: phone)
        .get();
    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }
  } catch (e) {
    debugPrint('Kullanıcı bulunamadı: $e');
  }
  return '';
}

// ==========================
// PREMIUM FEATURES SCREEN
// ==========================
class PremiumFeaturesScreen extends StatelessWidget {
  const PremiumFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text('Premium Özellikler'),
        backgroundColor: const Color(0xFF0A0E21),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
        builder: (context, snapshot) {
          final isPremium = (snapshot.data?.data() as Map<String, dynamic>?)?['isPremium'] ?? false;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Premium durumu
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPremium
                          ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
                          : [const Color(0xFF1D1E33), const Color(0xFF2D2E43)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(isPremium ? Icons.star : Icons.star_border,
                          color: isPremium ? Colors.black : Colors.grey, size: 40),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isPremium ? '⭐ Premium Kullanıcısınız' : 'Ücretsiz Plan',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isPremium ? Colors.black : Colors.white)),
                          Text(isPremium ? 'Tüm özellikler aktif' : 'Yükselterek daha fazlasına ulaş',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isPremium ? Colors.black87 : Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Premium Özellikler', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                _featureCard(
                  icon: Icons.people,
                  color: Colors.blue,
                  title: 'Sınırsız Acil Kişi',
                  description: 'İstediğin kadar acil kişi ekle. Ücretsiz planda sadece 1 kişi ekleyebilirsin.',
                  isPremium: true,
                  isActive: isPremium,
                ),
                _featureCard(
                  icon: Icons.mic,
                  color: Colors.green,
                  title: '15 Saniyelik Ses Kaydı',
                  description: 'Acil butona bastığında otomatik olarak 15 saniyelik ortam ses kaydı alınır ve acil kişilerine iletilir.',
                  isPremium: true,
                  isActive: isPremium,
                ),
                _featureCard(
                  icon: Icons.headphones,
                  color: Colors.purple,
                  title: 'Ses Kayıtlarını Dinle',
                  description: 'Acil kişilerinden gelen ses kayıtlarını uygulama içinden dinleyebilirsin.',
                  isPremium: true,
                  isActive: isPremium,
                ),
                _featureCard(
                  icon: Icons.location_on,
                  color: Colors.orange,
                  title: '1 Saat Canlı Konum',
                  description: 'Premium kullanıcılarda canlı konum 1 saat boyunca paylaşılır. Ücretsiz planda bu süre 10 dakikadır.',
                  isPremium: true,
                  isActive: isPremium,
                ),
                _featureCard(
                  icon: Icons.block,
                  color: Colors.red,
                  title: 'Reklamsız Kullanım',
                  description: 'Hiçbir reklam görmeden uygulamayı kullan.',
                  isPremium: true,
                  isActive: isPremium,
                ),

                const SizedBox(height: 8),
                const Text('Ücretsiz Özellikler', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                _featureCard(
                  icon: Icons.warning_rounded,
                  color: const Color(0xFFE63946),
                  title: 'Acil Durum Butonu',
                  description: 'Uzun basılı tutarak acil çağrı gönder.',
                  isPremium: false,
                  isActive: true,
                ),
                _featureCard(
                  icon: Icons.check_circle,
                  color: Colors.green,
                  title: 'Her Şey Yolunda Butonu',
                  description: 'Güvende olduğunu acil kişilerine bildir.',
                  isPremium: false,
                  isActive: true,
                ),
                _featureCard(
                  icon: Icons.map,
                  color: Colors.blue,
                  title: 'Canlı Konum (10 dk)',
                  description: 'Acil butona basıldığında 10 dakika boyunca canlı konum paylaşılır.',
                  isPremium: false,
                  isActive: true,
                ),
                _featureCard(
                  icon: Icons.history,
                  color: Colors.grey,
                  title: 'Geçmiş Çağrılar',
                  description: 'Geçmiş acil ve güvendeyim çağrılarını görüntüle.',
                  isPremium: false,
                  isActive: true,
                ),

                if (!isPremium) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Premium\'a Geç', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _featureCard({required IconData icon, required Color color, required String title, required String description, required bool isPremium, required bool isActive}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? color.withOpacity(0.3) : Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: isActive ? color : Colors.grey, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isActive ? Colors.white : Colors.grey)),
                    if (isPremium) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('PRO', style: TextStyle(color: Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: isActive ? Colors.grey : Colors.grey.withOpacity(0.5), fontSize: 12, height: 1.4)),
              ],
            ),
          ),
          Icon(isActive ? Icons.check_circle : Icons.lock_outline,
              color: isActive ? Colors.green : Colors.grey, size: 20),
        ],
      ),
    );
  }
}

// ==========================
// HOW IT WORKS SCREEN
// ==========================
class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text('Nasıl Çalışır?'),
        backgroundColor: const Color(0xFF0A0E21),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFE63946).withOpacity(0.2), const Color(0xFFE63946).withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE63946).withOpacity(0.3)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.shield, color: Color(0xFFE63946), size: 48),
                  SizedBox(height: 12),
                  Text('Beni Koruyun', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                    'Acil durumlarda sevdiklerinize anında ulaşmanızı sağlayan güvenlik uygulaması.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Temel Kullanım', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            _stepCard(step: '1', icon: Icons.person_add, color: Colors.blue,
                title: 'Acil Kişi Ekle',
                description: 'Kişiler sekmesinden güvendiğiniz kişileri acil kişi olarak ekleyin. Ücretsiz planda 1, Premium\'da sınırsız kişi ekleyebilirsiniz.'),
            _stepCard(step: '2', icon: Icons.touch_app, color: const Color(0xFFE63946),
                title: 'Acil Butona Uzun Bas',
                description: 'Tehlikede olduğunuzda "YARDIM ÇAĞIR" butonuna uzun basılı tutun. Yanlışlıkla tetiklenmeyi önlemek için uzun basma gereklidir.'),
            _stepCard(step: '3', icon: Icons.notifications_active, color: Colors.orange,
                title: 'Bildirim Gönderilir',
                description: 'Tüm acil kişilerinize anında bildirim gönderilir. Bildirimde "Konumu Gör" butonu bulunur.'),
            _stepCard(step: '4', icon: Icons.location_on, color: Colors.green,
                title: 'Canlı Konum Paylaşılır',
                description: 'Konumunuz acil kişilerinizle canlı olarak paylaşılır. Ücretsiz planda 10 dakika, Premium\'da 1 saat boyunca güncellenir.'),
            _stepCard(step: '5', icon: Icons.navigation, color: Colors.purple,
                title: 'Acil Kişiler Yol Tarifi Alır',
                description: 'Acil kişileriniz harita üzerinde konumunuzu görebilir ve Google Maps ile yol tarifi alabilir.'),

            const SizedBox(height: 24),
            const Text('Her Şey Yolunda Butonu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            _stepCard(step: '✓', icon: Icons.check_circle, color: Colors.green,
                title: 'Güvende Olduğunuzu Bildirin',
                description: 'Tehlike geçtiğinde veya endişelenen kişilere "Her Şey Yolunda" butonuna basarak güvende olduğunuzu bildirin. Acil kişilerinize bildirim gönderilir.'),

            const SizedBox(height: 24),
            const Text('Premium Özellikler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            _stepCard(step: '🎵', icon: Icons.mic, color: Colors.green,
                title: '15 Sn Ses Kaydı',
                description: 'Acil butona bastığınızda 15 saniyelik ortam ses kaydı otomatik alınır ve acil kişilerinize iletilir. Ses kaydı 24 saat sonra otomatik silinir.'),
            _stepCard(step: '⏱', icon: Icons.timer, color: Colors.orange,
                title: '1 Saat Canlı Konum',
                description: 'Premium kullanıcılarda canlı konum 1 saat boyunca paylaşılmaya devam eder.'),

            const SizedBox(height: 24),
            const Text('Önemli Notlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _noteCard(icon: Icons.location_on, text: 'Uygulamanın düzgün çalışması için konum iznini her zaman açık tutun.'),
            _noteCard(icon: Icons.notifications, text: 'Bildirimlerin gelmesi için bildirim iznini kapatmayın.'),
            _noteCard(icon: Icons.battery_full, text: 'Pil optimizasyonu uygulamayı kısıtlayabilir. Pil ayarlarından uygulamaya izin verin.'),
            _noteCard(icon: Icons.wifi, text: 'İnternet bağlantısı olmadan uygulama çalışmaz.'),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _stepCard({required String step, required IconData icon, required Color color, required String title, required String description}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(step, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                Text(description, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _noteCard({required IconData icon, required String text}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }
}

// ==========================
// PREMIUM SCREEN
// ==========================
class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Başlık
            const Icon(Icons.star, color: Color(0xFFFFD700), size: 64),
            const SizedBox(height: 16),
            const Text('Premium\'a Geç', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Tüm özelliklerin kilidini aç', style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 32),

            // Karşılaştırma tablosu
            Container(
              decoration: BoxDecoration(color: const Color(0xFF1D1E33), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  // Başlık satırı
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Expanded(child: Text('Özellik', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                        SizedBox(width: 70, child: Center(child: Text('Ücretsiz', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)))),
                        SizedBox(width: 70, child: Center(child: Text('Premium', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD700), fontSize: 12)))),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  _featureRow('Acil buton', true, true),
                  _featureRow('Her Şey Yolunda butonu', true, true),
                  _featureRow('Canlı konum paylaşımı', true, true),
                  _featureRow('Geçmiş çağrılar', true, true),
                  _featureRow('Acil kişi ekleme', false, true, freeDetail: '1 kişi', premiumDetail: 'Sınırsız'),
                  _featureRow('15 sn ortam ses kaydı', false, true),
                  _featureRow('Ses kayıtlarını dinleme', false, true),
                  _featureRow('Reklamlı kullanım', true, false, freeDetail: 'Reklamlı', premiumDetail: 'Reklamsız'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Fiyat kartları
            _priceCard(
              context,
              title: 'Aylık Plan',
              price: '79 TL',
              subtitle: 'Aylık',
              isPopular: false,
            ),
            const SizedBox(height: 12),
            _priceCard(
              context,
              title: 'Yıllık Plan',
              price: '699 TL',
              subtitle: 'Yıllık • Aylık sadece 58 TL',
              isPopular: true,
            ),
            const SizedBox(height: 24),

            // 3 gün ücretsiz deneme
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.celebration, color: Color(0xFFFFD700)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('3 Gün Ücretsiz Dene!', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                        Text('İlk 3 gün tamamen ücretsiz. İstediğin zaman iptal et.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Satın al butonu
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ödeme sistemi yakında aktif olacak!'), backgroundColor: Color(0xFFFFD700)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('3 Gün Ücretsiz Başla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('İstediğin zaman iptal edebilirsin', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _featureRow(String feature, bool free, bool premium, {String? freeDetail, String? premiumDetail}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(child: Text(feature, style: const TextStyle(fontSize: 14))),
              SizedBox(
                width: 70,
                child: Center(
                  child: free
                      ? (freeDetail != null
                          ? Text(freeDetail, style: const TextStyle(color: Colors.grey, fontSize: 11))
                          : const Icon(Icons.check_circle, color: Colors.green, size: 20))
                      : const Icon(Icons.cancel, color: Colors.red, size: 20),
                ),
              ),
              SizedBox(
                width: 70,
                child: Center(
                  child: premium
                      ? (premiumDetail != null
                          ? Text(premiumDetail, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.bold))
                          : const Icon(Icons.check_circle, color: Color(0xFFFFD700), size: 20))
                      : const Icon(Icons.cancel, color: Colors.red, size: 20),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white12, height: 1),
      ],
    );
  }

  Widget _priceCard(BuildContext context, {required String title, required String price, required String subtitle, required bool isPopular}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPopular ? const Color(0xFFFFD700).withOpacity(0.1) : const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPopular ? const Color(0xFFFFD700) : Colors.white12, width: isPopular ? 2 : 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(color: const Color(0xFFFFD700), borderRadius: BorderRadius.circular(20)),
                    child: const Text('EN POPÜLER', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(price, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isPopular ? const Color(0xFFFFD700) : Colors.white)),
        ],
      ),
    );
  }
}

// ==========================
// AUDIO PLAYER CARD
// ==========================
class AudioPlayerCard extends StatefulWidget {
  final String senderName;
  final String audioUrl;
  final String date;
  final bool isPremium;
  const AudioPlayerCard({super.key, required this.senderName, required this.audioUrl, required this.date, this.isPremium = false});
  @override
  State<AudioPlayerCard> createState() => _AudioPlayerCardState();
}

class _AudioPlayerCardState extends State<AudioPlayerCard> {
  final AudioPlayer _player = AudioPlayer();
  PlayerState _state = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((s) { if (mounted) setState(() => _state = s); });
    _player.onDurationChanged.listen((d) { if (mounted) setState(() => _duration = d); });
    _player.onPositionChanged.listen((p) { if (mounted) setState(() => _position = p); });
    _player.onPlayerComplete.listen((_) { if (mounted) setState(() => _position = Duration.zero); });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  Future<void> _downloadAudio() async {
    setState(() => _isDownloading = true);
    try {
      final fileName = 'benikoruyun_${widget.senderName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      // Android İndirilenler klasörü
      final downloadPath = '/storage/emulated/0/Download/$fileName';
      
      final dio = Dio();
      await dio.download(
        widget.audioUrl,
        downloadPath,
        onReceiveProgress: (received, total) {},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ İndirildi: İndirilenler/$fileName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İndirme başarısız: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isDownloading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _state == PlayerState.playing;
    final progress = _duration.inSeconds > 0
        ? _position.inSeconds / _duration.inSeconds
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.25)),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.05), blurRadius: 10, spreadRadius: 1)],
      ),
      child: Column(
        children: [
          // Üst kısım - gönderen bilgisi
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Colors.green, Colors.green.shade700]),
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.senderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                      Text(widget.date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.isPremium ? const Color(0xFFFFD700).withOpacity(0.15) : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.isPremium ? '24 saat' : '6 saat',
                    style: TextStyle(
                      color: widget.isPremium ? const Color(0xFFFFD700) : Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // İlerleme çubuğu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.green,
                    inactiveTrackColor: Colors.green.withOpacity(0.15),
                    thumbColor: Colors.green,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: SliderComponentShape.noOverlay,
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChanged: (v) async {
                      final pos = Duration(seconds: (v * _duration.inSeconds).toInt());
                      await _player.seek(pos);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_fmt(_position), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                      Text(_fmt(_duration), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Butonlar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                // Dinle butonu
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      if (isPlaying) {
                        await _player.pause();
                      } else {
                        await _player.play(UrlSource(widget.audioUrl));
                      }
                    },
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.green, Colors.green.shade700]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 20),
                          const SizedBox(width: 6),
                          Text(isPlaying ? 'Durdur' : 'Dinle', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // İndir butonu
                Expanded(
                  child: GestureDetector(
                    onTap: _isDownloading ? null : _downloadAudio,
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _isDownloading
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue))
                              : const Icon(Icons.download, color: Colors.blue, size: 20),
                          const SizedBox(width: 6),
                          Text(_isDownloading ? 'İndiriliyor...' : 'İndir', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _RecordingBanner extends StatefulWidget {
  @override
  State<_RecordingBanner> createState() => _RecordingBannerState();
}

class _RecordingBannerState extends State<_RecordingBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _animation = Tween<double>(begin: 1.0, end: 0.2).animate(_controller);
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          color: Colors.red.withOpacity(_animation.value),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mic, color: Colors.white.withOpacity(_animation.value + 0.2), size: 20),
              const SizedBox(width: 8),
              Text('🔴 Ses kaydı alınıyor... (15 sn)',
                  style: TextStyle(color: Colors.white.withOpacity(_animation.value + 0.2),
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════
// HISTORY SCREEN
// ══════════════════════════════
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _selectedIds = {};
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _deleteSelected(String userId) async {
    for (final id in _selectedIds) {
      await FirebaseFirestore.instance.collection('panic_events').doc(id).delete();
    }
    setState(() { _selectedIds.clear(); _selectionMode = false; });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                const Expanded(child: Text('Geçmiş', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                if (_selectionMode) ...[
                  TextButton.icon(
                    onPressed: () => setState(() { _selectedIds.clear(); _selectionMode = false; }),
                    icon: const Icon(Icons.close, color: Colors.grey),
                    label: const Text('İptal', style: TextStyle(color: Colors.grey)),
                  ),
                  TextButton.icon(
                    onPressed: _selectedIds.isEmpty ? null : () => _deleteSelected(user.uid),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: Text('Sil (${_selectedIds.length})', style: const TextStyle(color: Colors.red)),
                  ),
                ] else
                  IconButton(
                    icon: const Icon(Icons.checklist, color: Colors.grey),
                    tooltip: 'Seç ve sil',
                    onPressed: () => setState(() => _selectionMode = true),
                  ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFFE63946),
            labelColor: const Color(0xFFE63946),
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Çağrılar'),
              Tab(text: 'Ses Kayıtları 🎵'),
            ],
          ),
          // Ücretsiz kullanıcıya banner reklam
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, snapshot) {
              final isPremium = (snapshot.data?.data() as Map<String, dynamic>?)?['isPremium'] ?? false;
              if (isPremium) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(child: BannerAdWidget(adUnitId: _historyBannerAdId)),
              );
            },
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCallsList(user.uid),
                _buildAudioList(user.uid),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('panic_events')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFE63946)));
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Henüz çağrı geçmişi yok', style: TextStyle(color: Colors.grey, fontSize: 16)),
            ],
          ));
        }
        // Tarihe göre sırala
        final docs = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final aTime = (a.data() as Map)['timestamp'] as Timestamp?;
            final bTime = (b.data() as Map)['timestamp'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

        return Column(
          children: [
            if (_selectionMode)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        final allIds = docs.map((d) => d.id).toSet();
                        setState(() => _selectedIds.addAll(allIds));
                      },
                      icon: const Icon(Icons.select_all, color: Colors.grey, size: 18),
                      label: const Text('Tümünü Seç', style: TextStyle(color: Colors.grey)),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(() => _selectedIds.clear()),
                      icon: const Icon(Icons.deselect, color: Colors.grey, size: 18),
                      label: const Text('Seçimi Kaldır', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final type = data['type'] ?? 'panic';
            final isPanic = type == 'panic';
            final timestamp = data['timestamp'] as Timestamp?;
            final date = timestamp != null
                ? '${timestamp.toDate().day}.${timestamp.toDate().month}.${timestamp.toDate().year} ${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                : 'Bilinmiyor';
            final lat = data['latitude'];
            final lng = data['longitude'];
            final isSelected = _selectedIds.contains(doc.id);

            return GestureDetector(
              onLongPress: () => setState(() { _selectionMode = true; _selectedIds.add(doc.id); }),
              onTap: _selectionMode ? () => setState(() {
                isSelected ? _selectedIds.remove(doc.id) : _selectedIds.add(doc.id);
              }) : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE63946).withOpacity(0.15) : const Color(0xFF1D1E33),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFE63946) : (isPanic ? const Color(0xFFE63946).withOpacity(0.3) : Colors.green.withOpacity(0.3)),
                  ),
                ),
                child: Row(
                  children: [
                    if (_selectionMode)
                      Checkbox(
                        value: isSelected,
                        onChanged: (v) => setState(() => v! ? _selectedIds.add(doc.id) : _selectedIds.remove(doc.id)),
                        activeColor: const Color(0xFFE63946),
                      ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isPanic ? const Color(0xFFE63946).withOpacity(0.15) : Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(isPanic ? Icons.warning_rounded : Icons.check_circle,
                          color: isPanic ? const Color(0xFFE63946) : Colors.green, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isPanic ? '🚨 Acil Durum Çağrısı' : '✅ Güvendeyim Bildirimi',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                                  color: isPanic ? const Color(0xFFE63946) : Colors.green)),
                          const SizedBox(height: 4),
                          Text(date, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                    if (!_selectionMode && lat != null && lng != null)
                      IconButton(
                        icon: const Icon(Icons.map, color: Color(0xFFE63946)),
                        onPressed: () async {
                          final url = 'https://www.google.com/maps?q=$lat,$lng';
                          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAudioList(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, userSnapshot) {
        final isPremium = (userSnapshot.data?.data() as Map<String, dynamic>?)?['isPremium'] ?? false;

        if (!isPremium) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 64, color: Color(0xFFFFD700)),
                const SizedBox(height: 16),
                const Text('Bu özellik Premium\'a özel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Ses kayıtlarını dinlemek için\nPremium\'a geçin', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())),
                  icon: const Icon(Icons.star),
                  label: const Text('Premium\'a Yüksel'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: Colors.black),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users').doc(userId).collection('received_audio')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFE63946)));

            final docs = snapshot.data!.docs.toList()
              ..sort((a, b) {
                final aTime = (a.data() as Map)['timestamp'] as Timestamp?;
                final bTime = (b.data() as Map)['timestamp'] as Timestamp?;
                if (aTime == null || bTime == null) return 0;
                return bTime.compareTo(aTime);
              });

            if (docs.isEmpty) {
              return const Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Henüz ses kaydı yok', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final timestamp = data['timestamp'] as Timestamp?;
                final date = timestamp != null
                    ? '${timestamp.toDate().day}.${timestamp.toDate().month}.${timestamp.toDate().year} ${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                    : 'Bilinmiyor';

                return AudioPlayerCard(
                  senderName: data['senderName'] ?? 'Birisi',
                  audioUrl: data['audioUrl'] ?? '',
                  date: date,
                  isPremium: isPremium,
                );
              },
            );
          },
        );
      },
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
                final isPremium = data['isPremium'] ?? false;
                return Column(
                  children: [
                    // Ücretsiz kullanıcıya banner reklam
                    if (!isPremium) ...[
                      Center(child: BannerAdWidget(adUnitId: _profileBannerAdId)),
                      const SizedBox(height: 16),
                    ],
                    // Premium / Ücretsiz plan kartı
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isPremium
                              ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
                              : [const Color(0xFF1D1E33), const Color(0xFF2D2E43)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(isPremium ? Icons.star : Icons.star_border,
                              color: isPremium ? Colors.black : Colors.grey, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isPremium ? 'Premium Plan' : 'Ücretsiz Plan',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isPremium ? Colors.black : Colors.white)),
                                Text(isPremium ? 'Sınırsız kişi ekleyebilirsiniz' : '1 acil kişi hakkınız var',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: isPremium ? Colors.black87 : Colors.grey)),
                              ],
                            ),
                          ),
                          if (!isPremium)
                            ElevatedButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD700),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Yükselt', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [const Color(0xFF1D1E33), const Color(0xFF2D2E43)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE63946).withOpacity(0.2)),
                        boxShadow: [BoxShadow(color: const Color(0xFFE63946).withOpacity(0.1), blurRadius: 20, spreadRadius: 2)],
                      ),
                      child: Column(
                        children: [
                          // Üst kısım — avatar ve isim
                          Container(
                            padding: const EdgeInsets.all(24),
                            child: Row(
                              children: [
                                // Avatar
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [const Color(0xFFE63946), const Color(0xFFE63946).withOpacity(0.6)],
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      (data['name'] ?? '?')[0].toUpperCase(),
                                      style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(data['name'] ?? 'İsimsiz', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                                      const SizedBox(height: 4),
                                      Text(data['email'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Ayırıcı
                          Container(height: 1, color: Colors.white.withOpacity(0.05)),
                          // Alt kısım — bilgiler
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                // Telefon
                                Expanded(
                                  child: _profileInfoTile(
                                    icon: Icons.phone,
                                    label: 'Telefon',
                                    value: (data['telefon'] ?? data['phone'] ?? '').toString().isNotEmpty
                                        ? (data['telefon'] ?? data['phone']).toString().replaceFirst('90', '0')
                                        : 'Eklenmedi',
                                  ),
                                ),
                                Container(width: 1, height: 40, color: Colors.white.withOpacity(0.05)),
                                // Kan grubu
                                Expanded(
                                  child: _profileInfoTile(
                                    icon: Icons.bloodtype,
                                    label: 'Kan Grubu',
                                    value: (data['bloodType'] ?? '').toString().isNotEmpty ? data['bloodType'] : 'Eklenmedi',
                                    valueColor: (data['bloodType'] ?? '').toString().isNotEmpty ? const Color(0xFFE63946) : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            );
              },
            ),
            const SizedBox(height: 20),

            _profileButton(Icons.edit, 'Profili Düzenle', () => _showEditProfile(context, user.uid)),
            _profileButton(Icons.bloodtype, 'Kan Grubu', () => _showBloodType(context, user.uid)),
            _profileButton(Icons.card_giftcard, 'Promosyon Kodum Var', () => _showPromoCodeDialog(context, user.uid)),
            _profileButton(Icons.star, 'Premium Özellikler', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumFeaturesScreen()))),
            _profileButton(Icons.help_outline, 'Nasıl Çalışır?', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HowItWorksScreen()))),
            _profileButton(Icons.description, 'Kullanıcı Sözleşmesi', () => _showAgreementDialogProfile(context, 'terms')),
            _profileButton(Icons.privacy_tip, 'Gizlilik Politikası ve KVKK', () => _showAgreementDialogProfile(context, 'kvkk')),
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

  Widget _profileInfoTile({required IconData icon, required String label, required String value, Color? valueColor}) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
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
    final phoneCtrl = TextEditingController(text: data['telefon'] ?? data['phone'] ?? '');

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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    String phone = phoneCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith('0')) phone = '90${phone.substring(1)}';

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                'name': nameCtrl.text.trim(),
                'telefon': phone,
              }, SetOptions(merge: true));
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

  // ── Promosyon kodu dialog ──
  void _showPromoCodeDialog(BuildContext context, String uid) {
    final codeCtrl = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1D1E33),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.card_giftcard, color: Color(0xFFFFD700)),
              SizedBox(width: 8),
              Text('Promosyon Kodu'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('13 haneli promosyon kodunuzu girin:', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'XXXXXXXXXXXXX',
                  filled: true,
                  fillColor: const Color(0xFF0A0E21),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  counterText: '',
                ),
                maxLength: 13,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                final code = codeCtrl.text.trim().toUpperCase();
                if (code.length != 13) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kod 13 haneli olmalıdır'), backgroundColor: Colors.red),
                  );
                  return;
                }
                setState(() => isLoading = true);
                try {
                  final codeDoc = await FirebaseFirestore.instance.collection('promo_codes').doc(code).get();
                  if (!codeDoc.exists) {
                    if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Geçersiz kod!'), backgroundColor: Colors.red),
                    );
                  } else if (codeDoc.data()?['isUsed'] == true) {
                    if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bu kod daha önce kullanılmış!'), backgroundColor: Colors.orange),
                    );
                  } else {
                    await FirebaseFirestore.instance.collection('promo_codes').doc(code).update({
                      'isUsed': true,
                      'usedBy': uid,
                      'usedAt': FieldValue.serverTimestamp(),
                    });
                    await FirebaseFirestore.instance.collection('users').doc(uid).update({
                      'isPremium': true,
                    });
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('🎉 Premium\'a geçiş başarılı!'), backgroundColor: Colors.green),
                      );
                    }
                  }
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
                  );
                }
                setState(() => isLoading = false);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: Colors.black),
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Kodu Kullan', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
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

  // ── Sözleşme dialog (Profil) ──
  void _showAgreementDialogProfile(BuildContext context, String type) {
    final isTerms = type == 'terms';
    final title = isTerms ? 'Kullanıcı Sözleşmesi ve Gizlilik Politikası' : 'Açık Rıza Metni ve KVKK';
    final content = isTerms ? _LoginScreenState._termsText : _LoginScreenState._kvkkText;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1D1E33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const Divider(color: Colors.white12),
            SizedBox(
              height: 400,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Text(content, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.6)),
              ),
            ),
            const Divider(color: Colors.white12),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Kapat', style: TextStyle(color: Color(0xFFE63946))),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hakkında dialog ──
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
            Text('Beni Koruyun, acil durumlarda sevdiklerinize anında konum ve yardım bildirimi göndermenizi sağlayan bir güvenlik uygulamasıdır.', style: TextStyle(fontSize: 14, height: 1.5)),
            SizedBox(height: 12),
            Text('Acil butona bastığınızda kayıtlı kişilerinize anlık bildirim gönderilir ve 1 saat boyunca canlı konumunuz paylaşılır.', style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5)),
            SizedBox(height: 16),
            Text('© 2026 Beni Koruyun', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam', style: TextStyle(color: Color(0xFFE63946)))),
        ],
      ),
    );
  }
}


// ==========================
// LIVE LOCATION SCREEN
// ==========================
// ==========================
// AUDIO NOTIFICATION SCREEN
// ==========================
class AudioNotificationScreen extends StatelessWidget {
  const AudioNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text('🎵 Ses Kayıtları'),
        backgroundColor: const Color(0xFF0A0E21),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, userSnapshot) {
          final isPremium = (userSnapshot.data?.data() as Map<String, dynamic>?)?['isPremium'] ?? false;
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users').doc(user.uid).collection('received_audio')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFE63946)));
              if (snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mic_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Henüz ses kaydı yok', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                );
              }
              final docs = snapshot.data!.docs.toList()
                ..sort((a, b) {
                  final aTime = (a.data() as Map)['timestamp'] as Timestamp?;
                  final bTime = (b.data() as Map)['timestamp'] as Timestamp?;
                  if (aTime == null || bTime == null) return 0;
                  return bTime.compareTo(aTime);
                });
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final timestamp = data['timestamp'] as Timestamp?;
                  final date = timestamp != null
                      ? '${timestamp.toDate().day}.${timestamp.toDate().month}.${timestamp.toDate().year} ${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                      : 'Bilinmiyor';
                  return AudioPlayerCard(
                    senderName: data['senderName'] ?? 'Birisi',
                    audioUrl: data['audioUrl'] ?? '',
                    date: date,
                    isPremium: isPremium,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================
// LIVE LOCATION SCREEN
// ==========================
class LiveLocationScreen extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;
  const LiveLocationScreen({super.key, required this.targetUserId, required this.targetUserName});
  @override
  State<LiveLocationScreen> createState() => _LiveLocationScreenState();
}

class _LiveLocationScreenState extends State<LiveLocationScreen> {
  Future<void> _openGoogleMapsNavigation(double lat, double lng) async {
    final url = 'google.navigation:q=$lat,$lng&mode=d';
    final fallbackUrl = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await launchUrl(Uri.parse(fallbackUrl), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      await launchUrl(Uri.parse(fallbackUrl), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.targetUserName} - Canlı Konum'),
        backgroundColor: const Color(0xFFE63946),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('live_locations')
            .doc(widget.targetUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Konum bilgisi bulunamadı'));
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final isActive = data['isActive'] ?? false;
          final lat = (data['latitude'] ?? 0.0).toDouble();
          final lng = (data['longitude'] ?? 0.0).toDouble();
          if (!isActive) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Canlı konum paylaşımı sona erdi', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }
          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(lat, lng),
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.safenow.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(lat, lng),
                        width: 80,
                        height: 80,
                        child: GestureDetector(
                          onTap: () => _openGoogleMapsNavigation(lat, lng),
                          child: Column(
                            children: [
                              const Icon(Icons.location_pin, color: Color(0xFFE63946), size: 40),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE63946),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(widget.targetUserName, style: const TextStyle(color: Colors.white, fontSize: 10)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Navigasyon butonu
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: ElevatedButton.icon(
                  onPressed: () => _openGoogleMapsNavigation(lat, lng),
                  icon: const Icon(Icons.navigation),
                  label: const Text('Google Maps ile Yol Tarifi Al', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE63946),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

