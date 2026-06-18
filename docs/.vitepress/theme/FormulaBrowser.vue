<script setup>
import { ref, computed, onMounted } from 'vue'

const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')

const formulasData = ref([])
const searchQuery = ref('')
const selectedLicenses = ref(['all'])
const selectedSources = ref(['all'])
const showMobileFilters = ref(false)
const basePath = import.meta.env.BASE_URL || '/'

const licenseOptions = [
  { value: 'all', label: 'All', count: 0 },
  { value: 'ofl', label: 'OFL', count: 0 },
  { value: 'apache', label: 'Apache', count: 0 },
  { value: 'mit', label: 'MIT', count: 0 },
  { value: 'cc0', label: 'CC0', count: 0 },
  { value: 'other_open', label: 'Other Open', count: 0 },
  { value: 'freely_dist', label: 'Freely Dist.', count: 0 },
  { value: 'platform', label: 'Platform', count: 0 },
  { value: 'bundled', label: 'Bundled', count: 0 },
  { value: 'unknown', label: 'Unknown', count: 0 },
]

const sourceOptions = [
  { value: 'all', label: 'All', count: 0 },
  { value: 'google', label: 'Google', count: 0 },
  { value: 'sil', label: 'SIL', count: 0 },
  { value: 'macos', label: 'Apple', count: 0 },
  { value: 'manual', label: 'Curated', count: 0 },
]

// Map URL param values to internal license groups
const licenseParamMap = {
  'open_source': ['ofl', 'apache', 'mit', 'cc0', 'other_open'],
  'freely_distributable': ['freely_dist'],
  'platform_restricted': ['platform'],
  'bundled_software': ['bundled'],
  'ofl': ['ofl'],
  'apache': ['apache'],
  'mit': ['mit'],
}

function getLicenseGroup(f) {
  if (!f) return 'unknown'
  if (f.licenseCategory === 'open_source') {
    if (f.licenseType === 'ofl') return 'ofl'
    if (f.licenseType === 'apache') return 'apache'
    if (f.licenseType === 'mit') return 'mit'
    if (f.licenseType === 'cc0') return 'cc0'
    return 'other_open'
  }
  if (f.licenseCategory === 'freely_distributable') return 'freely_dist'
  if (f.licenseCategory === 'platform_restricted') return 'platform'
  if (f.licenseCategory === 'bundled_software') return 'bundled'
  return 'unknown'
}

function getLicenseBadge(f) {
  const basePath = import.meta.env.BASE_URL || '/'
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
  const basePath = import.meta.env.BASE_URL || '/'
  if (!f) return `<img src="${basePath}sources/fontist.svg" alt="Expert Curated" class="source-icon" title="Expert Curated">`
  if (f.sourceType === 'google') return `<img src="${basePath}sources/google.svg" alt="Google Fonts" class="source-icon" title="Google Fonts">`
  if (f.sourceType === 'sil') return `<img src="${basePath}sources/sil.svg" alt="SIL International" class="source-icon" title="SIL International">`
  if (f.sourceType === 'macos') return `<img src="${basePath}sources/apple.svg" alt="Apple" class="source-icon" title="Apple">`
  return `<img src="${basePath}sources/fontist.svg" alt="Expert Curated" class="source-icon" title="Expert Curated">`
}

function sourceLabel(value) {
  const opt = sourceOptions.find(o => o.value === value)
  return opt ? opt.label : value
}

function licenseLabel(value) {
  const opt = licenseOptions.find(o => o.value === value)
  return opt ? opt.label : value
}

// Read URL params on mount
function initFromUrl() {
  const params = new URLSearchParams(window.location.search)

  // Handle search query
  const q = params.get('q')
  if (q) {
    searchQuery.value = q
  }

  // Handle license filter
  const license = params.get('license')
  if (license && licenseParamMap[license]) {
    selectedLicenses.value = licenseParamMap[license]
  }

  // Handle source filter
  const source = params.get('source')
  if (source) {
    const srcOpt = sourceOptions.find(o => o.value === source)
    if (srcOpt) {
      selectedSources.value = [source]
    }
  }
}

