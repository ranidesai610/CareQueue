import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookAppointmentScreen extends StatefulWidget {
const BookAppointmentScreen({super.key});

@override
State<BookAppointmentScreen> createState() =>
_BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
String selectedDepartment = 'General Medicine';
String selectedDoctor = 'Dr. Sharma';
String selectedDate = '25 September 2026';
String selectedTime = '10:30 AM';

bool appointmentBooked = false;
bool isBooking = false;

Future<void> bookAppointment() async {
final user = FirebaseAuth.instance.currentUser;

if (user == null) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Please login first.'),
),
);
return;
}

setState(() {
isBooking = true;
});

try {
// Get patient name from Firestore
String patientName = 'Patient';

final patientDoc = await FirebaseFirestore.instance
    .collection('patients')
    .doc(user.uid)
    .get();

if (patientDoc.exists) {
final patientData = patientDoc.data();

if (patientData != null &&
patientData['name'] != null &&
patientData['name'].toString().isNotEmpty) {
patientName = patientData['name'].toString();
}
}

// 1. Save appointment
await FirebaseFirestore.instance
    .collection('appointments')
    .add({
'patientId': user.uid,
'patientEmail': user.email ?? '',
'patientName': patientName,
'department': selectedDepartment,
'doctor': selectedDoctor,
'date': selectedDate,
'time': selectedTime,
'status': 'Booked',
'createdAt': FieldValue.serverTimestamp(),
});

// 2. Create admin notification
await FirebaseFirestore.instance
    .collection('notifications')
    .add({
'title': 'New Appointment',
'message':
'$patientName booked an appointment with $selectedDoctor in $selectedDepartment.',
'type': 'admin',
'adminEmail': '',
'isRead': false,
'createdAt': FieldValue.serverTimestamp(),
});

if (!mounted) return;

setState(() {
appointmentBooked = true;
isBooking = false;
});

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'Appointment saved successfully!',
),
backgroundColor: Colors.green,
),
);
} catch (e) {
if (!mounted) return;

setState(() {
isBooking = false;
});

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
'Error booking appointment: $e',
),
),
);
}
}

@override
Widget build(BuildContext context) {
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
'Book Appointment',
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
maxWidth: 700,
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
Icons.calendar_month_outlined,
color: Colors.white,
size: 42,
),
SizedBox(height: 15),
Text(
'Book Your Appointment',
style: TextStyle(
color: Colors.white,
fontSize: 25,
fontWeight: FontWeight.bold,
),
),
SizedBox(height: 8),
Text(
'Select your doctor, date and preferred time.',
style: TextStyle(
color: Colors.white70,
fontSize: 14,
),
),
],
),
),

const SizedBox(height: 25),

// Form
Container(
padding: const EdgeInsets.all(24),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(20),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.06),
blurRadius: 15,
offset: const Offset(0, 5),
),
],
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
// Department
const Text(
'Select Department',
style: TextStyle(
fontWeight: FontWeight.w600,
color: Color(0xFF334155),
),
),

const SizedBox(height: 8),

DropdownButtonFormField<String>(
value: selectedDepartment,
decoration: InputDecoration(
prefixIcon: const Icon(
Icons.local_hospital_outlined,
),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
),
items: const [
DropdownMenuItem(
value: 'General Medicine',
child: Text('General Medicine'),
),
DropdownMenuItem(
value: 'Cardiology',
child: Text('Cardiology'),
),
DropdownMenuItem(
value: 'Dermatology',
child: Text('Dermatology'),
),
DropdownMenuItem(
value: 'Orthopedics',
child: Text('Orthopedics'),
),
DropdownMenuItem(
value: 'Pediatrics',
child: Text('Pediatrics'),
),
],
onChanged: (value) {
setState(() {
selectedDepartment = value!;

if (selectedDepartment !=
'General Medicine') {
selectedDoctor = 'No doctor assigned';
} else {
selectedDoctor = 'Dr. Sharma';
}
});
},
),

const SizedBox(height: 20),

// Doctor
const Text(
'Select Doctor',
style: TextStyle(
fontWeight: FontWeight.w600,
color: Color(0xFF334155),
),
),

