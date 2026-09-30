
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'queue_token_screen.dart';
import 'view_queue_screen.dart';
import 'my_history_screen.dart';
import 'notifications_screen.dart';

class PatientDashboard extends StatefulWidget {
const PatientDashboard({super.key});

@override
State<PatientDashboard> createState() =>
_PatientDashboardState();
}

class _PatientDashboardState
extends State<PatientDashboard> {
String patientName = 'Patient';

@override
void initState() {
super.initState();
loadPatientName();
}

Future<void> loadPatientName() async {
try {
User? user =
FirebaseAuth.instance.currentUser;

if (user != null) {
DocumentSnapshot patient =
await FirebaseFirestore.instance
    .collection('patients')
    .doc(user.uid)
    .get();

if (patient.exists) {
Map<String, dynamic> data =
patient.data()
as Map<String, dynamic>;

if (mounted) {
setState(() {
patientName =
data['name'] ?? 'Patient';
});
}
}
}
} catch (e) {
// Keep default name if Firestore data
// cannot be loaded.
}
}

Future<void> logoutUser() async {
await FirebaseAuth.instance.signOut();

if (!mounted) return;

Navigator.pop(context);
}

// --------------------------------------------------
// GET PATIENT QUEUE STATUS
// --------------------------------------------------

Widget buildQueueStatusCard() {
final user =
FirebaseAuth.instance.currentUser;

if (user == null) {
return _emptyQueueCard(
'Please login to view your queue.',
);
}

return StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
    .collection('queue_tokens')
    .where(
'patientId',
isEqualTo: user.uid,
)
    .snapshots(),
builder: (context, patientSnapshot) {
if (patientSnapshot.connectionState ==
ConnectionState.waiting) {
return _loadingQueueCard();
}

if (patientSnapshot.hasError) {
return _emptyQueueCard(
'Unable to load queue information.',
);
}

final patientDocuments =
patientSnapshot.data?.docs ?? [];

// Get active queue tokens belonging
// to this patient.
final activeTokens =
patientDocuments.where((doc) {
final data =
doc.data()
as Map<String, dynamic>;

final status =
data['status'] ?? 'Waiting';

return status == 'Waiting' ||
status == 'Serving';
}).toList();

// No active queue
if (activeTokens.isEmpty) {
return _noActiveQueueCard();
}

// Use the latest active token.
activeTokens.sort((a, b) {
final aData =
a.data()
as Map<String, dynamic>;

final bData =
b.data()
as Map<String, dynamic>;

final aToken =
_getTokenNumber(
aData['tokenNumber'],
);

final bToken =
_getTokenNumber(
bData['tokenNumber'],
);

return bToken.compareTo(aToken);
});

final patientTokenDoc =
activeTokens.first;

final patientData =
patientTokenDoc.data()
as Map<String, dynamic>;

final int patientToken =
_getTokenNumber(
patientData['tokenNumber'],
);

final String department =
patientData['department'] ??
'General Medicine';

final String doctor =
patientData['doctor'] ??
'Doctor';

final String status =
patientData['status'] ??
'Waiting';

// --------------------------------------------------
// GET ALL TOKENS FOR SAME DEPARTMENT
// --------------------------------------------------

return StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
    .collection('queue_tokens')
    .where(
'department',
isEqualTo: department,
)
    .snapshots(),
builder:
(context, queueSnapshot) {
if (queueSnapshot.connectionState ==
ConnectionState.waiting) {
return _loadingQueueCard();
}

if (queueSnapshot.hasError) {
return _emptyQueueCard(
'Unable to calculate queue position.',
);
}

final allDocuments =
queueSnapshot.data?.docs ?? [];

// Count waiting patients with a
// smaller token number.
int patientsAhead = 0;

int currentServingToken = 0;

for (final doc in allDocuments) {
final data =
doc.data()
as Map<String, dynamic>;

final int token =
_getTokenNumber(
data['tokenNumber'],
);

final String tokenStatus =
data['status'] ??
'Waiting';

// Current serving patient
if (tokenStatus == 'Serving') {
if (token >
currentServingToken) {
currentServingToken =
token;
}
}

// Patients ahead of current patient
if (token < patientToken &&
(tokenStatus == 'Waiting' ||
tokenStatus ==
'Serving')) {
patientsAhead++;
}
}

// If the patient is already serving,
// there are no patients ahead.
if (status == 'Serving') {
patientsAhead = 0;
}

// Estimate 5 minutes per patient.
final int estimatedMinutes =
patientsAhead * 5;

return _dynamicQueueCard(
tokenNumber: patientToken,
patientsAhead: patientsAhead,
estimatedMinutes:
estimatedMinutes,
status: status,
department: department,
doctor: doctor,
currentServingToken:
currentServingToken,
);
},
);
},
);
}

