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

    if (!summary) return;

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

    // Read the actual student record so a stale or incorrectly scoped
    // subjectAverages document cannot contribute to this student's total.
    const studentSnapshot = await db
      .collection("students")
      .doc(studentId)
      .get();

    const student = studentSnapshot.data();

    if (
      !studentSnapshot.exists ||
      !student ||
      student.schoolId !== schoolId ||
      typeof student.classId !== "string" ||
      !student.classId ||
      typeof student.sectionId !== "string" ||
      !student.sectionId
    ) {
      console.error(
        "Cannot calculate student average: student scope is missing or invalid.",
        { schoolId, studentId },
      );

      // Do not leave an old overall average that could contain marks from a
      // previous or mismatched section. This document is not used as a trigger.
      await db
        .collection("studentAverages")
        .doc(makeStudentSummaryId(schoolId, studentId))
        .delete()
        .catch((error) => {
          console.error("Unable to remove invalid student average.", {
            schoolId,
            studentId,
            error,
          });
        });
      return;
    }

    const studentClassId = student.classId as string;
    const studentSectionId = student.sectionId as string;

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

      // Ignore stale aggregates associated with another class or section.
      if (
        data.schoolId !== schoolId ||
        data.studentId !== studentId ||
        data.classId !== studentClassId ||
        data.sectionId !== studentSectionId
      ) {
        continue;
      }

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

    const percentage = possibleTotal > 0
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
        classId: studentClassId,
        sectionId: studentSectionId,
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
      classId: studentClassId,
      sectionId: studentSectionId,
      subjectCount,
      percentage,
      grade,
    });
  },
);