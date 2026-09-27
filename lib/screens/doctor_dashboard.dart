
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'doctor_login_screen.dart';
import 'doctor_profile_screen.dart';
import 'doctor_notifications_screen.dart';

class DoctorDashboard extends StatelessWidget {
const DoctorDashboard({super.key});

// --------------------------------------------------
// GET LOGGED-IN DOCTOR
// --------------------------------------------------

Future<Map<String, dynamic>?> getDoctorData() async {
final user = FirebaseAuth.instance.currentUser;

if (user == null) {
return null;
}

final snapshot = await FirebaseFirestore.instance
    .collection('doctors')
    .where(
'email',
isEqualTo: user.email,
)
    .limit(1)
    .get();

if (snapshot.docs.isEmpty) {
return null;
}

return snapshot.docs.first.data();
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
tooltip: 'Notifications',
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) =>
const DoctorNotificationsScreen(),
),
);
},
icon: const Icon(
Icons.notifications_none,
color: Colors.black87,
),
),

const SizedBox(width: 4),

// Doctor Profile
IconButton(
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) =>
const DoctorProfileScreen(),
),
);
},
icon: CircleAvatar(
backgroundColor: Colors.blue.shade100,
child: const Icon(
Icons.person,
color: Colors.blue,
),
),
),

// Logout
IconButton(
tooltip: 'Logout',
onPressed: () async {
final bool? confirmLogout =
await showDialog<bool>(
context: context,
builder: (context) {
return AlertDialog(
title: const Text('Logout'),
content: const Text(
'Are you sure you want to logout?',
),
actions: [
TextButton(
onPressed: () {
Navigator.pop(
context,
false,
);
},
child: const Text('Cancel'),
),

ElevatedButton(
onPressed: () {
Navigator.pop(
context,
true,
);
},
child: const Text('Logout'),
),
],
);
},
);

if (confirmLogout == true) {
await FirebaseAuth.instance.signOut();

if (!context.mounted) {
return;
}

Navigator.pushAndRemoveUntil(
context,
MaterialPageRoute(
builder: (context) =>
const DoctorLoginScreen(),
),
(route) => false,
);
}
},
icon: const Icon(
Icons.logout,
color: Colors.red,
),
),

const SizedBox(width: 12),
],
),

// --------------------------------------------------
// DOCTOR DATA
// --------------------------------------------------

body: FutureBuilder<Map<String, dynamic>?>(
future: getDoctorData(),

builder: (context, doctorSnapshot) {
if (doctorSnapshot.connectionState ==
ConnectionState.waiting) {
return const Center(
child: CircularProgressIndicator(),
);
}

if (doctorSnapshot.hasError) {
return Center(
child: Text(
'Error loading doctor: '
'${doctorSnapshot.error}',
),
);
}

final doctor = doctorSnapshot.data;

if (doctor == null) {
return const Center(
child: Text(
'Doctor information not found.',
style: TextStyle(
fontSize: 16,
color: Colors.grey,
),
),
);
}

// --------------------------------------------------
// DOCTOR DATA
// --------------------------------------------------

final String doctorName =
doctor['name'] ?? 'Doctor';

final String department =
doctor['department'] ??
'General Medicine';

final String email =
doctor['email'] ?? '';

// --------------------------------------------------
// QUEUE FOR THIS DOCTOR
// --------------------------------------------------

final queueRef = FirebaseFirestore.instance
    .collection('queue_tokens')
    .where(
'doctor',
isEqualTo: doctorName,
)
    .where(
'department',
isEqualTo: department,
);

return StreamBuilder<QuerySnapshot>(
stream: queueRef.snapshots(),

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
'Error loading queue: '
'${snapshot.error}',
),
);
}

final documents =
snapshot.data?.docs ?? [];

// --------------------------------------------------
// CONVERT FIRESTORE QUEUE DATA
// --------------------------------------------------

final queue = documents.map((doc) {
final data =
doc.data()
as Map<String, dynamic>;

return {
'id': doc.id,

'tokenNumber':
_getTokenNumber(
data['tokenNumber'],
),

'patientId':
data['patientId'] ?? '',

// IMPORTANT:
// Patient name is now stored directly
// inside queue_tokens.
'patientName':
data['patientName'] ??
'Patient',

'status':
data['status'] ??
'Waiting',

'createdAt':
data['createdAt'],
};
}).toList();

// Sort by token number
queue.sort(
(a, b) =>
(a['tokenNumber'] as int)
    .compareTo(
b['tokenNumber'] as int,
),
);

// --------------------------------------------------
// QUEUE COUNTS
// --------------------------------------------------

final waitingPatients = queue
    .where(
(patient) =>
patient['status'] ==
'Waiting',
)
    .toList();

final servingPatients = queue
    .where(
(patient) =>
patient['status'] ==
'Serving',
)
    .toList();

