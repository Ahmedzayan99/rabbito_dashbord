import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rabbit_ecosystem_dashboard/core/config/app_config.dart';
import 'package:rabbit_ecosystem_dashboard/core/di/injection_container.dart';
import 'package:rabbit_ecosystem_dashboard/core/theme/app_theme.dart';
import 'package:rabbit_ecosystem_dashboard/features/auth/presentation/bloc/auth_bloc.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AuthBloc>(),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withOpacity(0.1),
                AppTheme.secondaryColor.withOpacity(0.1),
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingXl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingXxl),
                    child: BlocConsumer<AuthBloc, AuthState>(
                      listener: (context, state) {
                        if (state is AuthSuccess) {
                          // Navigate to dashboard
                          Navigator.of(context).pushReplacementNamed('/dashboard');
                        } else if (state is AuthFailure) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.message),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                        }
                      },
                      builder: (context, state) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo and Title
                            _buildHeader(),

                            const SizedBox(height: AppTheme.spacingXxl),

                            // Login Form
                            _buildLoginForm(context, state),

                            const SizedBox(height: AppTheme.spacingLg),

                            // Remember Me & Forgot Password
                            _buildOptions(),

                            const SizedBox(height: AppTheme.spacingXxl),

                            // Login Button
                            _buildLoginButton(context, state),

                            const SizedBox(height: AppTheme.spacingLg),

                            // Footer
                            _buildFooter(),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.admin_panel_settings,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Text(
          AppConfig.appName,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          'Admin Dashboard',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(BuildContext context, AuthState state) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter your email',
              prefixIcon: Icon(Icons.email),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(AppConfig.emailRegex).hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
            enabled: state is! AuthLoading,
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < AppConfig.minPasswordLength) {
                return 'Password must be at least ${AppConfig.minPasswordLength} characters';
              }
              return null;
            },
            enabled: state is! AuthLoading,
            onFieldSubmitted: (_) => _handleLogin(context),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return Row(
      children: [
        // Remember Me
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              onChanged: (value) {
                setState(() {
                  _rememberMe = value ?? false;
                });
              },
            ),
            Text(
              'Remember me',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),

        const Spacer(),

        // Forgot Password
        TextButton(
          onPressed: () {
            // TODO: Implement forgot password
          },
          child: Text(
            'Forgot password?',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(BuildContext context, AuthState state) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: state is AuthLoading ? null : () => _handleLogin(context),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
        child: state is AuthLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Sign In',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'Â© 2024 Rabbit Ecosystem. All rights reserved.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.textDisabled,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          'Version ${AppConfig.appVersion}',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.textDisabled,
          ),
        ),
      ],
    );
  }

  void _handleLogin(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    context.read<AuthBloc>().add(
          AuthLoginRequested(
            email: email,
            password: password,
            rememberMe: _rememberMe,
          ),
        );
  }
}
