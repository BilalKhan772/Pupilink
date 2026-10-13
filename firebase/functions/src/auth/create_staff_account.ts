
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getAuth } from "firebase-admin/auth";
import {
  FieldValue,
  getFirestore,
} from "firebase-admin/firestore";

const db = getFirestore();
const auth = getAuth();

const allowedStaffRoles = [
  "classTeacher",
  "subjectTeacher",
  "monitor",
] as const;

type StaffRole = (typeof allowedStaffRoles)[number];

export const createStaffAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Pehle login karein.",
    );
  }

  const callerUid = request.auth.uid;

  // Verify the caller using the existing Firestore profile.
  const callerSnapshot = await db
    .collection("users")
    .doc(callerUid)
    .get();

  if (!callerSnapshot.exists) {
    throw new HttpsError(
      "permission-denied",
      "Admin profile nahi mila.",
    );
  }

  const caller = callerSnapshot.data()!;

  if (caller.role !== "schoolAdmin") {
    throw new HttpsError(
      "permission-denied",
      "Sirf School Admin staff accounts bana sakta hai.",
    );
  }

  const schoolId =
    typeof caller.schoolId === "string"
      ? caller.schoolId.trim()
      : "";

  if (!schoolId) {
    throw new HttpsError(
      "failed-precondition",
      "Admin profile mein schoolId missing hai.",
    );
  }

  const data = request.data as {
    email?: unknown;
    password?: unknown;
    name?: unknown;
    role?: unknown;
  };

  const email =
    typeof data.email === "string"
      ? data.email.trim().toLowerCase()
      : "";

  const password =
    typeof data.password === "string"
      ? data.password
      : "";

  const name =
    typeof data.name === "string"
      ? data.name.trim()
      : "";

  const role = data.role;

  if (
    !email ||
    !email.includes("@") ||
    !name ||
    name.length > 100 ||
    password.length < 8 ||
    password.length > 128
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Valid email, name aur kam az kam 8-character password dein.",
    );
  }

  if (
    typeof role !== "string" ||
    !allowedStaffRoles.includes(role as StaffRole)
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Staff role allowed list mein nahi hai.",
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
      role,
      schoolId,
      createdBy: callerUid,
      isActive: true,
      createdAt: FieldValue.serverTimestamp(),
    });

    await auth.setCustomUserClaims(newUser.uid, {
      role,
      schoolId,
    });

    return {
      success: true,
      uid: newUser.uid,
      name,
      email,
      role,
      schoolId,
    };
  } catch (error) {
    // Roll back a newly created Auth account if setup fails.
    if (createdUid) {
      try {
        await db.collection("users").doc(createdUid).delete();
      } catch (cleanupError) {
        console.error(
          "Staff profile cleanup failed:",
          cleanupError,
        );
      }

      try {
        await auth.deleteUser(createdUid);
      } catch (cleanupError) {
        console.error(
          "Staff Auth cleanup failed:",
          cleanupError,
        );
      }
    }

    if (error instanceof HttpsError) {
      throw error;
    }

    console.error("Staff account creation failed.");

    throw new HttpsError(
      "internal",
      "Staff account create nahi ho saka. Email pehle se registered ho sakti hai ya server error hua hai.",
    );
  }
});