final completedPatients = queue
    .where(
(patient) =>
patient['status'] ==
'Completed',
)
    .toList();

String currentToken = '--';

if (servingPatients.isNotEmpty) {
currentToken =
'#${servingPatients.first['tokenNumber']}';
}

// --------------------------------------------------
// MAIN DOCTOR DASHBOARD
// --------------------------------------------------

return SingleChildScrollView(
padding: const EdgeInsets.all(24),

child: Center(
child: ConstrainedBox(
constraints:
const BoxConstraints(
maxWidth: 1100,
),

child: Column(
crossAxisAlignment:
CrossAxisAlignment.stretch,

children: [
// --------------------------------------------------
// GREETING
// --------------------------------------------------

Text(
'Good Morning, '
'$doctorName 👋',

style:
const TextStyle(
fontSize: 28,
fontWeight:
FontWeight.bold,
color:
Color(0xFF1E293B),
),
),

const SizedBox(height: 6),

const Text(
'Manage your patients and hospital queue.',

style: TextStyle(
fontSize: 15,
color: Colors.grey,
),
),

const SizedBox(height: 25),

// --------------------------------------------------
// DOCTOR INFORMATION
// --------------------------------------------------

Container(
padding:
const EdgeInsets.all(
25,
),

decoration:
BoxDecoration(
gradient:
const LinearGradient(
colors: [
Color(0xFF1976D2),
Color(0xFF42A5F5),
],
),

borderRadius:
BorderRadius.circular(
20,
),
),

child: Row(
children: [
Container(
width: 70,
height: 70,

decoration:
BoxDecoration(
color: Colors.white
    .withOpacity(
0.2,
),
shape:
BoxShape.circle,
),

child: const Icon(
Icons
    .medical_services,
color: Colors.white,
size: 38,
),
),

const SizedBox(width: 20),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment
    .start,

children: [
Text(
doctorName,

style:
const TextStyle(
color:
Colors.white,
fontSize: 24,
fontWeight:
FontWeight.bold,
),
),

const SizedBox(
height: 5,
),

Text(
department,

style:
const TextStyle(
color:
Colors.white70,
fontSize: 15,
),
),

const SizedBox(
height: 5,
),

Text(
email,

style:
const TextStyle(
color:
Colors.white,
fontSize: 13,
),
),

const SizedBox(
height: 5,
),

const Text(
'Available Today',

style:
TextStyle(
color:
Colors.white,
fontWeight:
FontWeight.w600,
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
// TODAY'S OVERVIEW
// --------------------------------------------------

const Text(
'Today\'s Overview',

style:
TextStyle(
fontSize: 21,
fontWeight:
FontWeight.bold,
color:
Color(0xFF1E293B),
),
),

const SizedBox(height: 15),

LayoutBuilder(
builder:
(context, constraints) {
int crossAxisCount = 4;

if (constraints
    .maxWidth <
800) {
crossAxisCount = 2;
}

if (constraints
    .maxWidth <
500) {
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
_StatCard(
icon: Icons
    .people_outline,

title:
'Patients Today',

value:
'${queue.length}',

color:
Colors.blue,
),

_StatCard(
icon: Icons
    .hourglass_empty_outlined,

title: 'Waiting',

value:
'${waitingPatients.length}',

color:
Colors.orange,
),

_StatCard(
icon: Icons
    .check_circle_outline,

title: 'Completed',

value:
'${completedPatients.length}',

color:
Colors.green,
),

_StatCard(
icon: Icons
    .confirmation_number_outlined,

title:
'Current Token',

value:
currentToken,

color:
Colors.purple,
),
],
);
},
),

const SizedBox(height: 30),

// --------------------------------------------------
// CURRENT QUEUE
// --------------------------------------------------

const Text(
'Current Queue',

style:
TextStyle(
fontSize: 21,
fontWeight:
FontWeight.bold,
color:
Color(0xFF1E293B),
),
),

const SizedBox(height: 15),

Container(
padding:
const EdgeInsets.all(
20,
),

decoration:
BoxDecoration(
color: Colors.white,

borderRadius:
BorderRadius.circular(
18,
),

boxShadow: [
BoxShadow(
color: Colors.black
    .withOpacity(
0.05,
),

blurRadius: 15,

offset:
const Offset(
0,
5,
),
),
],
),

child: queue.isEmpty
? const Padding(
padding:
EdgeInsets.all(
25,
),

child: Center(
child: Text(
'No patients in the queue.',

style:
TextStyle(
color:
Colors.grey,
fontSize: 15,
),
),
),
)
    : Column(
children: [
...queue.map(
(patient) {
final int token =
patient[
'tokenNumber'] as int;

final String status =
patient[
'status'] as String;

final String patientId =
patient[
'patientId'] as String;

// First try the name saved
// inside queue_tokens.
String patientName =
patient[
'patientName'] ??
'Patient';

Color statusColor =
Colors.orange;

if (status ==
'Serving') {
statusColor =
Colors.blue;
}

if (status ==
'Completed') {
statusColor =
Colors.green;
}

return Column(
children: [
// --------------------------------------------------
// PATIENT NAME
// --------------------------------------------------

FutureBuilder<
DocumentSnapshot>(
future:
patientName ==
'Patient'
? FirebaseFirestore
    .instance
    .collection(
'patients')
    .doc(
patientId)
    .get()
    : null,

builder: (
context,
patientSnapshot,
) {
String
finalPatientName =
patientName;

// Fallback to
// patients collection
// for old queue tokens.
if (finalPatientName ==
'Patient' &&
patientSnapshot
    .hasData &&
patientSnapshot
    .data!
    .exists) {
final patientData =
patientSnapshot
    .data!
    .data()
as Map<
String,
dynamic>;

finalPatientName =
(patientData[
'name'] ??
patientData[
'fullName'] ??
patientData[
'patientName'] ??
patientData[
'email'] ??
'Patient')
    .toString();
}

return _PatientQueueRow(
token:
'#$token',

name:
finalPatientName,

time:
'Queue Token',

status:
status,

statusColor:
statusColor,
);
},
),

if (patient !=
queue.last)
const Divider(),
],
);
},
),
],
),
),

const SizedBox(height: 30),

// --------------------------------------------------
// QUEUE CONTROLS
// --------------------------------------------------

const Text(
'Queue Controls',

style:
TextStyle(
fontSize: 21,
fontWeight:
FontWeight.bold,
color:
Color(0xFF1E293B),
),
),

const SizedBox(height: 15),

LayoutBuilder(
builder:
(context, constraints) {
int crossAxisCount = 2;

if (constraints
    .maxWidth <
600) {
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

childAspectRatio: 2.3,

children: [
// --------------------------------------------------
// CALL NEXT PATIENT
// --------------------------------------------------

_DoctorActionCard(
icon:
Icons.play_arrow,

title:
'Call Next Patient',

subtitle:
'Start the next consultation',

color:
Colors.blue,

onTap:
waitingPatients
    .isEmpty
? null
    : () async {
try {
// Complete current patient
if (servingPatients
    .isNotEmpty) {
final current =
servingPatients
    .first;

await FirebaseFirestore
    .instance
    .collection(
'queue_tokens',
)
    .doc(
current[
'id'],
)
    .update({
'status':
'Completed',
});
}

// Get next patient
final nextPatient =
waitingPatients
    .first;

final patientId =
nextPatient[
'patientId'];

// Waiting -> Serving
await FirebaseFirestore
    .instance
    .collection(
'queue_tokens',
)
    .doc(
nextPatient[
'id'],
)
    .update({
'status':
'Serving',
});

// Notification
await FirebaseFirestore
    .instance
    .collection(
'notifications',
)
    .add({
'patientId':
patientId,

'title':
'Your Turn',

'message':
'$doctorName is ready to see you. Please proceed to the consultation room.',

'type':
'queue',

'isRead':
false,

'createdAt':
FieldValue
    .serverTimestamp(),
});

if (context
    .mounted) {
ScaffoldMessenger
    .of(
context,
).showSnackBar(
SnackBar(
content:
Text(
'Token #${nextPatient['tokenNumber']} is now serving. Notification sent to the patient.',
),
),
);
}
} catch (e) {
if (context
    .mounted) {
ScaffoldMessenger
    .of(
context,
).showSnackBar(
SnackBar(
content:
Text(
'Error: $e',
),
),
);
}
}
},
),

// --------------------------------------------------
// COMPLETE PATIENT
// --------------------------------------------------

_DoctorActionCard(
icon: Icons
    .check_circle_outline,

title:
'Complete Patient',

subtitle:
'Mark current patient completed',

color:
Colors.green,

onTap:
servingPatients
    .isEmpty
? null
    : () async {
try {
final currentPatient =
servingPatients
    .first;

final patientId =
currentPatient[
'patientId'];

// Serving -> Completed
await FirebaseFirestore
    .instance
    .collection(
'queue_tokens',
)
    .doc(
currentPatient[
'id'],
)
    .update({
'status':
'Completed',
});

// Notification
await FirebaseFirestore
    .instance
    .collection(
'notifications',
)
    .add({
'patientId':
patientId,

'title':
'Visit Completed',

'message':
'Your consultation with $doctorName has been completed.',

'type':
'queue',

'isRead':
false,

'createdAt':
FieldValue
    .serverTimestamp(),
});

if (context
    .mounted) {
ScaffoldMessenger
    .of(
context,
).showSnackBar(
SnackBar(
content:
Text(
'Token #${currentPatient['tokenNumber']} completed. Notification sent to patient.',
),
),
);
}
} catch (e) {
if (context
    .mounted) {
ScaffoldMessenger
    .of(
context,
).showSnackBar(
SnackBar(
content:
Text(
'Error: $e',
),
),
);
}
}
},
),
],
);
},
),

const SizedBox(height: 30),

// --------------------------------------------------
// FIREBASE STATUS
// --------------------------------------------------

Container(
padding:
const EdgeInsets.all(
16,
),

decoration:
BoxDecoration(
color:
Colors.blue.shade50,

borderRadius:
BorderRadius.circular(
14,
),
),

child: const Row(
children: [
Icon(
Icons.sync,
color: Colors.blue,
),

SizedBox(width: 10),

Expanded(
child: Text(
'Queue updates automatically from Firebase.',

style: TextStyle(
color: Colors.blue,
fontWeight:
FontWeight.w500,
),
),
),
],
),
),
],
),
),
),
);
},
);
},
),
);
}

