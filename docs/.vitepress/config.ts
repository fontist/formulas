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
    "TODO.revamp.md",
  ],

  ignoreDeadLinks: true,

  // https://vitepress.dev/guide/routing#generating-clean-url
  cleanUrls: true,

  title: "Fontist Formulas",
  description: "Index of all Fontist Formulas",

  lastUpdated: true,

  // Base path for deployment (e.g., /formulas/ for fontist.org/formulas/)
  base: process.env.BASE_PATH || "/formulas/",

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
      { text: "Licenses", link: "/licenses/" },
      { text: "Formulas", link: "/browse/" },
      { text: "Fontist", link: "https://www.fontist.org/fontist/", target: "_self" },
      { text: "Fontisan", link: "https://www.fontist.org/fontisan/", target: "_self" },
    ],

    // https://vitepress.dev/reference/default-theme-search
    search: {
      provider: "local",
    },

    sidebar: {
      // Guide sidebar - only guide content
      "/guide/": [
        {
          text: "Getting Started",
          items: [
            { text: "Overview", link: "/guide/" },
          ],
        },
        {
          text: "Understanding Formulas",
          items: [
            { text: "What is a Formula?", link: "/guide/what-is-formula" },
            { text: "Formula Structure", link: "/guide/formula-structure" },
            { text: "Choosing a Formula", link: "/guide/choosing-formula" },
          ],
        },
        {
          text: "Use Cases",
          collapsed: true,
          items: [
            { text: "Overview", link: "/guide/use-cases/" },
            { text: "Desktop Publishing", link: "/guide/use-cases/desktop-publishing" },
            { text: "Web Development", link: "/guide/use-cases/web-development" },
            { text: "Document Generation", link: "/guide/use-cases/document-generation" },
            { text: "PDF Generation", link: "/guide/use-cases/pdf-generation" },
            { text: "CI/CD & Servers", link: "/guide/use-cases/server-side" },
            { text: "Docker & Containers", link: "/guide/use-cases/containerized" },
            { text: "Cloud VMs", link: "/guide/use-cases/cloud-vms" },
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

      // Licenses sidebar - separate section
      "/licenses/": [
        {
          text: "License Overview",
          items: [
            { text: "All Licenses", link: "/licenses/" },
          ],
        },
        {
          text: "Open Source",
          collapsed: true,
          items: [
            { text: "OFL 1.1", link: "/licenses/ofl" },
            { text: "Apache 2.0", link: "/licenses/apache" },
            { text: "MIT", link: "/licenses/mit" },
            { text: "BSD", link: "/licenses/bsd" },
            { text: "CC0", link: "/licenses/cc0" },
            { text: "Public Domain", link: "/licenses/public-domain" },
            { text: "CC-BY 4.0", link: "/licenses/cc-by" },
            { text: "CC-BY-SA 4.0", link: "/licenses/cc-by-sa" },
            { text: "UFL 1.0", link: "/licenses/ufl" },
            { text: "GUST", link: "/licenses/gust" },
            { text: "LGPL", link: "/licenses/lgpl" },
            { text: "GPL", link: "/licenses/gpl" },
            { text: "IPA", link: "/licenses/ipa" },
            { text: "Bitstream Vera", link: "/licenses/bitstream" },
          ],
        },
        {
          text: "Freely Distributable",
          collapsed: true,
          items: [
            { text: "Freely Usable", link: "/licenses/free-use" },
            { text: "Microsoft Web Fonts", link: "/licenses/microsoft-web" },
            { text: "Freeware", link: "/licenses/freeware" },
          ],
        },
        {
          text: "Platform Restricted",
          collapsed: true,
          items: [
            { text: "Apple-only", link: "/licenses/apple-only" },
          ],
        },
        {
          text: "Bundled Software",
          collapsed: true,
          items: [
            { text: "Microsoft Software", link: "/licenses/ms-office" },
            { text: "Adobe Software", link: "/licenses/adobe" },
            { text: "Bundled Software", link: "/licenses/bundled" },
          ],
        },
        {
          text: "Other",
          collapsed: true,
          items: [
            { text: "Unknown", link: "/licenses/unknown" },
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