// --------------------------------------------------
// DYNAMIC QUEUE CARD
// --------------------------------------------------

Widget _dynamicQueueCard({
required int tokenNumber,
required int patientsAhead,
required int estimatedMinutes,
required String status,
required String department,
required String doctor,
required int currentServingToken,
}) {
String statusText;

if (status == 'Serving') {
statusText = 'It is your turn!';
} else {
statusText =
'$patientsAhead patient'
'${patientsAhead == 1 ? '' : 's'} '
'ahead of you';
}

String waitText;

if (status == 'Serving') {
waitText = 'Now';
} else if (estimatedMinutes == 0) {
waitText = 'Next';
} else {
waitText = '$estimatedMinutes min';
}

return Container(
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
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
const Text(
'Your Queue Status',
style: TextStyle(
color: Colors.white70,
fontSize: 15,
),
),

const SizedBox(height: 10),

Row(
mainAxisAlignment:
MainAxisAlignment.spaceBetween,
children: [
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
'Token #$tokenNumber',
style: const TextStyle(
color: Colors.white,
fontSize: 32,
fontWeight:
FontWeight.bold,
),
),

const SizedBox(height: 5),

Text(
statusText,
style: TextStyle(
color: status ==
'Serving'
? Colors.white
    : Colors.white70,
fontWeight:
status == 'Serving'
? FontWeight.bold
    : FontWeight.normal,
),
),

const SizedBox(height: 5),

Text(
'$department • $doctor',
style:
const TextStyle(
color: Colors.white70,
fontSize: 12,
),
),
],
),
),

const SizedBox(width: 15),

Container(
padding:
const EdgeInsets.symmetric(
horizontal: 16,
vertical: 12,
),
decoration: BoxDecoration(
color: Colors.white
    .withOpacity(0.15),
borderRadius:
BorderRadius.circular(12),
),
child: Column(
children: [
const Icon(
Icons.access_time,
color: Colors.white,
size: 25,
),

const SizedBox(height: 5),

Text(
waitText,
style:
const TextStyle(
color: Colors.white,
fontWeight:
FontWeight.bold,
),
),

Text(
status == 'Serving'
? 'Your Turn'
    : 'Estimated wait',
style:
const TextStyle(
color: Colors.white70,
fontSize: 11,
),
),
],
),
),
],
),

const SizedBox(height: 15),

// Current serving token
if (currentServingToken > 0)
Text(
'Currently serving: '
'Token #$currentServingToken',
style:
const TextStyle(
color: Colors.white70,
fontSize: 12,
),
),
],
),
);
}

// --------------------------------------------------
// LOADING CARD
// --------------------------------------------------

Widget _loadingQueueCard() {
return Container(
height: 170,
padding:
const EdgeInsets.all(25),
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
child: const Center(
child: CircularProgressIndicator(
color: Colors.white,
),
),
);
}

// --------------------------------------------------
// NO ACTIVE QUEUE
// --------------------------------------------------

Widget _noActiveQueueCard() {
return Container(
padding:
const EdgeInsets.all(25),
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
Icons.confirmation_number_outlined,
color: Colors.white,
size: 42,
),

SizedBox(width: 15),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
'Your Queue Status',
style: TextStyle(
color: Colors.white70,
fontSize: 15,
),
),

SizedBox(height: 6),

Text(
'No active queue token',
style: TextStyle(
color: Colors.white,
fontSize: 21,
fontWeight:
FontWeight.bold,
),
),

SizedBox(height: 4),

Text(
'Get a queue token to join a '
'department queue.',
style: TextStyle(
color: Colors.white70,
fontSize: 12,
),
),
],
),
),
],
),
);
}

