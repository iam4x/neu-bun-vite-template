import { os } from "@neutralinojs/lib";

// windows tray menu setup
export const initializeTray = () => {
  if (window.NL_OS !== "Darwin") {
    if (window.NL_MODE !== "window") {
      console.log("INFO: Tray menu is only available in the window mode.");
    } else {
      // Define tray menu items
      const tray = {
        icon: "/frontend/icons/trayIcon.png",
        menuItems: [{ id: "QUIT", text: "Quit" }],
      };

      // Set the tray menu
      os.setTray(tray);
    }
  }
};
