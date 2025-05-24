// Give the service worker access to Firebase Messaging.
// Note that you can only use Firebase Messaging here. Other Firebase libraries
// are not available in the service worker.
// Replace 10.13.2 with latest version of the Firebase JS SDK.
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker by passing in
// your app's Firebase config object.
// https://firebase.google.com/docs/web/setup#config-object
firebase.initializeApp({
  apiKey: 'AIzaSyCgIXiPp1KU-8V5Vi790oD782_nPAF42Ew',
  appId: '1:819858395455:web:cd82a245a46826a73a038a',
  messagingSenderId: '819858395455',
  projectId: 'dating-app-ab810',
  authDomain: 'dating-app-ab810.firebaseapp.com',
  databaseURL: 'https://dating-app-ab810-default-rtdb.firebaseio.com',
  storageBucket: 'dating-app-ab810.appspot.com',
  measurementId: 'G-2EJ1KZGSJP',
});

// Retrieve an instance of Firebase Messaging so that it can handle background
// messages.
const messaging = firebase.messaging();