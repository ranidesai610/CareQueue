import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QueueTokenScreen extends StatefulWidget {
  const QueueTokenScreen({super.key});

  @override
  State<QueueTokenScreen> createState() => _QueueTokenScreenState();
}

class _QueueTokenScreenState extends State<QueueTokenScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final List<String> departments = [
    'General Medicine',
    'Cardiology',
    'Dermatology',
    'Orthopedics',
    'Pediatrics',
  ];

  String selectedDepartment = 'General Medicine';

  String? selectedDoctor;
  String? selectedDoctorEmail;

  bool isLoading = false;

// --------------------------------------------------
// GET CURRENT PATIENT ID
// --------------------------------------------------

  String get patientId {
    final user = FirebaseAuth.instance.currentUser;

    return user?.uid ?? '';


  }

// --------------------------------------------------
// GET DEPARTMENT ID
// --------------------------------------------------

  String getDepartmentId(String department) {
    return department.trim().toLowerCase().replaceAll(' ', '_');
  }

// --------------------------------------------------
// GET PATIENT NAME
// --------------------------------------------------

  Future<String> getPatientName() async {
    final user = FirebaseAuth.instance.currentUser;


    if (user == null) {
    throw Exception('No patient is logged in.');
    }

    final String currentPatientId = user.uid;

    final patientDoc = await firestore
        .collection('patients')
        .doc(currentPatientId)
        .get();

    if (!patientDoc.exists) {
    throw Exception(
    'Patient profile not found.\n'
    'Firebase UID: $currentPatientId',
    );
    }

    final patientData = patientDoc.data();

    if (patientData == null) {
    throw Exception('Patient profile is empty.');
    }

    final String patientName =
    patientData['name']?.toString().trim() ?? '';

    if (patientName.isEmpty) {
    throw Exception(
    'Patient name is missing in the patient profile.',
    );
    }

    return patientName;


  }

