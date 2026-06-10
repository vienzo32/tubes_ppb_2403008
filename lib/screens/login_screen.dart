import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../utils/shared_pref_helper.dart';
import '../widgets/custom_button.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;
  bool _rememberMe = false;
  
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  final List<Map<String, String>> _demoAccounts = [
    {'email': 'test@animeport.com', 'password': '123456', 'role': 'Mahasiswa', 'name': 'Test User'},
    {'email': 'rina.dosen@animeport.com', 'password': '123456', 'role': 'Dosen', 'name': 'Rina'},
    {'email': 'maya.hrd@animeport.com', 'password': '123456', 'role': 'HRD', 'name': 'Maya'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _loadSavedData() async {
    final rememberMe = SharedPrefHelper.getRememberEmail();
    setState(() => _rememberMe = rememberMe);
    if (rememberMe) {
      final savedEmail = SharedPrefHelper.getSavedEmail();
      if (savedEmail.isNotEmpty) _emailController.text = savedEmail;
    }
  }

  bool _validateEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'Email tidak boleh kosong');
      return false;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _emailError = 'Email tidak valid');
      return false;
    }
    setState(() => _emailError = null);
    return true;
  }

  bool _validatePassword() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _passwordError = 'Password tidak boleh kosong');
      return false;
    }
    if (password.length < 6) {
      setState(() => _passwordError = 'Password minimal 6 karakter');
      return false;
    }
    setState(() => _passwordError = null);
    return true;
  }

  Future<void> _handleLogin() async {
    final isEmailValid = _validateEmail();
    final isPasswordValid = _validatePassword();
    if (!isEmailValid || !isPasswordValid) return;
    
    setState(() => _isLoading = true);
    final result = await ApiService.login(_emailController.text.trim(), _passwordController.text);
    setState(() => _isLoading = false);
    //sharedpreference di sini, di bawah ini
    if (result['success'] == true) {
      final user = result['user'];
      await SharedPrefHelper.setLoggedIn(true);
      await SharedPrefHelper.setUserId(user['id']);
      await SharedPrefHelper.setUserEmail(user['email']);
      await SharedPrefHelper.setUserName(user['name']);
      await SharedPrefHelper.setUserRole(user['role']);
      
      ref.read(authProvider.notifier).state = AuthState(
        isLoggedIn: true,
        userId: user['id'],
        userEmail: user['email'],
        userName: user['name'],
        userRole: user['role'],
      );
      
      if (_rememberMe) {
        await SharedPrefHelper.setRememberEmail(true);
        await SharedPrefHelper.setSavedEmail(_emailController.text.trim());
      } else {
        await SharedPrefHelper.setRememberEmail(false);
        await SharedPrefHelper.setSavedEmail('');
      }
      
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Email atau password salah!'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showNotAvailableSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur ini belum tersedia'), backgroundColor: AppColors.warning),
    );
  }

  void _fillDemoAccount(String email, String password) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
      _emailError = null;
      _passwordError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
                      ),
                      child: const Center(child: Icon(Icons.brush, size: 50, color: Colors.white)),
                    ),
                    const SizedBox(height: 20),
                    Text('AnimePort', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Text('Tunjukkan Karya Animemu ✨', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Text('Login', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text('Masuk untuk melanjutkan ke AnimePort', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                focusNode: _emailFocusNode,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onEditingComplete: () { _validateEmail(); FocusScope.of(context).requestFocus(_passwordFocusNode); },
                decoration: InputDecoration(
                  labelText: 'Email', hintText: 'contoh@gmail.com', errorText: _emailError,
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.textHint)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.textHint)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
                  labelStyle: GoogleFonts.poppins(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onEditingComplete: _handleLogin,
                decoration: InputDecoration(
                  labelText: 'Password', hintText: 'Masukkan password', errorText: _passwordError,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.textHint)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.textHint)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
                  labelStyle: GoogleFonts.poppins(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) => setState(() => _rememberMe = value ?? false),
                        activeColor: AppColors.primary, checkColor: Colors.white,
                      ),
                      Text('Ingat Saya', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                  TextButton(
                    onPressed: _showNotAvailableSnackbar,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                    child: Text('Lupa Password?', style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w500, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomButton(text: 'Login', onPressed: _handleLogin, isLoading: _isLoading, icon: Icons.login),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('atau login dengan', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12))),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: _showNotAvailableSnackbar,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!, width: 1),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 24, height: 24, decoration: const BoxDecoration(image: DecorationImage(image: NetworkImage('https://cdn-icons-png.flaticon.com/512/281/281764.png'), fit: BoxFit.contain))),
                        const SizedBox(width: 12),
                        Text('Lanjutkan dengan Google', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: isDark ? Colors.white : AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Belum punya akun? ', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                    child: Text('Daftar Sekarang', style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.1), AppColors.secondary.withValues(alpha: 0.05)]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.school, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Text('Akun Demo', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                            child: Text('Klik untuk isi otomatis', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.primary)),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 0, thickness: 1),
                    ..._demoAccounts.map((account) => _buildDemoAccountTile(
                      email: account['email']!, password: account['password']!, role: account['role']!, name: account['name']!,
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoAccountTile({required String email, required String password, required String role, required String name}) {
    return InkWell(
      onTap: () => _fillDemoAccount(email, password),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: _getRoleColor(role).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(role == 'Mahasiswa' ? Icons.person : (role == 'Dosen' ? Icons.school : Icons.business), size: 20, color: _getRoleColor(role)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: _getRoleColor(role), borderRadius: BorderRadius.circular(8)),
                        child: Text(role, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(email, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.copy, size: 14, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Mahasiswa': return Colors.blue;
      case 'Dosen': return Colors.green;
      case 'HRD': return Colors.orange;
      default: return Colors.grey;
    }
  }
}