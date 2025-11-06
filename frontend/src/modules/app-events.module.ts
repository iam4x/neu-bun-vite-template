import { app, events, extensions } from "@neutralinojs/lib";

export const registerAppEvents = () => {
  events.on("trayMenuItemClicked", (event: CustomEvent) => {
    switch (event.detail.id) {
      case "QUIT":
        app.exit();
        break;
    }
  });

  events.on("windowClose", () => {
    app.exit();
  });

  if (window.NL_MODE !== "window") {
    window.addEventListener("beforeunload", async (e: BeforeUnloadEvent) => {
      e.preventDefault();
      await extensions.dispatch("extBun", "appClose", "");
      await app.exit();
    });
  }
};