// --------------------------------------------------
// GENERATE QUEUE TOKEN
// --------------------------------------------------

  Future<void> generateToken() async {
    if (selectedDoctor == null || selectedDoctor!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a doctor'),
        ),
      );


    return;
    }

    if (patientId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
    content: Text('Please login as a patient first.'),
    ),
    );

    return;
    }

    setState(() {
    isLoading = true;
    });

    try {
    // --------------------------------------------------
    // GET ACTUAL PATIENT NAME
    // --------------------------------------------------

    final String patientName = await getPatientName();

    // --------------------------------------------------
    // DEPARTMENT ID
    // --------------------------------------------------

    final String departmentId =
    getDepartmentId(selectedDepartment);

    final DocumentReference counterRef = firestore
        .collection('queue_counters')
        .doc(departmentId);

    // --------------------------------------------------
    // GENERATE NEXT TOKEN NUMBER
    // --------------------------------------------------

    final int tokenNumber =
    await firestore.runTransaction<int>((transaction) async {
    final counterSnapshot =
    await transaction.get(counterRef);

    int lastToken = 0;

    if (counterSnapshot.exists) {
    final data =
    counterSnapshot.data() as Map<String, dynamic>;

    final dynamic savedLastToken = data['lastToken'];

    if (savedLastToken is int) {
    lastToken = savedLastToken;
    } else if (savedLastToken is double) {
    lastToken = savedLastToken.toInt();
    } else if (savedLastToken is String) {
    lastToken =
    int.tryParse(savedLastToken) ?? 0;
    }
    }

    final int newToken = lastToken + 1;

    transaction.set(
    counterRef,
    {
    'department': selectedDepartment,
    'lastToken': newToken,
    'updatedAt': FieldValue.serverTimestamp(),
    },
    SetOptions(merge: true),
    );

    return newToken;
    });

    // --------------------------------------------------
    // STORE PATIENT QUEUE TOKEN
    // --------------------------------------------------

    await firestore.collection('queue_tokens').add({
    'patientId': patientId,
    'patientName': patientName,
    'department': selectedDepartment,
    'doctor': selectedDoctor,
    'visitType': 'Walk-in',
    'tokenNumber': tokenNumber,
    'status': 'Waiting',
    'createdAt': FieldValue.serverTimestamp(),
    });

    // ==================================================
    // 1. PATIENT NOTIFICATION
    // ==================================================

    await firestore.collection('notifications').add({
    'recipientType': 'patient',

    'patientId': patientId,
    'patientName': patientName,

    'doctor': selectedDoctor,
    'doctorEmail': selectedDoctorEmail,

    'department': selectedDepartment,
    'tokenNumber': tokenNumber,

    'title': 'You Joined the Queue',

    'message':
    'You joined the $selectedDepartment queue. '
    'Your token number is #$tokenNumber for $selectedDoctor.',

    'type': 'patient',

    'isRead': false,

    'createdAt': FieldValue.serverTimestamp(),
    });

    // ==================================================
    // 2. DOCTOR NOTIFICATION
    // ==================================================

    if (selectedDoctorEmail != null &&
    selectedDoctorEmail!.isNotEmpty) {
    await firestore.collection('notifications').add({
    'recipientType': 'doctor',

    'doctorEmail': selectedDoctorEmail,
    'doctorName': selectedDoctor,

    'patientId': patientId,
    'patientName': patientName,

    'department': selectedDepartment,
    'tokenNumber': tokenNumber,

    'title': 'New Patient in Queue',

    'message':
    '$patientName has joined your '
    '$selectedDepartment queue. '
    'Token #$tokenNumber.',

    'type': 'doctor',

    'isRead': false,

    'createdAt': FieldValue.serverTimestamp(),
    });
    }

    // ==================================================
    // 3. ADMIN NOTIFICATION
    // ==================================================

    await firestore.collection('notifications').add({
    'recipientType': 'admin',

    'title': 'New Patient in Queue',

    'message':
    '$patientName joined the '
    '$selectedDepartment queue. '
    'Token #$tokenNumber for '
    '$selectedDoctor.',

    'patientName': patientName,
    'patientId': patientId,

    'department': selectedDepartment,
    'doctor': selectedDoctor,
    'tokenNumber': tokenNumber,

    'type': 'admin',

    'adminEmail': '',

    'isRead': false,

    'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) {
    return;
    }

    setState(() {
    isLoading = false;
    });

    // --------------------------------------------------
    // SHOW GENERATED TOKEN
    // --------------------------------------------------

    showDialog(
    context: context,
    builder: (context) {
    return AlertDialog(
    title: const Text(
    'Queue Token Generated',
    ),

    content: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    const Icon(
    Icons.check_circle,
    color: Colors.green,
    size: 65,
    ),

    const SizedBox(height: 15),

    const Text(
    'Your token number is',
    style: TextStyle(
    fontSize: 16,
    ),
    ),

    const SizedBox(height: 5),

    Text(
    '$tokenNumber',
    style: const TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.bold,
    ),
    ),

    const SizedBox(height: 15),

    Text(
    patientName,
    textAlign: TextAlign.center,
    style: const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 17,
    ),
    ),

    const SizedBox(height: 8),

    Text(
    selectedDepartment,
    textAlign: TextAlign.center,
    style: const TextStyle(
    fontWeight: FontWeight.bold,
    ),
    ),

    const SizedBox(height: 5),

    Text(
    selectedDoctor!,
    textAlign: TextAlign.center,
    ),
    ],
    ),

    actions: [
    TextButton(
    onPressed: () {
    Navigator.pop(context);
    },
    child: const Text('Done'),
    ),
    ],
    );
    },
    );
    } catch (e) {
    if (!mounted) {
    return;
    }

    setState(() {
    isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
    content: Text(
    'Error generating token: $e',
    ),
    ),
    );
    }


  }

