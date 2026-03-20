import '../models/assignment.dart';

class AppSession {
  static String? accessToken;
  static String? firebaseUid;
  static String? employeeId;
  static AssignmentSummary? activeAssignment;

  static bool get isAuthenticated => accessToken != null && accessToken!.isNotEmpty;

  static void clear() {
    accessToken = null;
    firebaseUid = null;
    employeeId = null;
    activeAssignment = null;
  }
}
