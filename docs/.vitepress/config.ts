import { defineConfig } from "vitepress";

// https://vitepress.dev/reference/site-config
export default defineConfig({
  ignoreDeadLinks: true,

  title: "Fontist Formulas",
  description: "Index of all Fontist Formulas",

  // https://github.com/vuejs/vitepress/issues/3508
  base: process.env.BASE_PATH,

  themeConfig: {
    logo: "/logo.png",

    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: "Home", link: "/" },
      { text: "Guide", link: "/guide/" },
      { text: "Formulas", link: "/formulas/" },
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

    footer: {
      message: `Fontist is <a href="https://open.ribose.com/">riboseopen</a>`,
      copyright: `Copyright &copy; 2023 Ribose Group Inc. All rights reserved.`,
    },
  },
});
