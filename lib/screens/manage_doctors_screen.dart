
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageDoctorsScreen extends StatelessWidget {
const ManageDoctorsScreen({super.key});

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
Icons.medical_services_outlined,
color: Colors.blue,
),
SizedBox(width: 10),
Text(
'Manage Doctors',
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
'Error loading doctors',
style: TextStyle(
color: Colors.red.shade700,
fontSize: 16,
),
),
);
}

final doctors = snapshot.data?.docs ?? [];

int availableDoctors = 0;
int unavailableDoctors = 0;

for (final doctor in doctors) {
final data = doctor.data() as Map<String, dynamic>;

final status = data['status'] ?? 'Available';

if (status == 'Available') {
availableDoctors++;
} else {
unavailableDoctors++;
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
'Doctors',
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
title: 'Total Doctors',
value: doctors.length.toString(),
icon: Icons.medical_services,
color: Colors.blue,
),
_SummaryCard(
title: 'Available',
value: availableDoctors.toString(),
icon: Icons.check_circle,
color: Colors.green,
),
_SummaryCard(
title: 'Unavailable',
value: unavailableDoctors.toString(),
icon: Icons.cancel,
color: Colors.orange,
),
],
),

const SizedBox(height: 30),

if (doctors.isEmpty)
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
Icons.medical_services_outlined,
size: 60,
color: Colors.grey,
),
SizedBox(height: 15),
Text(
'No doctors found',
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
children: doctors.map((doctor) {
final data =
doctor.data() as Map<String, dynamic>;

final String name =
data['name'] ?? 'Unknown Doctor';

final String department =
data['department'] ?? 'No department';

final String email =
data['email'] ?? 'No email';

final String phone =
data['phone'] ?? 'No phone number';

final String status =
data['status'] ?? 'Available';

final String role =
data['role'] ?? 'doctor';

return _DoctorCard(
name: name,
department: department,
email: email,
phone: phone,
status: status,
role: role,
onView: () {
_showDoctorDetails(
context,
name,
department,
email,
phone,
status,
role,
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

void _showDoctorDetails(
BuildContext context,
String name,
String department,
String email,
String phone,
String status,
String role,
) {
showDialog(
context: context,
builder: (context) {
return AlertDialog(
title: Text(name),
content: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('Department: $department'),
const SizedBox(height: 8),
Text('Email: $email'),
const SizedBox(height: 8),
Text('Phone: $phone'),
const SizedBox(height: 8),
Text('Status: $status'),
const SizedBox(height: 8),
Text('Role: $role'),
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

class _DoctorCard extends StatelessWidget {
final String name;
final String department;
final String email;
final String phone;
final String status;
final String role;
final VoidCallback onView;

const _DoctorCard({
required this.name,
required this.department,
required this.email,
required this.phone,
required this.status,
required this.role,
required this.onView,
});

@override
Widget build(BuildContext context) {
final bool isAvailable = status == 'Available';

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
Icons.medical_services,
color: Colors.blue.shade700,
size: 26,
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
const SizedBox(height: 6),
Text(
department,
style: TextStyle(
color: Colors.blue.shade700,
fontWeight: FontWeight.w500,
),
),
const SizedBox(height: 4),
Text(
email,
style: const TextStyle(
color: Colors.grey,
),
),
const SizedBox(height: 4),
Text(
phone,
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
color: isAvailable
? Colors.green.shade50
    : Colors.orange.shade50,
borderRadius: BorderRadius.circular(20),
),
child: Text(
status,
style: TextStyle(
color: isAvailable ? Colors.green : Colors.orange,
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

