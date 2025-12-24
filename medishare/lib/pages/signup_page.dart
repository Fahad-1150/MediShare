import 'package:flutter/material.dart';
import 'login_page.dart';

enum UserRole { receiver, donor }

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  UserRole role = UserRole.receiver;
  bool loading = false;

  Future<void> handleSignup() async {
    setState(() => loading = true);

    await Future.delayed(const Duration(seconds: 1));

    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account created successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 30,
                    offset: const Offset(0, 16),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                 
                  const Text(
                    'MediShare',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Create an account to start your journey',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 36),

                  
                  isWide
                      ? Row(
                          children: [
                            Expanded(child: _nameField()),
                            const SizedBox(width: 16),
                            Expanded(child: _roleField()),
                          ],
                        )
                      : Column(
                          children: [
                            _nameField(),
                            const SizedBox(height: 16)
                           
                          ],
                        ),

                  const SizedBox(height: 16),

                  _emailField(),
                  const SizedBox(height: 16),

                  _phoneField(),
                  const SizedBox(height: 16),

                  _passwordField(),
                  const SizedBox(height: 28),

                  // Signup Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: loading ? null : handleSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                      ),
                      child: Text(
                        loading ? 'Creating Account...' : 'Sign Up',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,color: Colors.white
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: Colors.black54),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign in',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
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
    );
  }

 
  Widget _nameField() {
    return _field(
      label: 'Full Name',
      controller: _nameController,
      hint: 'Nazmul Haque',
    );
  }

  Widget _emailField() {
    return _field(
      label: 'Email Address',
      controller: _emailController,
      hint: 'example@medishare.org',
      keyboard: TextInputType.emailAddress,
    );
  }

  Widget _phoneField() {
    return _field(
      label: 'Phone Number',
      controller: _phoneController,
      hint: '+880 1...',
      keyboard: TextInputType.phone,
    );
  }

  Widget _passwordField() {
    return _field(
      label: 'Password',
      controller: _passwordController,
      hint: 'Create a strong password',
      obscure: true,
    );
  }

  Widget _roleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Role'),
        DropdownButtonFormField<UserRole>(
          value: role,
          decoration: _decoration(),
          items: const [
            DropdownMenuItem(
              value: UserRole.receiver,
              child: Text('Receiver (Needs Medicine)'),
            ),
            DropdownMenuItem(
              value: UserRole.donor,
              child: Text('Donor (Has Medicine)'),
            ),
          ],
          onChanged: (value) => setState(() => role = value!),
        ),
      ],
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          obscureText: obscure,
          decoration: _decoration(hint: hint),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }

  InputDecoration _decoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
    );
  }
}
