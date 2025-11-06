import { extensions } from "@neutralinojs/lib";

export const bunRun = async (
  functionName: string,
  parameter: string | null = null,
) => {
  const ext = "extBun";
  const event = "runBun";

  const data = { function: functionName, parameter };

  console.log(`EXT_BUN: Calling ${ext}.${event}: ${JSON.stringify(data)}`);

  await extensions.dispatch(ext, event, data);
};
