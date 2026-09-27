
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyHistoryScreen extends StatelessWidget {
const MyHistoryScreen({super.key});

@override
Widget build(BuildContext context) {
final user = FirebaseAuth.instance.currentUser;

if (user == null) {
return Scaffold(
appBar: AppBar(
title: const Text('My History'),
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
'My History',
style: TextStyle(
color: Colors.black87,
fontWeight: FontWeight.bold,
),
),
),
body: SingleChildScrollView(
padding: const EdgeInsets.all(24),
child: Center(
child: ConstrainedBox(
constraints: const BoxConstraints(
maxWidth: 900,
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
// Header
Container(
padding: const EdgeInsets.all(25),
decoration: BoxDecoration(
gradient: const LinearGradient(
colors: [
Color(0xFF1976D2),
Color(0xFF42A5F5),
],
),
borderRadius: BorderRadius.circular(20),
),
child: const Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Icon(
Icons.history,
color: Colors.white,
size: 42,
),
SizedBox(height: 15),
Text(
'My History',
style: TextStyle(
color: Colors.white,
fontSize: 26,
fontWeight: FontWeight.bold,
),
),
SizedBox(height: 8),
Text(
'View your appointments and previous queue tokens.',
style: TextStyle(
color: Colors.white70,
fontSize: 14,
),
),
],
),
),

const SizedBox(height: 30),

// Appointments
const Text(
'Appointment History',
style: TextStyle(
fontSize: 21,
fontWeight: FontWeight.bold,
color: Color(0xFF1E293B),
),
),

const SizedBox(height: 12),

StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
    .collection('appointments')
    .where(
'patientId',
isEqualTo: user.uid,
)
    .snapshots(),
builder: (context, snapshot) {
if (snapshot.connectionState ==
ConnectionState.waiting) {
return const Center(
child: Padding(
padding: EdgeInsets.all(20),
child: CircularProgressIndicator(),
),
);
}

if (snapshot.hasError) {
return const _ErrorCard(
message:
'Unable to load appointments.',
);
}

final documents =
snapshot.data?.docs ?? [];

if (documents.isEmpty) {
return const _EmptyCard(
icon:
Icons.calendar_month_outlined,
message:
'No appointments found.',
);
}

return Column(
children: documents.map((doc) {
final data =
doc.data()
as Map<String, dynamic>;

return _AppointmentCard(
appointmentId: doc.id,
department:
data['department'] ?? '',
doctor: data['doctor'] ?? '',
date: data['date'] ?? '',
time: data['time'] ?? '',
status: data['status'] ?? '',
patientName:
data['patientName'] ??
'Patient',
);
}).toList(),
);
},
),

const SizedBox(height: 35),

// Queue History
const Text(
'Queue Token History',
style: TextStyle(
fontSize: 21,
fontWeight: FontWeight.bold,
color: Color(0xFF1E293B),
),
),

const SizedBox(height: 12),

StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
    .collection('queue_tokens')
    .where(
'patientId',
isEqualTo: user.uid,
)
    .snapshots(),
builder: (context, snapshot) {
if (snapshot.connectionState ==
ConnectionState.waiting) {
return const Center(
child: Padding(
padding: EdgeInsets.all(20),
child: CircularProgressIndicator(),
),
);
}

if (snapshot.hasError) {
return const _ErrorCard(
message:
'Unable to load queue history.',
);
}

final documents =
snapshot.data?.docs ?? [];

if (documents.isEmpty) {
return const _EmptyCard(
icon: Icons
    .confirmation_number_outlined,
message:
'No queue history found.',
);
}

return Column(
children: documents.map((doc) {
final data =
doc.data()
as Map<String, dynamic>;

return _QueueHistoryCard(
tokenNumber:
data['tokenNumber']
    ?.toString() ??
'-',
department:
data['department'] ?? '',
doctor: data['doctor'] ?? '',
visitType:
data['visitType'] ?? '',
status: data['status'] ?? '',
);
}).toList(),
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

// Appointment Card
class _AppointmentCard extends StatelessWidget {
final String appointmentId;
final String department;
final String doctor;
final String date;
final String time;
final String status;
final String patientName;

const _AppointmentCard({
required this.appointmentId,
required this.department,
required this.doctor,
required this.date,
required this.time,
required this.status,
required this.patientName,
});

Future<void> cancelAppointment(
BuildContext context,
) async {
try {
final user = FirebaseAuth.instance.currentUser;

if (user == null) {
return;
}

// Get the latest appointment data
final appointmentDoc =
await FirebaseFirestore.instance
    .collection('appointments')
    .doc(appointmentId)
    .get();

if (!appointmentDoc.exists) {
return;
}

final appointmentData =
appointmentDoc.data() as Map<String, dynamic>;

// Do not cancel an already cancelled appointment.
if (appointmentData['status'] == 'Cancelled') {
return;
}

// Update appointment status
await FirebaseFirestore.instance
    .collection('appointments')
    .doc(appointmentId)
    .update({
'status': 'Cancelled',
'cancelledAt': FieldValue.serverTimestamp(),
});

// Create admin notification
await FirebaseFirestore.instance
    .collection('notifications')
    .add({
'title': 'Appointment Cancelled',
'message':
'$patientName cancelled the appointment with '
'$doctor in $department.',
'patientName': patientName,
'patientId': user.uid,
'doctor': doctor,
'department': department,
'date': date,
'time': time,
'appointmentId': appointmentId,
'type': 'admin',
'adminEmail': '',
'isRead': false,
'createdAt': FieldValue.serverTimestamp(),
});

if (context.mounted) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'Appointment cancelled successfully.',
),
backgroundColor: Colors.green,
),
);
}
} catch (e) {
if (context.mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
'Unable to cancel appointment: $e',
),
backgroundColor: Colors.red,
),
);
}
}
}

