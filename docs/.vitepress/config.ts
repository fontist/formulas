import { defineConfig } from "vitepress";

// https://vitepress.dev/reference/site-config
export default defineConfig({
  // Exclude development/design documents from processing
  srcExclude: [
    "RESOURCE_ARCHITECTURE.md",
    "V4_*.md",
    "broken-formulas-branch-analysis.md",
    "dual-source-import-plan.md",
    "formula-font-format-proposal*.md",
    "google-fonts-import-*.md",
    "phase4-*.md",
    "testing-google-import.md",
    "GOOGLE_FONTS_IMPLEMENTATION.md",
  ],

  ignoreDeadLinks: [
    "./www.woowahan.com",
    "./www.woowahan.comm",
    "./http//scripts.sil.org/OFL",
  ],

  // https://vitepress.dev/guide/routing#generating-clean-url
  cleanUrls: true,

  title: "Fontist Formulas",
  description: "Index of all Fontist Formulas",

  // https://github.com/vuejs/vitepress/issues/3508
  base: process.env.BASE_PATH,

  themeConfig: {
    logo: "/logo.png",

    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: "Home", link: "/" },
      { text: "Guide", link: "/guide/create-formula" },
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
          items: [
            { text: "Create a Formula", link: "/guide/create-formula" },
            {
              text: "Private repositories",
              link: "/guide/private-repositories",
            },
          ],
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
