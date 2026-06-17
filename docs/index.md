---
layout: page
title: Fontist Formulas
pageClass: formulas-index
---

<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { data as buildTimeStats } from './.vitepress/stats.data'

const formulasData = ref([])
const searchQuery = ref('')
const showAutocomplete = ref(false)
const copied = ref(false)
const selectedIndex = ref(-1)
let searchIndexPromise = null

const stats = ref(buildTimeStats)

const autocompleteResults = computed(() => {
  if (!searchQuery.value.trim()) return []
  const q = searchQuery.value.toLowerCase()
  return formulasData.value.filter(f =>
    (f.name || '').toLowerCase().includes(q) ||
    (f.formulaName || '').toLowerCase().includes(q) ||
    ((f.familyNames || []).some(n => (n || '').toLowerCase().includes(q)))
  ).slice(0, 8)
})

const basePath = import.meta.env.BASE_URL || '/'

function loadSearchIndex() {
  if (!searchIndexPromise) {
    searchIndexPromise = fetch(`${basePath}search-index.json`)
      .then(r => r.json())
      .then(data => { formulasData.value = data })
      .catch(e => {
        console.error('Failed to load search index:', e)
        searchIndexPromise = null
      })
  }
  return searchIndexPromise
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
})

function handleClickOutside(e) {
  const container = document.querySelector('.search-form')
  if (container && !container.contains(e.target)) {
    showAutocomplete.value = false
  }
}

function handleSearch(e) {
  e.preventDefault()
  if (searchQuery.value.trim()) {
    window.location.href = `${basePath}browse/?q=${encodeURIComponent(searchQuery.value.trim())}`
  } else {
    window.location.href = `${basePath}browse/`
  }
}

function getLicenseBadge(f) {
  if (!f) return `<img src="${basePath}licenses/unknown.svg" alt="Unknown" class="license-icon" title="Unknown">`
  if (f.licenseType === 'ofl') return `<img src="${basePath}licenses/ofl.svg" alt="OFL" class="license-icon" title="OFL">`
  if (f.licenseType === 'apache') return `<img src="${basePath}licenses/apache.svg" alt="Apache" class="license-icon" title="Apache">`
  if (f.licenseType === 'mit') return `<img src="${basePath}licenses/mit.svg" alt="MIT" class="license-icon" title="MIT">`
  if (f.licenseType === 'cc0') return `<img src="${basePath}licenses/cc0.svg" alt="CC0" class="license-icon" title="CC0">`
  if (f.licenseType === 'macos') return `<img src="${basePath}licenses/platform-tied.svg" alt="Platform Tied" class="license-icon" title="Platform Tied">`
  if (f.licenseType === 'ms_office' || f.licenseType === 'ms_web_fonts') return `<img src="${basePath}licenses/microsoft.svg" alt="Microsoft" class="license-icon" title="Microsoft">`
  // Fallback by category
  if (f.licenseCategory === 'open_source') return `<img src="${basePath}licenses/open.svg" alt="Open Source" class="license-icon" title="Open Source">`
  if (f.licenseCategory === 'freely_distributable') return `<img src="${basePath}licenses/freely-distributed.svg" alt="Freely Distributable" class="license-icon" title="Freely Distributable">`
  if (f.licenseCategory === 'platform_restricted') return `<img src="${basePath}licenses/platform-tied.svg" alt="Platform Tied" class="license-icon" title="Platform Tied">`
  if (f.licenseCategory === 'bundled_software') return `<img src="${basePath}licenses/bundled.svg" alt="Bundled" class="license-icon" title="Bundled Software">`
  return `<img src="${basePath}licenses/unknown.svg" alt="Unknown" class="license-icon" title="Unknown">`
}

function getSourceBadge(f) {
  if (!f) return `<img src="${basePath}sources/fontist.svg" alt="Expert Curated" class="source-icon" title="Expert Curated">`
  if (f.sourceType === 'google') return `<img src="${basePath}sources/google.svg" alt="Google Fonts" class="source-icon" title="Google Fonts">`
  if (f.sourceType === 'sil') return `<img src="${basePath}sources/sil.svg" alt="SIL International" class="source-icon" title="SIL International">`
  if (f.sourceType === 'macos') return `<img src="${basePath}sources/apple.svg" alt="Apple" class="source-icon" title="Apple">`
  return `<img src="${basePath}sources/fontist.svg" alt="Expert Curated" class="source-icon" title="Expert Curated">`
}

function getItemClass(idx) {
  if (idx === selectedIndex.value) return 'autocomplete-item selected'
  return 'autocomplete-item'
}