const SizedBox(height: 8),

DropdownButtonFormField<String>(
value: selectedDoctor,
decoration: InputDecoration(
prefixIcon: const Icon(
Icons.person_outline,
),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
),
items: [
DropdownMenuItem(
value: selectedDepartment ==
'General Medicine'
? 'Dr. Sharma'
    : 'No doctor assigned',
child: Text(
selectedDepartment ==
'General Medicine'
? 'Dr. Sharma'
    : 'No doctor assigned',
),
),
],
onChanged: (value) {
if (value == null) {
return;
}

setState(() {
selectedDoctor = value;
});
},
),

const SizedBox(height: 20),

// Date
const Text(
'Select Date',
style: TextStyle(
fontWeight: FontWeight.w600,
color: Color(0xFF334155),
),
),

const SizedBox(height: 8),

DropdownButtonFormField<String>(
value: selectedDate,
decoration: InputDecoration(
prefixIcon: const Icon(
Icons.calendar_today_outlined,
),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
),
items: const [
DropdownMenuItem(
value: '25 September 2026',
child: Text('25 September 2026'),
),
DropdownMenuItem(
value: '26 September 2026',
child: Text('26 September 2026'),
),
DropdownMenuItem(
value: '27 September 2026',
child: Text('27 September 2026'),
),
DropdownMenuItem(
value: '28 September 2026',
child: Text('28 September 2026'),
),
],
onChanged: (value) {
setState(() {
selectedDate = value!;
});
},
),

const SizedBox(height: 20),

// Time
const Text(
'Select Time',
style: TextStyle(
fontWeight: FontWeight.w600,
color: Color(0xFF334155),
),
),

const SizedBox(height: 8),

DropdownButtonFormField<String>(
value: selectedTime,
decoration: InputDecoration(
prefixIcon: const Icon(
Icons.access_time,
),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
),
items: const [
DropdownMenuItem(
value: '10:30 AM',
child: Text('10:30 AM'),
),
DropdownMenuItem(
value: '11:30 AM',
child: Text('11:30 AM'),
),
DropdownMenuItem(
value: '2:00 PM',
child: Text('2:00 PM'),
),
DropdownMenuItem(
value: '4:00 PM',
child: Text('4:00 PM'),
),
],
onChanged: (value) {
setState(() {
selectedTime = value!;
});
},
),

const SizedBox(height: 30),

// Book Button
SizedBox(
height: 52,
child: ElevatedButton.icon(
onPressed:
isBooking ? null : bookAppointment,
icon: isBooking
? const SizedBox(
width: 20,
height: 20,
child: CircularProgressIndicator(
strokeWidth: 2,
color: Colors.white,
),
)
    : const Icon(
Icons.calendar_month,
),
label: Text(
isBooking
? 'Booking...'
    : 'Book Appointment',
style: const TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
),
),
style: ElevatedButton.styleFrom(
backgroundColor: Colors.blue,
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(12),
),
),
),
),
],
),
),

const SizedBox(height: 25),

// Confirmation
if (appointmentBooked)
Container(
padding: const EdgeInsets.all(25),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(20),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.06),
blurRadius: 15,
offset: const Offset(0, 5),
),
],
),
child: Column(
children: [
const Icon(
Icons.check_circle,
color: Colors.green,
size: 55,
),

const SizedBox(height: 12),

const Text(
'Appointment Booked!',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 22,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 20),

Text(
selectedDepartment,
style: const TextStyle(
fontSize: 17,
fontWeight: FontWeight.w600,
),
),

const SizedBox(height: 6),

Text(
selectedDoctor,
style: const TextStyle(
color: Colors.grey,
),
),

const SizedBox(height: 6),

Text(
'$selectedDate • $selectedTime',
style: const TextStyle(
color: Colors.grey,
),
),

const SizedBox(height: 15),

const Text(
'Your appointment has been confirmed.',
textAlign: TextAlign.center,
style: TextStyle(
color: Colors.green,
fontWeight: FontWeight.w600,
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
