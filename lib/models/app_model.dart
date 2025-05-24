import 'dart:convert';
import 'dart:developer';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating_app_dashboard/constants/constants.dart';
import 'package:dating_app_dashboard/datas/app_info.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:uuid/uuid.dart';

class AppModel extends Model {
  // Variables
  final _firestore = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instance;
  final _firebaseAuth = FirebaseAuth.instance;

  AppInfo? appInfo;
  List<DocumentSnapshot<Map<String, dynamic>>> users = [];
  int sortColumnIndex = 0;
  bool sortAscending = true;

  /// Create Singleton factory for [AppModel]
  ///
  static final AppModel _appModel = AppModel._internal();

  factory AppModel() {
    return _appModel;
  }

  AppModel._internal();

  // End

  /// Admin sign in method
  void adminSignIn({
    required String username,
    required String password,
    // VoidCallback functions
    required VoidCallback onSuccess,
    required VoidCallback onError,
  }) async {
    // Get app info
    final DocumentSnapshot<Map<String, dynamic>> appInfo =
        await getAppInfoDoc();
    // Get admin sign in credentials
    final String adminUsername = appInfo.data()![ADMIN_USERNAME];
    final String adminPassword = appInfo.data()![ADMIN_PASSWORD];

    // Check info
    if (adminUsername == username && adminPassword == password) {
      // Enable access
      onSuccess();
    } else {
      // Access denied
      onError();
    }
  }

  /// Get App Settings from database => Stream
  Stream<DocumentSnapshot<Map<String, dynamic>>> getAppInfoStream() {
    return _firestore.collection(C_APP_INFO).doc('settings').snapshots();
  }

  /// Get App Settings from database => DocumentSnapshot<Map<String, dynamic>>
  Future<DocumentSnapshot<Map<String, dynamic>>> getAppInfoDoc() async {
    final infoDoc =
        await _firestore.collection(C_APP_INFO).doc('settings').get();
    updateAppObject(infoDoc.data()!);
    return infoDoc;
  }

  /// Update AppInfo in database
  Future<void> updateAppData({required Map<String, dynamic> data}) {
    _firestore.collection(C_APP_INFO).doc('settings').update(data);
    return Future.value();
  }

  /// Update user data in database
  Future<void> updateUserData(
      {required String userId, required Map<String, dynamic> data}) async {
    // Update user data
    _firestore.collection(C_USERS).doc(userId).update(data);
  }

  /// Update Admin sign in info
  void updateAdminSignInInfo({
    required String adminUsername,
    required String adminPassword,
    // VoidCallback functions
    required VoidCallback onSuccess,
    required VoidCallback onError,
  }) {
    updateAppData(data: {
      ADMIN_USERNAME: adminUsername,
      ADMIN_PASSWORD: adminPassword,
    }).then((_) {
      onSuccess();
      debugPrint('updateAdminSignInInfo() -> success');
    }).catchError((error) {
      onError();
      debugPrint('updateAdminSignInInfo() -> error: $error');
    });
  }

  /// Update AppInfo object
  void updateAppObject(Map<String, dynamic> appDoc) {
    appInfo = AppInfo.fromDocument(appDoc);
    notifyListeners();
  }

  /// Get Users from database => stream
  Stream<QuerySnapshot<Map<String, dynamic>>> getUsers() {
    return _firestore
        .collection(C_USERS)
        .orderBy(USER_REG_DATE, descending: true)
        .snapshots();
  }

  /// Get Flagged Users Alert from database => stream
  Stream<QuerySnapshot<Map<String, dynamic>>> getFlaggedUsersAlert() {
    return _firestore
        .collection(C_FLAGGED_USERS)
        .orderBy(TIMESTAMP, descending: true)
        .snapshots();
  }

  /// Update User list
  void updateUsers(List<DocumentSnapshot<Map<String, dynamic>>> docs) {
    users = docs;
    notifyListeners();
    debugPrint('Users -> updated!');
  }

