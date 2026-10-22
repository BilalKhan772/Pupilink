
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

export const publishStudentResult = onDocumentWritten(
  "studentMarks/{markId}",
  async (event) => {
    const after = event.data?.after;

    // Document delete hua ho ya event data available na ho.
    if (!after || !after.exists) {
      return;
    }

    // TypeScript safety: data missing ho to function stop kare.
    const mark = after.data();

    if (!mark) {
      console.error("Student mark data is missing.", {
        markId: event.params.markId,
      });
      return;
    }

    const markId = event.params.markId;

    const studentId = mark.studentId;
    const examId = mark.examId;
    const schoolId = mark.schoolId;
    const subjectId = mark.subjectId;

    const obtainedMarks = Number(mark.obtainedMarks);
    const totalMarks = Number(mark.totalMarks);

    if (
      typeof studentId !== "string" ||
      !studentId ||
      typeof examId !== "string" ||
      !examId ||
      typeof schoolId !== "string" ||
      !schoolId ||
      typeof subjectId !== "string" ||
      !subjectId ||
      !Number.isFinite(obtainedMarks) ||
      !Number.isFinite(totalMarks) ||
      totalMarks <= 0 ||
      obtainedMarks < 0 ||
      obtainedMarks > totalMarks
    ) {
      console.error("Invalid student mark; result not published.", {
        markId,
      });
      return;
    }

    const resultRef = db.collection("results").doc(markId);
    const testRef = db.collection("tests").doc(examId);

    const [testSnapshot, existingResult] = await Promise.all([
      testRef.get(),
      resultRef.get(),
    ]);

    if (!testSnapshot.exists) {
      console.error("Test document not found.", {
        examId,
        markId,
      });
      return;
    }

    const test = testSnapshot.data();

    if (!test) {
      console.error("Test data is missing.", {
        examId,
        markId,
      });
      return;
    }

    // Ensure the mark belongs to the same school, section and subject.
    if (
      test.schoolId !== schoolId ||
      test.sectionId !== mark.sectionId ||
      test.subjectId !== subjectId
    ) {
      console.error("Test and mark data do not match.", {
        markId,
      });
      return;
    }

    const now = Timestamp.now();
    const previous = existingResult.data();

    const previousExpiry = previous?.expiresAt;

    const wasExpired =
      previousExpiry instanceof Timestamp &&
      previousExpiry.toMillis() <= now.toMillis();

    // Updating an unexpired result does not extend its expiry.
    const publishedAt =
      previous?.publishedAt instanceof Timestamp && !wasExpired
        ? previous.publishedAt
        : now;

    const expiresAt =
      previous?.expiresAt instanceof Timestamp && !wasExpired
        ? previous.expiresAt
        : Timestamp.fromMillis(
            publishedAt.toMillis() +
              RESULT_EXPIRY_DAYS * DAY_MS,
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
      sectionId: mark.sectionId ?? test.sectionId ?? "",
      classId: mark.classId ?? test.classId ?? "",
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
        ...(existingResult.exists
          ? {}
          : { createdAt: now }),
      },
      { merge: true },
    );

    console.log("Student result published.", {
      markId,
      studentId,
      expiresAt: expiresAt.toDate().toISOString(),
    });
  },
);