function copyInstall() {
  navigator.clipboard.writeText('fontist install "roboto"')
  copied.value = true
  setTimeout(() => { copied.value = false }, 2000)
}

function onKeydown(e) {
  const results = autocompleteResults.value
  if (!showAutocomplete.value || results.length === 0) {
    if (e.key === 'Enter') handleSearch(e)
    return
  }

  if (e.key === 'ArrowDown') {
    e.preventDefault()
    selectedIndex.value = Math.min(selectedIndex.value + 1, results.length - 1)
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    selectedIndex.value = Math.max(selectedIndex.value - 1, -1)
  } else if (e.key === 'Enter') {
    e.preventDefault()
    if (selectedIndex.value >= 0) {
      window.location.href = `${basePath}browse/${results[selectedIndex.value].slug}/`
    } else {
      handleSearch(e)
    }
  } else if (e.key === 'Escape') {
    showAutocomplete.value = false
    selectedIndex.value = -1
  }
}

watch(searchQuery, (val) => {
  showAutocomplete.value = val.trim().length > 0
  selectedIndex.value = -1
})
</script>

<div class="hero">
  <h1 class="hero-title">Find Your Font</h1>
  <p class="hero-tagline">{{ stats.total.toLocaleString() }}+ formulas · Install fonts anywhere</p>
</div>

<form class="search-form" @submit="handleSearch" @keydown="onKeydown">
  <div class="search-wrapper">
    <svg class="search-icon" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <circle cx="11" cy="11" r="8"/>
      <path d="m21 21-4.35-4.35"/>
    </svg>
    <input
      v-model="searchQuery"
      @focus="loadSearchIndex"
      type="search"
      placeholder="Search by name, family, or formula..."
      class="search-input"
      autocomplete="off"
    />
    <div v-if="showAutocomplete && autocompleteResults.length > 0" class="autocomplete-dropdown">
      <a
        v-for="(item, idx) in autocompleteResults"
        :key="item.slug"
        :href="basePath + 'browse/' + item.slug + '/'"
        :class="getItemClass(idx)"
        @mouseover="selectedIndex = idx"
      >
        <div class="autocomplete-main">
          <span class="autocomplete-name">{{ item.name }}</span>
          <code class="autocomplete-key">{{ item.formulaName }}</code>
        </div>
        <div class="autocomplete-meta">
          <span class="autocomplete-badges"><span v-html="getLicenseBadge(item)"></span> <span v-html="getSourceBadge(item)"></span></span>
          <span class="autocomplete-stats">{{ item.familyCount }} families</span>
        </div>
      </a>
      <div class="autocomplete-footer">
        <span v-if="searchQuery.trim()">Press Enter for all results →</span>
      </div>
    </div>
  </div>
  <button type="submit" class="search-btn">Search</button>
</form>

<section class="browse-section">
  <h2 class="section-title">Browse by License</h2>
  <div class="card-grid">
    <a href="browse/?license=open_source" class="browse-card">
      <img src="/licenses/open.svg" alt="Open Source" class="card-icon-img">
      <span class="card-title">Open Source</span>
      <span class="card-count">{{ stats.licenses.open_source.toLocaleString() }}+</span>
    </a>
    <a href="browse/?license=freely_distributable" class="browse-card">
      <img src="/licenses/freely-distributed.svg" alt="Freely Distributable" class="card-icon-img">
      <span class="card-title">Freely Distributable</span>
      <span class="card-count">{{ stats.licenses.freely_distributable.toLocaleString() }}+</span>
    </a>
    <a href="browse/?license=platform_restricted" class="browse-card">
      <img src="/licenses/platform-tied.svg" alt="Platform Tied" class="card-icon-img">
      <span class="card-title">Platform Tied</span>
      <span class="card-count">{{ stats.licenses.platform_restricted.toLocaleString() }}+</span>
    </a>
    <a href="browse/?license=bundled_software" class="browse-card">
      <img src="/licenses/bundled.svg" alt="Bundled Software" class="card-icon-img">
      <span class="card-title">Bundled Software</span>
      <span class="card-count">{{ stats.licenses.bundled_software.toLocaleString() }}+</span>
    </a>
  </div>
</section>

