import { init } from "@neutralinojs/lib";

import { registerBunEvents } from "./modules/bun-events.module";
import { registerAppEvents } from "./modules/app-events.module";
import { initializeTray } from "./modules/tray.module";
import { renderApp } from "./render";

init();
initializeTray();

registerAppEvents();
registerBunEvents();

renderApp();
