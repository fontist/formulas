import { defineConfig } from "astro/config";
import vue from "@astrojs/vue";
import tailwindcss from "@tailwindcss/vite";

// The GitHub Pages deploy passes SITE_URL + BASE_PATH; defaults keep local
// dev URLs resolvable.
const SITE_ORIGIN = process.env.SITE_URL || "http://localhost:4321";
const SITE_PATH = process.env.BASE_PATH || "/formulas/";

export default defineConfig({
  site: SITE_ORIGIN,
  base: SITE_PATH,
  trailingSlash: "ignore",
  output: "static",
  integrations: [vue()],
  vite: {
    plugins: [tailwindcss()],
  },
});