<section class="browse-section">
  <h2 class="section-title">Browse by Source</h2>
  <div class="card-grid">
    <a href="browse/?source=google" class="browse-card source-card">
      <img src="/sources/google.svg" alt="Google Fonts" class="card-icon-img">
      <span class="card-title">Google Fonts</span>
      <span class="card-count">{{ stats.sources.google.toLocaleString() }}+</span>
    </a>
    <a href="browse/?source=sil" class="browse-card source-card">
      <img src="/sources/sil.svg" alt="SIL International" class="card-icon-img">
      <span class="card-title">SIL International</span>
      <span class="card-count">{{ stats.sources.sil.toLocaleString() }}+</span>
    </a>
    <a href="browse/?source=macos" class="browse-card source-card">
      <img src="/sources/apple.svg" alt="Apple" class="card-icon-img">
      <span class="card-title">Apple</span>
      <span class="card-count">{{ stats.sources.macos.toLocaleString() }}+</span>
    </a>
    <a href="browse/?source=manual" class="browse-card source-card">
      <img src="/sources/fontist.svg" alt="Expert Curated" class="card-icon-img">
      <span class="card-title">Expert Curated</span>
      <span class="card-count">{{ stats.sources.manual.toLocaleString() }}+</span>
    </a>
  </div>
</section>

<div class="quick-install-section">
  <div class="quick-install">
    <code class="install-cmd">fontist install "roboto"</code>
    <button @click="copyInstall" class="copy-btn" :class="copied ? 'copied' : ''">
      {{ copied ? 'Copied!' : 'Copy' }}
    </button>
  </div>
</div>

<div class="index-footer">
  <a href="browse/" class="footer-link primary">View all formulas →</a>
  <div class="footer-links">
    <a href="guide/" class="footer-link">Guide</a>
    <a href="licenses/" class="footer-link">Licenses</a>
    <a href="https://github.com/fontist/formulas" target="_blank" class="footer-link">GitHub</a>
  </div>
</div>

<style>
.formulas-index .VPContent {
  padding-bottom: 0;
}

.formulas-index .VPDoc {
  padding: 0;
}

.formulas-index .content-container {
  max-width: 100%;
  padding: 0;
}

.hero {
  text-align: center;
  padding: 4rem 1.5rem 2rem;
  background: linear-gradient(180deg, var(--vp-c-bg-soft) 0%, var(--vp-c-bg) 100%);
}

.hero-title {
  font-size: 3.5rem;
  font-weight: 300;
  letter-spacing: -0.04em;
  margin: 0 0 0.5rem;
  color: var(--vp-c-text-1);
}

.hero-tagline {
  font-size: 1.125rem;
  color: var(--vp-c-text-2);
  margin: 0;
  font-weight: 400;
}

.search-form {
  max-width: 640px;
  margin: 0 auto 2rem;
  padding: 0 1.5rem;
  display: flex;
  gap: 0.75rem;
  position: relative;
}

.search-wrapper {
  flex: 1;
  position: relative;
}

.search-icon {
  position: absolute;
  left: 1rem;
  top: 50%;
  transform: translateY(-50%);
  color: var(--vp-c-text-3);
  pointer-events: none;
  z-index: 2;
}

.search-input {
  width: 100%;
  padding: 1rem 1rem 1rem 3rem;
  font-size: 1.125rem;
  border: 2px solid var(--vp-c-divider);
  border-radius: 12px;
  background: var(--vp-c-bg);
  color: var(--vp-c-text-1);
  transition: all 0.2s;
}

.search-input:focus {
  outline: none;
  border-color: var(--vp-c-brand-1);
  box-shadow: 0 0 0 3px var(--vp-c-brand-soft);
}

.search-input::placeholder {
  color: var(--vp-c-text-3);
}

.search-btn {
  padding: 1rem 1.5rem;
  font-size: 1rem;
  font-weight: 500;
  border: none;
  border-radius: 12px;
  background: var(--vp-c-brand-1);
  color: white;
  cursor: pointer;
  transition: all 0.2s;
}

.search-btn:hover {
  background: var(--vp-c-brand-2);
}

.autocomplete-dropdown {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  margin-top: 0.5rem;
  background: var(--vp-c-bg);
  border: 1px solid var(--vp-c-divider);
  border-radius: 12px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
  overflow: hidden;
  z-index: 100;
}

.autocomplete-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.875rem 1rem;
  text-decoration: none;
  border-bottom: 1px solid var(--vp-c-divider);
  transition: background 0.1s;
}

.autocomplete-item:last-of-type {
  border-bottom: none;
}

.autocomplete-item:hover,
.autocomplete-item.selected {
  background: var(--vp-c-bg-soft);
}

.autocomplete-item.selected {
  background: var(--vp-c-brand-soft);
}

