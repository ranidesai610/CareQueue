
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorNotificationsScreen extends StatelessWidget {
const DoctorNotificationsScreen({super.key});

Future<void> markAsRead(String documentId) async {
await FirebaseFirestore.instance
    .collection('notifications')
    .doc(documentId)
    .update({
'isRead': true,
});
}

Future<void> markAllAsRead(
List<QueryDocumentSnapshot> documents) async {
final batch = FirebaseFirestore.instance.batch();

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

@override
Widget build(BuildContext context) {
final user = FirebaseAuth.instance.currentUser;

if (user == null) {
return Scaffold(
appBar: AppBar(
title: const Text('Notifications'),
),
body: const Center(
child: Text('Please login first.'),
),
);
}

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
'Doctor Notifications',
style: TextStyle(
color: Colors.black87,
fontWeight: FontWeight.bold,
),
),
),

body: StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
    .collection('notifications')
    .where(
'doctorEmail',
isEqualTo: user.email,
)
    .snapshots(),

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
'Error loading notifications: ${snapshot.error}',
),
);
}

final documents =
snapshot.data?.docs ?? [];

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
'New patient queue notifications will appear here.',
textAlign: TextAlign.center,
style: TextStyle(
color: Colors.grey,
),
),
],
),
);
}

final unreadDocuments =
documents.where((doc) {
final data =
doc.data()
as Map<String, dynamic>;

return data['isRead'] != true;
}).toList();

return Column(
children: [

// HEADER
Container(
margin:
const EdgeInsets.all(20),

padding:
const EdgeInsets.all(20),

decoration: BoxDecoration(
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

const SizedBox(width: 15),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [

const Text(
'Doctor Notifications',
style: TextStyle(
color: Colors.white,
fontSize: 20,
fontWeight:
FontWeight.bold,
),
),

const SizedBox(height: 5),

Text(
'${unreadDocuments.length} unread notification${unreadDocuments.length == 1 ? '' : 's'}',

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
style: TextStyle(
color: Colors.white,
),
),
),
],
),
),

// NOTIFICATION LIST
Expanded(
child:
ListView.builder(
padding:
const EdgeInsets.symmetric(
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
as Map<String, dynamic>;

final title =
data['title'] ??
'Notification';

final message =
data['message'] ?? '';

final isRead =
data['isRead'] == true;

return InkWell(
onTap: () {
if (!isRead) {
markAsRead(doc.id);
}
},

child: Container(
margin:
const EdgeInsets.only(
bottom: 12,
),

padding:
const EdgeInsets.all(
18,
),

decoration:
BoxDecoration(
color: isRead
? Colors.white
    : Colors.blue.shade50,

borderRadius:
BorderRadius.circular(
16,
),

border: isRead
? null
    : Border.all(
color: Colors
    .blue.shade100,
),

boxShadow: [
BoxShadow(
color: Colors.black
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

Container(
padding:
const EdgeInsets
    .all(11),

decoration:
BoxDecoration(
color: Colors
    .blue.shade100,
shape:
BoxShape.circle,
),

child:
const Icon(
Icons
    .person_add_alt_1,
color:
Colors.blue,
size: 24,
),
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

Row(
children: [

Expanded(
child: Text(
title,
style:
const TextStyle(
fontSize:
16,
fontWeight:
FontWeight
    .bold,
),
),
),

if (!isRead)
Container(
width: 9,
height: 9,

decoration:
const BoxDecoration(
color:
Colors.blue,
shape:
BoxShape
    .circle,
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
height: 1.4,
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

