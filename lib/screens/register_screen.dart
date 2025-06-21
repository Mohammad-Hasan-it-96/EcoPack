import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lectures/main.dart' show themeNotifier;

import 'dart:convert';
import 'package:lectures/screens/home_screen.dart' as home;
import 'package:lectures/screens/login_screen.dart' as login;
import 'package:lectures/env.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _password = '';
  String _repeatPassword = '';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureRepeatPassword = true;
  final _storage = const FlutterSecureStorage();

  void _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final url = Uri.parse('${Env.apiBaseUrl}api/register');
      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': _name,
            'email': _email,
            'password': _password,
            'password_confirmation': _repeatPassword,
          }),
        );

        setState(() => _isLoading = false);

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          // Store the authentication token
          if (data['token'] != null) {
            await _storage.write(key: 'auth_token', value: data['token']);
          }

          // Registration successful, navigate to home
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const home.HomeScreen()),
          );
        } else {
          String errorMsg = 'Registration failed';
          try {
            final data = jsonDecode(response.body);
            if (data is Map && data.containsKey('message')) {
              errorMsg = data['message'];
            }
          } catch (_) {
            // If response is not JSON, use the raw body as error message
            errorMsg = response.body;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMsg)));
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo and Welcome Section
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Logo
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.secondary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.eco,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Welcome Text
                          Text(
                            'Создать аккаунт',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Присоединяйтесь к экологичному будущему',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // Name Field
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Имя',
                              prefixIcon: Icon(
                                Icons.person_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              hintText: 'Ваше имя',
                            ),
                            keyboardType: TextInputType.name,
                            validator: (value) =>
                                value != null && value.trim().isNotEmpty
                                    ? null
                                    : 'Введите имя',
                            onChanged: (value) => _name = value,
                          ),
                          const SizedBox(height: 20),

                          // Email Field
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Электронная почта',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              hintText: 'example@email.com',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                                value != null && value.contains('@')
                                    ? null
                                    : 'Введите корректный email',
                            onChanged: (value) => _email = value,
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Пароль',
                              prefixIcon: Icon(
                                Icons.lock_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: theme.colorScheme.primary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscurePassword,
                            validator: (value) => value != null &&
                                    value.length >= 8
                                ? null
                                : 'Пароль должен содержать минимум 8 символов',
                            onChanged: (value) => _password = value,
                          ),
                          const SizedBox(height: 20),

                          // Repeat Password Field
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Повторите пароль',
                              prefixIcon: Icon(
                                Icons.lock_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureRepeatPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: theme.colorScheme.primary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureRepeatPassword =
                                        !_obscureRepeatPassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscureRepeatPassword,
                            validator: (value) =>
                                value != null && value == _password
                                    ? null
                                    : 'Пароли не совпадают',
                            onChanged: (value) => _repeatPassword = value,
                          ),
                          const SizedBox(height: 32),

                          // Register Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 8,
                                shadowColor:
                                    theme.colorScheme.primary.withOpacity(0.3),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'Создать аккаунт',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'У вас уже есть аккаунт? ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const login.LoginScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Войти',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
