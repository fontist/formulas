<script setup>
import VPNavBarSearch from "vitepress/dist/client/theme-default/components/VPNavBarSearch.vue"
</script>

<VPNavBarSearch />

<style>
  /* We need to "infect" the '.VPNavBar' internal styles. To do that we need
  to NOT be in 'scoped' mode. But since we aren't in 'scoped' mode we need to
  make sure we don't accidentally override styles for the actual '.VPNavBar'
  search box (that one we want to stay normal). Thus, we prefix all our stuff
  so that it only affects search boxes in '.vp-doc' (the main body) which is
  crucially ONLY THIS PAGE. */
  .vp-doc .VPNavBarSearch #local-search {
    flex-grow: 1 !important;
  }
  .vp-doc .VPNavBarSearch .DocSearch-Button {
    border-color: var(--vp-c-brand-1) !important;
    background: var(--vp-c-bg-alt) !important;
}
</style>
