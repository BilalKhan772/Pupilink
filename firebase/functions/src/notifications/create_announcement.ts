
import { onCall, HttpsError } from "firebase-functions/v2/https";
import {
  getFirestore,
  FieldValue,
} from "firebase-admin/firestore";

const db = getFirestore();

export const createAnnouncement = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Pehle login karein.",
    );
  }

  const adminId = request.auth.uid;
  const input = request.data as {
    title?: unknown;
    body?: unknown;
    recipientType?: unknown;
    classIds?: unknown;
  };

  const title =
    typeof input.title === "string" ? input.title.trim() : "";
  const body =
    typeof input.body === "string" ? input.body.trim() : "";
  const recipientType = input.recipientType;
  const classIds = input.classIds;

  if (!title || title.length > 150) {
    throw new HttpsError(
      "invalid-argument",
      "Title required hai aur 150 characters se zyada nahi ho sakta.",
    );
  }

  if (!body || body.length > 5000) {
    throw new HttpsError(
      "invalid-argument",
      "Message required hai aur 5000 characters se zyada nahi ho sakta.",
    );
  }

  if (recipientType !== "all" && recipientType !== "classes") {
    throw new HttpsError(
      "invalid-argument",
      "Recipient option valid nahi hai.",
    );
  }

  if (
    !Array.isArray(classIds) ||
    !classIds.every(
      (id): id is string =>
        typeof id === "string" && id.trim().length > 0,
    )
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Class selection valid nahi hai.",
    );
  }

  const selectedClassIds = [
    ...new Set((classIds as string[]).map((id) => id.trim())),
  ];

  if (recipientType === "all" && selectedClassIds.length !== 0) {
    throw new HttpsError(
      "invalid-argument",
      "All Parents ke liye class selection empty honi chahiye.",
    );
  }

  if (
    recipientType === "classes" &&
    (selectedClassIds.length === 0 || selectedClassIds.length > 30)
  ) {
    throw new HttpsError(
      "invalid-argument",
      "1 se 30 classes select karein.",
    );
  }

  const adminSnapshot = await db
    .collection("users")
    .doc(adminId)
    .get();

  if (!adminSnapshot.exists) {
    throw new HttpsError(
      "failed-precondition",
      "Admin profile nahi mila.",
    );
  }

  const adminData = adminSnapshot.data()!;
  const schoolId =
    typeof adminData.schoolId === "string"
      ? adminData.schoolId.trim()
      : "";

  if (adminData.role !== "schoolAdmin" || !schoolId) {
    throw new HttpsError(
      "permission-denied",
      "Sirf valid school admin announcement bhej sakta hai.",
    );
  }

  // Validate selected classes against the admin's own school.
  if (recipientType === "classes") {
    const classSnapshots = await Promise.all(
      selectedClassIds.map((id) =>
        db.collection("classes").doc(id).get(),
      ),
    );

    for (let i = 0; i < classSnapshots.length; i++) {
      const classSnapshot = classSnapshots[i];

      if (
        !classSnapshot.exists ||
        classSnapshot.data()?.schoolId !== schoolId ||
        classSnapshot.data()?.isActive === false
      ) {
        throw new HttpsError(
          "permission-denied",
          "Selected class invalid hai ya aapke school se belong nahi karti.",
        );
      }
    }
  }

  // Get students in this school.
  const studentsSnapshot = await db
    .collection("students")
    .where("schoolId", "==", schoolId)
    .get();

  const eligibleStudentIds = new Set<string>();

  for (const studentDoc of studentsSnapshot.docs) {
    const student = studentDoc.data();

    if (student.isActive === false) continue;

    if (
      recipientType === "classes" &&
      !selectedClassIds.includes(
        typeof student.classId === "string" ? student.classId : "",
      )
    ) {
      continue;
    }

    eligibleStudentIds.add(studentDoc.id);
  }

  if (eligibleStudentIds.size === 0) {
    return {
      success: true,
      recipientCount: 0,
      message: "Selected audience mein eligible students nahi mile.",
    };
  }

  // Only approved parent-child links are eligible.
  const linksSnapshot = await db
    .collection("parent_child_links")
    .where("schoolId", "==", schoolId)
    .where("status", "==", "approved")
    .get();

  const parentIds = new Set<string>();

  for (const linkDoc of linksSnapshot.docs) {
    const link = linkDoc.data();

    if (
      typeof link.parentId === "string" &&
      typeof link.studentId === "string" &&
      eligibleStudentIds.has(link.studentId)
    ) {
      parentIds.add(link.parentId);
    }
  }

  if (parentIds.size === 0) {
    return {
      success: true,
      recipientCount: 0,
      message: "Kisi eligible student ka approved parent link nahi mila.",
    };
  }

  // Create one notification per unique parent.
  const recipients = [...parentIds];
  const createdAt = FieldValue.serverTimestamp();

  for (let start = 0; start < recipients.length; start += 400) {
    const batch = db.batch();
    const chunk = recipients.slice(start, start + 400);

    for (const parentId of chunk) {
      const notificationRef = db.collection("notifications").doc();

      batch.set(notificationRef, {
        parentId,
        schoolId,
        title,
        body,
        type: "announcement",
        isRead: false,
        createdAt,
      });
    }

    await batch.commit();
  }

  return {
    success: true,
    recipientCount: recipients.length,
  };
});
