
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import {
  FieldValue,
  getFirestore,
} from "firebase-admin/firestore";

const db = getFirestore();

function makeStudentAverageId(
  schoolId: string,
  studentId: string,
): string {
  return [
    encodeURIComponent(schoolId),
    encodeURIComponent(studentId),
  ].join("__");
}

function makeClassPositionId(
  schoolId: string,
  studentId: string,
): string {
  return [
    encodeURIComponent(schoolId),
    encodeURIComponent(studentId),
  ].join("__");
}

export const calculateClassPosition = onDocumentWritten(
  "studentAverages/{summaryId}",
  async (event) => {
    const after = event.data?.after;

    if (!after?.exists) return;

    const average = after.data();

    if (!average) return;

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

    // Get the student's class.
    const studentSnapshot = await db
      .collection("students")
      .doc(studentId)
      .get();

    if (!studentSnapshot.exists) {
      console.error("Student document not found.", { studentId });
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
      console.warn("Student has no classId.", { studentId });
      return;
    }

    const percentage = average.percentage;

    if (
      typeof percentage !== "number" ||
      !Number.isFinite(percentage) ||
      percentage < 0 ||
      percentage > 100
    ) {
      console.error("Invalid student percentage.", { studentId });
      return;
    }

    // Find active students in the same school and class.
    const classmatesSnapshot = await db
      .collection("students")
      .where("schoolId", "==", schoolId)
      .where("classId", "==", classId)
      .get();

    const classmates = classmatesSnapshot.docs.filter(
      (doc) => doc.data().isActive !== false,
    );

    // Read each classmate's overall average.
    const classAverages = await Promise.all(
      classmates.map(async (classmate) => {
        const averageSnapshot = await db
          .collection("studentAverages")
          .doc(makeStudentAverageId(schoolId, classmate.id))
          .get();

        if (!averageSnapshot.exists) return null;

        const data = averageSnapshot.data();

        if (!data) return null;

        const classmatePercentage = data.percentage;

        if (
          typeof classmatePercentage !== "number" ||
          !Number.isFinite(classmatePercentage) ||
          classmatePercentage < 0 ||
          classmatePercentage > 100
        ) {
          return null;
        }

        return {
          studentId: classmate.id,
          percentage: classmatePercentage,
        };
      }),
    );

    const validAverages = classAverages.filter(
      (
        item,
      ): item is { studentId: string; percentage: number } =>
        item !== null,
    );

    // Ensure the current student's latest average is included.
    const currentStudentIndex = validAverages.findIndex(
      (item) => item.studentId === studentId,
    );

    if (currentStudentIndex >= 0) {
      validAverages[currentStudentIndex].percentage = percentage;
    } else {
      validAverages.push({ studentId, percentage });
    }

    // Highest percentage gets the highest position.
    validAverages.sort(
      (a, b) => b.percentage - a.percentage,
    );

    // Competition ranking: 1, 2, 2, 4.
    let position = 1;

    for (let i = 0; i < validAverages.length; i++) {
      if (validAverages[i].studentId === studentId) {
        position = i + 1;

        while (
          position > 1 &&
          validAverages[position - 2].percentage === percentage
        ) {
          position--;
        }

        break;
      }
    }

    await db
      .collection("classPositions")
      .doc(makeClassPositionId(schoolId, studentId))
      .set(
        {
          schoolId,
          studentId,
          classId,
          position,
          classSize: validAverages.length,
          percentage,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

    console.log("Class position updated.", {
      schoolId,
      studentId,
      classId,
      position,
      classSize: validAverages.length,
    });
  },
);
