---
search: false
layout: home
pageClass: my-index-page
---

<script setup>
// We are dipping into the default theme components here to grab
// and use the `VPNavBarSearch` component as a primary feature of
// our home page.
import VPNavBarSearch from "vitepress/dist/client/theme-default/components/VPNavBarSearch.vue"
</script>

<br />
<h1 align=center>Fontist Formulas</h1>

<br />
<VPNavBarSearch id="bigsearch" />
<br />

<div align=center style="font-size: 1.2em; line-height: 1.8em">

[📘 List of all formulas](/formulas/)<br />
[🍰 Create your own formula](/guide/create-formula)

</div>

<!-- This is global CSS so that we can infect things and
    sub-components without using ':deep()' everywhere. -->
<style>
  .my-index-page .VPContent {
    display: flex;
    align-items: center;
    justify-content: center;
  }
  .my-index-page .VPContent > * {
    width: 100%;
  }

  #bigsearch #local-search {
    flex-grow: 1 !important;
    margin: 0 auto;
    max-width: 600px;
  }
  #bigsearch .DocSearch-Button {
    border-color: var(--vp-c-brand-1) !important;
    background: var(--vp-c-bg-alt) !important;
  }

  /* All this CSS is copied from the `@media (min-width: 768px)` blocks
     in the `VPNavBarSearch`` and 'VPNavBarSearchButton` components. Make
     sure that it's kept up to date. Treat it like a black box. This is
     here to make the homepage search box fill the width like it normally
     does even when the screen side gets small which normally shrinks it. */
  #bigsearch {
    flex-grow: 1;
    padding-left: 24px;
  }
  #bigsearch {
    padding-left: 32px;
  }
  #bigsearch .DocSearch-Button {
    justify-content: flex-start;
    border: 1px solid transparent;
    border-radius: 8px;
    padding: 0 10px 0 12px;
    width: 100%;
    height: 40px;
    background-color: var(--vp-c-bg-alt);
  }
  #bigsearch .DocSearch-Button:hover {
    border-color: var(--vp-c-brand-1);
    background: var(--vp-c-bg-alt);
  }
  #bigsearch .DocSearch-Button .DocSearch-Search-Icon {
    top: 1px;
    margin-right: 8px;
    width: 14px;
    height: 14px;
    color: var(--vp-c-text-2);
  }
  #bigsearch .DocSearch-Button .DocSearch-Button-Placeholder {
    display: inline-block;
  }
  #bigsearch .DocSearch-Button .DocSearch-Button-Keys {
    display: flex;
    align-items: center;
  }
</style>
