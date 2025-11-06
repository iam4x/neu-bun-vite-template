import type {
  Handlers,
  Config,
  MessageData,
  EventData,
  DebugTag,
} from "./extension.types";

export class NeutralinoBunExtension {
  private debug: boolean;
  private debugTermColors: boolean = true;
  private debugTermColorIN: string = "\x1b[32m";
  private debugTermColorCALL: string = "\x1b[91m";
  private debugTermColorOUT: string = "\x1b[33m";
  private termOnWindowClose: boolean = true;

  private port!: string;
  private token!: string;
  private connectToken!: string;
  private idExtension!: string;
  private urlSocket!: string;
  private socket?: WebSocket;
  private handlers?: Handlers;

  constructor(debug: boolean = false) {
    this.debug = debug;
  }

  start = async (handlers: Handlers) => {
    if (Bun.argv.length > 2) {
      const portArg = Bun.argv[2];
      const tokenArg = Bun.argv[3];
      const idArg = Bun.argv[4];

      if (!portArg || !tokenArg || !idArg) {
        throw new Error(
          "Missing required arguments: port, token, or extensionId",
        );
      }

      this.port = portArg.split("=")[1] || "";
      this.token = tokenArg.split("=")[1] || "";
      this.connectToken = "";
      this.idExtension = idArg.split("=")[1] || "";
      this.urlSocket = `ws://127.0.0.1:${this.port}?extensionId=${this.idExtension}`;
    } else {
      const conf: Config = await Bun.stdin.json();
      this.port = conf.nlPort;
      this.token = conf.nlToken;
      this.connectToken = conf.nlConnectToken;
      this.idExtension = conf.nlExtensionId;
      this.urlSocket = `ws://127.0.0.1:${this.port}?extensionId=${this.idExtension}&connectToken=${this.connectToken}`;
    }

    this.socket = undefined;
    this.handlers = handlers;
    this.debugLog(`${this.idExtension} running on port ${this.port}`);

    this.listenNeutralino();
  };

  sendMessage = (event: string, data: any = null): void => {
    const message: MessageData = {
      id: crypto.randomUUID(),
      method: "app.broadcast",
      accessToken: this.token,
      data: { event, data },
    };

    if (this.socket && this.socket.readyState === WebSocket.OPEN) {
      const msg = JSON.stringify(message);
      this.socket.send(msg);
      this.debugLog(msg, "out");
    } else {
      console.warn("WebSocket send: Socket is not connected.");
    }
  };

  private listenNeutralino = () => {
    this.socket = new WebSocket(this.urlSocket);

    this.socket.addEventListener("open", () => {
      console.log("WebSocket ready");
      console.log(`Running on port ${this.port}`);
    });

    this.socket.addEventListener("message", (event: MessageEvent) => {
      let msg: string | EventData =
        typeof event.data === "string"
          ? event.data
          : new TextDecoder().decode(event.data as ArrayBuffer);

      try {
        msg = JSON.parse(msg as string) as EventData;
      } catch {
        // Invalid JSON, ignore
      }

      try {
        if (this.termOnWindowClose) {
          if (
            (msg as EventData).event === "windowClose" ||
            (msg as EventData).event === "appClose"
          ) {
            try {
              process.exit(0);
            } catch {
              // Ignore exit errors
            }
            return;
          }
        }
      } catch {
        // Ignore parsing errors
      }

      this.debugLog(msg, "in");

      if (this.handlers && this.isEvent(msg as EventData, "runBun")) {
        const eventData = msg as EventData;
        const functionName = eventData.data?.function;
        const parameter = eventData.data?.parameter;

        if (functionName && this.handlers[functionName]) {
          const handler = this.handlers[functionName];
          const result = handler(parameter);

          if (result instanceof Promise) {
            result.catch((error) => {
              console.error(`Error in handler "${functionName}":`, error);
            });
          }

          return;
        }
      }
    });

    this.socket.addEventListener("close", (event: CloseEvent) => {
      console.log(
        `WebSocket closed: ${event.code} - ${event.reason || "No reason provided"}`,
      );
    });

    this.socket.addEventListener("error", (error: Event) => {
      console.error(`WebSocket Error: ${error}`);
    });
  };

  private isEvent = (e: EventData, eventName: string): boolean => {
    return "event" in e && e.event === eventName;
  };

  private debugLog = (
    msg: string | EventData,
    tag: DebugTag = "info",
  ): void => {
    if (!this.debug) return;

    let cIN = "";
    let cCALL = "";
    let cOUT = "";
    let cRST = "";

    if (this.debugTermColors) {
      cIN = this.debugTermColorIN;
      cCALL = this.debugTermColorCALL;
      cOUT = this.debugTermColorOUT;
      cRST = "\x1b[0m";
    }

    let msgStr: string;

    try {
      msgStr = typeof msg === "string" ? msg : JSON.stringify(msg);
    } catch {
      msgStr = String(msg);
    }

    if (tag === "in") {
      console.log(
        msgStr.includes("runBun")
          ? `${cCALL}IN:  ${msgStr}${cRST}`
          : `${cIN}IN:  ${msgStr}${cRST}`,
      );
    }

    if (tag === "out") {
      console.log(`${cOUT}OUT: ${msgStr}${cRST}`);
    }
  };
}
