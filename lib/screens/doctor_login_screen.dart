
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'doctor_dashboard.dart';

class DoctorLoginScreen extends StatefulWidget {
const DoctorLoginScreen({super.key});

@override
State<DoctorLoginScreen> createState() =>
_DoctorLoginScreenState();
}

class _DoctorLoginScreenState
extends State<DoctorLoginScreen> {
final TextEditingController emailController =
TextEditingController();

final TextEditingController passwordController =
TextEditingController();

bool isLoading = false;
bool hidePassword = true;

Future<void> doctorLogin() async {
final email = emailController.text.trim();
final password = passwordController.text.trim();

if (email.isEmpty || password.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'Please enter email and password.',
),
),
);
return;
}

setState(() {
isLoading = true;
});

try {
// --------------------------------------------
// FIREBASE AUTHENTICATION
// --------------------------------------------
final credential = await FirebaseAuth.instance
    .signInWithEmailAndPassword(
email: email,
password: password,
);

final user = credential.user;

if (user == null) {
throw Exception('Login failed.');
}

// --------------------------------------------
// CHECK DOCTOR IN FIRESTORE
// --------------------------------------------
final doctorSnapshot = await FirebaseFirestore
    .instance
    .collection('doctors')
    .where(
'email',
isEqualTo: email,
)
    .limit(1)
    .get();

if (doctorSnapshot.docs.isEmpty) {
await FirebaseAuth.instance.signOut();

if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'Doctor profile not found in Firebase.',
),
),
);
}

return;
}

final doctorData =
doctorSnapshot.docs.first.data();

final role = doctorData['role'];

// --------------------------------------------
// CHECK ROLE
// --------------------------------------------
if (role != 'Doctor') {
await FirebaseAuth.instance.signOut();

if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'This account is not registered as a doctor.',
),
),
);
}

return;
}

// --------------------------------------------
// LOGIN SUCCESS
// --------------------------------------------
if (mounted) {
Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (context) =>
const DoctorDashboard(),
),
);
}
} on FirebaseAuthException catch (e) {
String message =
'Login failed. Please try again.';

if (e.code == 'user-not-found') {
message = 'No account found with this email.';
} else if (e.code == 'wrong-password' ||
e.code == 'invalid-credential') {
message = 'Incorrect email or password.';
} else if (e.code == 'invalid-email') {
message = 'Please enter a valid email address.';
} else if (e.code == 'user-disabled') {
message = 'This doctor account has been disabled.';
}

if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(message),
),
);
}
} catch (e) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
'Error: $e',
),
),
);
}
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

appBar: AppBar(
backgroundColor: Colors.white,
elevation: 0,

leading: IconButton(
icon: const Icon(
Icons.arrow_back,
color: Colors.black87,
),
onPressed: () {
Navigator.pop(context);
},
),

title: const Text(
'Doctor Login',
style: TextStyle(
color: Colors.black87,
fontWeight: FontWeight.bold,
),
),
),

body: Center(
child: SingleChildScrollView(
padding: const EdgeInsets.all(24),

child: ConstrainedBox(
constraints: const BoxConstraints(
maxWidth: 450,
),

child: Container(
padding: const EdgeInsets.all(30),

decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(20),

boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.05),
blurRadius: 20,
offset: const Offset(0, 8),
),
],
),

child: Column(
crossAxisAlignment:
CrossAxisAlignment.stretch,

children: [

// ICON
Container(
width: 75,
height: 75,

decoration: BoxDecoration(
color: Colors.blue.shade50,
shape: BoxShape.circle,
),

child: const Icon(
Icons.medical_services,
color: Colors.blue,
size: 38,
),
),

const SizedBox(height: 20),

const Text(
'Doctor Login',
textAlign: TextAlign.center,

style: TextStyle(
fontSize: 26,
fontWeight: FontWeight.bold,
color: Color(0xFF1E293B),
),
),

const SizedBox(height: 8),

const Text(
'Login to manage your patient queue.',
textAlign: TextAlign.center,

style: TextStyle(
color: Colors.grey,
fontSize: 14,
),
),

const SizedBox(height: 30),

// EMAIL
const Text(
'Email',
style: TextStyle(
fontWeight: FontWeight.w600,
),
),

const SizedBox(height: 8),

TextField(
controller: emailController,

keyboardType:
TextInputType.emailAddress,

decoration: InputDecoration(
hintText: 'Enter doctor email',
prefixIcon: const Icon(
Icons.email_outlined,
),

border: OutlineInputBorder(
borderRadius:
BorderRadius.circular(12),
),
),
),

const SizedBox(height: 20),

// PASSWORD
const Text(
'Password',
style: TextStyle(
fontWeight: FontWeight.w600,
),
),

const SizedBox(height: 8),

TextField(
controller: passwordController,

obscureText: hidePassword,

decoration: InputDecoration(
hintText: 'Enter password',

prefixIcon: const Icon(
Icons.lock_outline,
),

suffixIcon: IconButton(
icon: Icon(
hidePassword
? Icons.visibility
    : Icons.visibility_off,
),

onPressed: () {
setState(() {
hidePassword =
!hidePassword;
});
},
),

border: OutlineInputBorder(
borderRadius:
BorderRadius.circular(12),
),
),
),

const SizedBox(height: 30),

// LOGIN BUTTON
SizedBox(
height: 52,

child: ElevatedButton(
onPressed:
isLoading ? null : doctorLogin,

style: ElevatedButton.styleFrom(
backgroundColor:
Colors.blue,

foregroundColor:
Colors.white,

shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(12),
),
),

child: isLoading
? const SizedBox(
width: 22,
height: 22,

child:
CircularProgressIndicator(
strokeWidth: 2,
color: Colors.white,
),
)
    : const Text(
'Login',
style: TextStyle(
fontSize: 16,
fontWeight:
FontWeight.bold,
),
),
),
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

