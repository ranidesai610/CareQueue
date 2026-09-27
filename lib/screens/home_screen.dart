
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'doctor_login_screen.dart';
import 'admin_login_screen.dart';

class HomeScreen extends StatelessWidget {
const HomeScreen({super.key});

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFFF5F8FC),
body: SafeArea(
child: Center(
child: SingleChildScrollView(
child: ConstrainedBox(
constraints: const BoxConstraints(maxWidth: 1100),
child: Padding(
padding: const EdgeInsets.all(30),
child: Column(
children: [
// Header
Row(
children: [
Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: Colors.blue.shade600,
borderRadius: BorderRadius.circular(14),
),
child: const Icon(
Icons.local_hospital,
color: Colors.white,
size: 30,
),
),
const SizedBox(width: 15),
const Text(
'CareQueue',
style: TextStyle(
fontSize: 28,
fontWeight: FontWeight.bold,
color: Color(0xFF16324F),
),
),
],
),

const SizedBox(height: 55),

// Welcome Section
Container(
width: double.infinity,
padding: const EdgeInsets.all(40),
decoration: BoxDecoration(
gradient: LinearGradient(
colors: [
Colors.blue.shade700,
Colors.blue.shade500,
],
),
borderRadius: BorderRadius.circular(28),
),
child: Column(
children: [
const Icon(
Icons.health_and_safety,
color: Colors.white,
size: 70,
),
const SizedBox(height: 20),
const Text(
'Smart Hospital Queue System',
textAlign: TextAlign.center,
style: TextStyle(
color: Colors.white,
fontSize: 36,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 15),
const Text(
'Book your appointment, get your queue token, '
'and track your waiting time easily.',
textAlign: TextAlign.center,
style: TextStyle(
color: Colors.white70,
fontSize: 17,
),
),

const SizedBox(height: 30),

// Login Buttons
Wrap(
spacing: 15,
runSpacing: 15,
alignment: WrapAlignment.center,
children: [
// Patient Login
ElevatedButton.icon(
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) =>
const LoginScreen(),
),
);
},
icon: const Icon(Icons.person),
label: const Text('Patient Login'),
style: ElevatedButton.styleFrom(
backgroundColor: Colors.white,
foregroundColor: Colors.blue.shade700,
padding: const EdgeInsets.symmetric(
horizontal: 25,
vertical: 17,
),
shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(12),
),
),
),

// Doctor Login
OutlinedButton.icon(
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) =>
const DoctorLoginScreen(),
),
);
},
icon: const Icon(
Icons.medical_services,
),
label: const Text('Doctor Login'),
style: OutlinedButton.styleFrom(
foregroundColor: Colors.white,
side: const BorderSide(
color: Colors.white,
width: 1.5,
),
padding: const EdgeInsets.symmetric(
horizontal: 25,
vertical: 17,
),
shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(12),
),
),
),

// Admin Login
OutlinedButton.icon(
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) =>
const AdminLoginScreen(),
),
);
},
icon: const Icon(
Icons.admin_panel_settings,
),
label: const Text('Admin Login'),
style: OutlinedButton.styleFrom(
foregroundColor: Colors.white,
side: const BorderSide(
color: Colors.white,
width: 1.5,
),
padding: const EdgeInsets.symmetric(
horizontal: 25,
vertical: 17,
),
shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(12),
),
),
),
],
),
],
),
),

const SizedBox(height: 40),

// Section Title
const Align(
alignment: Alignment.centerLeft,
child: Text(
'Everything you need',
style: TextStyle(
fontSize: 25,
fontWeight: FontWeight.bold,
color: Color(0xFF16324F),
),
),
),

const SizedBox(height: 20),

// Feature Cards
Wrap(
spacing: 20,
runSpacing: 20,
children: [
_featureCard(
Icons.confirmation_number_outlined,
'Get Queue Token',
'Get your digital token without standing in a long queue.',
),
_featureCard(
Icons.access_time,
'Track Your Queue',
'Know your current position and estimated waiting time.',
),
_featureCard(
Icons.calendar_month_outlined,
'Book Appointment',
'Choose a doctor and book your preferred appointment.',
),
_featureCard(
Icons.notifications_none,
'Live Notifications',
'Receive updates when your turn is approaching.',
),
],
),

const SizedBox(height: 40),

// Footer
const Text(
'Making hospital visits simpler and more organized.',
style: TextStyle(
color: Colors.grey,
fontSize: 14,
),
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

static Widget _featureCard(
IconData icon,
String title,
String description,
) {
return SizedBox(
width: 250,
child: Container(
padding: const EdgeInsets.all(24),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(18),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.06),
blurRadius: 15,
offset: const Offset(0, 6),
),
],
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: Colors.blue.shade50,
borderRadius: BorderRadius.circular(12),
),
child: Icon(
icon,
color: Colors.blue.shade700,
size: 28,
),
),
const SizedBox(height: 18),
Text(
title,
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
color: Color(0xFF16324F),
),
),
const SizedBox(height: 8),
Text(
description,
style: const TextStyle(
color: Colors.grey,
height: 1.5,
fontSize: 14,
),
),
],
),
),
);
}
}

