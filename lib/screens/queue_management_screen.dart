
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QueueManagementScreen extends StatelessWidget {
const QueueManagementScreen({super.key});

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
Icons.queue_outlined,
color: Colors.blue,
),
SizedBox(width: 10),
Text(
'Queue Management',
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
    .collection('queue_tokens')
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
'Error loading queue: ${snapshot.error}',
textAlign: TextAlign.center,
),
);
}

final queueDocs = snapshot.data?.docs ?? [];

int waitingCount = 0;
int servingCount = 0;
int completedCount = 0;

String currentServingToken = '-';

for (final doc in queueDocs) {
final data = doc.data() as Map<String, dynamic>;

final status = data['status']?.toString() ?? '';

if (status == 'Waiting') {
waitingCount++;
} else if (status == 'Serving') {
servingCount++;

final tokenNumber = data['tokenNumber'];

if (tokenNumber != null) {
currentServingToken = '#$tokenNumber';
}
} else if (status == 'Completed') {
completedCount++;
}
}

// Show Waiting and Serving patients first.
final activeQueue = queueDocs.where((doc) {
final data = doc.data() as Map<String, dynamic>;
final status = data['status']?.toString() ?? '';

return status == 'Waiting' || status == 'Serving';
}).toList();

// Sort by token number.
activeQueue.sort((a, b) {
final dataA = a.data() as Map<String, dynamic>;
final dataB = b.data() as Map<String, dynamic>;

final tokenA =
int.tryParse(dataA['tokenNumber']?.toString() ?? '0') ?? 0;

final tokenB =
int.tryParse(dataB['tokenNumber']?.toString() ?? '0') ?? 0;

return tokenA.compareTo(tokenB);
});

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
'Live Queue',
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
title: 'Total Waiting',
value: waitingCount.toString(),
icon: Icons.people_outline,
color: Colors.blue,
),

_SummaryCard(
title: 'Currently Serving',
value: currentServingToken,
icon: Icons.play_circle_outline,
color: Colors.green,
),

_SummaryCard(
title: 'Completed',
value: completedCount.toString(),
icon: Icons.check_circle_outline,
color: Colors.purple,
),
],
),

const SizedBox(height: 30),

Container(
width: double.infinity,
padding: const EdgeInsets.all(22),

decoration: BoxDecoration(
color: Colors.blue.shade50,
borderRadius: BorderRadius.circular(18),
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
'The current queue is being managed by the hospital staff.',
style: TextStyle(
color: Color(0xFF16324F),
fontWeight: FontWeight.w500,
),
),
),
],
),
),

const SizedBox(height: 30),

const Text(
'Current Queue',
style: TextStyle(
fontSize: 22,
fontWeight: FontWeight.bold,
color: Color(0xFF16324F),
),
),

const SizedBox(height: 15),

if (activeQueue.isEmpty)
Container(
width: double.infinity,
padding: const EdgeInsets.all(35),

decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(18),
),

child: const Column(
children: [
Icon(
Icons.queue,
size: 50,
color: Colors.grey,
),

SizedBox(height: 15),

Text(
'No active patients in the queue.',
style: TextStyle(
fontSize: 17,
color: Colors.grey,
),
),
],
),
)
else
Column(
children: activeQueue.map((doc) {
final data =
doc.data() as Map<String, dynamic>;

final tokenNumber =
data['tokenNumber']?.toString() ?? '-';

final patientId =
data['patientId']?.toString() ?? '';

final doctor =
data['doctor']?.toString() ??
'Unknown Doctor';

final department =
data['department']?.toString() ??
'Unknown Department';

final status =
data['status']?.toString() ?? 'Waiting';

return _QueueCardWithPatient(
token: '#$tokenNumber',
patientId: patientId,
doctor: doctor,
department: department,
status: status,
queueDocumentId: doc.id,
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
// QUEUE CARD
// ------------------------------------------------------------

class _QueueCardWithPatient extends StatelessWidget {
final String token;
final String patientId;
final String doctor;
final String department;
final String status;
final String queueDocumentId;

const _QueueCardWithPatient({
required this.token,
required this.patientId,
required this.doctor,
required this.department,
required this.status,
required this.queueDocumentId,
});

Future<String> getPatientName() async {
if (patientId.isEmpty) {
return 'Unknown Patient';
}

final patientDoc = await FirebaseFirestore.instance
    .collection('patients')
    .doc(patientId)
    .get();

if (!patientDoc.exists) {
return 'Unknown Patient';
}

final data = patientDoc.data();

return data?['name']?.toString() ??
data?['patientName']?.toString() ??
data?['email']?.toString() ??
'Unknown Patient';
}

Future<void> updateQueueStatus(
BuildContext context,
String newStatus,
) async {
try {
final updateData = <String, dynamic>{
'status': newStatus,
};

if (newStatus == 'Completed') {
updateData['completedAt'] =
FieldValue.serverTimestamp();
}

await FirebaseFirestore.instance
    .collection('queue_tokens')
    .doc(queueDocumentId)
    .update(updateData);

if (!context.mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
'$token queue status updated to $newStatus.',
),
),
);
} catch (e) {
if (!context.mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
'Unable to update queue: $e',
),
),
);
}
}

@override
Widget build(BuildContext context) {
final bool isServing = status == 'Serving';

return FutureBuilder<String>(
future: getPatientName(),

builder: (context, snapshot) {
final patient =
snapshot.data ?? 'Loading patient...';

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
width: 65,
height: 65,

decoration: BoxDecoration(
color: isServing
? Colors.green.shade50
    : Colors.blue.shade50,
borderRadius: BorderRadius.circular(15),
),

child: Center(
child: Text(
token,
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
color: isServing
? Colors.green
    : Colors.blue,
),
),
),
),

const SizedBox(width: 18),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [
Text(
patient,
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 5),

Text(
'$doctor • $department',
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
color: isServing
? Colors.green.shade50
    : Colors.orange.shade50,
borderRadius: BorderRadius.circular(20),
),

child: Text(
status,
style: TextStyle(
color: isServing
? Colors.green
    : Colors.orange,
fontWeight: FontWeight.bold,
),
),
),

const SizedBox(width: 15),

ElevatedButton(
onPressed: () async {
if (status == 'Waiting') {
await updateQueueStatus(
context,
'Serving',
);
} else if (status == 'Serving') {
await updateQueueStatus(
context,
'Completed',
);
}
},

child: Text(
isServing ? 'Complete' : 'Serve',
),
),
],
),
);
},
);
}
}

