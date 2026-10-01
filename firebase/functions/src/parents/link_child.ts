import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getApps, initializeApp } from "firebase-admin/app";

if (getApps().length === 0) {
    initializeApp();
}

const db = getFirestore();

export const linkChild = onCall(async (request) => {
    /*
     * ============================
     * AUTH CHECK
     * ============================
     */

    if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "Aapko pehle login karna hoga.",
        );
    }

    const parentId = request.auth.uid;

    // ==========================================
    // DEBUG LOGS - TEMPORARY
    // ==========================================

    console.log(
        "LINK CHILD - Parent UID:",
        parentId,
    );

    console.log(
        "LINK CHILD - FIRESTORE_EMULATOR_HOST:",
        process.env.FIRESTORE_EMULATOR_HOST,
    );

    /*
     * ============================
     * INPUT
     * ============================
     */

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

    if (
        city.length === 0 ||
        schoolId.length === 0 ||
        admissionNumber.length === 0
    ) {
        throw new HttpsError(
            "invalid-argument",
            "City, school aur admission number required hain.",
        );
    }

    /*
     * ============================
     * PARENT PROFILE CHECK
     * ============================
     */

    const parentRef = db
        .collection("users")
        .doc(parentId);

    // ==========================================
    // DEBUG LOGS - FIRESTORE CHECK
    // ==========================================

    console.log(
        "LINK CHILD - Parent document path:",
        parentRef.path,
    );

    console.log(
        "LINK CHILD - Firebase project:",
        process.env.GCLOUD_PROJECT,
    );

    console.log(
        "LINK CHILD - Firestore host:",
        process.env.FIRESTORE_EMULATOR_HOST,
    );

    const parentSnapshot =
        await parentRef.get();

    // ==========================================
    // DEBUG - LIST USERS SEEN BY ADMIN SDK
    // ==========================================

    const usersSnapshot =
        await db
            .collection("users")
            .limit(20)
            .get();

    console.log(
        "LINK CHILD - Users collection document count:",
        usersSnapshot.size,
    );

    for (const userDoc of usersSnapshot.docs) {
        console.log(
            "LINK CHILD - User document found:",
            userDoc.id,
        );

        console.log(
            "LINK CHILD - User document data:",
            userDoc.data(),
        );
    }

    console.log(
        "LINK CHILD - Requested parent document ID:",
        parentId,
    );

    // ==========================================
    // DEBUG - EXACT DOCUMENT ID COMPARISON
    // ==========================================

    const matchingUserDocs =
        usersSnapshot.docs.filter(
            (userDoc) =>
                userDoc.id === parentId,
        );

    console.log(
        "LINK CHILD - Matching user document count:",
        matchingUserDocs.length,
    );

    console.log(
        "LINK CHILD - Parent ID length:",
        parentId.length,
    );

    for (const userDoc of usersSnapshot.docs) {
        console.log(
            "LINK CHILD - User ID length:",
            userDoc.id.length,
        );

        console.log(
            "LINK CHILD - User ID JSON:",
            JSON.stringify(userDoc.id),
        );

        console.log(
            "LINK CHILD - Parent ID JSON:",
            JSON.stringify(parentId),
        );
    }

    // ==========================================
    // DEBUG - DIRECT ADMIN SDK READ
    // ==========================================

    const directParentSnapshot =
        await db
            .collection("users")
            .doc(parentId)
            .get();

    console.log(
        "LINK CHILD - Direct parent read exists:",
        directParentSnapshot.exists,
    );

    console.log(
        "LINK CHILD - Direct parent read data:",
        directParentSnapshot.data(),
    );

    console.log(
        "LINK CHILD - Parent document exists:",
        parentSnapshot.exists,
    );

    if (!parentSnapshot.exists) {
        throw new HttpsError(
            "failed-precondition",
            "Parent profile nahi mila.",
        );
    }

    const parentData =
        parentSnapshot.data();

    if (parentData?.role !== "parent") {
        throw new HttpsError(
            "permission-denied",
            "Sirf parent account child link kar sakta hai.",
        );
    }

    /*
     * ============================
     * FIND STUDENT
     * ============================
     */

    const studentQuery =
        await db
            .collection("students")
            .where(
                "admissionNumber",
                "==",
                admissionNumber,
            )
            .where(
                "city",
                "==",
                city,
            )
            .where(
                "schoolId",
                "==",
                schoolId,
            )
            .where(
                "isActive",
                "==",
                true,
            )
            .limit(1)
            .get();

    if (studentQuery.empty) {
        throw new HttpsError(
            "not-found",
            "Is information ke saath koi student nahi mila.",
        );
    }

    const studentDocument =
        studentQuery.docs[0];

    const studentData =
        studentDocument.data();

    const studentId =
        studentDocument.id;

    /*
     * ============================
     * DETERMINISTIC LINK ID
     * ============================
     */

    const linkId =
        `${parentId}_${studentId}`;

    const linkRef =
        db
            .collection("parent_child_links")
            .doc(linkId);

    /*
     * ============================
     * EXISTING LINK CHECK
     * ============================
     */

    const existingLink =
        await linkRef.get();

    if (existingLink.exists) {
        const existingData =
            existingLink.data();

        const status =
            existingData?.status ??
            "pending";

        if (status === "approved") {
            throw new HttpsError(
                "already-exists",
                "Ye child pehle se aapke account ke saath linked hai.",
            );
        }

        if (status === "pending") {
            throw new HttpsError(
                "already-exists",
                "Is child ki linking request already pending hai.",
            );
        }

        /*
         * If previous request was rejected,
         * allow a new request.
         */
    }

    /*
     * ============================
     * CREATE LINK REQUEST
     * ============================
     */

    await linkRef.set({
        parentId: parentId,

        studentId: studentId,

        admissionNumber:
            studentData.admissionNumber ??
            admissionNumber,

        city:
            studentData.city ??
            city,

        schoolId:
            studentData.schoolId ??
            schoolId,

        schoolName:
            studentData.schoolName ??
            "",

        status: "pending",

        requestedAt:
            FieldValue.serverTimestamp(),

        approvedAt: null,

        rejectionReason: null,
    });

    /*
     * ============================
     * RESPONSE
     * ============================
     */

    return {
        success: true,

        linkId: linkId,

        studentId: studentId,

        studentName:
            studentData.name ?? "",

        status: "pending",
    };
});