
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getAuth } from "firebase-admin/auth";
import {
  FieldValue,
  getFirestore,
} from "firebase-admin/firestore";

const db = getFirestore();
const auth = getAuth();

export const createMonitorAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Pehle School Admin account se login karein.",
    );
  }

  const adminUid = request.auth.uid;

  const adminSnapshot = await db
    .collection("users")
    .doc(adminUid)
    .get();

  if (!adminSnapshot.exists) {
    throw new HttpsError(
      "permission-denied",
      "Admin profile nahi mila.",
    );
  }

  const admin = adminSnapshot.data()!;

  if (admin.role !== "schoolAdmin") {
    throw new HttpsError(
      "permission-denied",
      "Sirf School Admin monitor account bana sakta hai.",
    );
  }

  const schoolId =
    typeof admin.schoolId === "string"
      ? admin.schoolId.trim()
      : "";

  if (!schoolId) {
    throw new HttpsError(
      "failed-precondition",
      "Admin profile mein schoolId missing hai.",
    );
  }

  const data = request.data as {
    name?: unknown;
    email?: unknown;
    password?: unknown;
    sectionId?: unknown;
  };

  const name =
    typeof data.name === "string" ? data.name.trim() : "";

  const email =
    typeof data.email === "string"
      ? data.email.trim().toLowerCase()
      : "";

  const password =
    typeof data.password === "string" ? data.password : "";

  const sectionId =
    typeof data.sectionId === "string"
      ? data.sectionId.trim()
      : "";

  if (
    !name ||
    name.length > 100 ||
    !email ||
    !email.includes("@") ||
    password.length < 8 ||
    password.length > 128 ||
    !sectionId
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Name, valid email, kam az kam 8-character password aur section select karein.",
    );
  }

  const sectionRef = db.collection("sections").doc(sectionId);
  const sectionSnapshot = await sectionRef.get();

  if (!sectionSnapshot.exists) {
    throw new HttpsError(
      "not-found",
      "Selected section nahi mila.",
    );
  }

  const section = sectionSnapshot.data()!;

  if (section.schoolId !== schoolId) {
    throw new HttpsError(
      "permission-denied",
      "Yeh section aapke school ka nahi hai.",
    );
  }

  if (section.isActive === false) {
    throw new HttpsError(
      "failed-precondition",
      "Inactive section ko monitor assign nahi kar sakte.",
    );
  }

  let createdUid: string | undefined;

  try {
    const newUser = await auth.createUser({
      email,
      password,
      displayName: name,
      emailVerified: false,
      disabled: false,
    });

    createdUid = newUser.uid;

    await db.collection("users").doc(newUser.uid).set({
      uid: newUser.uid,
      name,
      email,
      role: "monitor",
      schoolId,
      classId: section.classId,
      sectionId,
      sectionName: section.name ?? "",
      createdBy: adminUid,
      isActive: true,
      createdAt: FieldValue.serverTimestamp(),
    });

    await auth.setCustomUserClaims(newUser.uid, {
      role: "monitor",
      schoolId,
      classId: section.classId,
      sectionId,
    });

    await sectionRef.update({
      monitorId: newUser.uid,
      monitorName: name,
      monitorEmail: email,
      monitorAssignedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      uid: newUser.uid,
      name,
      email,
      role: "monitor",
      schoolId,
      classId: section.classId,
      sectionId,
      sectionName: section.name ?? "",
    };
  } catch (error) {
    if (createdUid) {
      try {
        await db.collection("users").doc(createdUid).delete();
      } catch (cleanupError) {
        console.error(
          "Monitor profile cleanup failed:",
          cleanupError,
        );
      }

      try {
        await auth.deleteUser(createdUid);
      } catch (cleanupError) {
        console.error(
          "Monitor Auth cleanup failed:",
          cleanupError,
        );
      }
    }

    if (error instanceof HttpsError) {
      throw error;
    }

    console.error("Monitor account creation failed:", error);

    throw new HttpsError(
      "internal",
      "Monitor account create nahi ho saka. Email pehle se registered ho sakti hai ya server error hua hai.",
    );
  }
});
