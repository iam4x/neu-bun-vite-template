import { render } from "solid-js/web";

import { AppComponent } from "./components/app.component";

export const renderApp = () => {
  const appElement = document.getElementById("app");
  if (!appElement) throw new Error("App element not found");
  render(() => <AppComponent />, appElement);
};
