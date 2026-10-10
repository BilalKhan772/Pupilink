import {getApps, initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";

import {
  sendPushNotification,
} from "./send_push_notification";

if (getApps().length === 0) {
  initializeApp();
}

const db = getFirestore();

export interface SendTestReminderInput {
  studentId: string;
  date: string;
  subject: string;
  testName: string;
  description?: string;
}

export async function sendTestReminder(
  input: SendTestReminderInput,
): Promise<string[]> {
  const studentId = input.studentId.trim();
  const date = input.date.trim();
  const subject = input.subject.trim();
  const testName = input.testName.trim();
  const description =
      input.description?.trim() ?? "";

  if (!studentId) {
    throw new Error(
      "Test reminder ke liye studentId required hai.",
    );
  }

  if (!date) {
    throw new Error(
      "Test reminder ke liye date required hai.",
    );
  }

  if (!subject) {
    throw new Error(
      "Test reminder ke liye subject required hai.",
    );
  }

  if (!testName) {
    throw new Error(
      "Test name required hai.",
    );
  }

  const parentLinksSnapshot = await db
      .collection("parent_child_links")
      .where("studentId", "==", studentId)
      .where("status", "==", "approved")
      .get();

  if (parentLinksSnapshot.empty) {
    console.log(
      "TEST REMINDER - No approved parent found for student:",
      studentId,
    );

    return [];
  }

  const notificationIds: string[] = [];

  const message = description.length > 0
      ? `${testName} ${date} ko scheduled hai. ${description}`
      : `${testName} ${date} ko scheduled hai.`;

  for (const linkDocument of parentLinksSnapshot.docs) {
    const linkData = linkDocument.data();

    const parentId =
        typeof linkData.parentId === "string"
            ? linkData.parentId.trim()
            : "";

    if (!parentId) {
      console.warn(
        "TEST REMINDER - Link has no parentId:",
        linkDocument.id,
      );

      continue;
    }

    const notificationId =
        await sendPushNotification({
          parentId: parentId,
          title:
              `Upcoming Test - ${subject}`,
          message: message,
          type: "test_reminder",
          studentId: studentId,
          data: {
            notificationType:
                "test_reminder",
            testDate: date,
            subject: subject,
            testName: testName,
          },
        });

    notificationIds.push(
      notificationId,
    );
  }

  console.log(
    "TEST REMINDER - Notifications created:",
    notificationIds.length,
  );

  return notificationIds;
}