  // Update variables used on table
  void updateOnSort(int columnIndex, bool sortAsc) {
    sortColumnIndex = columnIndex;
    sortAscending = sortAsc;
    notifyListeners();
    debugPrint('sortColumnIndex: $columnIndex');
    debugPrint('sortAscending: $sortAsc');
  }

  /// Save/Update app settings in database
  /// it is called in AppSettings screen
  void saveAppSettings({
    required int androidAppCurrentVersion,
    required int iosAppCurrentVersion,
    required String androidPackageName,
    required String iOsAppId,
    required String appEmail,
    required String privacyPolicyUrl,
    required String termsOfServicesUrl,
    required double? freeAccountMaxDistance,
    required double? vipAccountMaxDistance,
    required double? subscriptionAmount,
    required List<String>? censoredWords,
    // VoidCallback functions
    required VoidCallback onSuccess,
    required VoidCallback onError,
  }) {
    updateAppData(data: {
      ANDROID_APP_CURRENT_VERSION: androidAppCurrentVersion,
      IOS_APP_CURRENT_VERSION: iosAppCurrentVersion,
      ANDROID_PACKAGE_NAME: androidPackageName,
      IOS_APP_ID: iOsAppId,
      PRIVACY_POLICY_URL: privacyPolicyUrl,
      TERMS_OF_SERVICE_URL: termsOfServicesUrl,
      APP_EMAIL: appEmail,
      FREE_ACCOUNT_MAX_DISTANCE: freeAccountMaxDistance ?? 100,
      VIP_ACCOUNT_MAX_DISTANCE: vipAccountMaxDistance ?? 200,
      CENSORED_WORDS: censoredWords ?? [],
      SUBSCRIPTION_AMOUNT: subscriptionAmount ?? 100,

    }).then((_) {
      onSuccess();
      debugPrint('updateAppSettings() -> success');
    }).catchError((error) {
      onError();
      debugPrint('updateAppSettings() -> error:$error ');
    });
  }

  /// Format firestore server Timestamp
  String formatDate(DateTime timestamp) {
    // Format
    final DateFormat dateFormat = DateFormat('yyyy-MM-dd h:m a');
    return dateFormat.format(timestamp);
  }

  /// Calculate user current age
  int calculateUserAge(int userBirthYear) {
    DateTime date = DateTime.now();
    int currentYear = date.year;
    return (currentYear - userBirthYear);
  }

  Future<List<String>> getAllUserTokens() async {
    try {
      // Fetch all user documents from the 'users' collection
      QuerySnapshot usersSnapshot =
          await FirebaseFirestore.instance.collection('Users').get();

      // Extract FCM tokens from each user document
      List<String> tokens = [];
      for (var doc in usersSnapshot.docs) {
        var userData = doc.data() as Map<String, dynamic>;
        if (userData.containsKey('user_device_token')) {
          tokens.add(userData['user_device_token']);
        }
      }

      return tokens;
    } catch (e) {
      print('Error retrieving user tokens: $e');
      return [];
    }
  }

