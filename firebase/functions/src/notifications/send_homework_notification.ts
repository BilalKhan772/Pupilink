import {
  sendPushNotification,
} from "./send_push_notification";

/**
 * Input required to send a homework notification
 * to a parent.
 */
export interface SendHomeworkNotificationInput {
  parentId: string;

  studentId?: string;
  studentName?: string;

  subject: string;
  homeworkTitle: string;
  homeworkMessage: string;
}

/**
 * Sends a homework notification to a parent.
 *
 * This function uses the common
 * sendPushNotification() helper.
 */
export async function sendHomeworkNotification(
  input: SendHomeworkNotificationInput,
): Promise<string> {
  const parentId = input.parentId.trim();
  const subject = input.subject.trim();
  const homeworkTitle =
      input.homeworkTitle.trim();
  const homeworkMessage =
      input.homeworkMessage.trim();

  if (!parentId) {
    throw new Error(
      "Homework notification ke liye parentId required hai.",
    );
  }

  if (!subject) {
    throw new Error(
      "Homework notification ke liye subject required hai.",
    );
  }

  if (!homeworkTitle) {
    throw new Error(
      "Homework title required hai.",
    );
  }

  if (!homeworkMessage) {
    throw new Error(
      "Homework message required hai.",
    );
  }

  /*
   * ============================
   * NOTIFICATION TITLE
   * ============================
   */

  const title =
      `New Homework - ${subject}`;

  /*
   * ============================
   * NOTIFICATION MESSAGE
   * ============================
   */

  const message =
      `${homeworkTitle}: ${homeworkMessage}`;

  /*
   * ============================
   * SEND NOTIFICATION
   * ============================
   */

  return await sendPushNotification({
    parentId: parentId,

    title: title,

    message: message,

    type: "homework",

    studentId: input.studentId,

    studentName: input.studentName,

    data: {
      notificationType: "homework",
      subject: subject,
    },
  });
}