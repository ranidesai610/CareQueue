
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'manage_patients_screen.dart';
import 'manage_doctors_screen.dart';
import 'queue_management_screen.dart';
import 'manage_departments_screen.dart';
import 'reports_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_login_screen.dart';

class AdminDashboard extends StatelessWidget {
const AdminDashboard({super.key});

// --------------------------------------------------
// GET FIREBASE COUNTS
// --------------------------------------------------

Future<Map<String, int>> getDashboardCounts() async {
final firestore = FirebaseFirestore.instance;

final patientsSnapshot =
await firestore.collection('patients').get();

final doctorsSnapshot =
await firestore.collection('doctors').get();

final queueSnapshot =
await firestore.collection('queue_tokens').get();

int activeQueue = 0;

for (final doc in queueSnapshot.docs) {
final data = doc.data();

final status = data['status'] ?? '';

if (status == 'Waiting' || status == 'Serving') {
activeQueue++;
}
}

return {
'patients': patientsSnapshot.docs.length,
'doctors': doctorsSnapshot.docs.length,
'activeQueue': activeQueue,
};
}

// --------------------------------------------------
// ADMIN LOGOUT
// --------------------------------------------------

Future<void> logout(BuildContext context) async {
await FirebaseAuth.instance.signOut();

if (context.mounted) {
Navigator.pushAndRemoveUntil(
context,
MaterialPageRoute(
builder: (context) => const AdminLoginScreen(),
),
(route) => false,
);
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFFF5F8FC),

// --------------------------------------------------
// APP BAR
// --------------------------------------------------

appBar: AppBar(
backgroundColor: Colors.white,
elevation: 0,
automaticallyImplyLeading: false,

title: Row(
children: [
Container(
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
color: Colors.blue.shade50,
borderRadius: BorderRadius.circular(10),
),
child: const Icon(
Icons.local_hospital,
color: Colors.blue,
),
),

const SizedBox(width: 10),

const Text(
'CareQueue',
style: TextStyle(
color: Colors.black87,
fontWeight: FontWeight.bold,
fontSize: 20,
),
),
],
),

actions: [
// Notifications
IconButton(
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) =>
const AdminNotificationsScreen(),
),
);
},
icon: const Icon(
Icons.notifications_none,
color: Colors.black87,
),
),

const SizedBox(width: 8),

// Admin Profile
Padding(
padding: const EdgeInsets.only(right: 8),
child: InkWell(
onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) =>
const AdminProfileScreen(),
),
);
},
borderRadius: BorderRadius.circular(30),
child: CircleAvatar(
backgroundColor: Colors.blue.shade100,
child: const Icon(
Icons.admin_panel_settings_outlined,
color: Colors.blue,
),
),
),
),

// Logout
IconButton(
tooltip: 'Logout',
onPressed: () {
logout(context);
},
icon: const Icon(
Icons.logout,
color: Colors.red,
),
),

const SizedBox(width: 8),
],
),

// --------------------------------------------------
// BODY
// --------------------------------------------------

body: FutureBuilder<Map<String, int>>(
future: getDashboardCounts(),

builder: (context, snapshot) {
if (snapshot.connectionState ==
ConnectionState.waiting) {
return const Center(
child: CircularProgressIndicator(),
);
}

if (snapshot.hasError) {
return Center(
child: Text(
'Error loading dashboard: '
'${snapshot.error}',
),
);
}

final counts = snapshot.data ??
{
'patients': 0,
'doctors': 0,
'activeQueue': 0,
};

return SingleChildScrollView(
padding: const EdgeInsets.all(24),

child: Center(
child: ConstrainedBox(
constraints: const BoxConstraints(
maxWidth: 1100,
),

child: Column(
crossAxisAlignment:
CrossAxisAlignment.stretch,

children: [
// --------------------------------------------------
// HEADING
// --------------------------------------------------

const Text(
'Admin Dashboard',
style: TextStyle(
fontSize: 28,
fontWeight: FontWeight.bold,
color: Color(0xFF1E293B),
),
),

const SizedBox(height: 6),

const Text(
'Manage hospital operations and monitor the queue system.',
style: TextStyle(
fontSize: 15,
color: Colors.grey,
),
),

const SizedBox(height: 25),

// --------------------------------------------------
// ADMIN OVERVIEW
// --------------------------------------------------

Container(
padding: const EdgeInsets.all(25),

decoration: BoxDecoration(
gradient: const LinearGradient(
colors: [
Color(0xFF1976D2),
Color(0xFF42A5F5),
],
),

borderRadius:
BorderRadius.circular(20),
),

child: const Row(
children: [
Icon(
Icons.admin_panel_settings_outlined,
color: Colors.white,
size: 50,
),

SizedBox(width: 20),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
Text(
'Hospital Administration',
style: TextStyle(
color: Colors.white,
fontSize: 24,
fontWeight:
FontWeight.bold,
),
),

SizedBox(height: 6),

Text(
'Monitor patients, doctors and queues.',
style: TextStyle(
color: Colors.white70,
),
),
],
),
),
],
),
),

const SizedBox(height: 30),

// --------------------------------------------------
// SYSTEM OVERVIEW
// --------------------------------------------------

const Text(
'System Overview',
style: TextStyle(
fontSize: 21,
fontWeight: FontWeight.bold,
color: Color(0xFF1E293B),
),
),

const SizedBox(height: 15),

LayoutBuilder(
builder: (context, constraints) {
int crossAxisCount = 3;

if (constraints.maxWidth < 700) {
crossAxisCount = 2;
}

if (constraints.maxWidth < 500) {
crossAxisCount = 1;
}

return GridView.count(
crossAxisCount:
crossAxisCount,

shrinkWrap: true,

physics:
const NeverScrollableScrollPhysics(),

crossAxisSpacing: 15,
mainAxisSpacing: 15,

childAspectRatio: 1.7,

children: [
_AdminStatCard(
icon: Icons.people_outline,
title: 'Total Patients',
value:
'${counts['patients']}',
color: Colors.blue,
),

_AdminStatCard(
icon:
Icons.medical_services_outlined,
title: 'Doctors',
value:
'${counts['doctors']}',
color: Colors.green,
),

_AdminStatCard(
icon:
Icons.confirmation_number_outlined,
title: 'Active Queue',
value:
'${counts['activeQueue']}',
color: Colors.purple,
),
],
);
},
),

const SizedBox(height: 30),

// --------------------------------------------------
// MANAGEMENT
// --------------------------------------------------

const Text(
'Management',
style: TextStyle(
fontSize: 21,
fontWeight: FontWeight.bold,
color: Color(0xFF1E293B),
),
),

const SizedBox(height: 15),

LayoutBuilder(
builder: (context, constraints) {
int crossAxisCount = 3;

if (constraints.maxWidth < 700) {
crossAxisCount = 2;
}

if (constraints.maxWidth < 500) {
crossAxisCount = 1;
}

return GridView.count(
crossAxisCount:
crossAxisCount,

shrinkWrap: true,

physics:
const NeverScrollableScrollPhysics(),

crossAxisSpacing: 15,
mainAxisSpacing: 15,

childAspectRatio: 2.1,

children: [
_AdminActionCard(
icon: Icons.people_outline,
title: 'Manage Patients',
subtitle:
'View registered patients',
color: Colors.blue,

onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) =>
const ManagePatientsScreen(),
),
);
},
),

_AdminActionCard(
icon:
Icons.medical_services_outlined,
title: 'Manage Doctors',
subtitle:
'View and manage doctors',
color: Colors.green,

onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) =>
const ManageDoctorsScreen(),
),
);
},
),

