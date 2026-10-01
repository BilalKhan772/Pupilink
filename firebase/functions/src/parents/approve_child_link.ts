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

export const approveChildLink = onCall(
    async (request) => {
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

        const approverId =
            request.auth.uid;

        /*
         * ============================
         * INPUT
         * ============================
         */

        const data = request.data as {
            linkId?: unknown;
        };

        const linkId =
            typeof data.linkId === "string"
                ? data.linkId.trim()
                : "";

        if (linkId.length === 0) {
            throw new HttpsError(
                "invalid-argument",
                "Link ID required hai.",
            );
        }

        /*
         * ============================
         * APPROVER PROFILE CHECK
         * ============================
         */

        const approverRef =
            db
                .collection("users")
                .doc(approverId);

        const approverSnapshot =
            await approverRef.get();

        if (!approverSnapshot.exists) {
            throw new HttpsError(
                "failed-precondition",
                "Admin profile nahi mila.",
            );
        }

        const approverData =
            approverSnapshot.data();

        const approverRole =
            approverData?.role;

        /*
         * Sirf superAdmin ya schoolAdmin
         * child link approve kar sakta hai.
         */

        if (
            approverRole !== "superAdmin" &&
            approverRole !== "schoolAdmin"
        ) {
            throw new HttpsError(
                "permission-denied",
                "Sirf school admin ya super admin child link approve kar sakta hai.",
            );
        }

        /*
         * ============================
         * FIND LINK REQUEST
         * ============================
         */

        const linkRef =
            db
                .collection("parent_child_links")
                .doc(linkId);

        const linkSnapshot =
            await linkRef.get();

        if (!linkSnapshot.exists) {
            throw new HttpsError(
                "not-found",
                "Child link request nahi mili.",
            );
        }

        const linkData =
            linkSnapshot.data();

        /*
         * ============================
         * LINK STATUS CHECK
         * ============================
         */

        const status =
            linkData?.status;

        if (status === "approved") {
            throw new HttpsError(
                "already-exists",
                "Ye child link pehle hi approve ho chuki hai.",
            );
        }

        if (status !== "pending") {
            throw new HttpsError(
                "failed-precondition",
                "Sirf pending child link request approve ki ja sakti hai.",
            );
        }

        /*
         * ============================
         * REQUIRED LINK DATA
         * ============================
         */

        const parentId =
            typeof linkData?.parentId === "string"
                ? linkData.parentId
                : "";

        const studentId =
            typeof linkData?.studentId === "string"
                ? linkData.studentId
                : "";

        const schoolId =
            typeof linkData?.schoolId === "string"
                ? linkData.schoolId
                : "";

        if (
            parentId.length === 0 ||
            studentId.length === 0 ||
            schoolId.length === 0
        ) {
            throw new HttpsError(
                "failed-precondition",
                "Child link request mein required information missing hai.",
            );
        }

        /*
         * ============================
         * SCHOOL AUTHORIZATION
         * ============================
         *
         * schoolAdmin sirf apne school ki
         * request approve kar sakta hai.
         *
         * superAdmin kisi bhi school ki
         * request approve kar sakta hai.
         */

        if (
            approverRole === "schoolAdmin"
        ) {
            const adminSchoolId =
                typeof approverData?.schoolId === "string"
                    ? approverData.schoolId.trim()
                    : "";

            if (
                adminSchoolId.length === 0 ||
                adminSchoolId !== schoolId
            ) {
                throw new HttpsError(
                    "permission-denied",
                    "Aap sirf apne school ki child link request approve kar sakte hain.",
                );
            }
        }

        /*
         * ============================
         * STUDENT CHECK
         * ============================
         */

        const studentRef =
            db
                .collection("students")
                .doc(studentId);

        const studentSnapshot =
            await studentRef.get();

        if (!studentSnapshot.exists) {
            throw new HttpsError(
                "not-found",
                "Student nahi mila.",
            );
        }

        const studentData =
            studentSnapshot.data();

        /*
         * Student ko bhi same school se
         * belong karna chahiye.
         */

        if (
            studentData?.schoolId !== schoolId
        ) {
            throw new HttpsError(
                "failed-precondition",
                "Student aur link request ka school match nahi karta.",
            );
        }

        /*
         * ============================
         * APPROVE REQUEST
         * ============================
         */

        await db.runTransaction(
            async (transaction) => {
                transaction.update(
                    linkRef,
                    {
                        status: "approved",

                        approvedAt:
                            FieldValue.serverTimestamp(),

                        approvedBy:
                            approverId,

                        rejectionReason:
                            null,
                    },
                );

                /*
                 * Student document mein parentId
                 * add kar dein.
                 *
                 * Agar parentIds field nahi hai,
                 * arrayUnion usko create kar dega.
                 */

                transaction.update(
                    studentRef,
                    {
                        parentIds:
                            FieldValue.arrayUnion(
                                parentId,
                            ),
                    },
                );
            },
        );

        /*
         * ============================
         * RESPONSE
         * ============================
         */

        return {
            success: true,

            linkId: linkId,

            parentId: parentId,

            studentId: studentId,

            studentName:
                studentData?.name ?? "",

            status: "approved",
        };
    },
);