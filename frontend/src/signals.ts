import { createSignal } from "solid-js";

export const [pingResults, setPingResults] = createSignal<string[]>([]);
