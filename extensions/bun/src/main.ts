import { sleep } from "bun";

import { NeutralinoBunExtension } from "./extension/extension";

// Activate Extension
const extension = new NeutralinoBunExtension(true);

// This simulates a long-running task, reporting its progress to the frontend.
async function longRun(_d: any) {
  for (let i = 1; i <= 5; i++) {
    extension.sendMessage("pingResult", `Long-running task ${i}/5`);
    await sleep(1000);
  }
}

// Ping pong neutralino example
function ping(d: any) {
  extension.sendMessage("pingResult", `Bun says PONG, in reply to "${d}"`);
}

await extension.start({
  ping: (json: string) => ping(json),
  longRun: (json: string) => longRun(json),
});
