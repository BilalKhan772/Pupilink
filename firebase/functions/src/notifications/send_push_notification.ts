import {getApps, initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";

if (getApps().length === 0) {
  initializeApp();
}

const db = getFirestore();
const messaging = getMessaging();

/**
 * Notification data required by the Parent App.
 */
export interface SendPushNotificationInput {
  parentId: string;
  title: string;
  message: string;
  type: string;

  studentId?: string;
  studentName?: string;

  data?: Record<string, string>;
}

/**
 * Creates a notification for a parent.
 *
 * Flow:
 *
 * Firebase Function
 *       ↓
 * notifications/{notificationId}
 *       ↓
 * Parent App
 *
 * If an FCM token exists for the parent, this function
 * also attempts to send a push notification.
 *
 * During Firebase Emulator testing, FCM sending is skipped.
 * The Firestore notification is still created normally.
 */
export async function sendPushNotification(
  input: SendPushNotificationInput,
): Promise<string> {
  const parentId = input.parentId.trim();
  const title = input.title.trim();
  const message = input.message.trim();
  const type = input.type.trim();

  if (!parentId) {
    throw new Error(
      "Notification ke liye parentId required hai.",
    );
  }

  if (!title) {
    throw new Error(
      "Notification title required hai.",
    );
  }

  if (!message) {
    throw new Error(
      "Notification message required hai.",
    );
  }

  if (!type) {
    throw new Error(
      "Notification type required hai.",
    );
  }

  /*
   * ============================
   * CREATE FIRESTORE NOTIFICATION
   * ============================
   */

  const notificationRef =
      db.collection("notifications").doc();

  const notificationData: Record<string, unknown> = {
    parentId: parentId,
    title: title,
    message: message,
    type: type,
    isRead: false,
    createdAt: FieldValue.serverTimestamp(),
  };

  /*
   * Optional student ID
   */
  if (
    input.studentId != null &&
    input.studentId!.trim().length > 0
  ) {
    notificationData["studentId"] =
        input.studentId!.trim();
  }

  /*
   * Optional student name
   */
  if (
    input.studentName != null &&
    input.studentName!.trim().length > 0
  ) {
    notificationData["studentName"] =
        input.studentName!.trim();
  }

  /*
   * Optional extra data
   */
  if (
    input.data != null &&
    Object.keys(input.data!).length > 0
  ) {
    notificationData["data"] = input.data;
  }

  await notificationRef.set(
    notificationData,
  );

  /*
   * ============================
   * FIREBASE EMULATOR
   * ============================
   *
   * Emulator testing mein actual FCM push
   * send nahi karni.
   *
   * Firestore notification already create
   * ho chuki hai, jisay Parent App read karegi.
   */

  if (process.env.FIRESTORE_EMULATOR_HOST) {
    console.log(
      "NOTIFICATION - Emulator mode.",
    );

    console.log(
      "NOTIFICATION - Firestore notification created:",
      notificationRef.id,
    );

    return notificationRef.id;
  }

  /*
   * ============================
   * PRODUCTION FCM
   * ============================
   *
   * Parent document mein agar fcmToken
   * available hai to push notification
   * send karne ki koshish karenge.
   *
   * Agar token available nahi hai to
   * Firestore notification phir bhi valid
   * rahegi.
   */

  try {
    const parentSnapshot = await db
        .collection("users")
        .doc(parentId)
        .get();

    if (!parentSnapshot.exists) {
      console.warn(
        "NOTIFICATION - Parent profile not found:",
        parentId,
      );

      return notificationRef.id;
    }

    const parentData =
        parentSnapshot.data();

    const fcmToken =
        typeof parentData?.fcmToken === "string"
            ? parentData.fcmToken.trim()
            : "";

    if (!fcmToken) {
      console.log(
        "NOTIFICATION - No FCM token found for parent:",
        parentId,
      );

      return notificationRef.id;
    }

    /*
     * ============================
     * SEND FCM MESSAGE
     * ============================
     */

    const messageId =
        await messaging.send({
          token: fcmToken,

          notification: {
            title: title,
            body: message,
          },

          data: {
            notificationId:
                notificationRef.id,
            type: type,
            ...(input.studentId != null
                ? {
                  studentId:
                      input.studentId,
                }
                : {}),
            ...(input.data ?? {}),
          },
        });

    console.log(
      "NOTIFICATION - FCM sent successfully:",
      messageId,
    );
  } catch (error) {
    /*
     * Push notification fail hone par
     * Firestore notification delete nahi
     * karni.
     *
     * Parent App notification list se
     * notification phir bhi dekh sakti hai.
     */

    console.error(
      "NOTIFICATION - FCM sending failed:",
      error,
    );
  }

  return notificationRef.id;
}