.autocomplete-main {
  display: flex;
  flex-direction: column;
  gap: 0.125rem;
  min-width: 0;
  flex: 1;
}

.autocomplete-name {
  font-weight: 600;
  color: var(--vp-c-text-1);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.autocomplete-key {
  font-family: var(--vp-font-family-mono);
  font-size: 0.8125rem;
  color: var(--vp-c-text-2);
  background: none;
  padding: 0;
}

.autocomplete-meta {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex-shrink: 0;
  margin-left: 0.75rem;
}

.autocomplete-badges {
  display: flex;
  align-items: center;
  gap: 4px;
}

.license-icon,
.source-icon {
  width: 14px;
  height: 14px;
  display: inline-block;
  vertical-align: middle;
}

.autocomplete-stats {
  font-size: 0.75rem;
  color: var(--vp-c-text-3);
}

.autocomplete-footer {
  padding: 0.625rem 1rem;
  font-size: 0.8125rem;
  color: var(--vp-c-text-3);
  background: var(--vp-c-bg-soft);
  text-align: center;
}

.browse-section {
  max-width: 960px;
  margin: 0 auto 2rem;
  padding: 0 1.5rem;
}

.section-title {
  font-size: 1rem;
  font-weight: 600;
  color: var(--vp-c-text-2);
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin: 0 0 1rem;
  padding-bottom: 0.5rem;
  border-bottom: 1px solid var(--vp-c-divider);
}

.card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
}

.browse-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 1.5rem 1rem;
  border: 1px solid var(--vp-c-divider);
  border-radius: 12px;
  background: var(--vp-c-bg);
  text-decoration: none;
  transition: all 0.2s;
}

.browse-card:hover {
  border-color: var(--vp-c-brand-1);
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
}

.card-icon-img {
  width: 24px;
  height: 24px;
  margin-bottom: 0.5rem;
}

.card-title {
  font-size: 0.9375rem;
  font-weight: 600;
  color: var(--vp-c-text-1);
  text-align: center;
}

.card-count {
  font-size: 0.8125rem;
  color: var(--vp-c-text-3);
  margin-top: 0.25rem;
}

.quick-install-section {
  max-width: 960px;
  margin: 0 auto 2rem;
  padding: 0 1.5rem;
}

.quick-install {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  padding: 1rem 1.5rem;
  background: var(--vp-c-bg-soft);
  border-radius: 12px;
  border: 1px solid var(--vp-c-divider);
}

.install-cmd {
  font-family: var(--vp-font-family-mono);
  font-size: 0.9375rem;
  color: var(--vp-c-text-1);
}

.copy-btn {
  padding: 0.375rem 0.75rem;
  font-size: 0.8125rem;
  font-weight: 500;
  border: 1px solid var(--vp-c-divider);
  border-radius: 6px;
  background: var(--vp-c-bg);
  color: var(--vp-c-text-2);
  cursor: pointer;
  transition: all 0.15s;
}

.copy-btn:hover {
  border-color: var(--vp-c-brand-1);
  color: var(--vp-c-brand-1);
}

.copy-btn.copied {
  background: var(--vp-c-brand-1);
  border-color: var(--vp-c-brand-1);
  color: white;
}

.index-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  max-width: 960px;
  margin: 0 auto;
  padding: 1.5rem;
  border-top: 1px solid var(--vp-c-divider);
  flex-wrap: wrap;
  gap: 1rem;
}

.footer-link {
  font-size: 0.875rem;
  color: var(--vp-c-text-2);
  text-decoration: none;
  transition: color 0.15s;
}

.footer-link:hover {
  color: var(--vp-c-brand-1);
}

.footer-link.primary {
  font-weight: 500;
  color: var(--vp-c-brand-1);
}

.footer-links {
  display: flex;
  gap: 1.5rem;
}

@media (max-width: 768px) {
  .hero-title {
    font-size: 2.5rem;
  }

  .hero-tagline {
    font-size: 1rem;
  }

  .search-form {
    flex-direction: column;
  }

  .search-btn {
    width: 100%;
  }

  .autocomplete-dropdown {
    position: fixed;
    left: 1.5rem;
    right: 1.5rem;
    margin-top: 0.25rem;
  }

  .card-grid {
    grid-template-columns: 1fr 1fr;
  }

  .index-footer {
    flex-direction: column;
    text-align: center;
  }
}

@media (max-width: 480px) {
  .card-grid {
    grid-template-columns: 1fr;
  }
}

html.dark .browse-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
}

html.dark .autocomplete-dropdown {
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
}
</style>
