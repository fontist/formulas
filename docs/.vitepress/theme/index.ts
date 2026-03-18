import DefaultTheme from "vitepress/theme";
import FormulaBrowser from "./FormulaBrowser.vue";
import "./style.css";

export default {
  ...DefaultTheme,
  enhanceApp({ app }) {
    app.component("FormulaBrowser", FormulaBrowser);
  },
};
