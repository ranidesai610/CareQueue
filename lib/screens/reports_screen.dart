
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportsScreen extends StatelessWidget {
const ReportsScreen({super.key});

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFFF5F8FC),

appBar: AppBar(
backgroundColor: Colors.white,
elevation: 0,

iconTheme: const IconThemeData(
color: Colors.black87,
),

title: const Row(
children: [
Icon(
Icons.bar_chart_outlined,
color: Colors.blue,
),
SizedBox(width: 10),
Text(
'Reports',
style: TextStyle(
color: Colors.black87,
fontWeight: FontWeight.bold,
),
),
],
),
),

body: StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
    .collection('appointments')
    .snapshots(),

builder: (context, appointmentSnapshot) {
if (appointmentSnapshot.connectionState ==
ConnectionState.waiting) {
return const Center(
child: CircularProgressIndicator(),
);
}

if (appointmentSnapshot.hasError) {
return Center(
child: Text(
'Error loading reports: ${appointmentSnapshot.error}',
textAlign: TextAlign.center,
),
);
}

final appointmentDocs =
appointmentSnapshot.data?.docs ?? [];

int completedAppointments = 0;
int pendingAppointments = 0;
int cancelledAppointments = 0;

for (final doc in appointmentDocs) {
final data =
doc.data() as Map<String, dynamic>;

final status =
data['status']?.toString() ?? '';

if (status == 'Completed') {
completedAppointments++;
} else if (status == 'Pending') {
pendingAppointments++;
} else if (status == 'Cancelled') {
cancelledAppointments++;
}
}

return StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
    .collection('patients')
    .snapshots(),

builder: (context, patientSnapshot) {
if (patientSnapshot.connectionState ==
ConnectionState.waiting) {
return const Center(
child: CircularProgressIndicator(),
);
}

final patientDocs =
patientSnapshot.data?.docs ?? [];

return StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
    .collection('doctors')
    .snapshots(),

builder: (context, doctorSnapshot) {
if (doctorSnapshot.connectionState ==
ConnectionState.waiting) {
return const Center(
child: CircularProgressIndicator(),
);
}

final doctorDocs =
doctorSnapshot.data?.docs ?? [];

return StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
    .collection('queue_tokens')
    .snapshots(),

builder: (context, queueSnapshot) {
if (queueSnapshot.connectionState ==
ConnectionState.waiting) {
return const Center(
child: CircularProgressIndicator(),
);
}

final queueDocs =
queueSnapshot.data?.docs ?? [];

int completedQueue = 0;

for (final doc in queueDocs) {
final data =
doc.data()
as Map<String, dynamic>;

final status =
data['status']?.toString() ?? '';

if (status == 'Completed') {
completedQueue++;
}
}

return _buildReportPage(
context,
totalPatients: patientDocs.length,
totalDoctors: doctorDocs.length,
totalAppointments:
appointmentDocs.length,
completedVisits:
completedQueue,
completedAppointments:
completedAppointments,
pendingAppointments:
pendingAppointments,
cancelledAppointments:
cancelledAppointments,
);
},
);
},
);
},
);
},
),
);
}

Widget _buildReportPage(
BuildContext context, {
required int totalPatients,
required int totalDoctors,
required int totalAppointments,
required int completedVisits,
required int completedAppointments,
required int pendingAppointments,
required int cancelledAppointments,
}) {
return SingleChildScrollView(
child: Center(
child: ConstrainedBox(
constraints: const BoxConstraints(
maxWidth: 1100,
),

child: Padding(
padding: const EdgeInsets.all(30),

child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
const Text(
'Hospital Reports',
style: TextStyle(
fontSize: 28,
fontWeight: FontWeight.bold,
color: Color(0xFF16324F),
),
),

const SizedBox(height: 8),

const Text(
'View hospital activity and performance information.',
style: TextStyle(
fontSize: 16,
color: Colors.grey,
),
),

const SizedBox(height: 25),

// REPORT CARDS
Wrap(
spacing: 20,
runSpacing: 20,

children: [
_ReportCard(
title: 'Total Patients',
value: totalPatients.toString(),
icon: Icons.people_outline,
color: Colors.blue,
),

_ReportCard(
title: 'Appointments',
value: totalAppointments.toString(),
icon: Icons.calendar_month_outlined,
color: Colors.green,
),

_ReportCard(
title: 'Doctors',
value: totalDoctors.toString(),
icon: Icons.medical_services_outlined,
color: Colors.purple,
),

_ReportCard(
title: 'Completed Visits',
value: completedVisits.toString(),
icon: Icons.check_circle_outline,
color: Colors.orange,
),
],
),

const SizedBox(height: 35),

const Text(
'Daily Summary',
style: TextStyle(
fontSize: 22,
fontWeight: FontWeight.bold,
color: Color(0xFF16324F),
),
),

const SizedBox(height: 15),

Container(
width: double.infinity,
padding: const EdgeInsets.all(25),

decoration: BoxDecoration(
color: Colors.white,
borderRadius:
BorderRadius.circular(18),

boxShadow: [
BoxShadow(
color:
Colors.black.withOpacity(0.04),
blurRadius: 10,
offset:
const Offset(0, 4),
),
],
),

child: Column(
children: [
_SummaryRow(
title: 'Patients Registered',
value:
totalPatients.toString(),
),

const Divider(height: 25),

_SummaryRow(
title:
'Appointments Completed',
value:
completedAppointments
    .toString(),
),

const Divider(height: 25),

_SummaryRow(
title:
'Appointments Pending',
value:
pendingAppointments
    .toString(),
),

const Divider(height: 25),

_SummaryRow(
title:
'Appointments Cancelled',
value:
cancelledAppointments
    .toString(),
),
],
),
),

const SizedBox(height: 30),

Container(
width: double.infinity,
padding: const EdgeInsets.all(22),

decoration: BoxDecoration(
color: Colors.blue.shade50,
borderRadius:
BorderRadius.circular(18),
),

child: Row(
children: [
Icon(
Icons.info_outline,
color: Colors.blue.shade700,
size: 28,
),

const SizedBox(width: 15),

const Expanded(
child: Text(
'Report information is automatically updated from the hospital database.',
style: TextStyle(
color: Color(0xFF16324F),
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
),
);
}
}


// ------------------------------------------------------------
// REPORT CARD
// ------------------------------------------------------------

class _ReportCard extends StatelessWidget {
final String title;
final String value;
final IconData icon;
final Color color;

const _ReportCard({
required this.title,
required this.value,
required this.icon,
required this.color,
});

@override
Widget build(BuildContext context) {
return Container(
width: 250,

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
borderRadius:
BorderRadius.circular(12),
),

child: Icon(
icon,
color: color,
size: 28,
),
),

const SizedBox(width: 15),

Column(
crossAxisAlignment:
CrossAxisAlignment.start,

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


// ------------------------------------------------------------
// SUMMARY ROW
// ------------------------------------------------------------

class _SummaryRow extends StatelessWidget {
final String title;
final String value;

const _SummaryRow({
required this.title,
required this.value,
});

@override
Widget build(BuildContext context) {
return Row(
children: [
Expanded(
child: Text(
title,

style: const TextStyle(
fontSize: 16,
fontWeight: FontWeight.w500,
),
),
),

Text(
value,

style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
color: Colors.blue,
),
),
],
);
}
}

