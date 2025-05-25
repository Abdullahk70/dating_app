const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();

// Cloud Function to send message to all users
exports.sendMessageToAllUsers = functions.https.onCall(async (data, context) => {
    try {
        // Verify authentication
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
        }

        const { title, body, callInfo } = data;

        if (!title || !body) {
            throw new functions.https.HttpsError('invalid-argument', 'Title and body are required');
        }

        // Get all users with FCM tokens
        const usersSnapshot = await admin.firestore().collection('users').get();
        const tokens = [];

        usersSnapshot.forEach((doc) => {
            const userData = doc.data();
            if (userData.fcmToken) {
                tokens.push(userData.fcmToken);
            }
        });

        if (tokens.length === 0) {
            return { success: false, message: 'No FCM tokens found.' };
        }

        // Prepare the message
        const message = {
            notification: {
                title: title,
                body: body,
            },
            data: callInfo ? { callInfo: JSON.stringify(callInfo) } : {},
            tokens: tokens
        };

        // Send the message
        const response = await admin.messaging().sendMulticast(message);

        console.log('Successfully sent message:', response);

        return {
            success: true,
            message: `Message sent to ${response.successCount} devices`,
            failureCount: response.failureCount
        };

    } catch (error) {
        console.error('Error sending message:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});

// Cloud Function to send push notification
exports.sendPushNotification = functions.https.onCall(async (data, context) => {
    try {
        // Verify authentication
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
        }

        const { token, title, body, data: messageData } = data;

        if (!token || !title || !body) {
            throw new functions.https.HttpsError('invalid-argument', 'Token, title, and body are required');
        }

        const message = {
            notification: {
                title: title,
                body: body,
            },
            data: messageData || {},
            token: token
        };

        const response = await admin.messaging().send(message);
        console.log('Successfully sent message:', response);

        return { success: true, messageId: response };

    } catch (error) {
        console.error('Error sending push notification:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});

// Cloud Function to get user statistics
exports.getUserStats = functions.https.onCall(async (data, context) => {
    try {
        // Verify authentication
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
        }

        const usersSnapshot = await admin.firestore().collection('users').get();
        const totalUsers = usersSnapshot.size;

        let activeUsers = 0;
        let premiumUsers = 0;

        usersSnapshot.forEach((doc) => {
            const userData = doc.data();
            if (userData.isActive) activeUsers++;
            if (userData.isPremium) premiumUsers++;
        });

        return {
            success: true,
            stats: {
                totalUsers,
                activeUsers,
                premiumUsers,
                freeUsers: totalUsers - premiumUsers
            }
        };

    } catch (error) {
        console.error('Error getting user stats:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});