onMounted(async () => {
  try {
    // Initialize from URL params first
    initFromUrl()

    // Use import.meta.env.BASE_URL to get the correct base path
    const basePath = import.meta.env.BASE_URL || '/'
    const response = await fetch(`${basePath}formulas-data.json`)
    const data = await response.json()
    formulasData.value = data

    // Set 'all' counts to total
    licenseOptions[0].count = data.length
    sourceOptions[0].count = data.length

    data.forEach(f => {
      const licOpt = licenseOptions.find(o => o.value === getLicenseGroup(f))
      if (licOpt) licOpt.count++
      const srcOpt = sourceOptions.find(o => o.value === f.sourceType)
      if (srcOpt) srcOpt.count++
    })
  } catch (e) {
    console.error('Failed to load formulas data:', e)
  }
})

const filteredFormulas = computed(() => {
  let result = formulasData.value
  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase()
    result = result.filter(f =>
      (f.name || '').toLowerCase().includes(q) ||
      (f.formulaName || '').toLowerCase().includes(q) ||
      ((f.familyNames || []).some(n => (n || '').toLowerCase().includes(q)))
    )
  }
  if (!selectedLicenses.value.includes('all')) {
    result = result.filter(f => selectedLicenses.value.includes(getLicenseGroup(f)))
  }
  if (!selectedSources.value.includes('all')) {
    result = result.filter(f => selectedSources.value.includes(f.sourceType))
  }
  return result.sort((a, b) => (a.name || '').localeCompare(b.name || ''))
})

const groupedFormulas = computed(() => {
  const groups = {}
  filteredFormulas.value.forEach(f => {
    if (!f || !f.name) return
    const letter = f.name.charAt(0).toUpperCase()
    if (!groups[letter]) groups[letter] = []
    groups[letter].push(f)
  })
  return groups
})

const activeLetters = computed(() => {
  return alphabet.filter(letter => {
    const group = groupedFormulas.value[letter]
    return group && group.length > 0
  })
})

const activeLicenseChips = computed(() => {
  if (selectedLicenses.value.includes('all')) return []
  return selectedLicenses.value.map(v => ({ kind: 'license', value: v, label: licenseLabel(v) }))
})

const activeSourceChips = computed(() => {
  if (selectedSources.value.includes('all')) return []
  return selectedSources.value.map(v => ({ kind: 'source', value: v, label: sourceLabel(v) }))
})

const activeChips = computed(() => [...activeLicenseChips.value, ...activeSourceChips.value])

function scrollToLetter(letter) {
  const el = document.getElementById('letter-' + letter)
  if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' })
}

function goToFormula(slug) {
  // Formula pages are rendered in CI batches (docs.yml build-batch matrix),
  // and each batch's VitePress router manifest only includes its own pages.
  // SPA navigation from /browse/ to a formula in a different batch hits a
  // "Page not found" 404 even though the SSR HTML exists on the server.
  // Bypass SPA routing for formula clicks — full page load fetches the
  // correct HTML which loads the correct app chunk for that formula's batch.
  // No trailing slash: cleanUrls:true route map expects /browse/foo, and
  // GitHub Pages serves /browse/foo/index.html for either form.
  window.location.href = `${basePath}browse/${slug}`
}

function toggleLicense(value) {
  if (value === 'all') {
    selectedLicenses.value = ['all']
  } else {
    selectedLicenses.value = [value]
  }
}

function toggleSource(value) {
  if (value === 'all') {
    selectedSources.value = ['all']
  } else {
    selectedSources.value = [value]
  }
}

function removeChip(chip) {
  if (chip.kind === 'license') selectedLicenses.value = ['all']
  else selectedSources.value = ['all']
}

function clearAllFilters() {
  selectedLicenses.value = ['all']
  selectedSources.value = ['all']
  searchQuery.value = ''
}
</script>

