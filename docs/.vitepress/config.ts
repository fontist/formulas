import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Fontist Formulas",
  description: "Index of all Fontist Formulas",

  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Examples', link: '/markdown-examples' }
    ],

    // https://vitepress.dev/reference/default-theme-search
    search: {
      provider: 'local',
      // https://vitepress.dev/reference/default-theme-search#example-excluding-pages-from-search
      options: {
        _render(src, env, md) {
          const html = md.render(src, env)
          if (env.frontmatter?.search === false) return ''
          if (env.relativePath.match(/(^|\/)guide($|\/)/)) return ''
          console.debug(`Indexing ${env.relativePath} for search!`)
          return html
        }
      }
    },

    sidebar: {
      "/guide/": [
        {
          text: 'Guide',
          items: [
            { text: 'Create a Formula', link: '/guide/create-formula' },
          ]
        }
      ]
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/vuejs/vitepress' }
    ]
  }
})
