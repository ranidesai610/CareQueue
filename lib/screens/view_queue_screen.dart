
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewQueueScreen extends StatelessWidget {
const ViewQueueScreen({super.key});

@override
Widget build(BuildContext context) {
final user = FirebaseAuth.instance.currentUser;

if (user == null) {
return const Scaffold(
body: Center(
child: Text('Please login first.'),
),
);
}

final queueRef = FirebaseFirestore.instance
    .collection('queue_tokens')
    .where('patientId', isEqualTo: user.uid);

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
'Your Queue Status',
style: TextStyle(
color: Colors.black87,
fontWeight: FontWeight.bold,
),
),
),

body: StreamBuilder<QuerySnapshot>(
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
'Error loading queue: ${snapshot.error}',
),
);
}

final documents = snapshot.data?.docs ?? [];

// Only show active queue tokens.
// Waiting and Serving are both active.
final activeTokens = documents.where((doc) {
final data =
doc.data() as Map<String, dynamic>;

final status = data['status'] ?? '';

return status == 'Waiting' ||
status == 'Serving';
}).toList();

if (activeTokens.isEmpty) {
return const Center(
child: Text(
'You are not currently in a queue.',
style: TextStyle(
fontSize: 16,
color: Colors.grey,
),
),
);
}

// Sort by token number
activeTokens.sort((a, b) {
final dataA =
a.data() as Map<String, dynamic>;

final dataB =
b.data() as Map<String, dynamic>;

final tokenA =
_getTokenNumber(dataA['tokenNumber']);

final tokenB =
_getTokenNumber(dataB['tokenNumber']);

return tokenA.compareTo(tokenB);
});

final myDocument = activeTokens.last;

final myData =
myDocument.data()
as Map<String, dynamic>;

final myToken =
_getTokenNumber(
myData['tokenNumber'],
);

final department =
myData['department'] ?? '';

final doctor =
myData['doctor'] ?? '';

final myStatus =
myData['status'] ?? 'Waiting';

// Find currently serving token
return StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
    .collection('queue_tokens')
    .where(
'department',
isEqualTo: department,
)
    .snapshots(),