_AdminActionCard(
icon: Icons.queue_outlined,
title: 'Queue Management',
subtitle:
'Monitor live queues',
color: Colors.purple,

onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) =>
const QueueManagementScreen(),
),
);
},
),

_AdminActionCard(
icon:
Icons.local_hospital_outlined,
title: 'Departments',
subtitle:
'Manage departments',
color: Colors.teal,

onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) =>
const ManageDepartmentsScreen(),
),
);
},
),

_AdminActionCard(
icon: Icons.bar_chart,
title: 'Reports',
subtitle:
'View system reports',
color: Colors.indigo,

onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) =>
const ReportsScreen(),
),
);
},
),
],
);
},
),
],
),
),
),
);
},
),
);
}
}

// ==================================================
// STAT CARD
// ==================================================

class _AdminStatCard extends StatelessWidget {
final IconData icon;
final String title;
final String value;
final Color color;

const _AdminStatCard({
required this.icon,
required this.title,
required this.value,
required this.color,
});

@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.all(18),

decoration: BoxDecoration(
color: Colors.white,

borderRadius: BorderRadius.circular(16),

boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.05),
blurRadius: 12,
offset: const Offset(0, 4),
),
],
),

child: Row(
children: [
Container(
width: 48,
height: 48,

decoration: BoxDecoration(
color: color.withOpacity(0.1),
borderRadius:
BorderRadius.circular(12),
),

child: Icon(
icon,
color: color,
size: 25,
),
),

const SizedBox(width: 12),

Expanded(
child: Column(
mainAxisAlignment:
MainAxisAlignment.center,

crossAxisAlignment:
CrossAxisAlignment.start,

children: [
Text(
value,
style: TextStyle(
color: color,
fontSize: 22,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 4),

Text(
title,
style: const TextStyle(
fontSize: 12,
color: Colors.grey,
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

// ==================================================
// MANAGEMENT ACTION CARD
// ==================================================

class _AdminActionCard extends StatelessWidget {
final IconData icon;
final String title;
final String subtitle;
final Color color;
final VoidCallback onTap;

const _AdminActionCard({
required this.icon,
required this.title,
required this.subtitle,
required this.color,
required this.onTap,
});

@override
Widget build(BuildContext context) {
return InkWell(
onTap: onTap,

borderRadius: BorderRadius.circular(16),

child: Container(
padding: const EdgeInsets.all(18),

decoration: BoxDecoration(
color: Colors.white,

borderRadius: BorderRadius.circular(16),

boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.05),
blurRadius: 12,
offset: const Offset(0, 4),
),
],
),

child: Row(
children: [
Container(
width: 48,
height: 48,

decoration: BoxDecoration(
color: color.withOpacity(0.1),
borderRadius:
BorderRadius.circular(12),
),

child: Icon(
icon,
color: color,
size: 25,
),
),

const SizedBox(width: 12),

Expanded(
child: Column(
mainAxisAlignment:
MainAxisAlignment.center,

crossAxisAlignment:
CrossAxisAlignment.start,

children: [
Text(
title,
style: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 14,
color: Color(0xFF1E293B),
),
),

const SizedBox(height: 4),

Text(
subtitle,
style: const TextStyle(
fontSize: 12,
color: Colors.grey,
),
),
],
),
),
],
),
),
);
}
}
