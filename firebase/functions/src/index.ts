
import { setGlobalOptions } from "firebase-functions";

import { linkChild } from "./parents/link_child";
import { approveChildLink } from "./parents/approve_child_link";
import { createStaffAccount } from "./auth/create_staff_account";
import { createMonitorAccount } from "./auth/create_monitor_account";
import { setCustomClaims } from "./auth/set_custom_claims";
import { createAnnouncement } from "./notifications/create_announcement";
import { publishStudentResult } from "./results/publish_student_result";
import { expireOldTestResults } from "./scheduled/expire_old_test_results";
import { calculateSubjectAverage } from "./results/calculate_subject_average";
import { calculateStudentAverage } from "./results/calculate_student_average";
import { updateStudentProgressSummary } from "./aggregations/update_student_progress_summary";
import { calculateClassAverage } from "./results/calculate_class_average";
import { calculateClassPosition } from "./results/calculate_class_position";


setGlobalOptions({
  maxInstances: 10,
});

export {
  linkChild,
  approveChildLink,
  createStaffAccount,
  createMonitorAccount,
  setCustomClaims,
  createAnnouncement,
  publishStudentResult,
  expireOldTestResults,
  calculateSubjectAverage,
  calculateStudentAverage,
  updateStudentProgressSummary,
  calculateClassAverage,
  calculateClassPosition,
};
