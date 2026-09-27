
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageDepartmentsScreen extends StatelessWidget {
const ManageDepartmentsScreen({super.key});

// Hospital departments used in CareQueue
final List<Map<String, String>> departments = const [
{
'name': 'General Medicine',
'description': 'General health consultation and treatment',
},
{
'name': 'Cardiology',
'description': 'Heart and cardiovascular treatment',
},
{
'name': 'Dermatology',
'description': 'Skin, hair and nail treatment',
},
{
'name': 'Orthopedics',
'description': 'Bone, joint and muscle treatment',
},
{
'name': 'Pediatrics',
'description': 'Healthcare for children',
},
];

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
Icons.local_hospital_outlined,
color: Colors.blue,
),
SizedBox(width: 10),
Text(
'Manage Departments',
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
    .collection('doctors')
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
'Error loading departments: ${snapshot.error}',
textAlign: TextAlign.center,
),
);
}

final doctorDocs = snapshot.data?.docs ?? [];

// Count doctors for every department
final Map<String, int> doctorCounts = {};

for (final doc in doctorDocs) {
final data = doc.data() as Map<String, dynamic>;

final department =
data['department']?.toString() ?? '';

if (department.isNotEmpty) {
doctorCounts[department] =
(doctorCounts[department] ?? 0) + 1;
}
}

final totalDoctors = doctorDocs.length;

int activeDepartments = 0;

for (final department in departments) {
final name = department['name']!;
final doctorCount = doctorCounts[name] ?? 0;

if (doctorCount > 0) {
activeDepartments++;
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
'Departments',
style: TextStyle(
fontSize: 28,
fontWeight: FontWeight.bold,
color: Color(0xFF16324F),
),
),

const SizedBox(height: 8),

const Text(
'View and manage hospital departments.',
style: TextStyle(
fontSize: 16,
color: Colors.grey,
),
),

const SizedBox(height: 25),

// Summary cards
Wrap(
spacing: 20,
runSpacing: 20,

children: [
_SummaryCard(
title: 'Total Departments',
value: departments.length.toString(),
icon: Icons.business_outlined,
color: Colors.blue,
),

_SummaryCard(
title: 'Active Departments',
value: activeDepartments.toString(),
icon: Icons.check_circle_outline,
color: Colors.green,
),

_SummaryCard(
title: 'Total Doctors',
value: totalDoctors.toString(),
icon: Icons.people_outline,
color: Colors.purple,
),
],
),

const SizedBox(height: 30),

const Text(
'Department List',
style: TextStyle(
fontSize: 22,
fontWeight: FontWeight.bold,
color: Color(0xFF16324F),
),
),

const SizedBox(height: 15),

// Department list
Column(
children: departments.map((department) {
final name = department['name']!;
final description =
department['description']!;

final doctorCount =
doctorCounts[name] ?? 0;

final status =
doctorCount > 0
? 'Active'
    : 'No Doctors';

return _DepartmentCard(
name: name,
description: description,
doctors: doctorCount.toString(),
status: status,

onView: () {
showDialog(
context: context,

builder: (context) {
return AlertDialog(
title: Text(name),

content: Text(
'Department: $name\n\n'
'Description: $description\n\n'
'Doctors: $doctorCount\n\n'
'Status: $status',
),

actions: [
TextButton(
onPressed: () {
Navigator.pop(context);
},

child: const Text(
'Close',
),
),
],
);
},
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
}


// ------------------------------------------------------------
// SUMMARY CARD
// ------------------------------------------------------------

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


// ------------------------------------------------------------
// DEPARTMENT CARD
// ------------------------------------------------------------

class _DepartmentCard extends StatelessWidget {
final String name;
final String description;
final String doctors;
final String status;
final VoidCallback onView;

const _DepartmentCard({
required this.name,
required this.description,
required this.doctors,
required this.status,
required this.onView,
});

@override
Widget build(BuildContext context) {
final bool isActive = status == 'Active';

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
Container(
width: 60,
height: 60,

decoration: BoxDecoration(
color: Colors.blue.shade50,
borderRadius: BorderRadius.circular(15),
),

child: const Icon(
Icons.local_hospital_outlined,
color: Colors.blue,
size: 30,
),
),

const SizedBox(width: 18),

Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,

children: [
Text(
name,

style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 5),

Text(
description,

style: const TextStyle(
color: Colors.grey,
),
),

const SizedBox(height: 8),

Text(
'$doctors Doctors',

style: const TextStyle(
fontWeight: FontWeight.w500,
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
color: isActive
? Colors.green.shade50
    : Colors.orange.shade50,
borderRadius: BorderRadius.circular(20),
),

child: Text(
status,

style: TextStyle(
color: isActive
? Colors.green
    : Colors.orange,
fontWeight: FontWeight.bold,
),
),
),

const SizedBox(width: 15),

ElevatedButton(
onPressed: onView,

child: const Text('View'),
),
],
),
);
}
}
