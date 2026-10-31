
import { onCall, HttpsError } from "firebase-functions/v2/https";
import {
  getFirestore,
  FieldValue,
} from "firebase-admin/firestore";
import {
  getApps,
  initializeApp,
} from "firebase-admin/app";

if (getApps().length === 0) {
  initializeApp();
}

const db = getFirestore();

export const linkChild = onCall(async (request) => {
  // --------------------------------------------------
  // 1. AUTHENTICATION
  // --------------------------------------------------

  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Please log in before connecting a child.",
    );
  }

  const parentId = request.auth.uid;

  // --------------------------------------------------
  // 2. INPUT VALIDATION
  // --------------------------------------------------

  const data = request.data as {
    city?: unknown;
    schoolId?: unknown;
    admissionNumber?: unknown;
  };

  const city =
    typeof data.city === "string"
      ? data.city.trim()
      : "";

  const schoolId =
    typeof data.schoolId === "string"
      ? data.schoolId.trim()
      : "";

  const admissionNumber =
    typeof data.admissionNumber === "string"
      ? data.admissionNumber.trim()
      : "";

  if (!city || !schoolId || !admissionNumber) {
    throw new HttpsError(
      "invalid-argument",
      "City, school and admission number are required.",
    );
  }

  if (
    city.length > 100 ||
    schoolId.length > 150 ||
    admissionNumber.length > 64
  ) {
    throw new HttpsError(
      "invalid-argument",
      "One or more entered values are too long.",
    );
  }

  // --------------------------------------------------
  // 3. VERIFY PARENT ACCOUNT
  // --------------------------------------------------

  const parentRef = db
    .collection("users")
    .doc(parentId);

  const parentSnapshot = await parentRef.get();

  if (!parentSnapshot.exists) {
    throw new HttpsError(
      "failed-precondition",
      "Parent profile could not be found.",
    );
  }

  const parentData = parentSnapshot.data();

  if (parentData?.role !== "parent") {
    throw new HttpsError(
      "permission-denied",
      "Only parent accounts can connect students.",
    );
  }

  // --------------------------------------------------
  // 4. FIND STUDENT
  // --------------------------------------------------

  const studentQuery = await db
    .collection("students")
    .where("admissionNumber", "==", admissionNumber)
    .where("city", "==", city)
    .where("schoolId", "==", schoolId)
    .where("isActive", "==", true)
    .limit(2)
    .get();

  if (studentQuery.empty) {
    throw new HttpsError(
      "not-found",
      "No active student was found with these details.",
    );
  }

  // Avoid connecting the wrong student when duplicate
  // admission records exist.
  if (studentQuery.docs.length > 1) {
    throw new HttpsError(
      "failed-precondition",
      "Multiple student records have this admission number. "
      + "Please contact the school.",
    );
  }

  const studentDocument = studentQuery.docs[0];
  const studentId = studentDocument.id;

  const studentRef = db
    .collection("students")
    .doc(studentId);

  // --------------------------------------------------
  // 5. DETERMINISTIC LINK ID
  // --------------------------------------------------

  const linkId = `${parentId}_${studentId}`;

  const linkRef = db
    .collection("parent_child_links")
    .doc(linkId);

  // --------------------------------------------------
  // 6. AUTOMATIC LINK TRANSACTION
  // --------------------------------------------------

  const linkResult = await db.runTransaction(
    async (transaction) => {
      // Read both documents before making any writes.
      const [freshStudentSnapshot, existingLinkSnapshot] =
          await Promise.all([
        transaction.get(studentRef),
        transaction.get(linkRef),
      ]);

      if (!freshStudentSnapshot.exists) {
        throw new HttpsError(
          "not-found",
          "Student record could not be found.",
        );
      }

      const freshStudentData =
          freshStudentSnapshot.data();

      if (!freshStudentData) {
        throw new HttpsError(
          "failed-precondition",
          "Student information is unavailable.",
        );
      }

      // Recheck student details inside the transaction.
      if (
        freshStudentData.schoolId !== schoolId ||
        freshStudentData.city !== city ||
        freshStudentData.admissionNumber !== admissionNumber ||
        freshStudentData.isActive !== true
      ) {
        throw new HttpsError(
          "failed-precondition",
          "Student information changed. Please verify the details.",
        );
      }

      const existingData = existingLinkSnapshot.exists
        ? existingLinkSnapshot.data()
        : undefined;

      const existingStatus = existingData?.status;

      // ----------------------------------------------
      // ALREADY CONNECTED
      // ----------------------------------------------

      if (existingStatus === "approved") {
        // Repair parentIds if an older approved link
        // exists but the student document is missing it.
        transaction.update(studentRef, {
          parentIds: FieldValue.arrayUnion(parentId),
        });

        return {
          studentName:
              freshStudentData.name ?? "",
          alreadyLinked: true,
        };
      }

      // ----------------------------------------------
      // ALLOW NEW OR PREVIOUSLY PENDING/REJECTED LINK
      // ----------------------------------------------

      if (
        existingStatus !== undefined &&
        existingStatus !== "pending" &&
        existingStatus !== "rejected"
      ) {
        throw new HttpsError(
          "failed-precondition",
          "This child connection cannot be updated.",
        );
      }

      // ----------------------------------------------
      // SAVE APPROVED LINK DIRECTLY
      // ----------------------------------------------

      transaction.set(
        linkRef,
        {
          parentId: parentId,
          studentId: studentId,

          admissionNumber:
              freshStudentData.admissionNumber,

          city: freshStudentData.city,
          schoolId: freshStudentData.schoolId,

          schoolName:
              freshStudentData.schoolName ?? "",

          // Direct automatic linking.
          status: "approved",

          // Preserve the original request time when
          // approving a previously pending request.
          requestedAt:
              existingData?.requestedAt ??
              FieldValue.serverTimestamp(),

          approvedAt:
              FieldValue.serverTimestamp(),

          approvedBy: "system",
          autoApproved: true,

          rejectionReason: null,

          updatedAt:
              FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      // Add the parent UID to the student's parent list.
      // This is done atomically with the link document.
      transaction.update(studentRef, {
        parentIds: FieldValue.arrayUnion(parentId),
      });

      return {
        studentName:
            freshStudentData.name ?? "",
        alreadyLinked: false,
      };
    },
  );

  // --------------------------------------------------
  // 7. RESPONSE
  // --------------------------------------------------

  console.log("Child automatically linked.", {
    parentId,
    studentId,
    alreadyLinked: linkResult.alreadyLinked,
  });

  return {
    success: true,
    linkId: linkId,
    studentId: studentId,
    studentName: linkResult.studentName,
    status: "approved",
    alreadyLinked: linkResult.alreadyLinked,
  };
});
