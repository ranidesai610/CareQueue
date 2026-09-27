
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorProfileScreen extends StatelessWidget {
const DoctorProfileScreen({super.key});

Future<Map<String, dynamic>?> getDoctorData() async {
User? user = FirebaseAuth.instance.currentUser;

if (user == null || user.email == null) {
return null;
}

QuerySnapshot snapshot = await FirebaseFirestore.instance
    .collection('doctors')
    .where('email', isEqualTo: user.email)
    .limit(1)
    .get();

if (snapshot.docs.isEmpty) {
return null;
}

return snapshot.docs.first.data() as Map<String, dynamic>;
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFFF5F8FC),
appBar: AppBar(
title: const Text('My Profile'),
backgroundColor: Colors.white,
foregroundColor: Colors.black87,
elevation: 0,
),
body: FutureBuilder<Map<String, dynamic>?>(
future: getDoctorData(),
builder: (context, snapshot) {
if (snapshot.connectionState == ConnectionState.waiting) {
return const Center(
child: CircularProgressIndicator(),
);
}

if (snapshot.hasError) {
return Center(
child: Text(
'Something went wrong.\n${snapshot.error}',
textAlign: TextAlign.center,
),
);
}

if (!snapshot.hasData || snapshot.data == null) {
return const Center(
child: Text(
'Doctor profile not found.',
style: TextStyle(fontSize: 18),
),
);
}

Map<String, dynamic> doctor = snapshot.data!;

String name = doctor['name'] ?? 'Doctor';
String department = doctor['department'] ?? 'Not available';
String email = doctor['email'] ?? 'Not available';
String role = doctor['role'] ?? 'doctor';

return Center(
child: SingleChildScrollView(
padding: const EdgeInsets.all(24),
child: ConstrainedBox(
constraints: const BoxConstraints(
maxWidth: 600,
),
child: Card(
elevation: 3,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(20),
),
child: Padding(
padding: const EdgeInsets.all(30),
child: Column(
children: [
CircleAvatar(
radius: 50,
backgroundColor: Colors.blue.shade50,
child: Icon(
Icons.medical_services,
size: 50,
color: Colors.blue.shade700,
),
),

const SizedBox(height: 20),

Text(
name,
style: const TextStyle(
fontSize: 26,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 8),

Text(
department,
style: TextStyle(
fontSize: 17,
color: Colors.grey.shade600,
),
),

const SizedBox(height: 30),

_profileRow(
Icons.person,
'Name',
name,
),

_profileRow(
Icons.local_hospital,
'Department',
department,
),

_profileRow(
Icons.email,
'Email',
email,
),

_profileRow(
Icons.verified_user,
'Role',
role,
),
],
),
),
),
),
),
);
},
),
);
}

Widget _profileRow(
IconData icon,
String title,
String value,
) {
return Container(
margin: const EdgeInsets.only(bottom: 15),
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: const Color(0xFFF7F9FC),
borderRadius: BorderRadius.circular(12),
),
child: Row(
children: [
Icon(
icon,
color: Colors.blue.shade700,
size: 25,
),

const SizedBox(width: 15),

Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
style: TextStyle(
fontSize: 13,
color: Colors.grey.shade600,
),
),
const SizedBox(height: 4),
Text(
value,
style: const TextStyle(
fontSize: 16,
fontWeight: FontWeight.w600,
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