// --------------------------------------------------
// TOKEN NUMBER
// --------------------------------------------------

static int _getTokenNumber(dynamic value) {
if (value is int) {
return value;
}

if (value is double) {
return value.toInt();
}

if (value is String) {
return int.tryParse(value) ?? 0;
}

return 0;
}
}

// --------------------------------------------------
// STAT CARD
// --------------------------------------------------

class _StatCard extends StatelessWidget {
final IconData icon;
final String title;
final String value;
final Color color;

const _StatCard({
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

borderRadius:
BorderRadius.circular(16),

boxShadow: [
BoxShadow(
color:
Colors.black.withOpacity(0.05),

blurRadius: 12,

offset:
const Offset(0, 4),
),
],
),

child: Row(
children: [
Container(
width: 48,
height: 48,

decoration: BoxDecoration(
color:
color.withOpacity(0.1),

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
fontWeight:
FontWeight.bold,
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

// --------------------------------------------------
// PATIENT QUEUE ROW
// --------------------------------------------------

class _PatientQueueRow
extends StatelessWidget {
final String token;
final String name;
final String time;
final String status;
final Color statusColor;

const _PatientQueueRow({
required this.token,
required this.name,
required this.time,
required this.status,
required this.statusColor,
});

@override
Widget build(BuildContext context) {
return Padding(
padding:
const EdgeInsets.symmetric(
vertical: 12,
),

child: Row(
children: [
Container(
width: 55,
height: 55,

decoration:
BoxDecoration(
color:
Colors.blue.shade50,

borderRadius:
BorderRadius.circular(
12,
),
),

child: Center(
child: Text(
token,

style:
const TextStyle(
color: Colors.blue,
fontWeight:
FontWeight.bold,
),
),
),
),

const SizedBox(width: 15),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
Text(
name,

style:
const TextStyle(
fontWeight:
FontWeight.bold,
fontSize: 15,
),
),

const SizedBox(height: 4),

Text(
time,

style:
const TextStyle(
color: Colors.grey,
fontSize: 13,
),
),
],
),
),

Container(
padding:
const EdgeInsets.symmetric(
horizontal: 12,
vertical: 7,
),

decoration:
BoxDecoration(
color:
statusColor.withOpacity(
0.1,
),

borderRadius:
BorderRadius.circular(
20,
),
),

child: Text(
status,

style: TextStyle(
color: statusColor,
fontWeight:
FontWeight.w600,
fontSize: 12,
),
),
),
],
),
);
}
}

// --------------------------------------------------
// DOCTOR ACTION CARD
// --------------------------------------------------

class _DoctorActionCard
extends StatelessWidget {
final IconData icon;
final String title;
final String subtitle;
final Color color;
final VoidCallback? onTap;

const _DoctorActionCard({
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

borderRadius:
BorderRadius.circular(16),

child: Container(
padding:
const EdgeInsets.all(18),

decoration:
BoxDecoration(
color: Colors.white,

borderRadius:
BorderRadius.circular(16),

boxShadow: [
BoxShadow(
color:
Colors.black.withOpacity(
0.05,
),

blurRadius: 12,

offset:
const Offset(0, 4),
),
],
),

child: Row(
children: [
Container(
width: 48,
height: 48,

decoration:
BoxDecoration(
color:
color.withOpacity(
0.1,
),

borderRadius:
BorderRadius.circular(
12,
),
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
MainAxisAlignment
    .center,

crossAxisAlignment:
CrossAxisAlignment
    .start,

children: [
Text(
title,

style:
const TextStyle(
fontWeight:
FontWeight.bold,
fontSize: 14,
color:
Color(0xFF1E293B),
),
),

const SizedBox(height: 4),

Text(
subtitle,

style:
const TextStyle(
fontSize: 12,
color:
Colors.grey,
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