// --------------------------------------------------
// EMPTY / ERROR CARD
// --------------------------------------------------

Widget _emptyQueueCard(
String message) {
return Container(
padding:
const EdgeInsets.all(25),
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
child: Text(
message,
style: const TextStyle(
color: Colors.white,
),
),
);
}

// --------------------------------------------------
// TOKEN NUMBER CONVERTER
// --------------------------------------------------

int _getTokenNumber(dynamic value) {
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

// --------------------------------------------------
// BUILD
// --------------------------------------------------

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor:
const Color(0xFFF5F8FC),

// --------------------------------------------------
// APP BAR
// --------------------------------------------------

appBar: AppBar(
backgroundColor:
Colors.white,

elevation: 0,

automaticallyImplyLeading:
false,

title: Row(
children: [
Container(
padding:
const EdgeInsets.all(8),
decoration:
BoxDecoration(
color:
Colors.blue.shade50,
borderRadius:
BorderRadius.circular(10),
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
fontWeight:
FontWeight.bold,
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
const PatientNotificationsScreen(),
),
);
},
icon: const Icon(
Icons.notifications_none,
color: Colors.black87,
),
tooltip: 'Notifications',
),

// Logout
IconButton(
onPressed: logoutUser,
icon: const Icon(
Icons.logout,
color: Colors.red,
),
tooltip: 'Logout',
),

const SizedBox(width: 8),

// Profile Icon
Padding(
padding:
const EdgeInsets.only(
right: 16,
),
child: CircleAvatar(
backgroundColor:
Colors.blue.shade100,
child: const Icon(
Icons.person,
color: Colors.blue,
),
),
),
],
),

// --------------------------------------------------
// BODY
// --------------------------------------------------

body:
SingleChildScrollView(
padding:
const EdgeInsets.all(24),
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
'$patientName 👋',
style:
const TextStyle(
fontSize: 28,
fontWeight:
FontWeight.bold,
color:
Color(0xFF1E293B),
),
),

const SizedBox(
height: 6,
),

const Text(
'Welcome back to CareQueue.',
style:
TextStyle(
fontSize: 15,
color: Colors.grey,
),
),

const SizedBox(
height: 25,
),

// --------------------------------------------------
// DYNAMIC QUEUE STATUS
// --------------------------------------------------

buildQueueStatusCard(),

const SizedBox(
height: 30,
),

// --------------------------------------------------
// QUICK ACTIONS TITLE
// --------------------------------------------------

const Text(
'Quick Actions',
style:
TextStyle(
fontSize: 21,
fontWeight:
FontWeight.bold,
color:
Color(0xFF1E293B),
),
),

const SizedBox(
height: 15,
),

// --------------------------------------------------
// QUICK ACTIONS
// --------------------------------------------------

LayoutBuilder(
builder:
(context,
constraints) {
int crossAxisCount = 3;

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

crossAxisSpacing:
15,

mainAxisSpacing:
15,

childAspectRatio:
1.8,

children: [
// Get Queue Token
_QuickActionCard(
icon: Icons
    .confirmation_number_outlined,

title:
'Get Queue Token',

subtitle:
'Join the queue',

color:
Colors.blue,

onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder:
(context) =>
const QueueTokenScreen(),
),
);
},
),

// View Queue
_QuickActionCard(
icon: Icons
    .people_outline,

title:
'View Queue',

subtitle:
'Track your position',

color:
Colors.orange,

onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder:
(context) =>
const ViewQueueScreen(),
),
);
},
),

// My History
_QuickActionCard(
icon:
Icons.history,

title:
'My History',

subtitle:
'Previous visits',

color:
Colors.purple,

onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder:
(context) =>
const MyHistoryScreen(),
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
),
);
}
}

// --------------------------------------------------
// QUICK ACTION CARD
// --------------------------------------------------

class _QuickActionCard
extends StatelessWidget {
final IconData icon;
final String title;
final String subtitle;
final Color color;
final VoidCallback onTap;

const _QuickActionCard({
required this.icon,
required this.title,
required this.subtitle,
required this.color,
required this.onTap,
});

@override
Widget build(
BuildContext context) {
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
color: Colors.black
    .withOpacity(0.05),
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

const SizedBox(
width: 12,
),

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

const SizedBox(
height: 4,
),

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

