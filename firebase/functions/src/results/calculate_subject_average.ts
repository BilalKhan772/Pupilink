import { onDocumentWritten } from "firebase-functions/v2/firestore";
import {
  getFirestore,
  FieldValue,
} from "firebase-admin/firestore";

const db = getFirestore();

function makeSummaryId(
  schoolId: string,
  studentId: string,
  subjectId: string,
): string {
  return [schoolId, studentId, subjectId]
    .map((value) => encodeURIComponent(value))
    .join("__");
}

function isValidMarks(obtained: unknown, total: unknown): boolean {
  return (
    typeof obtained === "number" &&
    typeof total === "number" &&
    Number.isFinite(obtained) &&
    Number.isFinite(total) &&
    total > 0 &&
    obtained >= 0 &&
    obtained <= total
  );
}

export const calculateSubjectAverage = onDocumentWritten(
  "studentMarks/{markId}",
  async (event) => {
    const beforeSnapshot = event.data?.before;
    const afterSnapshot = event.data?.after;

    const before = beforeSnapshot?.exists
      ? beforeSnapshot.data()
      : undefined;

    const after = afterSnapshot?.exists
      ? afterSnapshot.data()
      : undefined;

    const affectedMarks = [before, after].filter(
      (mark): mark is FirebaseFirestore.DocumentData =>
        mark !== undefined,
    );

    const affectedKeys = new Map<
      string,
      {
        schoolId: string;
        studentId: string;
        subjectId: string;
      }
    >();

    for (const mark of affectedMarks) {
      const { schoolId, studentId, subjectId } = mark;

      if (
        typeof schoolId !== "string" ||
        !schoolId ||
        typeof studentId !== "string" ||
        !studentId ||
        typeof subjectId !== "string" ||
        !subjectId
      ) {
        console.error(
          "Cannot calculate subject average: missing identifiers.",
          { markId: event.params.markId },
        );
        continue;
      }

      const key = makeSummaryId(schoolId, studentId, subjectId);
      affectedKeys.set(key, { schoolId, studentId, subjectId });
    }

    for (const key of affectedKeys.values()) {
      const summaryRef = db
        .collection("subjectAverages")
        .doc(makeSummaryId(key.schoolId, key.studentId, key.subjectId));

      // The students document is the authoritative source of the student's
      // current class and section. Marks from any other section are excluded.
      const studentSnapshot = await db
        .collection("students")
        .doc(key.studentId)
        .get();

      const student = studentSnapshot.data();

      if (
        !studentSnapshot.exists ||
        !student ||
        student.schoolId !== key.schoolId ||
        typeof student.classId !== "string" ||
        !student.classId ||
        typeof student.sectionId !== "string" ||
        !student.sectionId
      ) {
        console.error(
          "Cannot calculate subject average: student scope is missing or invalid.",
          {
            schoolId: key.schoolId,
            studentId: key.studentId,
            subjectId: key.subjectId,
          },
        );

        // Remove stale aggregate data if the student no longer belongs to
        // this school or has no valid class/section assignment.
        await summaryRef.delete().catch((error) => {
          console.error("Unable to remove invalid subject average.", {
            summaryId: summaryRef.id,
            error,
          });
        });
        continue;
      }

      const studentClassId = student.classId as string;
      const studentSectionId = student.sectionId as string;

      const marksSnapshot = await db
        .collection("studentMarks")
        .where("schoolId", "==", key.schoolId)
        .where("studentId", "==", key.studentId)
        .where("subjectId", "==", key.subjectId)
        .where("status", "==", "published")
        .get();

      let obtainedTotal = 0;
      let possibleTotal = 0;
      let testCount = 0;
      let subjectName = "Subject";

      for (const document of marksSnapshot.docs) {
        const data = document.data();

        // Critical scope guard: do not aggregate a mark from another class
        // or section, even when schoolId/studentId/subjectId match.
        if (
          data.schoolId !== key.schoolId ||
          data.studentId !== key.studentId ||
          data.subjectId !== key.subjectId ||
          data.classId !== studentClassId ||
          data.sectionId !== studentSectionId ||
          data.status !== "published"
        ) {
          continue;
        }

        const obtained = data.obtainedMarks;
        const total = data.totalMarks;

        if (!isValidMarks(obtained, total)) {
          continue;
        }

        obtainedTotal += obtained;
        possibleTotal += total;
        testCount += 1;

        if (typeof data.subjectName === "string" && data.subjectName.trim()) {
          subjectName = data.subjectName.trim();
        }
      }

      const percentage = possibleTotal > 0
        ? (obtainedTotal / possibleTotal) * 100
        : 0;

      await summaryRef.set(
        {
          schoolId: key.schoolId,
          studentId: key.studentId,
          subjectId: key.subjectId,
          subject: subjectName,
          // Always persist the student's authoritative scope, not whichever
          // section happened to be encountered last in the marks query.
          sectionId: studentSectionId,
          classId: studentClassId,
          obtainedMarks: obtainedTotal,
          totalMarks: possibleTotal,
          percentage,
          testCount,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      console.log("Subject average updated.", {
        schoolId: key.schoolId,
        studentId: key.studentId,
        classId: studentClassId,
        sectionId: studentSectionId,
        subjectId: key.subjectId,
        testCount,
        percentage,
      });
    }
  },
);