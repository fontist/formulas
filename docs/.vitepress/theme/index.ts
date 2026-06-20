import DefaultTheme from "vitepress/theme";
import FormulaBrowser from "./FormulaBrowser.vue";
import ShaCopy from "../components/ShaCopy.vue";
import FontSpecimen from "../components/FontSpecimen.vue";
import UnicodeCoverage from "../components/UnicodeCoverage.vue";
import "./style.css";

export default {
  ...DefaultTheme,
  enhanceApp({ app }) {
    app.component("FormulaBrowser", FormulaBrowser);
    app.component("ShaCopy", ShaCopy);
    app.component("FontSpecimen", FontSpecimen);
    app.component("UnicodeCoverage", UnicodeCoverage);
  },
};
