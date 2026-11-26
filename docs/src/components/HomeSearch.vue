<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'

const props = defineProps({
  // Build-time stats rendered server-side; the client re-fetches the index
  // lazily for autocomplete.
  stats: { type: Object, required: true },
})

const formulasData = ref([])
const searchQuery = ref('')
const showAutocomplete = ref(false)
const copied = ref(false)
const selectedIndex = ref(-1)
let searchIndexPromise = null

const stats = props.stats

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
  if (f.licenseCategory === 'open_source') return `<img src="${basePath}licenses/open.svg" alt="Open Source" class="license-icon" title="Open Source">`
  if (f.licenseCategory === 'freely_distributable') return `<img src="${basePath}licenses/freely-distributed.svg" alt="Freely Distributable" class="license-icon" title="Freely Distributable">`
  if (f.licenseCategory === 'platform_restricted') return `<img src="${basePath}licenses/platform-tied.svg" alt="Platform Tied" class="license-icon" title="Platform Tied">`
  if (f.licenseCategory === 'bundled_software') return `<img src="${basePath}licenses/bundled.svg" alt="Bundled" class="license-icon" title="Bundled Software">`
  return `<img src="${basePath}licenses/unknown.svg" alt="Unknown" class="license-icon" title="Unknown">`
}

function goToFormula(slug) {
  window.location.href = `${basePath}browse/${slug}`
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
      window.location.href = `${basePath}browse/${results[selectedIndex.value].slug}`
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

<template>
  <div>
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
            :href="basePath + 'browse/' + item.slug"
            :class="getItemClass(idx)"
            @mouseover="selectedIndex = idx"
            @click.stop.prevent="goToFormula(item.slug)"
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
  </div>
</template>
