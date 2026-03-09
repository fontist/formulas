import { defineConfig } from "vitepress";

// https://vitepress.dev/reference/site-config
export default defineConfig({
  lang: "en-US",

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

  ignoreDeadLinks: true,

  // https://vitepress.dev/guide/routing#generating-clean-url
  cleanUrls: true,

  title: "Fontist Formulas",
  description: "Index of all Fontist Formulas",

  lastUpdated: true,

  // https://github.com/vuejs/vitepress/issues/3508
  base: process.env.BASE_PATH,

  head: [
    [
      "link",
      { rel: "icon", type: "image/png", href: "/favicon-96x96.png", sizes: "96x96" },
    ],
    ["link", { rel: "icon", type: "image/svg+xml", href: "/favicon.svg" }],
    ["link", { rel: "shortcut icon", href: "/favicon.ico" }],
    [
      "link",
      { rel: "apple-touch-icon", sizes: "180x180", href: "/apple-touch-icon.png" },
    ],
    ["link", { rel: "manifest", href: "/site.webmanifest" }],
    ["meta", { property: "og:type", content: "website" }],
    ["meta", { property: "og:title", content: "Fontist Formulas" }],
    [
      "meta",
      {
        property: "og:description",
        content: "Searchable index of all Fontist Formulas",
      },
    ],
    ["meta", { property: "og:image", content: "/logo-full.svg" }],
    ["meta", { name: "twitter:card", content: "summary_large_image" }],
  ],

  themeConfig: {
    logo: "/logo-full.svg",
    siteTitle: false,

    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: "← Fontist.org", link: "https://www.fontist.org", target: "_self" },
      { text: "Guide", link: "/guide/" },
      { text: "Licenses", link: "/guide/licenses/" },
      { text: "Formulas", link: "/formulas/" },
      { text: "Fontist CLI & API", link: "https://www.fontist.org/fontist/", target: "_self" },
      { text: "Fontisan", link: "https://www.fontist.org/fontisan/", target: "_self" },
    ],

    // https://vitepress.dev/reference/default-theme-search
    search: {
      provider: "local",
    },

    sidebar: {
      "/guide/": [
        {
          text: "Getting Started",
          items: [
            { text: "Overview", link: "/guide/" },
          ],
        },
        {
          text: "Font Licenses",
          collapsed: true,
          items: [
            { text: "License Overview", link: "/guide/licenses/" },
            // Open Source
            { text: "OFL 1.1", link: "/guide/licenses/ofl" },
            { text: "Apache 2.0", link: "/guide/licenses/apache" },
            { text: "MIT", link: "/guide/licenses/mit" },
            { text: "BSD", link: "/guide/licenses/bsd" },
            { text: "CC0 / Public Domain", link: "/guide/licenses/cc0" },
            { text: "Public Domain", link: "/guide/licenses/public-domain" },
            { text: "CC-BY 4.0", link: "/guide/licenses/cc-by" },
            { text: "CC-BY-SA 4.0", link: "/guide/licenses/cc-by-sa" },
            { text: "UFL 1.0", link: "/guide/licenses/ufl" },
            { text: "GUST", link: "/guide/licenses/gust" },
            { text: "LGPL", link: "/guide/licenses/lgpl" },
            { text: "GPL", link: "/guide/licenses/gpl" },
            { text: "IPA", link: "/guide/licenses/ipa" },
            { text: "Bitstream Vera", link: "/guide/licenses/bitstream" },
            { text: "Freely Usable", link: "/guide/licenses/free-use" },
            // Freely Distributable
            { text: "Microsoft Web Fonts", link: "/guide/licenses/microsoft-web" },
            { text: "Freeware", link: "/guide/licenses/freeware" },
            // Platform Restricted
            { text: "Apple-only", link: "/guide/licenses/apple-only" },
            // Bundled Software
            { text: "MS Software", link: "/guide/licenses/ms-office" },
            { text: "Adobe Software", link: "/guide/licenses/adobe" },
            { text: "Bundled Software", link: "/guide/licenses/bundled" },
            // Unknown
            { text: "Unknown", link: "/guide/licenses/unknown" },
          ],
        },
        {
          text: "Creating Formulas",
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
      copyright: `Copyright &copy; 2026 Ribose Group Inc. All rights reserved.`,
    },
  },
});
