
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import {
  getFirestore,
  FieldValue,
} from "firebase-admin/firestore";

const db = getFirestore();

function makeClassAverageId(
  schoolId: string,
  classId: string,
): string {
  return [
    encodeURIComponent(schoolId),
    encodeURIComponent(classId),
  ].join("__");
}

export const calculateClassAverage = onDocumentWritten(
  "studentAverages/{summaryId}",
  async (event) => {
    const after = event.data?.after;

    if (!after || !after.exists) {
      return;
    }

    const average = after.data();

    if (!average) {
      return;
    }

    const schoolId = average.schoolId;
    const studentId = average.studentId;

    if (
      typeof schoolId !== "string" ||
      !schoolId ||
      typeof studentId !== "string" ||
      !studentId
    ) {
      console.error("Missing schoolId or studentId.", {
        summaryId: event.params.summaryId,
      });
      return;
    }

    const studentSnapshot = await db
      .collection("students")
      .doc(studentId)
      .get();

    if (!studentSnapshot.exists) {
      console.error("Student document not found.", {
        studentId,
      });
      return;
    }

    const student = studentSnapshot.data();

    if (!student || student.schoolId !== schoolId) {
      console.error("Student does not belong to this school.", {
        studentId,
        schoolId,
      });
      return;
    }

    const classId = student.classId;

    if (typeof classId !== "string" || !classId) {
      console.warn("Student has no classId; class average skipped.", {
        studentId,
      });
      return;
    }

    const classStudentsSnapshot = await db
      .collection("students")
      .where("schoolId", "==", schoolId)
      .where("classId", "==", classId)
      .get();

    let obtainedTotal = 0;
    let possibleTotal = 0;
    let studentsWithResults = 0;

    for (const classStudent of classStudentsSnapshot.docs) {
      const studentData = classStudent.data();

      if (studentData.isActive === false) {
        continue;
      }

      const studentAverageSnapshot = await db
        .collection("studentAverages")
        .doc(
          [
            encodeURIComponent(schoolId),
            encodeURIComponent(classStudent.id),
          ].join("__"),
        )
        .get();

      if (!studentAverageSnapshot.exists) {
        continue;
      }

      const studentAverage = studentAverageSnapshot.data();

      if (!studentAverage) {
        continue;
      }

      const obtained = studentAverage.totalObtainedMarks;
      const possible = studentAverage.totalPossibleMarks;

      if (
        typeof obtained !== "number" ||
        typeof possible !== "number" ||
        !Number.isFinite(obtained) ||
        !Number.isFinite(possible) ||
        possible <= 0 ||
        obtained < 0 ||
        obtained > possible
      ) {
        continue;
      }

      obtainedTotal += obtained;
      possibleTotal += possible;
      studentsWithResults += 1;
    }

    const percentage =
      possibleTotal > 0
        ? (obtainedTotal / possibleTotal) * 100
        : 0;

    const classAverageRef = db
      .collection("classAverages")
      .doc(makeClassAverageId(schoolId, classId));

    await classAverageRef.set(
      {
        schoolId,
        classId,
        totalObtainedMarks: obtainedTotal,
        totalPossibleMarks: possibleTotal,
        percentage,
        studentsWithResults,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    console.log("Class average updated.", {
      schoolId,
      classId,
      studentsWithResults,
      percentage,
    });
  },
);
