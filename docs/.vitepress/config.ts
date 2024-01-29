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

    footer: {
      copyright: `\
Fontist is <a href="https://open.ribose.com/"><img alt="riboseopen" style="display: inline; height: 28px" valign=middle src="${process.env.BASE_PATH || ""}riboseopen.png" /></a><br />
Copyright &copy; 2023 Ribose Group Inc. All rights reserved.<br />
<a href="https://www.ribose.com/tos">Terms of Service</a> | <a href="https://www.ribose.com/privacy">Privacy Policy</a>`,
    },
  },
});
