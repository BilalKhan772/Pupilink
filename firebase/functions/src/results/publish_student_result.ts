import { onDocumentWritten } from "firebase-functions/v2/firestore";
import {
  getFirestore,
  Timestamp,
} from "firebase-admin/firestore";

const db = getFirestore();

const RESULT_EXPIRY_DAYS = 3;
const DAY_MS = 24 * 60 * 60 * 1000;

function calculateGrade(percentage: number): string {
  if (percentage >= 90) return "A+";
  if (percentage >= 80) return "A";
  if (percentage >= 70) return "B";
  if (percentage >= 60) return "C";
  if (percentage >= 50) return "D";
  return "F";
}

async function removeTemporaryResult(
  markId: string,
  reason: string,
): Promise<void> {
  try {
    await db.collection("results").doc(markId).delete();
  } catch (error) {
    console.error("Unable to remove invalid temporary result.", {
      markId,
      reason,
      error,
    });
  }
}

export const publishStudentResult = onDocumentWritten(
  "studentMarks/{markId}",
  async (event) => {
    const after = event.data?.after;
    const markId = event.params.markId;
    const resultRef = db.collection("results").doc(markId);

    if (!after || !after.exists) {
      await removeTemporaryResult(markId, "The source mark was deleted.");
      return;
    }

    const mark = after.data();

    if (!mark) {
      console.error("Student mark data is missing.", { markId });
      await removeTemporaryResult(markId, "The mark data is missing.");
      return;
    }

    // Draft or otherwise unpublished marks must not appear in the Parent App.
    if (mark.status !== "published") {
      await removeTemporaryResult(markId, "The mark is not published.");
      return;
    }

    const studentId = mark.studentId;
    const examId = mark.examId;
    const schoolId = mark.schoolId;
    const classId = mark.classId;
    const sectionId = mark.sectionId;
    const subjectId = mark.subjectId;

    const obtainedMarks = mark.obtainedMarks;
    const totalMarks = mark.totalMarks;

    if (
      typeof studentId !== "string" ||
      !studentId ||
      typeof examId !== "string" ||
      !examId ||
      typeof schoolId !== "string" ||
      !schoolId ||
      typeof classId !== "string" ||
      !classId ||
      typeof sectionId !== "string" ||
      !sectionId ||
      typeof subjectId !== "string" ||
      !subjectId ||
      typeof obtainedMarks !== "number" ||
      typeof totalMarks !== "number" ||
      !Number.isFinite(obtainedMarks) ||
      !Number.isFinite(totalMarks) ||
      totalMarks <= 0 ||
      obtainedMarks < 0 ||
      obtainedMarks > totalMarks
    ) {
      console.error("Invalid published student mark.", { markId });
      await removeTemporaryResult(markId, "The published mark is invalid.");
      return;
    }

    const testRef = db.collection("tests").doc(examId);
    const studentRef = db.collection("students").doc(studentId);

    const [testSnapshot, studentSnapshot, existingResult] =
      await Promise.all([
        testRef.get(),
        studentRef.get(),
        resultRef.get(),
      ]);

    if (!testSnapshot.exists) {
      console.error("Test document not found.", { examId, markId });
      await removeTemporaryResult(markId, "The test does not exist.");
      return;
    }

    const test = testSnapshot.data();
    const student = studentSnapshot.data();

    if (!test) {
      console.error("Test data is missing.", { examId, markId });
      await removeTemporaryResult(markId, "The test data is missing.");
      return;
    }

    if (!studentSnapshot.exists || !student) {
      console.error("Student document not found.", { studentId, markId });
      await removeTemporaryResult(markId, "The student does not exist.");
      return;
    }

    // Validate the mark against the test's full scope.
    if (
      test.schoolId !== schoolId ||
      test.classId !== classId ||
      test.sectionId !== sectionId ||
      test.subjectId !== subjectId
    ) {
      console.error("Test and mark scope do not match.", { markId });
      await removeTemporaryResult(
        markId,
        "The mark does not match the test class, section, or subject.",
      );
      return;
    }

    // Validate the student against the authoritative student document.
    // This prevents publishing a result for a different class or section.
    if (
      student.schoolId !== schoolId ||
      student.classId !== classId ||
      student.sectionId !== sectionId
    ) {
      console.error("Student and mark scope do not match.", {
        markId,
        studentId,
        markClassId: classId,
        markSectionId: sectionId,
        studentClassId: student.classId,
        studentSectionId: student.sectionId,
      });
      await removeTemporaryResult(
        markId,
        "The student does not belong to the class and section of this mark.",
      );
      return;
    }

    const now = Timestamp.now();
    const previous = existingResult.data();
    const previousExpiry = previous?.expiresAt;

    const wasExpired =
      previousExpiry instanceof Timestamp &&
      previousExpiry.toMillis() <= now.toMillis();

    const publishedAt =
      previous?.publishedAt instanceof Timestamp && !wasExpired
        ? previous.publishedAt
        : now;

    const expiresAt =
      previous?.expiresAt instanceof Timestamp && !wasExpired
        ? previous.expiresAt
        : Timestamp.fromMillis(
            publishedAt.toMillis() + RESULT_EXPIRY_DAYS * DAY_MS,
          );

    const percentage = (obtainedMarks / totalMarks) * 100;

    const testDate =
      test.testDate instanceof Timestamp
        ? test.testDate.toDate().toISOString()
        : test.createdAt instanceof Timestamp
          ? test.createdAt.toDate().toISOString()
          : now.toDate().toISOString();

    const result = {
      studentId,
      schoolId,
      classId,
      sectionId,
      subjectId,
      subject: mark.subjectName ?? test.subjectName ?? "Subject",
      examId,
      examName: test.title ?? "Test",
      testName: test.title ?? "Test",
      obtainedMarks,
      totalMarks,
      percentage,
      grade: calculateGrade(percentage),
      date: testDate,
      publishedAt,
      expiresAt,
      updatedAt: now,
    };

    await resultRef.set(
      {
        ...result,
        ...(existingResult.exists ? {} : { createdAt: now }),
      },
      { merge: true },
    );

    console.log("Student result published.", {
      markId,
      studentId,
      schoolId,
      classId,
      sectionId,
      subjectId,
      expiresAt: expiresAt.toDate().toISOString(),
    });
  },
);