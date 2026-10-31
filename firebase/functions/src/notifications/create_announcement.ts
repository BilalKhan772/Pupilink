
import { onCall, HttpsError } from "firebase-functions/v2/https";
import {
  getFirestore,
  FieldValue,
} from "firebase-admin/firestore";

const db = getFirestore();

interface AnnouncementRecipientChild {
  studentId: string;
  name: string;
  classId: string;
  className: string;
  section: string;
  schoolName: string;
}

export const createAnnouncement = onCall(async (request) => {
  // -------------------------------------------------------------------------
  // 1. Authentication
  // -------------------------------------------------------------------------

  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Please log in first.",
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
    typeof input.title === "string"
      ? input.title.trim()
      : "";

  const body =
    typeof input.body === "string"
      ? input.body.trim()
      : "";

  const recipientType = input.recipientType;
  const classIds = input.classIds;

  // -------------------------------------------------------------------------
  // 2. Validate announcement input
  // -------------------------------------------------------------------------

  if (!title || title.length > 150) {
    throw new HttpsError(
      "invalid-argument",
      "Title is required and cannot exceed 150 characters.",
    );
  }

  if (!body || body.length > 5000) {
    throw new HttpsError(
      "invalid-argument",
      "Message is required and cannot exceed 5,000 characters.",
    );
  }

  if (
    recipientType !== "all" &&
    recipientType !== "classes"
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Invalid recipient option.",
    );
  }

  if (
    !Array.isArray(classIds) ||
    !classIds.every(
      (id): id is string =>
        typeof id === "string" &&
        id.trim().length > 0,
    )
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Invalid class selection.",
    );
  }

  const selectedClassIds = [
    ...new Set(
      (classIds as string[]).map((id) => id.trim()),
    ),
  ];

  if (
    recipientType === "all" &&
    selectedClassIds.length !== 0
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Class selection must be empty when sending to all parents.",
    );
  }

  if (
    recipientType === "classes" &&
    (
      selectedClassIds.length === 0 ||
      selectedClassIds.length > 30
    )
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Select between 1 and 30 classes.",
    );
  }

  // -------------------------------------------------------------------------
  // 3. Verify school admin
  // -------------------------------------------------------------------------

  const adminSnapshot = await db
    .collection("users")
    .doc(adminId)
    .get();

  if (!adminSnapshot.exists) {
    throw new HttpsError(
      "failed-precondition",
      "Admin profile was not found.",
    );
  }

  const adminData = adminSnapshot.data()!;

  const schoolId =
    typeof adminData.schoolId === "string"
      ? adminData.schoolId.trim()
      : "";

  if (
    adminData.role !== "schoolAdmin" ||
    !schoolId
  ) {
    throw new HttpsError(
      "permission-denied",
      "Only a valid school admin can send announcements.",
    );
  }

  // -------------------------------------------------------------------------
  // 4. Validate selected classes
  // -------------------------------------------------------------------------

  if (recipientType === "classes") {
    const classSnapshots = await Promise.all(
      selectedClassIds.map((id) =>
        db.collection("classes").doc(id).get(),
      ),
    );

    for (const classSnapshot of classSnapshots) {
      const classData = classSnapshot.data();

      if (
        !classSnapshot.exists ||
        !classData ||
        classData.schoolId !== schoolId ||
        classData.isActive === false
      ) {
        throw new HttpsError(
          "permission-denied",
          "A selected class is invalid or does not belong to your school.",
        );
      }
    }
  }

  // -------------------------------------------------------------------------
  // 5. Fetch eligible students from this school
  // -------------------------------------------------------------------------

  const studentsSnapshot = await db
    .collection("students")
    .where("schoolId", "==", schoolId)
    .get();

  const eligibleStudents =
    new Map<string, AnnouncementRecipientChild>();

  for (const studentDoc of studentsSnapshot.docs) {
    const student = studentDoc.data();

    // Ignore inactive students.
    if (student.isActive === false) {
      continue;
    }

    const classId =
      typeof student.classId === "string"
        ? student.classId
        : "";

    // For selected classes, only include matching students.
    if (
      recipientType === "classes" &&
      !selectedClassIds.includes(classId)
    ) {
      continue;
    }

    eligibleStudents.set(studentDoc.id, {
      studentId: studentDoc.id,

      name:
        typeof student.name === "string"
          ? student.name.trim()
          : "",

      classId,

      className:
        typeof student.className === "string"
          ? student.className.trim()
          : "",

      section:
        typeof student.section === "string"
          ? student.section.trim()
          : "",

      schoolName:
        typeof student.schoolName === "string"
          ? student.schoolName.trim()
          : "",
    });
  }

  if (eligibleStudents.size === 0) {
    return {
      success: true,
      recipientCount: 0,
      message: "No eligible students were found for this audience.",
    };
  }

  // -------------------------------------------------------------------------
  // 6. Fetch approved parent-child links
  // -------------------------------------------------------------------------

  const linksSnapshot = await db
    .collection("parent_child_links")
    .where("schoolId", "==", schoolId)
    .where("status", "==", "approved")
    .get();

  // One parent can have multiple eligible children.
  // Each child is stored only once per parent.
  const parentChildren = new Map<
    string,
    Map<string, AnnouncementRecipientChild>
  >();

  for (const linkDoc of linksSnapshot.docs) {
    const link = linkDoc.data();

    if (
      typeof link.parentId !== "string" ||
      typeof link.studentId !== "string"
    ) {
      continue;
    }

    const recipientChild = eligibleStudents.get(
      link.studentId,
    );

    if (!recipientChild) {
      continue;
    }

    let parentStudentMap = parentChildren.get(
      link.parentId,
    );

    if (!parentStudentMap) {
      parentStudentMap = new Map<
        string,
        AnnouncementRecipientChild
      >();

      parentChildren.set(
        link.parentId,
        parentStudentMap,
      );
    }

    parentStudentMap.set(
      recipientChild.studentId,
      recipientChild,
    );
  }

  if (parentChildren.size === 0) {
    return {
      success: true,
      recipientCount: 0,
      message: "No eligible approved parent connections were found.",
    };
  }

  // -------------------------------------------------------------------------
  // 7. Resolve school name
  // -------------------------------------------------------------------------

  const adminSchoolName =
    typeof adminData.schoolName === "string"
      ? adminData.schoolName.trim()
      : "";

  // Correct TypeScript string check.
  const studentSchoolName = [
    ...eligibleStudents.values(),
  ].find(
    (student) =>
      student.schoolName.trim().length > 0,
  );

  const schoolName =
    adminSchoolName ||
    studentSchoolName?.schoolName.trim() ||
    "";

  // -------------------------------------------------------------------------
  // 8. Generate a shared announcement ID
  // -------------------------------------------------------------------------

  // All parent notification documents created for this announcement
  // will carry the same announcementId.
  const announcementId =
    db.collection("announcements").doc().id;

  // -------------------------------------------------------------------------
  // 9. Create one notification per unique parent
  // -------------------------------------------------------------------------

  const recipientIds = [
    ...parentChildren.keys(),
  ];

  const createdAt = FieldValue.serverTimestamp();

  // Keep each batch below Firestore's 500-write batch limit.
  for (
    let start = 0;
    start < recipientIds.length;
    start += 400
  ) {
    const batch = db.batch();

    const chunk = recipientIds.slice(
      start,
      start + 400,
    );

    for (const parentId of chunk) {
      const notificationRef = db
        .collection("notifications")
        .doc();

      const recipientStudentMap =
        parentChildren.get(parentId);

      // For selected classes, save only this parent's
      // children who belong to the selected classes.
      //
      // For all-school announcements, do not duplicate
      // child records inside the notification.
      const recipientChildren =
        recipientType === "classes"
          ? Array.from(
              recipientStudentMap?.values() ?? [],
            )
          : [];

      batch.set(notificationRef, {
        parentId,
        schoolId,

        ...(schoolName
          ? { schoolName }
          : {}),

        announcementId,

        title,
        body,

        type: "announcement",

        recipientType,

        classIds:
          recipientType === "classes"
            ? selectedClassIds
            : [],

        recipientChildren,

        isRead: false,
        createdAt,
      });
    }

    await batch.commit();
  }

  // -------------------------------------------------------------------------
  // 10. Return result to the admin app
  // -------------------------------------------------------------------------

  return {
    success: true,
    recipientCount: recipientIds.length,
    announcementId,
  };
});
