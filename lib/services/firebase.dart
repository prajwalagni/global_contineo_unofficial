import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

final FirebaseFirestore firestore = FirebaseFirestore.instance;

class FirebaseService {
  Future<void> saveStudentData({
    required String semester,
    required String course,
    required String section,
    required String usn,
    required String name,
    required String dob,
    required List<Map<String, dynamic>> subjects,
    required Map<String, Map<String, String>> cie,
    required Map<String, List> attendance,
    required Map<String, dynamic> deviceInfo,
  }) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    try {
      await firestore
          .collection('students')
          .doc(course)
          .collection(semester)
          .doc(section)
          .collection(usn)
          .doc('details')
          .set({
            'name': name,
            'dob': dob,
            'attendance': attendance,
            'cie': cie,
            'deviceInfo': deviceInfo,
            'appVer': packageInfo.version,
            'appInstallTime': packageInfo.installTime,
            'appUpdateTime': packageInfo.updateTime,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      print("Student data saved to Firestore!");
    } catch (e) {
      print("Error saving data: $e");
    }
  }
}
