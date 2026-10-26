
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

      const key = makeSummaryId(
        schoolId,
        studentId,
        subjectId,
      );

      affectedKeys.set(key, {
        schoolId,
        studentId,
        subjectId,
      });
    }

    for (const key of affectedKeys.values()) {
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
      let sectionId = "";
      let classId = "";

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

        subjectName = data.subjectName ?? subjectName;
        sectionId = data.sectionId ?? sectionId;
        classId = data.classId ?? classId;
      }

      const percentage =
        possibleTotal > 0
          ? (obtainedTotal / possibleTotal) * 100
          : 0;

      const summaryRef = db
        .collection("subjectAverages")
        .doc(
          makeSummaryId(
            key.schoolId,
            key.studentId,
            key.subjectId,
          ),
        );

      await summaryRef.set(
        {
          schoolId: key.schoolId,
          studentId: key.studentId,
          subjectId: key.subjectId,
          subject: subjectName,
          sectionId,
          classId,
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
        subjectId: key.subjectId,
        testCount,
        percentage,
      });
    }
  },
);
