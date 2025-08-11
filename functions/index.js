const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();


function sanitizeEmail(email) {
  return email.replace(/[^\w]/g, "_"); // Replace anything not [a-zA-Z0-9_]
}



exports.notifications = onDocumentCreated(
  {

    document: "chats/{docId}",
  },
  async (event) => {
  console.log("message triggered");
    try {
      const snap = event.data;
      const chatId = event.params.docId;

      const chatData = snap.data();
      console.log(chatData);
      const username = chatData.name || "Unknown";
      const currentUserId = chatData.id || "";
      const metadata = chatData.metadata || {};
      const text = metadata.text || "";
      const img = metadata.img || "";
      const url = metadata.url || "";

      const usersSnapshot = await getFirestore().collection("users").get();
      const promises = [];

      usersSnapshot.forEach((doc) => {
        const userData = doc.data();
        const email = userData.email;
          console.log(email);
          console.log(userData);
          const isCurrentUser = userData.uid == currentUserId ;
          const isBlocked = userData.isBlocked;
          console.log(`isCurrentUser ${isCurrentUser} and isBlocked ${isBlocked}`);
        if (email && !isCurrentUser && !isBlocked) {
          const message = {
           notification: {
              title: username,
              body: text,
              image:img,
           },
            topic: sanitizeEmail(email),
          };

          promises.push(getMessaging().send(message));
        }
      });

      const results = await Promise.allSettled(promises);
      const successes = results.filter((r) => r.status === "fulfilled").length;
      const failures = results.filter((r) => r.status === "rejected").length;

      console.log(`Custom data sent: ${successes} succeeded, ${failures} failed.`);
    } catch (error) {
      console.error("Error sending custom data:", error);
    }
  }
);