
import { onSchedule } from "firebase-functions/v2/scheduler";
import {
  getFirestore,
  Timestamp,
} from "firebase-admin/firestore";

const db = getFirestore();

const BATCH_SIZE = 400;

export const expireOldTestResults = onSchedule(
  {
    schedule: "every 60 minutes",
    timeZone: "Asia/Karachi",
    region: "asia-south1",
  },
  async () => {
    const now = Timestamp.now();
    let deletedCount = 0;

    while (true) {
      const snapshot = await db
        .collection("results")
        .where("expiresAt", "<=", now)
        .orderBy("expiresAt", "asc")
        .limit(BATCH_SIZE)
        .get();

      if (snapshot.empty) {
        break;
      }

      const batch = db.batch();

      for (const document of snapshot.docs) {
        batch.delete(document.ref);
      }

      await batch.commit();

      deletedCount += snapshot.size;

      if (snapshot.size < BATCH_SIZE) {
        break;
      }
    }

    console.log(
      `Expired test results cleanup completed. Deleted ${deletedCount} documents.`,
    );
  },
);
