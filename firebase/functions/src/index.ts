
import { setGlobalOptions } from "firebase-functions";
import { linkChild } from "./parents/link_child";
import { approveChildLink } from "./parents/approve_child_link";
import { createStaffAccount } from "./auth/create_staff_account";
import { setCustomClaims } from "./auth/set_custom_claims";

setGlobalOptions({
  maxInstances: 10,
});

export {
  linkChild,
  approveChildLink,
  createStaffAccount,
  setCustomClaims,
};