builder: (context, queueSnapshot) {
if (queueSnapshot.connectionState ==
ConnectionState.waiting) {
return const Center(
child: CircularProgressIndicator(),
);
}

final allDocuments =
queueSnapshot.data?.docs ?? [];

int servingToken = 0;

int patientsAhead = 0;

for (final doc in allDocuments) {
final data =
doc.data()
as Map<String, dynamic>;

final token =
_getTokenNumber(
data['tokenNumber'],
);

final status =
data['status'] ?? '';

if (status == 'Serving') {
if (token > servingToken) {
servingToken = token;
}
}

if (status == 'Waiting' &&
token < myToken) {
patientsAhead++;
}
}

int estimatedWait =
patientsAhead * 5;

double progress = 0;

if (myStatus == 'Serving') {
progress = 1;
} else if (myToken > 0 &&
servingToken > 0) {
progress =
servingToken / myToken;

if (progress > 0.9) {
progress = 0.9;
}
}

return SingleChildScrollView(
padding:
const EdgeInsets.all(24),

child: Center(
child: ConstrainedBox(
constraints:
const BoxConstraints(
maxWidth: 700,
),

child: Column(
children: [
const SizedBox(height: 10),

// Token Card
Container(
width: double.infinity,
padding:
const EdgeInsets.all(30),

decoration: BoxDecoration(
gradient:
const LinearGradient(
colors: [
Color(0xFF1976D2),
Color(0xFF42A5F5),
],
),

borderRadius:
BorderRadius.circular(24),
),

child: Column(
children: [
const Text(
'YOUR TOKEN',
style: TextStyle(
color:
Colors.white70,
fontSize: 14,
fontWeight:
FontWeight.w600,
letterSpacing: 1,
),
),

const SizedBox(height: 10),

Text(
'#$myToken',
style:
const TextStyle(
color: Colors.white,
fontSize: 60,
fontWeight:
FontWeight.bold,
),
),

const SizedBox(height: 10),

Text(
department,
style:
const TextStyle(
color: Colors.white,
fontSize: 18,
fontWeight:
FontWeight.w500,
),
),
],
),
),

const SizedBox(height: 25),

// Status
Container(
width: double.infinity,
padding:
const EdgeInsets.all(20),

decoration: BoxDecoration(
color: myStatus ==
'Serving'
? Colors.green.shade50
    : Colors.orange.shade50,

borderRadius:
BorderRadius.circular(18),
),

child: Row(
children: [
Icon(
myStatus ==
'Serving'
? Icons
    .check_circle
    : Icons
    .hourglass_top,

color: myStatus ==
'Serving'
? Colors.green
    : Colors.orange,

size: 32,
),

const SizedBox(width: 15),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
Text(
myStatus ==
'Serving'
? 'It is your turn!'
    : 'You are in the queue',

style:
TextStyle(
fontSize: 18,
fontWeight:
FontWeight.bold,
color: myStatus ==
'Serving'
? Colors.green
    : Colors
    .orange,
),
),

const SizedBox(height: 5),

Text(
myStatus ==
'Serving'
? 'Please proceed to the doctor.'
    : 'Please wait for your token to be called.',
style:
const TextStyle(
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

const SizedBox(height: 25),

// Doctor
_InfoCard(
icon:
Icons.medical_services,
title: 'Doctor',
value: doctor,
),

const SizedBox(height: 12),

// Serving Now
_InfoCard(
icon:
Icons.confirmation_number,
title: 'Serving Now',
value: servingToken == 0
? '--'
    : '#$servingToken',
),

const SizedBox(height: 12),

// Patients Ahead
_InfoCard(
icon: Icons.people,
title: 'Patients Ahead',
value:
myStatus == 'Serving'
? '0'
    : '$patientsAhead',
),

const SizedBox(height: 12),

// Estimated Wait
_InfoCard(
icon: Icons.access_time,
title: 'Estimated Wait',
value:
myStatus == 'Serving'
? 'Your turn'
    : '$estimatedWait min',
),

const SizedBox(height: 25),

// Progress
Container(
width: double.infinity,
padding:
const EdgeInsets.all(20),

decoration: BoxDecoration(
color: Colors.white,
borderRadius:
BorderRadius.circular(18),
),

child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
const Text(
'Queue Progress',
style: TextStyle(
fontSize: 16,
fontWeight:
FontWeight.bold,
),
),

const SizedBox(height: 12),

LinearProgressIndicator(
value: progress,
minHeight: 10,
borderRadius:
BorderRadius.circular(
10,
),
),

const SizedBox(height: 10),

Text(
myStatus == 'Serving'
? 'Your consultation is in progress.'
    : 'The queue is updating automatically.',
style:
const TextStyle(
color: Colors.grey,
fontSize: 13,
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

class _InfoCard extends StatelessWidget {
final IconData icon;
final String title;
final String value;

const _InfoCard({
required this.icon,
required this.title,
required this.value,
});

@override
Widget build(BuildContext context) {
return Container(
width: double.infinity,
padding: const EdgeInsets.all(18),

decoration: BoxDecoration(
color: Colors.white,
borderRadius:
BorderRadius.circular(16),

boxShadow: [
BoxShadow(
color:
Colors.black.withOpacity(0.04),
blurRadius: 10,
offset: const Offset(0, 3),
),
],
),

child: Row(
children: [
Container(
width: 45,
height: 45,

decoration: BoxDecoration(
color: Colors.blue.shade50,
borderRadius:
BorderRadius.circular(12),
),

child: Icon(
icon,
color: Colors.blue,
),
),

const SizedBox(width: 15),

Expanded(
child: Text(
title,
style: const TextStyle(
color: Colors.grey,
fontSize: 14,
),
),
),

Text(
value,
style: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 16,
color: Color(0xFF1E293B),
),
),
],
),
);
}
}

