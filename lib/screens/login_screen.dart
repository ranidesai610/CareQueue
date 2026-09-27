
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'register_screen.dart';
import 'patient_dashboard.dart';

class LoginScreen extends StatefulWidget {
const LoginScreen({super.key});

@override
State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
bool hidePassword = true;
bool isLoading = false;

final TextEditingController emailController = TextEditingController();
final TextEditingController passwordController = TextEditingController();

Future<void> loginUser() async {
String email = emailController.text.trim();
String password = passwordController.text.trim();

if (email.isEmpty || password.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Please enter email and password.'),
),
);
return;
}

setState(() {
isLoading = true;
});

try {
await FirebaseAuth.instance.signInWithEmailAndPassword(
email: email,
password: password,
);

if (!mounted) return;

Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (context) => const PatientDashboard(),
),
);
} on FirebaseAuthException catch (e) {
String message = 'Login failed.';

if (e.code == 'user-not-found' ||
e.code == 'invalid-credential') {
message = 'No account found with these login details.';
} else if (e.code == 'wrong-password') {
message = 'Incorrect password.';
} else if (e.code == 'invalid-email') {
message = 'Please enter a valid email address.';
} else if (e.code == 'user-disabled') {
message = 'This account has been disabled.';
}

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(message),
backgroundColor: Colors.red,
),
);
} catch (e) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Something went wrong. Please try again.'),
backgroundColor: Colors.red,
),
);
} finally {
if (mounted) {
setState(() {
isLoading = false;
});
}
}
}

@override
void dispose() {
emailController.dispose();
passwordController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFFF5F8FC),
body: Center(
child: SingleChildScrollView(
padding: const EdgeInsets.all(24),
child: ConstrainedBox(
constraints: const BoxConstraints(maxWidth: 450),
child: Container(
padding: const EdgeInsets.all(32),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(24),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.08),
blurRadius: 20,
offset: const Offset(0, 8),
),
],
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
Container(
width: 70,
height: 70,
decoration: BoxDecoration(
color: Colors.blue.shade50,
shape: BoxShape.circle,
),
child: const Icon(
Icons.local_hospital,
color: Colors.blue,
size: 38,
),
),

const SizedBox(height: 24),

const Text(
'Welcome Back!',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 30,
fontWeight: FontWeight.bold,
color: Color(0xFF1E293B),
),
),

const SizedBox(height: 8),

const Text(
'Login to continue to CareQueue',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 15,
color: Colors.grey,
),
),

const SizedBox(height: 32),

const Text(
'Email Address',
style: TextStyle(
fontWeight: FontWeight.w600,
color: Color(0xFF334155),
),
),

const SizedBox(height: 8),

TextField(
controller: emailController,
keyboardType: TextInputType.emailAddress,
decoration: InputDecoration(
hintText: 'Enter your email',
prefixIcon: const Icon(Icons.email_outlined),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: BorderSide(
color: Colors.grey.shade300,
),
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: const BorderSide(
color: Colors.blue,
width: 2,
),
),
),
),

const SizedBox(height: 20),

const Text(
'Password',
style: TextStyle(
fontWeight: FontWeight.w600,
color: Color(0xFF334155),
),
),

const SizedBox(height: 8),

TextField(
controller: passwordController,
obscureText: hidePassword,
decoration: InputDecoration(
hintText: 'Enter your password',
prefixIcon: const Icon(Icons.lock_outline),
suffixIcon: IconButton(
icon: Icon(
hidePassword
? Icons.visibility_off
    : Icons.visibility,
),
onPressed: () {
setState(() {
hidePassword = !hidePassword;
});
},
),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: BorderSide(
color: Colors.grey.shade300,
),
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: const BorderSide(
color: Colors.blue,
width: 2,
),
),
),
),

const SizedBox(height: 12),

Align(
alignment: Alignment.centerRight,
child: TextButton(
onPressed: () {},
child: const Text(
'Forgot Password?',
style: TextStyle(
color: Colors.blue,
fontWeight: FontWeight.w600,
),
),
),
),

const SizedBox(height: 12),

SizedBox(
height: 52,
child: ElevatedButton(
onPressed: isLoading ? null : loginUser,
style: ElevatedButton.styleFrom(
backgroundColor: Colors.blue,
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
elevation: 0,
),
child: isLoading
? const SizedBox(
height: 22,
width: 22,
child: CircularProgressIndicator(
color: Colors.white,
strokeWidth: 2,
),
)
    : const Text(
'Login',
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
),
),
),
),

const SizedBox(height: 24),

Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const Text(
"Don't have an account? ",
style: TextStyle(
color: Colors.grey,
),
),
TextButton(
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) =>
const RegisterScreen(),
),
);
},
child: const Text(
'Register',
style: TextStyle(
color: Colors.blue,
fontWeight: FontWeight.bold,
),
),
),
],
),

const SizedBox(height: 8),

TextButton.icon(
onPressed: () {
Navigator.pop(context);
},
icon: const Icon(Icons.arrow_back),
label: const Text('Back to Home'),
),
],
),
),
),
),
),
);
}
}