// --------------------------------------------------
// BUILD
// --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),


    appBar: AppBar(
    title: const Text(
      'Get Queue Token',
    ),
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0,
    ),

    body: StreamBuilder<QuerySnapshot>(
    stream: firestore
        .collection('doctors')
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
    child: Padding(
    padding: const EdgeInsets.all(20),

    child: Text(
    'Firebase Error:\n${snapshot.error}',
    textAlign: TextAlign.center,
    style: const TextStyle(
    color: Colors.red,
    fontSize: 16,
    ),
    ),
    ),
    );
    }

    final doctors = snapshot.data?.docs ?? [];

    if (doctors.isEmpty) {
    return const Center(
    child: Text(
    'No doctors found in Firebase.',
    style: TextStyle(
    fontSize: 18,
    ),
    ),
    );
    }

    // --------------------------------------------------
    // FIND DOCTORS FOR SELECTED DEPARTMENT
    // --------------------------------------------------

    final matchingDoctors = doctors.where((doc) {
    final data =
    doc.data() as Map<String, dynamic>;

    final doctorDepartment =
    (data['department'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    final selectedDepartmentValue =
    selectedDepartment
        .trim()
        .toLowerCase();

    return doctorDepartment ==
    selectedDepartmentValue;
    }).toList();

    // --------------------------------------------------
    // AUTOMATICALLY SELECT FIRST DOCTOR
    // --------------------------------------------------

    if (matchingDoctors.isNotEmpty) {
    final firstDoctorData =
    matchingDoctors.first.data()
    as Map<String, dynamic>;

    final firstDoctorName =
    (firstDoctorData['name'] ?? '')
        .toString();

    final firstDoctorEmail =
    (firstDoctorData['email'] ?? '')
        .toString();

    final doctorStillExists =
    matchingDoctors.any((doc) {
    final data =
    doc.data() as Map<String, dynamic>;

    return data['name'] == selectedDoctor;
    });

    if (selectedDoctor == null ||
    !doctorStillExists) {
    selectedDoctor = firstDoctorName;
    selectedDoctorEmail =
    firstDoctorEmail;
    }
    } else {
    selectedDoctor = null;
    selectedDoctorEmail = null;
    }

    // --------------------------------------------------
    // SCREEN
    // --------------------------------------------------

    return SingleChildScrollView(
    padding: const EdgeInsets.all(20),

    child: Center(
    child: ConstrainedBox(
    constraints: const BoxConstraints(
    maxWidth: 600,
    ),

    child: Column(
    crossAxisAlignment:
    CrossAxisAlignment.start,

    children: [
    const SizedBox(height: 20),

    const Text(
    'Get Queue Token',
    style: TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    ),
    ),

    const SizedBox(height: 8),

    const Text(
    'Select your department and doctor',
    style: TextStyle(
    fontSize: 16,
    color: Colors.grey,
    ),
    ),

    const SizedBox(height: 30),

    // --------------------------------------------------
    // DEPARTMENT
    // --------------------------------------------------

    const Text(
    'Department',
    style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    ),
    ),

    const SizedBox(height: 8),

    DropdownButtonFormField<String>(
    value: selectedDepartment,

    decoration: InputDecoration(
    filled: true,
    fillColor: Colors.white,

    border: OutlineInputBorder(
    borderRadius:
    BorderRadius.circular(12),
    ),
    ),

    items: departments.map((department) {
    return DropdownMenuItem<String>(
    value: department,
    child: Text(department),
    );
    }).toList(),

    onChanged: (value) {
    setState(() {
    selectedDepartment = value!;

    selectedDoctor = null;

    selectedDoctorEmail = null;
    });
    },
    ),

    const SizedBox(height: 25),

    // --------------------------------------------------
    // DOCTOR
    // --------------------------------------------------

    const Text(
    'Doctor',
    style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    ),
    ),

    const SizedBox(height: 8),

    if (matchingDoctors.isEmpty)
    Container(
    width: double.infinity,

    padding:
    const EdgeInsets.all(16),

    decoration: BoxDecoration(
    color: Colors.orange.shade50,

    borderRadius:
    BorderRadius.circular(12),

    border: Border.all(
    color:
    Colors.orange.shade200,
    ),
    ),

    child: Text(
    'No doctor available for '
    '$selectedDepartment',

    style: const TextStyle(
    fontSize: 15,
    ),
    ),
    )
    else
    DropdownButtonFormField<String>(
    value: selectedDoctor,

    decoration: InputDecoration(
    filled: true,
    fillColor: Colors.white,

    border: OutlineInputBorder(
    borderRadius:
    BorderRadius.circular(12),
    ),
    ),

    items:
    matchingDoctors.map((doc) {
    final data =
    doc.data()
    as Map<String, dynamic>;

    final doctorName =
    (data['name'] ?? '')
        .toString();

    return DropdownMenuItem<String>(
    value: doctorName,
    child: Text(doctorName),
    );
    }).toList(),

    onChanged: (value) {
    setState(() {
    selectedDoctor = value;

    for (final doc
    in matchingDoctors) {
    final data =
    doc.data()
    as Map<String, dynamic>;

    if (data['name'] == value) {
    selectedDoctorEmail =
    (data['email'] ?? '')
        .toString();

    break;
    }
    }
    });
    },
    ),

    const SizedBox(height: 35),

    // --------------------------------------------------
    // GENERATE TOKEN
    // --------------------------------------------------

    SizedBox(
    width: double.infinity,
    height: 55,

    child: ElevatedButton.icon(
    onPressed:
    isLoading ||
    selectedDoctor ==
    null
    ? null
        : generateToken,

    icon: isLoading
    ? const SizedBox(
    width: 20,
    height: 20,

    child:
    CircularProgressIndicator(
    strokeWidth: 2,
    color: Colors.white,
    ),
    )
        : const Icon(
    Icons
        .confirmation_number,
    ),

    label: Text(
    isLoading
    ? 'Generating Token...'
        : 'Generate Queue Token',
    ),

    style:
    ElevatedButton.styleFrom(
    shape:
    RoundedRectangleBorder(
    borderRadius:
    BorderRadius.circular(12),
    ),
    ),
    ),
    ),
    ],
    ),
    ),
    ),
    );
    },
    ),
    );


  }
}