  Future<void> sendTopicNotificationv2({
    required String nBody,
    required VoidCallback onSuccess,
    required VoidCallback onError,
  }) async {
    try {
      final serviceAccountKey = await rootBundle.loadString(
          'assets/dating-app-ab810-firebase-adminsdk-km13g-9503b9ffd6.json');
      final credentials =
          ServiceAccountCredentials.fromJson(json.decode(serviceAccountKey));

      final scopes = ['https://www.googleapis.com/auth/cloud-platform'];

      // Get an authenticated HTTP client
      final client = await clientViaServiceAccount(credentials, scopes);

      final accessToken = (await client.credentials).accessToken.data;

      print("AccessToken: $accessToken");

      final List<String> usersTokens = await getAllUserTokens();

      log("USER TOKEN:::: ${usersTokens}");

      // Build the notification object with the dynamic data
      final Map<String, dynamic> notification = {
        'body': nBody,
      };

      // Build the message map with the dynamic values
      for (int i = 0; i < usersTokens.length; i++) {
        final Map<String, dynamic> message = {
          'token': usersTokens[i], // Use the current user's device token
          'notification': notification,
          'data': {
            'type': 'alert',
            'title': APP_NAME,
            'body': nBody,
            'deviceToken': usersTokens[i],
            'senderId': 'admin',
          },
        };

        final String url =
            'https://fcm.googleapis.com/v1/projects/dating-app-ab810/messages:send';

        final response = await http.post(
          Uri.parse(url),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode(<String, dynamic>{
            'message': message,
          }),
        );

        if (response.statusCode == 200) {
          print('Notification sent to ${usersTokens[i]}');
        } else {
          print(
              'Failed to send notification to ${usersTokens[i]}: ${response.statusCode}');
          print('Response: ${response.body}');
        }
      }

      // Call onSuccess callback after all notifications are sent
      onSuccess();

      client.close();
    } catch (e) {
      print("Error sending push notification: $e");

      // Call onError callback if an error occurs
      onError();
    }
  }

  /// Send push notification method
  Future<void> sendPushNotification({
    required String nBody,
    // VoidCallback functions
    required VoidCallback onSuccess,
    required VoidCallback onError,
  }) async {
    try {
      await _functions.httpsCallable('sendPushNotification').call({
        'type': 'alert',
        'title': APP_NAME,
        'body': nBody,
        'deviceToken': 'admin',
        'senderId': 'admin',
      });
      onSuccess();
      debugPrint('sendPushNotification() -> success');
    } catch (e) {
      onError();
      debugPrint('sendPushNotification() -> error: $e');
    }
  }

  Future<void> saveMessage({
    required String messageId,
    required String type,
    required String senderId,
    required String receiverId,
    required String fromUserId,
    required String userPhotoLink,
    required String userFullName,
    required String textMsg,
    required String imgLink,
    required String audioLink,
    required bool isRead,
    bool isEdit = false,
  }) async {
    await _firestore
        .collection("Messages")
        .doc(senderId)
        .collection(receiverId)
        .doc(messageId)
        .set(<String, dynamic>{
      "message_id": messageId,
      USER_ID: fromUserId,
      MESSAGE_TYPE: type,
      "message_text": textMsg,
      "message_img_link": imgLink,
      "message_audio_link": audioLink,
      TIMESTAMP: FieldValue.serverTimestamp(),
    });

    /// Save last conversation
    saveConversation(
        type: type,
        senderId: senderId,
        receiverId: receiverId,
        userPhotoLink: userPhotoLink,
        userFullName: userFullName,
        textMsg: textMsg,
        isRead: isRead);
  }

  /// Send Message to all users
  Future<void> sendMessage2AllUser({
    required String message,
    required VoidCallback onSuccess,
    required VoidCallback onError,
  }) async {
    try {
      // Get the users
      var usersSnapshot = await _firestore
          .collection(C_USERS)
          .orderBy(USER_REG_DATE, descending: true)
          .get();

      var currentUser = await _firebaseAuth.currentUser;

      if (currentUser == null) {
        print("No current user found");
        onError();
        return;
      }

      // Iterate through each user in the collection
      for (var userDoc in usersSnapshot.docs) {
        String receiverId = userDoc.id;
        String messageId = Uuid().v4().toString();
        String fromUserId = currentUser.uid;
        String textMsg = message;
        String imgLink = ''; // Add an image link if necessary
        String audioLink = ''; // Add an audio link if necessary
        String type =
            'text'; // Define the message type (e.g., text, image, etc.)

        saveMessage(
            userPhotoLink: '',
            messageId: messageId,
            type: type,
            senderId: fromUserId,
            receiverId: receiverId,
            fromUserId: fromUserId,
            userFullName: 'Admin',
            textMsg: textMsg,
            imgLink: imgLink,
            audioLink: audioLink,
            isRead: false);

        saveMessage(
            userPhotoLink: '',
            messageId: messageId,
            type: type,
            senderId: receiverId,
            receiverId: fromUserId,
            fromUserId: fromUserId,
            userFullName: 'Admin',
            textMsg: textMsg,
            imgLink: imgLink,
            audioLink: audioLink,
            isRead: false);
      }

      onSuccess(); // Notify on success
    } catch (e) {
      print('Error sending message to all users: $e');
      onError(); // Notify on error
    }
  }

