import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  Future<String> getPatientName(String? patientId) async {
    if (patientId == null || patientId.isEmpty) {
      return 'Patient';
    }

    try {
      DocumentSnapshot patientDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .get();

      if (patientDoc.exists) {
        Map<String, dynamic> data =
        patientDoc.data() as Map<String, dynamic>;

        if (data['name'] != null &&
            data['name'].toString().trim().isNotEmpty) {
          return data['name'].toString();
        }

        if (data['fullName'] != null &&
            data['fullName'].toString().trim().isNotEmpty) {
          return data['fullName'].toString();
        }

        if (data['patientName'] != null &&
            data['patientName'].toString().trim().isNotEmpty) {
          return data['patientName'].toString();
        }

        if (data['email'] != null &&
            data['email'].toString().trim().isNotEmpty) {
          return data['email'].toString();
        }
      }
    } catch (e) {
      debugPrint('Error getting patient name: $e');
    }

    return 'Patient';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),

      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
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
                'Error: ${snapshot.error}',
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No notifications'),
            );
          }

          List<QueryDocumentSnapshot> notifications =
          snapshot.data!.docs.where((doc) {
            final data =
            doc.data() as Map<String, dynamic>;

            final type =
            data['type']?.toString().toLowerCase();

            final adminEmail =
                data['adminEmail']?.toString() ?? '';

            final currentAdminEmail =
                currentUser?.email?.toLowerCase() ?? '';

            return type == 'admin' &&
                (adminEmail.isEmpty ||
                    adminEmail.toLowerCase() ==
                        currentAdminEmail);
          }).toList();

          notifications.sort((a, b) {
            final aData =
            a.data() as Map<String, dynamic>;
            final bData =
            b.data() as Map<String, dynamic>;

            final aTime =
            aData['createdAt'] as Timestamp?;
            final bTime =
            bData['createdAt'] as Timestamp?;

            if (aTime == null && bTime == null) {
              return 0;
            }

            if (aTime == null) {
              return 1;
            }

            if (bTime == null) {
              return -1;
            }

            return bTime.compareTo(aTime);
          });

          if (notifications.isEmpty) {
            return const Center(
              child: Text('No notifications'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: notifications.length,

            itemBuilder: (context, index) {
              final doc = notifications[index];

              final data =
              doc.data() as Map<String, dynamic>;

              return _AdminNotificationCard(
                data: data,
                getPatientName: getPatientName,
              );
            },
          );
        },
      ),
    );
  }
}

class _AdminNotificationCard extends StatelessWidget {
  final Map<String, dynamic> data;

  final Future<String> Function(String?) getPatientName;

  const _AdminNotificationCard({
    required this.data,
    required this.getPatientName,
  });

  @override
  Widget build(BuildContext context) {
    final title =
        data['title']?.toString() ?? 'Notification';

    final type =
        data['type']?.toString().toLowerCase() ?? '';

    final patientId =
    data['patientId']?.toString();

    // First try patientName saved directly
    // inside the notification.
    final savedPatientName =
        data['patientName']?.toString() ?? '';

    final department =
        data['department']?.toString() ?? '';

    final doctor =
        data['doctor']?.toString() ?? '';

    final token =
        data['tokenNumber']?.toString() ?? '';

    final createdAt =
    data['createdAt'] as Timestamp?;

    return FutureBuilder<String>(
      future: savedPatientName.isNotEmpty
          ? Future.value(savedPatientName)
          : getPatientName(patientId),

      builder: (context, snapshot) {
        final patientName =
            snapshot.data ?? 'Patient';

        String message =
            data['message']?.toString() ??
                '';

        // Queue notification
        if (department.isNotEmpty &&
            doctor.isNotEmpty &&
            token.isNotEmpty) {
          message =
          '$patientName joined the $department queue. '
              'Token #$token for $doctor.';
        }

        IconData icon = Icons.notifications;
        Color iconColor = Colors.blue;

        if (title.toLowerCase().contains('appointment')) {
          icon = Icons.calendar_month;
          iconColor = Colors.green;
        } else if (title.toLowerCase().contains('queue')) {
          icon = Icons.people;
          iconColor = Colors.orange;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          elevation: 1,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),

          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Container(
                  width: 48,
                  height: 48,

                  decoration: BoxDecoration(
                    color:
                    iconColor.withOpacity(0.12),
                    borderRadius:
                    BorderRadius.circular(12),
                  ),

                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 25,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Patient name
                      if (savedPatientName.isNotEmpty ||
                          patientId != null)
                        Text(
                          'Patient: $patientName',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight:
                            FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),

                      const SizedBox(height: 5),

                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 8),

                      if (createdAt != null)
                        Text(
                          _formatDate(
                            createdAt.toDate(),
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color:
                            Colors.grey.shade600,
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
    );
  }

  String _formatDate(DateTime date) {
    String hour = date.hour > 12
        ? '${date.hour - 12}'
        : date.hour == 0
        ? '12'
        : '${date.hour}';

    String minute =
    date.minute.toString().padLeft(2, '0');

    String period =
    date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day}/${date.month}/${date.year} '
        '$hour:$minute $period';
  }
}