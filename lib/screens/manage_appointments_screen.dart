
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageAppointmentsScreen extends StatelessWidget {
const ManageAppointmentsScreen({super.key});

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFFF5F8FC),
appBar: AppBar(
backgroundColor: Colors.white,
elevation: 0,
title: const Row(
children: [
Icon(
Icons.calendar_month_outlined,
color: Colors.blue,
),
SizedBox(width: 10),
Text(
'Manage Appointments',
style: TextStyle(
color: Colors.black87,
fontWeight: FontWeight.bold,
),
),
],
),
iconTheme: const IconThemeData(
color: Colors.black87,
),
),
body: StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
    .collection('appointments')
    .orderBy('createdAt', descending: true)
    .snapshots(),
builder: (context, snapshot) {
if (snapshot.connectionState == ConnectionState.waiting) {
return const Center(
child: CircularProgressIndicator(),
);
}

if (snapshot.hasError) {
return Center(
child: Text(
'Error loading appointments',
style: TextStyle(
color: Colors.red.shade700,
fontSize: 16,
),
),
);
}

final appointments = snapshot.data?.docs ?? [];

int confirmed = 0;
int pending = 0;
int cancelled = 0;

for (final appointment in appointments) {
final data =
appointment.data() as Map<String, dynamic>;

final String status =
data['status'] ?? '';

if (status == 'Confirmed' || status == 'Booked') {
confirmed++;
} else if (status == 'Pending') {
pending++;
} else if (status == 'Cancelled') {
cancelled++;
}
}

return SingleChildScrollView(
child: Center(
child: ConstrainedBox(
constraints: const BoxConstraints(
maxWidth: 1100,
),
child: Padding(
padding: const EdgeInsets.all(30),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Appointments',
style: TextStyle(
fontSize: 28,
fontWeight: FontWeight.bold,
color: Color(0xFF16324F),
),
),

const SizedBox(height: 25),

Wrap(
spacing: 20,
runSpacing: 20,
children: [
_SummaryCard(
title: 'Total',
value: appointments.length.toString(),
icon: Icons.calendar_month,
color: Colors.blue,
),
_SummaryCard(
title: 'Confirmed',
value: confirmed.toString(),
icon: Icons.check_circle,
color: Colors.green,
),
_SummaryCard(
title: 'Pending',
value: pending.toString(),
icon: Icons.pending_actions,
color: Colors.orange,
),
_SummaryCard(
title: 'Cancelled',
value: cancelled.toString(),
icon: Icons.cancel,
color: Colors.red,
),
],
),

const SizedBox(height: 30),

if (appointments.isEmpty)
Container(
width: double.infinity,
padding: const EdgeInsets.all(30),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(18),
),
child: const Column(
children: [
Icon(
Icons.calendar_month_outlined,
size: 60,
color: Colors.grey,
),
SizedBox(height: 15),
Text(
'No appointments found',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
],
),
)
else
Column(
children: appointments.map((appointment) {
final data = appointment.data()
as Map<String, dynamic>;

final String patient =
data['patientName'] ??
data['patientEmail'] ??
'Unknown Patient';

final String doctor =
data['doctor'] ?? 'Unknown Doctor';

final String department =
data['department'] ??
'Unknown Department';

final String date =
data['date'] ?? 'No date';

final String time =
data['time'] ?? 'No time';

final String status =
data['status'] ?? 'Pending';

return _AppointmentCard(
patient: patient,
doctor: doctor,
department: department,
date: date,
time: time,
status: status,
onView: () {
_showAppointmentDetails(
context,
patient,
doctor,
department,
date,
time,
status,
);
},
);
}).toList(),
),
],
),
),
),
),
);
},
),
);
}

void _showAppointmentDetails(
BuildContext context,
String patient,
String doctor,
String department,
String date,
String time,
String status,
) {
showDialog(
context: context,
builder: (context) {
return AlertDialog(
title: const Text(
'Appointment Details',
),
content: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('Patient: $patient'),
const SizedBox(height: 8),
Text('Doctor: $doctor'),
const SizedBox(height: 8),
Text('Department: $department'),
const SizedBox(height: 8),
Text('Date: $date'),
const SizedBox(height: 8),
Text('Time: $time'),
const SizedBox(height: 8),
Text('Status: $status'),
],
),
actions: [
TextButton(
onPressed: () {
Navigator.pop(context);
},
child: const Text('Close'),
),
],
);
},
);
}
}

class _SummaryCard extends StatelessWidget {
final String title;
final String value;
final IconData icon;
final Color color;

const _SummaryCard({
required this.title,
required this.value,
required this.icon,
required this.color,
});

@override
Widget build(BuildContext context) {
return Container(
width: 230,
padding: const EdgeInsets.all(22),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(18),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.05),
blurRadius: 12,
offset: const Offset(0, 5),
),
],
),
child: Row(
children: [
Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: color.withOpacity(0.1),
borderRadius: BorderRadius.circular(12),
),
child: Icon(
icon,
color: color,
size: 28,
),
),
const SizedBox(width: 15),
Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
value,
style: const TextStyle(
fontSize: 25,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 4),
Text(
title,
style: const TextStyle(
color: Colors.grey,
),
),
],
),
],
),
);
}
}

class _AppointmentCard extends StatelessWidget {
final String patient;
final String doctor;
final String department;
final String date;
final String time;
final String status;
final VoidCallback onView;

const _AppointmentCard({
required this.patient,
required this.doctor,
required this.department,
required this.date,
required this.time,
required this.status,
required this.onView,
});

@override
Widget build(BuildContext context) {
Color statusColor;

if (status == 'Confirmed' || status == 'Booked') {
statusColor = Colors.green;
} else if (status == 'Pending') {
statusColor = Colors.orange;
} else if (status == 'Cancelled') {
statusColor = Colors.red;
} else {
statusColor = Colors.blue;
}

return Container(
width: double.infinity,
margin: const EdgeInsets.only(bottom: 15),
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(18),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.04),
blurRadius: 10,
offset: const Offset(0, 4),
),
],
),
child: Row(
children: [
CircleAvatar(
radius: 25,
backgroundColor: Colors.blue.shade50,
child: Icon(
Icons.calendar_month,
color: Colors.blue.shade700,
),
),

const SizedBox(width: 18),

Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
patient,
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 6),
Text(
'$doctor • $department',
style: TextStyle(
color: Colors.blue.shade700,
fontWeight: FontWeight.w500,
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

Container(
padding: const EdgeInsets.symmetric(
horizontal: 12,
vertical: 7,
),
decoration: BoxDecoration(
color: statusColor.withOpacity(0.1),
borderRadius: BorderRadius.circular(20),
),
child: Text(
status,
style: TextStyle(
color: statusColor,
fontWeight: FontWeight.bold,
),
),
),

const SizedBox(width: 15),

IconButton(
onPressed: onView,
tooltip: 'View Details',
icon: const Icon(
Icons.visibility_outlined,
color: Colors.blue,
),
),
],
),
);
}
}

