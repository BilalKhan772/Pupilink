
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";

const db = getFirestore();
const auth = getAuth();

const allowedStaffRoles = [
  "classTeacher",
  "subjectTeacher",
  "monitor",
] as const;

export const setCustomClaims = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Pehle login karein.",
    );
  }

  const callerUid = request.auth.uid;
  const data = request.data as {
    staffUid?: unknown;
    role?: unknown;
  };

  const staffUid =
    typeof data.staffUid === "string"
      ? data.staffUid.trim()
      : "";

  const role = data.role;

  if (!staffUid || staffUid === callerUid) {
    throw new HttpsError(
      "invalid-argument",
      "Valid staff UID dein.",
    );
  }

  if (
    typeof role !== "string" ||
    !allowedStaffRoles.includes(
      role as (typeof allowedStaffRoles)[number],
    )
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Yeh staff role allowed nahi hai.",
    );
  }

  const callerSnapshot = await db
    .collection("users")
    .doc(callerUid)
    .get();

  const caller = callerSnapshot.data();

  if (
    !callerSnapshot.exists ||
    caller?.role !== "schoolAdmin" ||
    typeof caller.schoolId !== "string" ||
    !caller.schoolId.trim()
  ) {
    throw new HttpsError(
      "permission-denied",
      "Authorized School Admin required hai.",
    );
  }

  const staffRef = db.collection("users").doc(staffUid);
  const staffSnapshot = await staffRef.get();
  const staff = staffSnapshot.data();

  if (
    !staffSnapshot.exists ||
    staff?.schoolId !== caller.schoolId ||
    !allowedStaffRoles.includes(
      staff?.role as (typeof allowedStaffRoles)[number],
    )
  ) {
    throw new HttpsError(
      "permission-denied",
      "Sirf isi school ke existing staff ka role update ho sakta hai.",
    );
  }

  const targetAuthUser = await auth.getUser(staffUid);

  await auth.setCustomUserClaims(staffUid, {
    ...(targetAuthUser.customClaims ?? {}),
    role,
    schoolId: caller.schoolId,
  });

  await staffRef.update({ role });

  return {
    success: true,
    uid: staffUid,
    role,
    schoolId: caller.schoolId,
  };
});
