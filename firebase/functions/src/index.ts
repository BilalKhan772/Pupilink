import { setGlobalOptions } from "firebase-functions";

import { linkChild } from "./parents/link_child";
import { approveChildLink } from "./parents/approve_child_link";

setGlobalOptions({
  maxInstances: 10,
});

export {
    linkChild,
    approveChildLink,
};