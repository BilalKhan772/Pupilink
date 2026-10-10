import {getApps, initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";

import {
  sendPushNotification,
} from "./send_push_notification";

if (getApps().length === 0) {
  initializeApp();
}

const db = getFirestore();

/**
 * Input required for an attendance notification.
 */
export interface SendAttendanceNotificationInput {
  studentId: string;
  date: string;
  status: string;
}

/**
 * Sends attendance notifications to all approved
 * parents linked with the student.
 *
 * Flow:
 *
 * attendance
 *      ↓
 * studentId
 *      ↓
 * parent_child_links
 *      ↓
 * approved parent(s)
 *      ↓
 * sendPushNotification()
 *      ↓
 * notifications
 */
export async function sendAttendanceNotification(
  input: SendAttendanceNotificationInput,
): Promise<string[]> {
  const studentId = input.studentId.trim();
  const date = input.date.trim();
  const status = input.status.trim().toLowerCase();

  if (!studentId) {
    throw new Error(
      "Attendance notification ke liye studentId required hai.",
    );
  }

  if (!date) {
    throw new Error(
      "Attendance notification ke liye date required hai.",
    );
  }

  if (!status) {
    throw new Error(
      "Attendance notification ke liye status required hai.",
    );
  }

  /*
   * ============================
   * FIND APPROVED PARENTS
   * ============================
   */

  const parentLinksSnapshot = await db
      .collection("parent_child_links")
      .where(
        "studentId",
        "==",
        studentId,
      )
      .where(
        "status",
        "==",
        "approved",
      )
      .get();

  if (parentLinksSnapshot.empty) {
    console.log(
      "ATTENDANCE NOTIFICATION - No approved parent found for student:",
      studentId,
    );

    return [];
  }

  /*
   * ============================
   * STATUS LABEL
   * ============================
   */

  let statusLabel = "Attendance Updated";

  switch (status) {
    case "present":
      statusLabel = "Present";
      break;

    case "absent":
      statusLabel = "Absent";
      break;

    case "late":
      statusLabel = "Late";
      break;

    default:
      statusLabel = status;
  }

  /*
   * ============================
   * SEND TO EACH APPROVED PARENT
   * ============================
   */

  const notificationIds: string[] = [];

  for (const linkDocument of parentLinksSnapshot.docs) {
    const linkData = linkDocument.data();

    const parentId =
        typeof linkData.parentId === "string"
            ? linkData.parentId.trim()
            : "";

    if (!parentId) {
      console.warn(
        "ATTENDANCE NOTIFICATION - Link has no parentId:",
        linkDocument.id,
      );

      continue;
    }

    const notificationId =
        await sendPushNotification({
          parentId: parentId,

          title:
              `Attendance - ${statusLabel}`,

          message:
              `Aapke child ki attendance ${date} ko ${statusLabel} mark hui hai.`,

          type: "attendance",

          studentId: studentId,

          data: {
            notificationType:
                "attendance",
            attendanceDate: date,
            attendanceStatus: status,
          },
        });

    notificationIds.push(
      notificationId,
    );
  }

  /*
   * ============================
   * RESPONSE
   * ============================
   */

  console.log(
    "ATTENDANCE NOTIFICATION - Notifications created:",
    notificationIds.length,
  );

  return notificationIds;
}