  Future<void> saveConversation({
    required String type,
    required String senderId,
    required String receiverId,
    required String userPhotoLink,
    required String userFullName,
    required String textMsg,
    required bool isRead,
  }) async {
    await _firestore
        .collection(C_CONNECTIONS)
        .doc(senderId)
        .collection(C_CONVERSATIONS)
        .doc(receiverId)
        .set(<String, dynamic>{
      USER_ID: receiverId,
      USER_PROFILE_PHOTO: userPhotoLink,
      USER_FULLNAME: userFullName,
      MESSAGE_TYPE: type,
      LAST_MESSAGE: textMsg,
      MESSAGE_READ: isRead,
      TIMESTAMP: FieldValue.serverTimestamp(),
    }).then((value) {
      debugPrint('saveConversation() -> success');
    }).catchError((e) {
      debugPrint('saveConversation() -> error: $e');
    });
  }
}

// change this to cloud function that sends to all users
//
//
//
// Future<void> sendTopicNotificationv2({
//   required String nTitle,
//   required String nBody,
//   required String nType,
//   required String nSenderId,
//   required String nUserDeviceToken,
//   Map<String, dynamic>? nCallInfo,
// }) async {
//   log("i am call info:::: ${nCallInfo}");
//   try {
//     log("me334");
//     // Load the service account key
//     final serviceAccountKey = await rootBundle.loadString(
//         'assets/dating-app-ab810-firebase-adminsdk-km13g-9503b9ffd6.json');
//     final credentials =
//     ServiceAccountCredentials.fromJson(json.decode(serviceAccountKey));
//
//     final scopes = ['https://www.googleapis.com/auth/cloud-platform'];
//
//     // Get an authenticated HTTP client
//     final client = await clientViaServiceAccount(credentials, scopes);
//
//     final accessToken = (await client.credentials).accessToken.data;
//
//     print("AccessToken: $accessToken");
//
//     // Build the notification object with the dynamic data
//     final Map<String, dynamic> notification = {
//       'title': nTitle,
//       'body': nBody,
//     };
//     // Encode the nCallInfo to JSON string
//     String callInfoJson = json.encode(nCallInfo);
//     // Build the message map with the dynamic values
//     final Map<String, dynamic> message = {
//       'token': nUserDeviceToken, // Use the user’s device token
//       'notification': notification,
//       'data': {
//         'n_type': nType,
//         'n_sender_id': nSenderId,
//         'n_message': nBody,
//         'call_info': callInfoJson,
//         'click_action': "FLUTTER_NOTIFICATION_CLICK",
//         'status': 'done',
//       },
//     };
//
//     final String url =
//         'https://fcm.googleapis.com/v1/projects/dating-app-ab810/messages:send';
//
//     final response = await http.post(
//       Uri.parse(url),
//       headers: <String, String>{
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $accessToken',
//       },
//       body: jsonEncode(<String, dynamic>{
//         'message': message,
//       }),
//     );
//
//     if (response.statusCode == 200) {
//       print('Notification sent successfully');
//     } else {
//       print('Failed to send notification: ${response.statusCode}');
//       print('Response: ${response.body}');
//     }
//
//     client.close();
//   } catch (e) {
//     print("Error sending push notification: $e");
//   }
// }