Future<void> showCancelConfirmation(
BuildContext context,
) async {
final shouldCancel = await showDialog<bool>(
context: context,
builder: (dialogContext) {
return AlertDialog(
title: const Text('Cancel Appointment'),
content: Text(
'Are you sure you want to cancel your appointment with $doctor?',
),
actions: [
TextButton(
onPressed: () {
Navigator.pop(dialogContext, false);
},
child: const Text('No'),
),
ElevatedButton(
onPressed: () {
Navigator.pop(dialogContext, true);
},
style: ElevatedButton.styleFrom(
backgroundColor: Colors.red,
foregroundColor: Colors.white,
),
child: const Text('Yes, Cancel'),
),
],
);
},
);

if (shouldCancel == true) {
await cancelAppointment(context);
}
}

@override
Widget build(BuildContext context) {
final canCancel =
status != 'Cancelled' &&
status != 'Completed';

return Container(
margin: const EdgeInsets.only(bottom: 14),
padding: const EdgeInsets.all(18),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(16),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.05),
blurRadius: 10,
offset: const Offset(0, 4),
),
],
),
child: Column(
children: [
Row(
children: [
Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: Colors.blue.shade50,
borderRadius: BorderRadius.circular(12),
),
child: const Icon(
Icons.calendar_month,
color: Colors.blue,
size: 28,
),
),

const SizedBox(width: 15),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
department,
style: const TextStyle(
fontSize: 17,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 5),
Text(
doctor,
style: const TextStyle(
color: Colors.grey,
),
),
const SizedBox(height: 5),
Text(
'$date • $time',
style: const TextStyle(
color: Colors.grey,
),
),
],
),
),

_StatusBadge(status: status),
],
),

if (canCancel) ...[
const SizedBox(height: 15),

SizedBox(
width: double.infinity,
child: OutlinedButton.icon(
onPressed: () {
showCancelConfirmation(context);
},
icon: const Icon(
Icons.cancel_outlined,
color: Colors.red,
),
label: const Text(
'Cancel Appointment',
style: TextStyle(
color: Colors.red,
),
),
style: OutlinedButton.styleFrom(
side: const BorderSide(
color: Colors.red,
),
padding:
const EdgeInsets.symmetric(
vertical: 12,
),
shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(10),
),
),
),
),
],
],
),
);
}
}

// Queue History Card
class _QueueHistoryCard extends StatelessWidget {
final String tokenNumber;
final String department;
final String doctor;
final String visitType;
final String status;

const _QueueHistoryCard({
required this.tokenNumber,
required this.department,
required this.doctor,
required this.visitType,
required this.status,
});

@override
Widget build(BuildContext context) {
return Container(
margin: const EdgeInsets.only(bottom: 14),
padding: const EdgeInsets.all(18),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(16),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.05),
blurRadius: 10,
offset: const Offset(0, 4),
),
],
),
child: Row(
children: [
Container(
width: 55,
height: 55,
alignment: Alignment.center,
decoration: BoxDecoration(
color: Colors.blue.shade50,
borderRadius: BorderRadius.circular(14),
),
child: Text(
tokenNumber,
style: const TextStyle(
color: Colors.blue,
fontSize: 20,
fontWeight: FontWeight.bold,
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
department,
style: const TextStyle(
fontSize: 17,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 5),
Text(
doctor,
style: const TextStyle(
color: Colors.grey,
),
),
const SizedBox(height: 5),
Text(
visitType,
style: const TextStyle(
color: Colors.grey,
),
),
],
),
),

_StatusBadge(status: status),
],
),
);
}
}

// Status Badge
class _StatusBadge extends StatelessWidget {
final String status;

const _StatusBadge({
required this.status,
});

@override
Widget build(BuildContext context) {
Color backgroundColor;
Color textColor;

if (status == 'Completed') {
backgroundColor = Colors.green.shade50;
textColor = Colors.green;
} else if (status == 'Serving') {
backgroundColor = Colors.orange.shade50;
textColor = Colors.orange;
} else if (status == 'Cancelled') {
backgroundColor = Colors.red.shade50;
textColor = Colors.red;
} else {
backgroundColor = Colors.blue.shade50;
textColor = Colors.blue;
}

return Container(
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 6,
),
decoration: BoxDecoration(
color: backgroundColor,
borderRadius: BorderRadius.circular(20),
),
child: Text(
status,
style: TextStyle(
color: textColor,
fontSize: 12,
fontWeight: FontWeight.bold,
),
),
);
}
}

// Empty Card
class _EmptyCard extends StatelessWidget {
final IconData icon;
final String message;

const _EmptyCard({
required this.icon,
required this.message,
});

@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.all(25),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(16),
),
child: Column(
children: [
Icon(
icon,
size: 45,
color: Colors.grey,
),
const SizedBox(height: 10),
Text(
message,
style: const TextStyle(
color: Colors.grey,
fontSize: 15,
),
),
],
),
);
}
}

// Error Card
class _ErrorCard extends StatelessWidget {
final String message;

const _ErrorCard({
required this.message,
});

@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(
color: Colors.red.shade50,
borderRadius: BorderRadius.circular(16),
),
child: Text(
message,
style: const TextStyle(
color: Colors.red,
),
),
);
}
}

