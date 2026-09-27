
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientNotificationsScreen extends StatelessWidget {
const PatientNotificationsScreen({super.key});

// --------------------------------------------------
// MARK ONE NOTIFICATION AS READ
// --------------------------------------------------

Future<void> markAsRead(String documentId) async {
await FirebaseFirestore.instance
    .collection('notifications')
    .doc(documentId)
    .update({
'isRead': true,
});
}

// --------------------------------------------------
// MARK ALL NOTIFICATIONS AS READ
// --------------------------------------------------

Future<void> markAllAsRead(
List<QueryDocumentSnapshot> documents,
) async {
final batch =
FirebaseFirestore.instance.batch();

for (final doc in documents) {
batch.update(
doc.reference,
{
'isRead': true,
},
);
}

await batch.commit();
}

// --------------------------------------------------
// FORMAT DATE
// --------------------------------------------------

String formatDate(dynamic timestamp) {
if (timestamp == null) {
return '';
}

if (timestamp is Timestamp) {
final date = timestamp.toDate();

return '${date.day.toString().padLeft(2, '0')}/'
'${date.month.toString().padLeft(2, '0')}/'
'${date.year} '
'${date.hour.toString().padLeft(2, '0')}:'
'${date.minute.toString().padLeft(2, '0')}';
}

return '';
}

@override
Widget build(BuildContext context) {
final user =
FirebaseAuth.instance.currentUser;

// --------------------------------------------------
// USER NOT LOGGED IN
// --------------------------------------------------

if (user == null) {
return Scaffold(
appBar: AppBar(
title: const Text(
'Notifications',
),
),
body: const Center(
child: Text(
'Please login first.',
),
),
);
}

final String currentPatientId =
user.uid;

return Scaffold(
backgroundColor:
const Color(0xFFF5F8FC),

// --------------------------------------------------
// APP BAR
// --------------------------------------------------

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
'Notifications',
style: TextStyle(
color: Colors.black87,
fontWeight: FontWeight.bold,
),
),
),

// --------------------------------------------------
// NOTIFICATIONS
// --------------------------------------------------

body: StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
    .collection('notifications')
    .snapshots(),

builder: (context, snapshot) {
if (snapshot.connectionState ==
ConnectionState.waiting) {
return const Center(
child:
CircularProgressIndicator(),
);
}

if (snapshot.hasError) {
return Center(
child: Padding(
padding:
const EdgeInsets.all(20),
child: Text(
'Error loading notifications:\n'
'${snapshot.error}',
textAlign:
TextAlign.center,
),
),
);
}

final allDocuments =
snapshot.data?.docs ?? [];

// --------------------------------------------------
// FILTER ONLY CURRENT PATIENT'S NOTIFICATIONS
// --------------------------------------------------

final documents =
allDocuments.where((doc) {
final data =
doc.data()
as Map<String, dynamic>;

return data['patientId'] ==
currentPatientId;
}).toList();

// --------------------------------------------------
// SORT NEWEST FIRST
// --------------------------------------------------

documents.sort((a, b) {
final dataA =
a.data()
as Map<String, dynamic>;

final dataB =
b.data()
as Map<String, dynamic>;

final timestampA =
dataA['createdAt'];

final timestampB =
dataB['createdAt'];

if (timestampA is Timestamp &&
timestampB is Timestamp) {
return timestampB
    .compareTo(timestampA);
}

return 0;
});

// --------------------------------------------------
// NO NOTIFICATIONS
// --------------------------------------------------

if (documents.isEmpty) {
return const Center(
child: Column(
mainAxisAlignment:
MainAxisAlignment.center,

children: [
Icon(
Icons.notifications_none,
size: 70,
color: Colors.grey,
),

SizedBox(height: 15),

Text(
'No notifications yet',
style: TextStyle(
fontSize: 18,
fontWeight:
FontWeight.bold,
color: Colors.grey,
),
),

SizedBox(height: 5),

Text(
'Your notifications will appear here.',
style: TextStyle(
color: Colors.grey,
),
),
],
),
);
}

// --------------------------------------------------
// UNREAD NOTIFICATIONS
// --------------------------------------------------

final unreadDocuments =
documents.where((doc) {
final data =
doc.data()
as Map<String, dynamic>;

return data['isRead'] != true;
}).toList();

return Column(
children: [
// --------------------------------------------------
// HEADER
// --------------------------------------------------

Container(
margin:
const EdgeInsets.all(20),

padding:
const EdgeInsets.all(20),

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
BorderRadius.circular(18),
),

child: Row(
children: [
const Icon(
Icons.notifications_active,
color: Colors.white,
size: 38,
),

const SizedBox(
width: 15,
),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment
    .start,

children: [
const Text(
'Your Notifications',

style: TextStyle(
color:
Colors.white,
fontSize: 20,
fontWeight:
FontWeight.bold,
),
),

const SizedBox(
height: 5,
),

Text(
'${unreadDocuments.length} unread notification'
'${unreadDocuments.length == 1 ? '' : 's'}',

style:
const TextStyle(
color:
Colors.white70,
),
),
],
),
),

if (unreadDocuments
    .isNotEmpty)
TextButton(
onPressed: () {
markAllAsRead(
unreadDocuments,
);
},

child: const Text(
'Mark all read',
style:
TextStyle(
color:
Colors.white,
),
),
),
],
),
),

// --------------------------------------------------
// NOTIFICATION LIST
// --------------------------------------------------

Expanded(
child:
ListView.builder(
padding:
const EdgeInsets
    .symmetric(
horizontal: 20,
),

itemCount:
documents.length,

itemBuilder:
(context, index) {
final doc =
documents[index];

final data =
doc.data()
as Map<String,
dynamic>;

final String title =
(data['title'] ??
'Notification')
    .toString();

final String message =
(data['message'] ??
'')
    .toString();

final String type =
(data['type'] ??
'')
    .toString();

final bool isRead =
data['isRead'] ==
true;

final String date =
formatDate(
data['createdAt'],
);

// --------------------------------------------------
// ICON
// --------------------------------------------------

IconData icon;

if (title
    .toLowerCase()
    .contains(
'your turn',
)) {
icon =
Icons.directions_run;
} else if (title
    .toLowerCase()
    .contains(
'completed',
)) {
icon =
Icons.check_circle;
} else if (type ==
'appointment') {
icon =
Icons.calendar_month;
} else if (type ==
'queue') {
icon = Icons
    .confirmation_number;
} else {
icon =
Icons.notifications;
}

// --------------------------------------------------
// NOTIFICATION CARD
// --------------------------------------------------

return InkWell(
onTap: () {
if (!isRead) {
markAsRead(
doc.id,
);
}
},

child: Container(
margin:
const EdgeInsets
    .only(
bottom: 12,
),

padding:
const EdgeInsets
    .all(18),

decoration:
BoxDecoration(
color: isRead
? Colors.white
    : Colors
    .blue
    .shade50,

borderRadius:
BorderRadius
    .circular(
16,
),

border: isRead
? null
    : Border.all(
color: Colors
    .blue
    .shade100,
),

boxShadow: [
BoxShadow(
color: Colors
    .black
    .withOpacity(
0.04,
),

blurRadius: 8,

offset:
const Offset(
0,
3,
),
),
],
),

child: Row(
crossAxisAlignment:
CrossAxisAlignment
    .start,

children: [
// ICON
Container(
padding:
const EdgeInsets
    .all(
11,
),

decoration:
BoxDecoration(
color: Colors
    .blue
    .shade100,

shape:
BoxShape
    .circle,
),

child: Icon(
icon,

color:
Colors.blue,

size: 24,
),
),

const SizedBox(
width: 15,
),

// TEXT
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment
    .start,

children: [
Row(
children: [
Expanded(
child:
Text(
title,

style:
const TextStyle(
fontSize:
16,
fontWeight:
FontWeight.bold,
),
),
),

if (!isRead)
Container(
width:
9,
height:
9,

decoration:
const BoxDecoration(
color:
Colors.blue,
shape:
BoxShape.circle,
),
),
],
),

const SizedBox(
height: 6,
),

Text(
message,

style:
const TextStyle(
color:
Colors.grey,
height:
1.4,
),
),

if (date
    .isNotEmpty)
Padding(
padding:
const EdgeInsets
    .only(
top: 8,
),

child:
Text(
date,

style:
const TextStyle(
color:
Colors.grey,
fontSize:
12,
),
),
),
],
),
),
],
),
),
);
},
),
),
],
);
},
),
);
}
}