<template>
  <div class="gallery">
    <!-- Sticky masthead: hero search + alphabet wayfinding -->
    <header class="masthead">
      <div class="masthead-inner">
        <div class="search-hero">
          <svg class="search-glyph" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round">
            <circle cx="11" cy="11" r="7" />
            <path d="m20 20-3.2-3.2" />
          </svg>
          <input
            v-model="searchQuery"
            type="search"
            placeholder="Search typefaces, families, formulas…"
            class="search-field"
            autocomplete="off"
            spellcheck="false"
          />
          <span class="result-count">{{ filteredFormulas.length }} <span class="result-count-word">{{ filteredFormulas.length === 1 ? 'specimen' : 'specimens' }}</span></span>
        </div>

        <nav class="alpha-strip" aria-label="Jump to letter">
          <button
            v-for="letter in activeLetters"
            :key="letter"
            class="alpha-letter"
            @click="scrollToLetter(letter)"
          >{{ letter }}</button>
        </nav>
      </div>
    </header>

    <!-- Filter bar: horizontal pills -->
    <section class="filter-bar" :class="{ 'is-open': showMobileFilters }">
      <div class="filter-group">
        <span class="filter-key">License</span>
        <div class="pill-row">
          <button
            v-for="opt in licenseOptions"
            :key="'l-' + opt.value"
            class="pill"
            :class="{ active: selectedLicenses.includes(opt.value) }"
            @click="toggleLicense(opt.value)"
          >
            <span class="pill-label">{{ opt.label }}</span>
            <span class="pill-count">{{ opt.count }}</span>
          </button>
        </div>
      </div>

      <div class="filter-group">
        <span class="filter-key">Source</span>
        <div class="pill-row">
          <button
            v-for="opt in sourceOptions"
            :key="'s-' + opt.value"
            class="pill"
            :class="{ active: selectedSources.includes(opt.value) }"
            @click="toggleSource(opt.value)"
          >
            <span class="pill-label">{{ opt.label }}</span>
            <span class="pill-count">{{ opt.count }}</span>
          </button>
        </div>
      </div>

      <div v-if="activeChips.length" class="active-chips">
        <button
          v-for="chip in activeChips"
          :key="chip.kind + '-' + chip.value"
          class="chip"
          @click="removeChip(chip)"
        >
          <span class="chip-kind">{{ chip.kind }}</span>
          <span class="chip-label">{{ chip.label }}</span>
          <span class="chip-x" aria-hidden="true">×</span>
        </button>
        <button class="chip clear-all" @click="clearAllFilters">Clear all</button>
      </div>
    </section>

    <!-- Mobile filter toggle -->
    <button class="mobile-filter-toggle" @click="showMobileFilters = !showMobileFilters">
      <span>Filters</span>
      <span v-if="activeChips.length" class="toggle-badge">{{ activeChips.length }}</span>
      <span class="toggle-caret" :class="{ open: showMobileFilters }">▾</span>
    </button>

    <!-- Gallery: full-width specimen bands -->
    <div class="gallery-results">
      <template v-if="activeLetters.length">
        <section
          v-for="(letter, idx) in activeLetters"
          :key="letter"
          :id="'letter-' + letter"
          class="letter-group"
          :class="{ 'band-alt': idx % 2 === 1 }"
        >
          <h2 class="letter-mark">{{ letter }}</h2>

          <a
            v-for="f in groupedFormulas[letter]"
            :key="f.slug"
            :href="`${basePath}browse/${f.slug}`"
            class="specimen"
            @click.stop.prevent="goToFormula(f.slug)"
          >
            <div class="specimen-meta-top">
              <span class="badges" :title="f.licenseName">
                <span class="badge-dot" aria-hidden="true"></span>
                <span v-html="getLicenseBadge(f)"></span>
                <span v-html="getSourceBadge(f)"></span>
              </span>
            </div>

            <div class="specimen-body">
              <h3 class="specimen-name">{{ f.name }}</h3>
              <p class="specimen-sub">
                <span class="sub-key">{{ f.formulaName }}</span>
                <span class="sub-sep">·</span>
                <span>{{ f.familyCount }} {{ f.familyCount === 1 ? 'family' : 'families' }}</span>
                <span class="sub-sep">·</span>
                <span>{{ f.styleCount }} {{ f.styleCount === 1 ? 'style' : 'styles' }}</span>
              </p>
            </div>

            <span class="specimen-cta" aria-hidden="true">
              View formula
              <span class="cta-arrow">→</span>
            </span>
          </a>
        </section>
      </template>

      <div v-else class="empty-state">
        <p class="empty-head">No typefaces match.</p>
        <button class="empty-reset" @click="clearAllFilters">Reset filters</button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.gallery {
  --specimen-name-size: clamp(2rem, 4.5vw, 3.5rem);
  --specimen-pad-y: clamp(1.75rem, 3.2vw, 3rem);
  --gallery-rule: var(--vp-c-divider, rgba(60, 60, 67, 0.12));
  --gallery-bg: var(--vp-c-bg);
  --gallery-bg-soft: var(--vp-c-bg-soft);
  --gallery-bg-alt: var(--vp-c-bg-alt);
  --display-font: "Iowan Old Style", "Apple Garamond", Baskerville, Georgia,
    "Times New Roman", "Droid Serif", Times, serif;
  --meta-font: var(--vp-font-family-mono, ui-monospace, SFMono-Regular, Menlo,
    monospace);
  margin-top: 0.5rem;
  font-feature-settings: "kern" 1, "liga" 1;
}

