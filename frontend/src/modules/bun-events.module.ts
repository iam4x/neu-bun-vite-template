import { events } from "@neutralinojs/lib";

import { setPingResults } from "../signals";

export const registerBunEvents = () => {
  events.on("pingResult", (event: CustomEvent) => {
    const message = event.detail || "No message";
    setPingResults((prev) => [...prev, message]);
  });
};
