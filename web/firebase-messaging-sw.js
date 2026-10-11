// Give the service worker access to Firebase Messaging.
importScripts(
  "https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js",
  "https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js"
);

// Initialize the Firebase app in the service worker by passing in
// your app's Firebase config object.
// https://firebase.google.com/docs/web/setup#config-object
const firebaseConfig = {
  apiKey: "AIzaSyBFLKV01T-XGVmHEV6QlBRHkVcaHejs0hc",
  authDomain: "kurichya-matrimony.firebaseapp.com",
  projectId: "kurichya-matrimony",
  storageBucket: "kurichya-matrimony.firebasestorage.app",
  messagingSenderId: "224732363568",
  appId: "1:224732363568:web:placeholder" // Web App ID needed if web push is fully set up
};

firebase.initializeApp(firebaseConfig);

// Retrieve an instance of Firebase Messaging so that it can handle background
// messages.
const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log(
    '[firebase-messaging-sw.js] Received background message ',
    payload
  );
  
  // Customize notification here
  const notificationTitle = payload.notification?.title || 'പുതിയ അറിയിപ്പ് (New Notification)';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