/* ── Masthead ─────────────────────────────────────────── */
.masthead {
  position: sticky;
  top: var(--vp-nav-height, 64px);
  z-index: 20;
  background: color-mix(in srgb, var(--gallery-bg) 88%, transparent);
  backdrop-filter: saturate(160%) blur(10px);
  -webkit-backdrop-filter: saturate(160%) blur(10px);
  border-bottom: 1px solid var(--gallery-rule);
}

.masthead-inner {
  max-width: 1280px;
  margin: 0 auto;
  padding: 0.85rem clamp(1rem, 3vw, 2rem);
}

.search-hero {
  position: relative;
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.search-glyph {
  position: absolute;
  left: 0;
  top: 50%;
  transform: translateY(-50%);
  color: var(--vp-c-text-3);
  pointer-events: none;
}

.search-field {
  flex: 1;
  width: 100%;
  padding: 0.5rem 0 0.5rem 2rem;
  font-size: clamp(1.1rem, 2vw, 1.5rem);
  font-family: var(--display-font);
  font-weight: 400;
  letter-spacing: -0.01em;
  border: none;
  border-bottom: 1px solid transparent;
  background: transparent;
  color: var(--vp-c-text-1);
  transition: border-color 0.2s ease;
}

.search-field::-webkit-search-cancel-button,
.search-field::-webkit-search-decoration {
  -webkit-appearance: none;
  appearance: none;
}

.search-field::placeholder {
  color: var(--vp-c-text-3);
  font-style: italic;
  opacity: 0.8;
}

.search-field:focus {
  outline: none;
  border-bottom-color: var(--fontist-rose);
}

.result-count {
  font-family: var(--meta-font);
  font-size: 0.7rem;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--vp-c-text-3);
  white-space: nowrap;
  flex-shrink: 0;
}

.result-count-word {
  display: none;
}

@media (min-width: 540px) {
  .result-count-word {
    display: inline;
  }
}

/* Alphabet wayfinding strip */
.alpha-strip {
  display: flex;
  flex-wrap: wrap;
  gap: 0;
  margin-top: 0.6rem;
  padding-top: 0.5rem;
  border-top: 1px solid var(--gallery-rule);
}

.alpha-letter {
  padding: 0.15rem 0.4rem;
  border: none;
  background: none;
  cursor: pointer;
  font-family: var(--meta-font);
  font-size: 0.72rem;
  font-weight: 500;
  letter-spacing: 0.04em;
  color: var(--vp-c-text-3);
  opacity: 0.55;
  transition: opacity 0.15s ease, color 0.15s ease;
  line-height: 1.6;
}

.alpha-letter:hover,
.alpha-letter:focus-visible {
  opacity: 1;
  color: var(--fontist-rose);
  outline: none;
}

.alpha-letter:focus-visible {
  background: var(--vp-c-brand-soft);
}

