
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class RegisterScreen extends StatefulWidget {
const RegisterScreen({super.key});

@override
State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
bool hidePassword = true;
bool hideConfirmPassword = true;
bool isLoading = false;

final TextEditingController nameController = TextEditingController();
final TextEditingController emailController = TextEditingController();
final TextEditingController phoneController = TextEditingController();
final TextEditingController passwordController = TextEditingController();
final TextEditingController confirmPasswordController =
TextEditingController();

Future<void> registerUser() async {
String name = nameController.text.trim();
String email = emailController.text.trim();
String phone = phoneController.text.trim();
String password = passwordController.text.trim();
String confirmPassword = confirmPasswordController.text.trim();

if (name.isEmpty ||
email.isEmpty ||
phone.isEmpty ||
password.isEmpty ||
confirmPassword.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Please fill all fields.'),
),
);
return;
}

if (password != confirmPassword) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Passwords do not match.'),
),
);
return;
}

if (password.length < 6) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Password must be at least 6 characters.'),
),
);
return;
}

setState(() {
isLoading = true;
});

try {
await FirebaseAuth.instance.createUserWithEmailAndPassword(
email: email,
password: password,
);
User? user = FirebaseAuth.instance.currentUser;

if (user != null) {
  await FirebaseFirestore.instance
      .collection('patients')
      .doc(user.uid)
      .set({
    'name': name,
    'email': email,
    'phone': phone,
    'role': 'patient',
    'createdAt': FieldValue.serverTimestamp(),
  });
}
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Account created successfully!'),
backgroundColor: Colors.green,
),
);

Navigator.pop(context);
} on FirebaseAuthException catch (e) {
String message = 'Registration failed.';

if (e.code == 'email-already-in-use') {
message = 'This email is already registered.';
} else if (e.code == 'invalid-email') {
message = 'Please enter a valid email address.';
} else if (e.code == 'weak-password') {
message = 'Password is too weak.';
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
nameController.dispose();
emailController.dispose();
phoneController.dispose();
passwordController.dispose();
confirmPasswordController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFFF5F8FC),
body: Center(
child: SingleChildScrollView(
child: Container(
width: 500,
margin: const EdgeInsets.all(25),
padding: const EdgeInsets.all(35),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(25),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.08),
blurRadius: 25,
offset: const Offset(0, 10),
),
],
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Center(
child: Container(
padding: const EdgeInsets.all(15),
decoration: BoxDecoration(
color: Colors.blue.shade50,
shape: BoxShape.circle,
),
child: Icon(
Icons.person_add_alt_1,
color: Colors.blue.shade700,
size: 42,
),
),
),
const SizedBox(height: 20),
const Center(
child: Text(
'Create Account',
style: TextStyle(
fontSize: 28,
fontWeight: FontWeight.bold,
color: Color(0xFF16324F),
),
),
),
const SizedBox(height: 8),
const Center(
child: Text(
'Register as a patient to manage your appointments',
textAlign: TextAlign.center,
style: TextStyle(
color: Colors.grey,
fontSize: 14,
),
),
),
const SizedBox(height: 30),

const Text(
'Full Name',
style: TextStyle(
fontWeight: FontWeight.w600,
color: Color(0xFF16324F),
),
),
const SizedBox(height: 8),
TextField(
controller: nameController,
decoration: InputDecoration(
hintText: 'Enter your full name',
prefixIcon: const Icon(Icons.person_outline),
filled: true,
fillColor: const Color(0xFFF5F8FC),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: BorderSide.none,
),
),
),

const SizedBox(height: 18),

const Text(
'Email',
style: TextStyle(
fontWeight: FontWeight.w600,
color: Color(0xFF16324F),
),
),
const SizedBox(height: 8),
TextField(
controller: emailController,
keyboardType: TextInputType.emailAddress,
decoration: InputDecoration(
hintText: 'Enter your email',
prefixIcon: const Icon(Icons.email_outlined),
filled: true,
fillColor: const Color(0xFFF5F8FC),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: BorderSide.none,
),
),
),

const SizedBox(height: 18),

const Text(
'Phone Number',
style: TextStyle(
fontWeight: FontWeight.w600,
color: Color(0xFF16324F),
),
),
const SizedBox(height: 8),
TextField(
controller: phoneController,
keyboardType: TextInputType.phone,
decoration: InputDecoration(
hintText: 'Enter your phone number',
prefixIcon: const Icon(Icons.phone_outlined),
filled: true,
fillColor: const Color(0xFFF5F8FC),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: BorderSide.none,
),
),
),

const SizedBox(height: 18),

const Text(
'Password',
style: TextStyle(
fontWeight: FontWeight.w600,
color: Color(0xFF16324F),
),
),
const SizedBox(height: 8),
TextField(
controller: passwordController,
obscureText: hidePassword,
decoration: InputDecoration(
hintText: 'Create a password',
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
filled: true,
fillColor: const Color(0xFFF5F8FC),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: BorderSide.none,
),
),
),

const SizedBox(height: 18),

const Text(
'Confirm Password',
style: TextStyle(
fontWeight: FontWeight.w600,
color: Color(0xFF16324F),
),
),
const SizedBox(height: 8),
TextField(
controller: confirmPasswordController,
obscureText: hideConfirmPassword,
decoration: InputDecoration(
hintText: 'Confirm your password',
prefixIcon: const Icon(Icons.lock_outline),
suffixIcon: IconButton(
icon: Icon(
hideConfirmPassword
? Icons.visibility_off
    : Icons.visibility,
),
onPressed: () {
setState(() {
hideConfirmPassword = !hideConfirmPassword;
});
},
),
filled: true,
fillColor: const Color(0xFFF5F8FC),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: BorderSide.none,
),
),
),

const SizedBox(height: 25),

SizedBox(
width: double.infinity,
child: ElevatedButton(
onPressed: isLoading ? null : registerUser,
style: ElevatedButton.styleFrom(
backgroundColor: Colors.blue.shade700,
foregroundColor: Colors.white,
padding: const EdgeInsets.symmetric(vertical: 17),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
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
'Create Account',
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
),
),
),
),

const SizedBox(height: 15),

Center(
child: TextButton(
onPressed: () {
Navigator.pop(context);
},
child: const Text('Already have an account? Login'),
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

