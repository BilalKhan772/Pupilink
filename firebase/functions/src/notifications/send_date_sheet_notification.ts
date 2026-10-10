import {getApps, initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";

import {
  sendPushNotification,
} from "./send_push_notification";

if (getApps().length === 0) {
  initializeApp();
}

const db = getFirestore();

export interface SendDateSheetNotificationInput {
  studentId: string;
  examName: string;
  date: string;
  subject: string;
  description?: string;
}

export async function sendDateSheetNotification(
  input: SendDateSheetNotificationInput,
): Promise<string[]> {
  const studentId = input.studentId.trim();
  const examName = input.examName.trim();
  const date = input.date.trim();
  const subject = input.subject.trim();
  const description =
      input.description?.trim() ?? "";

  if (!studentId) {
    throw new Error(
      "Date sheet notification ke liye studentId required hai.",
    );
  }

  if (!examName) {
    throw new Error(
      "Exam name required hai.",
    );
  }

  if (!date) {
    throw new Error(
      "Exam date required hai.",
    );
  }

  if (!subject) {
    throw new Error(
      "Subject required hai.",
    );
  }

  const parentLinksSnapshot = await db
      .collection("parent_child_links")
      .where("studentId", "==", studentId)
      .where("status", "==", "approved")
      .get();

  if (parentLinksSnapshot.empty) {
    console.log(
      "DATE SHEET NOTIFICATION - No approved parent found for student:",
      studentId,
    );

    return [];
  }

  const notificationIds: string[] = [];

  const message = description.length > 0
      ? `${subject} ka exam ${date} ko hai. ${description}`
      : `${subject} ka exam ${date} ko hai.`;

  for (const linkDocument of parentLinksSnapshot.docs) {
    const linkData = linkDocument.data();

    const parentId =
        typeof linkData.parentId === "string"
            ? linkData.parentId.trim()
            : "";

    if (!parentId) {
      console.warn(
        "DATE SHEET NOTIFICATION - Link has no parentId:",
        linkDocument.id,
      );

      continue;
    }

    const notificationId =
        await sendPushNotification({
          parentId: parentId,
          title:
              `Date Sheet - ${examName}`,
          message: message,
          type: "date_sheet",
          studentId: studentId,
          data: {
            notificationType:
                "date_sheet",
            examName: examName,
            examDate: date,
            subject: subject,
          },
        });

    notificationIds.push(
      notificationId,
    );
  }

  console.log(
    "DATE SHEET NOTIFICATION - Notifications created:",
    notificationIds.length,
  );

  return notificationIds;
}