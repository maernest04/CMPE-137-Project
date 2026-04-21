import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cmpe_137_study_space/services/auth_scope.dart';
import 'package:cmpe_137_study_space/services/auth_service.dart';
import 'package:cmpe_137_study_space/widgets/profile_my_reviews_section.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _majorController = TextEditingController();
  bool _isLoginMode = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _majorController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = AuthScope.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter both email and password.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_isLoginMode) {
        await auth.signIn(email: email, password: password);
        _showMessage('Welcome back, $email!');
      } else {
        final name = _nameController.text.trim();
        final major = _majorController.text.trim();

        if (name.isEmpty || major.isEmpty) {
          _showMessage('Please enter your name and major.');
          return;
        }

        await auth.register(
          email: email,
          password: password,
          displayName: name,
          major: major,
        );
        _showMessage('Welcome, $name! Your account is ready.');
      }

      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      _majorController.clear();
    } catch (e) {
      _showMessage('Auth error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: auth.isSignedIn ? _buildProfileView(auth) : _buildAuthForm(),
      ),
    );
  }

  Widget _buildProfileView(AuthService authScope) {
    final email = authScope.userEmail ?? 'Unknown';
    final name = authScope.displayName ?? email.split('@').first;
    final major = authScope.major ?? 'Undeclared';
    final reviews = authScope.reviewCount;

    String initials() {
      final parts = name.split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return name.isNotEmpty ? name[0].toUpperCase() : '?';
    }

    return ListView(
      children: [
        const SizedBox(height: 24),
        CircleAvatar(
          radius: 50,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            initials(),
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          major,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Signed in as $email',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Text(
                  reviews.toString(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Reviews', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(width: 32),
            Column(
              children: [
                Icon(
                  Icons.school,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(height: 4),
                Text('Student', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'Your reviews',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        const ProfileMyReviewsSection(),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text('Sign Out'),
          onPressed: () async {
            try {
              await authScope.signOut();
              if (mounted) {
                context.go('/login');
              }
            } catch (e) {
              _showMessage('Error signing out: $e');
            }
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Tip: Use the filters on the Home tab to narrow down study spaces.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAuthForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Text(
          _isLoginMode ? 'Sign in' : 'Register',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Center(
          child: ToggleButtons(
            isSelected: [_isLoginMode, !_isLoginMode],
            onPressed: (index) {
              setState(() {
                _isLoginMode = index == 0;
              });
            },
            borderRadius: BorderRadius.circular(8),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Login'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Register'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        if (!_isLoginMode) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _majorController,
            decoration: const InputDecoration(
              labelText: 'Major',
              prefixIcon: Icon(Icons.school),
            ),
          ),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isLoginMode ? 'Sign in' : 'Create account'),
        ),
        const SizedBox(height: 16),
        const Text(
          'This app uses a mocked auth flow. There is no backend yet.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
