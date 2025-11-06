import { For } from "solid-js";

import { pingResults, setPingResults } from "../signals";
import { bunRun } from "../modules/bun-run.module";

export const AppComponent = () => {
  const ping = async () => {
    const message = `Ping from Neutralino at ${new Date().toLocaleTimeString()}`;

    try {
      await bunRun("ping", message);
      setPingResults((prev) => [...prev, `Ping: ${message}`]);
    } catch (error) {
      console.error("Error sending ping:", error);
      setPingResults((prev) => [...prev, `Failed to send ping: ${error}`]);
    }
  };

  return (
    <>
      <div>
        {window.NL_APPID} is running on port {window.NL_PORT} inside{" "}
        {window.NL_OS} {window.NL_ARCH}
        <br />
        <br />
        <span>
          server: v{window.NL_VERSION} . client: v{window.NL_CVERSION}
        </span>
      </div>
      <div>
        <button onClick={ping}>Ping</button>
      </div>
      <div>
        <For each={pingResults()}>{(result) => <div>{result}</div>}</For>
      </div>
    </>
  );
};
