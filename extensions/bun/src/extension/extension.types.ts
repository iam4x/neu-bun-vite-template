export interface Config {
  nlPort: string;
  nlToken: string;
  nlConnectToken: string;
  nlExtensionId: string;
}

export interface EventData {
  event?: string;
  data?: any;
}

export interface MessageData {
  id: string;
  method: string;
  accessToken: string;
  data: {
    event: string;
    data: any;
  };
}

export type DebugTag = "in" | "out" | "info";

export type HandlerFunction = (parameter: any) => void | Promise<void>;

export interface Handlers {
  [key: string]: HandlerFunction;
}
