importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyBvgUSmYJ8T9QB09Vc_htmMK0BtgpjpPHI",
  authDomain: "ai-smart-life-assistant-a697a.firebaseapp.com",
  projectId: "ai-smart-life-assistant-a697a",
  storageBucket: "ai-smart-life-assistant-a697a.firebasestorage.app",
  messagingSenderId: "467878544533",
  appId: "1:467878544533:web:aa8e961739b03f9981079c"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