/* ── Filter bar ───────────────────────────────────────── */
.filter-bar {
  max-width: 1280px;
  margin: 0 auto;
  padding: 1.5rem clamp(1rem, 3vw, 2rem) 1.25rem;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.filter-group {
  display: flex;
  align-items: flex-start;
  gap: 0.85rem;
}

.filter-key {
  flex-shrink: 0;
  width: 4.2rem;
  padding-top: 0.4rem;
  font-family: var(--meta-font);
  font-size: 0.65rem;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: var(--vp-c-text-3);
}

.pill-row {
  display: flex;
  flex-wrap: wrap;
  gap: 0.4rem;
}

.pill {
  display: inline-flex;
  align-items: baseline;
  gap: 0.4rem;
  padding: 0.3rem 0.7rem;
  border: 1px solid var(--gallery-rule);
  border-radius: 999px;
  background: transparent;
  color: var(--vp-c-text-2);
  font-size: 0.8rem;
  font-weight: 400;
  line-height: 1.4;
  cursor: pointer;
  transition: border-color 0.15s ease, color 0.15s ease, background 0.15s ease;
}

.pill:hover {
  border-color: var(--vp-c-text-3);
  color: var(--vp-c-text-1);
}

.pill.active {
  border-color: var(--fontist-rose);
  color: var(--fontist-rose);
  background: var(--vp-c-brand-soft);
}

.pill-count {
  font-family: var(--meta-font);
  font-size: 0.65rem;
  color: var(--vp-c-text-3);
  font-variant-numeric: tabular-nums;
}

.pill.active .pill-count {
  color: var(--fontist-rose);
  opacity: 0.8;
}

/* Active removable chips */
.active-chips {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.45rem;
  padding-top: 0.35rem;
  margin-top: 0.1rem;
  border-top: 1px dashed var(--gallery-rule);
}

.chip {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  padding: 0.2rem 0.55rem 0.2rem 0.6rem;
  border: 1px solid var(--fontist-rose);
  border-radius: 3px;
  background: transparent;
  color: var(--fontist-rose);
  font-size: 0.72rem;
  cursor: pointer;
  transition: background 0.15s ease;
}

.chip:hover {
  background: var(--vp-c-brand-soft);
}

.chip-kind {
  font-family: var(--meta-font);
  font-size: 0.58rem;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  opacity: 0.7;
}

.chip-x {
  font-size: 0.9rem;
  line-height: 1;
  opacity: 0.8;
}

.chip.clear-all {
  border-color: var(--gallery-rule);
  color: var(--vp-c-text-3);
  border-style: dashed;
}

.chip.clear-all:hover {
  color: var(--vp-c-text-1);
  border-color: var(--vp-c-text-2);
}

/* Mobile filter toggle (hidden on desktop) */
.mobile-filter-toggle {
  display: none;
}

/* ── Gallery results ──────────────────────────────────── */
.gallery-results {
  max-width: 1280px;
  margin: 0 auto;
}

.letter-group {
  scroll-margin-top: calc(var(--vp-nav-height, 64px) + 140px);
}

.letter-group.band-alt {
  background: var(--gallery-bg-soft);
}

.letter-group.band-alt .letter-mark {
  /* keep mark readable on soft bg */
}

.letter-mark {
  max-width: 1280px;
  margin: 0 auto;
  padding: clamp(2rem, 4vw, 3.5rem) clamp(1rem, 3vw, 2rem) 0.5rem;
  font-family: var(--display-font);
  font-weight: 300;
  font-size: clamp(3.5rem, 8vw, 6rem);
  line-height: 0.9;
  letter-spacing: -0.04em;
  color: var(--vp-c-text-1);
  opacity: 0.16;
  user-select: none;
}

/* The specimen band */
.specimen {
  position: relative;
  display: grid;
  grid-template-columns: 1fr;
  grid-template-areas:
    "meta"
    "body"
    "cta";
  gap: 0.4rem;
  max-width: 1280px;
  margin: 0 auto;
  padding: var(--specimen-pad-y) clamp(1rem, 3vw, 2rem);
  text-decoration: none;
  color: inherit;
  border-top: 1px solid transparent;
  transition: border-color 0.2s ease;
}

.specimen::before {
  content: "";
  position: absolute;
  left: clamp(1rem, 3vw, 2rem);
  right: clamp(1rem, 3vw, 2rem);
  top: 0;
  height: 2px;
  background: var(--fontist-rose);
  transform: scaleX(0);
  transform-origin: left center;
  transition: transform 0.35s cubic-bezier(0.2, 0.7, 0.2, 1);
}

.specimen:hover {
  border-top-color: transparent;
}

.specimen:hover::before {
  transform: scaleX(1);
}

.specimen-meta-top {
  grid-area: meta;
  display: flex;
  align-items: center;
}

.badges {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
}

.badge-dot {
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background: var(--fontist-rose);
  opacity: 0.75;
  flex-shrink: 0;
}

.badges :deep(.license-icon),
.badges :deep(.source-icon) {
  width: 13px;
  height: 13px;
  display: inline-block;
  vertical-align: middle;
  opacity: 0.85;
}

.specimen-body {
  grid-area: body;
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
}

.specimen-name {
  margin: 0;
  font-family: var(--display-font);
  font-weight: 500;
  font-size: var(--specimen-name-size);
  line-height: 1.02;
  letter-spacing: -0.025em;
  color: var(--vp-c-text-1);
  transition: color 0.2s ease;
}

.specimen:hover .specimen-name {
  color: var(--fontist-rose);
}

.specimen-sub {
  margin: 0;
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  gap: 0.5rem;
  font-family: var(--meta-font);
  font-size: 0.72rem;
  letter-spacing: 0.02em;
  color: var(--vp-c-text-3);
}

.sub-key {
  color: var(--vp-c-text-2);
}

.sub-sep {
  opacity: 0.4;
}

.specimen-cta {
  grid-area: cta;
  justify-self: start;
  align-self: end;
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  font-family: var(--meta-font);
  font-size: 0.68rem;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--vp-c-text-3);
  opacity: 0;
  transform: translateX(-6px);
  transition: opacity 0.25s ease, transform 0.25s ease, color 0.2s ease;
}

