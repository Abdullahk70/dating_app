const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendMessageToAllUsers = functions.https.onCall(async (data, context) => {
    try {
    // Load the service account key
        final serviceAccountKey = await rootBundle.loadString(
            'assets/dating-app-ab810-firebase-adminsdk-km13g-9503b9ffd6.json');
        final credentials =
        ServiceAccountCredentials.fromJson(json.decode(serviceAccountKey));

        final scopes = ['https://www.googleapis.com/auth/cloud-platform'];

        // Get an authenticated HTTP client
        final client = await clientViaServiceAccount(credentials, scopes);

        final accessToken = (await client.credentials).accessToken.data;

        print("AccessToken: $accessToken");

        // Build the notification object with the dynamic data
        final Map<String, dynamic> notification = {
          'title': nTitle,
          'body': nBody,
        };
        // Encode the nCallInfo to JSON string
        String callInfoJson = json.encode(nCallInfo);
        // Build the message map with the dynamic values

    const usersSnapshot = await admin.firestore().collection('users').get();
        const tokens = [];

        usersSnapshot.forEach((doc) => {
              const userData = doc.data();
              if (userData.user_device_token) {
                tokens.push(userData.fcmToken);
              }
            });

            if (tokens.length === 0) {
                  return { success: false, message: 'No FCM tokens found.' };
                }
    }
    } catch (error) {
         console.error('Error sending message:', error);
         return { success: false, error: error.message };
    }
}