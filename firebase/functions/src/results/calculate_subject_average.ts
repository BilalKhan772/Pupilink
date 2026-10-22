
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

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

export const calculateSubjectAverage = onDocumentWritten(
  "studentMarks/{markId}",
  async (event) => {
    const after = event.data?.after;
    const before = event.data?.before;

    // Read the changed document to identify the affected student/subject.
    const current = after?.exists ? after.data() : undefined;
    const previous = before?.exists ? before.data() : undefined;
    const mark = current ?? previous;

    if (!mark) {
      return;
    }

    const schoolId = mark.schoolId;
    const studentId = mark.studentId;
    const subjectId = mark.subjectId;

    if (
      typeof schoolId !== "string" ||
      !schoolId ||
      typeof studentId !== "string" ||
      !studentId ||
      typeof subjectId !== "string" ||
      !subjectId
    ) {
      console.error("Cannot calculate subject average: missing identifiers.", {
        markId: event.params.markId,
      });
      return;
    }

    const marksSnapshot = await db
      .collection("studentMarks")
      .where("schoolId", "==", schoolId)
      .where("studentId", "==", studentId)
      .where("subjectId", "==", subjectId)
      .get();

    let obtainedTotal = 0;
    let possibleTotal = 0;
    let testCount = 0;

    for (const document of marksSnapshot.docs) {
      const data = document.data();
      const obtained = data.obtainedMarks;
      const total = data.totalMarks;

      if (
        typeof obtained !== "number" ||
        typeof total !== "number" ||
        !Number.isFinite(obtained) ||
        !Number.isFinite(total) ||
        total <= 0 ||
        obtained < 0 ||
        obtained > total
      ) {
        continue;
      }

      obtainedTotal += obtained;
      possibleTotal += total;
      testCount += 1;
    }

    const percentage =
      possibleTotal > 0
        ? (obtainedTotal / possibleTotal) * 100
        : 0;

    const summaryRef = db
      .collection("subjectAverages")
      .doc(makeSummaryId(schoolId, studentId, subjectId));

    if (testCount === 0 || possibleTotal === 0) {
      // Keep a zero summary rather than deleting history unexpectedly.
      await summaryRef.set(
        {
          schoolId,
          studentId,
          subjectId,
          obtainedMarks: 0,
          totalMarks: 0,
          percentage: 0,
          testCount: 0,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      return;
    }

    await summaryRef.set(
      {
        schoolId,
        studentId,
        subjectId,
        subject: mark.subjectName ?? "Subject",
        sectionId: mark.sectionId ?? "",
        classId: mark.classId ?? "",
        obtainedMarks: obtainedTotal,
        totalMarks: possibleTotal,
        percentage,
        testCount,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    console.log("Subject average updated.", {
      studentId,
      subjectId,
      testCount,
      percentage,
    });
  },
);