.specimen:hover .specimen-cta {
  opacity: 1;
  transform: translateX(0);
  color: var(--fontist-rose);
}

.cta-arrow {
  transition: transform 0.25s ease;
}

.specimen:hover .cta-arrow {
  transform: translateX(3px);
}

/* Two-column band on wider screens: body left, cta bottom-right */
@media (min-width: 720px) {
  .specimen {
    grid-template-columns: 1fr auto;
    grid-template-areas:
      "meta  meta"
      "body  cta";
    align-items: end;
  }
  .specimen-cta {
    justify-self: end;
    align-self: end;
    padding-bottom: 0.4rem;
  }
}

/* Empty state */
.empty-state {
  max-width: 1280px;
  margin: 0 auto;
  padding: clamp(4rem, 10vw, 8rem) clamp(1rem, 3vw, 2rem);
  text-align: center;
}

.empty-head {
  margin: 0 0 1.5rem;
  font-family: var(--display-font);
  font-size: clamp(1.8rem, 4vw, 2.8rem);
  font-weight: 400;
  color: var(--vp-c-text-2);
  letter-spacing: -0.02em;
}

.empty-reset {
  padding: 0.5rem 1.2rem;
  border: 1px solid var(--fontist-rose);
  border-radius: 999px;
  background: transparent;
  color: var(--fontist-rose);
  font-size: 0.85rem;
  cursor: pointer;
  transition: background 0.15s ease;
}

.empty-reset:hover {
  background: var(--vp-c-brand-soft);
}

/* ── Responsive: tablet / mobile ──────────────────────── */
@media (max-width: 768px) {
  .filter-bar {
    display: none;
    padding-top: 1rem;
  }

  .filter-bar.is-open {
    display: flex;
  }

  .mobile-filter-toggle {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    margin: 0 clamp(1rem, 3vw, 2rem);
    padding: 0.55rem 0.9rem;
    border: 1px solid var(--gallery-rule);
    border-radius: 999px;
    background: var(--gallery-bg);
    color: var(--vp-c-text-1);
    font-size: 0.8rem;
    cursor: pointer;
  }

  .toggle-badge {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    min-width: 1.1rem;
    height: 1.1rem;
    padding: 0 0.3rem;
    border-radius: 999px;
    background: var(--fontist-rose);
    color: #fff;
    font-size: 0.62rem;
    font-family: var(--meta-font);
  }

  .toggle-caret {
    margin-left: auto;
    font-size: 0.7rem;
    transition: transform 0.2s ease;
  }

  .toggle-caret.open {
    transform: rotate(180deg);
  }

  .filter-group {
    flex-direction: column;
    gap: 0.5rem;
  }

  .filter-key {
    width: auto;
    padding-top: 0;
  }

  .pill-row {
    overflow-x: auto;
    flex-wrap: nowrap;
    -webkit-overflow-scrolling: touch;
    padding-bottom: 0.25rem;
  }

  .pill {
    flex-shrink: 0;
  }

  .alpha-strip {
    overflow-x: auto;
    flex-wrap: nowrap;
    -webkit-overflow-scrolling: touch;
  }

  .alpha-letter {
    flex-shrink: 0;
  }

  .letter-mark {
    font-size: clamp(2.8rem, 14vw, 4rem);
  }
}

/* Respect reduced motion */
@media (prefers-reduced-motion: reduce) {
  .specimen::before,
  .specimen-cta,
  .cta-arrow,
  .alpha-letter,
  .toggle-caret {
    transition: none;
  }

  html {
    scroll-behavior: auto;
  }
}
</style>
