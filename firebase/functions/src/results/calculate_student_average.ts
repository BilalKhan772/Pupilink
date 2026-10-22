
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import {
  getFirestore,
  FieldValue,
} from "firebase-admin/firestore";

const db = getFirestore();

function calculateGrade(percentage: number): string {
  if (percentage >= 90) return "A+";
  if (percentage >= 80) return "A";
  if (percentage >= 70) return "B";
  if (percentage >= 60) return "C";
  if (percentage >= 50) return "D";
  return "F";
}

function makeStudentSummaryId(
  schoolId: string,
  studentId: string,
): string {
  return [
    encodeURIComponent(schoolId),
    encodeURIComponent(studentId),
  ].join("__");
}

export const calculateStudentAverage = onDocumentWritten(
  "subjectAverages/{summaryId}",
  async (event) => {
    const after = event.data?.after;
    const before = event.data?.before;

    const current = after?.exists ? after.data() : undefined;
    const previous = before?.exists ? before.data() : undefined;
    const summary = current ?? previous;

    if (!summary) {
      return;
    }

    const schoolId = summary.schoolId;
    const studentId = summary.studentId;

    if (
      typeof schoolId !== "string" ||
      !schoolId ||
      typeof studentId !== "string" ||
      !studentId
    ) {
      console.error(
        "Cannot calculate student average: missing identifiers.",
        { summaryId: event.params.summaryId },
      );
      return;
    }

    const subjectSnapshot = await db
      .collection("subjectAverages")
      .where("schoolId", "==", schoolId)
      .where("studentId", "==", studentId)
      .get();

    let obtainedTotal = 0;
    let possibleTotal = 0;
    let subjectCount = 0;

    for (const document of subjectSnapshot.docs) {
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
      subjectCount += 1;
    }

    const percentage =
      possibleTotal > 0
        ? (obtainedTotal / possibleTotal) * 100
        : 0;

    const grade = calculateGrade(percentage);

    const studentSummaryRef = db
      .collection("studentAverages")
      .doc(makeStudentSummaryId(schoolId, studentId));

    await studentSummaryRef.set(
      {
        schoolId,
        studentId,
        totalObtainedMarks: obtainedTotal,
        totalPossibleMarks: possibleTotal,
        percentage,
        grade,
        totalSubjects: subjectCount,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    console.log("Student average updated.", {
      schoolId,
      studentId,
      subjectCount,
      percentage,
      grade,
    });
  },
);
