import { defineConfig } from "vitepress";

// https://vitepress.dev/reference/site-config
export default defineConfig({
  ignoreDeadLinks: true,

  base: process.env.BASE_PATH,

  title: "Fontist Formulas",
  description: "Index of all Fontist Formulas",

  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: "Home", link: "/" },
      { text: "Guide", link: "/guide/" },
    ],

    // https://vitepress.dev/reference/default-theme-search
    search: {
      provider: "local",
    },

    sidebar: {
      "/guide/": [
        {
          text: "Guide",
          items: [{ text: "Create a Formula", link: "/guide/create-formula" }],
        },
      ],
    },

    socialLinks: [
      { icon: "github", link: "https://github.com/fontist/formulas" },
    ],
  },
});
