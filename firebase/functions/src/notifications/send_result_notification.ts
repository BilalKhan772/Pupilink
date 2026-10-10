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
 * Input required for a result notification.
 */
export interface SendResultNotificationInput {
  studentId: string;
  date: string;
  subject: string;
  testName: string;
  obtainedMarks: number;
  totalMarks: number;
}

/**
 * Sends result notifications to all approved
 * parents linked with the student.
 *
 * Flow:
 *
 * results
 *    ↓
 * studentId
 *    ↓
 * parent_child_links
 *    ↓
 * approved parent(s)
 *    ↓
 * sendPushNotification()
 *    ↓
 * notifications
 */
export async function sendResultNotification(
  input: SendResultNotificationInput,
): Promise<string[]> {
  const studentId = input.studentId.trim();
  const date = input.date.trim();
  const subject = input.subject.trim();
  const testName = input.testName.trim();

  if (!studentId) {
    throw new Error(
      "Result notification ke liye studentId required hai.",
    );
  }

  if (!date) {
    throw new Error(
      "Result notification ke liye date required hai.",
    );
  }

  if (!subject) {
    throw new Error(
      "Result notification ke liye subject required hai.",
    );
  }

  if (!testName) {
    throw new Error(
      "Result notification ke liye testName required hai.",
    );
  }

  if (
    !Number.isFinite(input.obtainedMarks)
  ) {
    throw new Error(
      "Obtained marks valid number hona chahiye.",
    );
  }

  if (
    !Number.isFinite(input.totalMarks) ||
    input.totalMarks <= 0
  ) {
    throw new Error(
      "Total marks valid number hona chahiye.",
    );
  }

  /*
   * ============================
   * CALCULATE PERCENTAGE
   * ============================
   */

  const percentage =
      (input.obtainedMarks /
          input.totalMarks) *
      100;

  const percentageText =
      percentage.toFixed(1);

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
      "RESULT NOTIFICATION - No approved parent found for student:",
      studentId,
    );

    return [];
  }

  /*
   * ============================
   * SEND TO EACH APPROVED PARENT
   * ============================
   */

  const notificationIds: string[] = [];

  for (
    const linkDocument
    of parentLinksSnapshot.docs
  ) {
    const linkData =
        linkDocument.data();

    const parentId =
        typeof linkData.parentId === "string"
            ? linkData.parentId.trim()
            : "";

    if (!parentId) {
      console.warn(
        "RESULT NOTIFICATION - Link has no parentId:",
        linkDocument.id,
      );

      continue;
    }

    const notificationId =
        await sendPushNotification({
          parentId: parentId,

          title:
              `Result Published - ${subject}`,

          message:
              `${testName}: ${input.obtainedMarks}/${input.totalMarks} marks (${percentageText}%). Date: ${date}.`,

          type: "results",

          studentId: studentId,

          data: {
            notificationType:
                "result",

            resultDate: date,

            subject: subject,

            testName: testName,

            obtainedMarks:
                String(
                  input.obtainedMarks,
                ),

            totalMarks:
                String(
                  input.totalMarks,
                ),

            percentage:
                percentageText,
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
    "RESULT NOTIFICATION - Notifications created:",
    notificationIds.length,
  );

  return notificationIds;
}