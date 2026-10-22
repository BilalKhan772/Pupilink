
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import {
  getFirestore,
  FieldValue,
} from "firebase-admin/firestore";

const db = getFirestore();

function getPerformanceLevel(percentage: number): string {
  if (percentage >= 90) return "Excellent";
  if (percentage >= 80) return "Very Good";
  if (percentage >= 70) return "Good";
  if (percentage >= 60) return "Satisfactory";
  if (percentage >= 50) return "Needs Improvement";
  return "At Risk";
}

export const updateStudentProgressSummary = onDocumentWritten(
  "studentAverages/{summaryId}",
  async (event) => {
    const after = event.data?.after;

    if (!after || !after.exists) {
      // Keep the last progress summary if a source average is removed.
      return;
    }

    const average = after.data();

    if (!average) {
      console.error("Student average data is missing.", {
        summaryId: event.params.summaryId,
      });
      return;
    }

    const schoolId = average.schoolId;
    const studentId = average.studentId;
    const obtained = average.totalObtainedMarks;
    const possible = average.totalPossibleMarks;

    if (
      typeof schoolId !== "string" ||
      !schoolId ||
      typeof studentId !== "string" ||
      !studentId ||
      typeof obtained !== "number" ||
      typeof possible !== "number" ||
      !Number.isFinite(obtained) ||
      !Number.isFinite(possible) ||
      obtained < 0 ||
      possible < 0 ||
      obtained > possible
    ) {
      console.error("Invalid student average; progress not updated.", {
        summaryId: event.params.summaryId,
      });
      return;
    }

    const percentage =
      possible > 0 ? (obtained / possible) * 100 : 0;

    const progressRef = db
      .collection("studentProgressSummaries")
      .doc(event.params.summaryId);

    await progressRef.set(
      {
        schoolId,
        studentId,
        totalObtainedMarks: obtained,
        totalPossibleMarks: possible,
        percentage,
        grade: average.grade ?? "N/A",
        totalSubjects:
          typeof average.totalSubjects === "number"
            ? average.totalSubjects
            : 0,
        performanceLevel: getPerformanceLevel(percentage),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    console.log("Student progress summary updated.", {
      schoolId,
      studentId,
      percentage,
    });
  },
);
