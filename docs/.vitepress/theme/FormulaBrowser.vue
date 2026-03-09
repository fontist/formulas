<script setup>
import { ref, computed, onMounted } from 'vue'

const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')

const formulasData = ref([])
const searchQuery = ref('')
const selectedLicenses = ref(['all'])
const selectedSources = ref(['all'])

const licenseOptions = [
  { value: 'all', label: 'All Licenses', icon: '📋', count: 0 },
  { value: 'ofl', label: 'OFL 1.1', icon: '🟢', count: 0 },
  { value: 'apache', label: 'Apache 2.0', icon: '🟢', count: 0 },
  { value: 'mit', label: 'MIT', icon: '🟢', count: 0 },
  { value: 'cc0', label: 'CC0 / Public Domain', icon: '🟢', count: 0 },
  { value: 'other_open', label: 'Other Open Source', icon: '🟢', count: 0 },
  { value: 'freely_dist', label: 'Freely Distributable', icon: '🔵', count: 0 },
  { value: 'platform', label: 'Platform Restricted', icon: '🟡', count: 0 },
  { value: 'bundled', label: 'Bundled Software', icon: '🟣', count: 0 },
  { value: 'unknown', label: 'License Not Specified', icon: '❓', count: 0 },
]

const sourceOptions = [
  { value: 'all', label: 'All Sources', icon: '📁', count: 0 },
  { value: 'google', label: 'Google Fonts', icon: '🌐', count: 0 },
  { value: 'sil', label: 'SIL International', icon: '📜', count: 0 },
  { value: 'macos', label: 'Apple', icon: '🍎', count: 0 },
  { value: 'manual', label: 'Manual Formulas', icon: '📦', count: 0 },
]

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
  if (!f) return '❓'
  if (f.licenseCategory === 'open_source') return '🟢'
  if (f.licenseCategory === 'freely_distributable') return '🔵'
  if (f.licenseCategory === 'platform_restricted') return '🟡'
  if (f.licenseCategory === 'bundled_software') return '🟣'
  return '❓'
}

function getSourceBadge(f) {
  if (!f) return '📦'
  if (f.sourceType === 'google') return '🌐'
  if (f.sourceType === 'sil') return '📜'
  if (f.sourceType === 'macos') return '🍎'
  return '📦'
}

onMounted(async () => {
  try {
    const response = await fetch('/formulas-data.json')
    const data = await response.json()
    formulasData.value = data
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

function scrollToLetter(letter) {
  const el = document.getElementById('letter-' + letter)
  if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' })
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
</script>

<template>
  <div class="formulas-browser">
    <div class="search-container">
      <input v-model="searchQuery" type="text" placeholder="Search fonts by name, family, or formula key..." class="search-input" />
      <span class="result-count">{{ filteredFormulas.length }} formulas</span>
    </div>

    <div class="browser-layout">
      <aside class="filters-sidebar">
        <div class="filter-section">
          <h4>License</h4>
          <label v-for="opt in licenseOptions" :key="opt.value" class="filter-checkbox">
            <input type="checkbox" :checked="selectedLicenses.includes(opt.value)" @change="toggleLicense(opt.value)" />
            <span class="filter-label"><span class="filter-icon">{{ opt.icon }}</span> {{ opt.label }} <span class="filter-count">({{ opt.count }})</span></span>
          </label>
        </div>
        <div class="filter-section">
          <h4>Source</h4>
          <label v-for="opt in sourceOptions" :key="opt.value" class="filter-checkbox">
            <input type="checkbox" :checked="selectedSources.includes(opt.value)" @change="toggleSource(opt.value)" />
            <span class="filter-label"><span class="filter-icon">{{ opt.icon }}</span> {{ opt.label }} <span class="filter-count">({{ opt.count }})</span></span>
          </label>
        </div>
      </aside>

      <main class="results-main">
        <nav class="alpha-nav">
          <button v-for="letter in alphabet" :key="letter" @click="scrollToLetter(letter)" :class="{ 'has-content': groupedFormulas[letter] }" :disabled="!groupedFormulas[letter]">{{ letter }}</button>
        </nav>

        <div class="formula-list">
          <div v-for="letter in activeLetters" :key="letter" :id="'letter-' + letter" class="letter-group">
            <h3 class="letter-heading">{{ letter }}</h3>
            <div class="formula-items">
              <a v-for="f in groupedFormulas[letter]" :key="f.slug" :href="'/formulas/' + f.slug" class="formula-item">
                <div class="formula-main">
                  <span class="formula-name">{{ f.name }}</span>
                  <span class="formula-key">{{ f.formulaName }}</span>
                </div>
                <div class="formula-meta">
                  <span class="formula-badges"><span :title="f.licenseName">{{ getLicenseBadge(f) }}</span> <span :title="f.sourceType">{{ getSourceBadge(f) }}</span></span>
                  <span class="formula-counts">{{ f.familyCount }} {{ f.familyCount === 1 ? 'family' : 'families' }}, {{ f.styleCount }} {{ f.styleCount === 1 ? 'style' : 'styles' }}</span>
                </div>
              </a>
            </div>
          </div>
        </div>
      </main>
    </div>
  </div>
</template>

<style scoped>
.formulas-browser { margin-top: 1rem; }
.search-container { display: flex; align-items: center; gap: 1rem; margin-bottom: 1.5rem; }
.search-input { flex: 1; padding: 0.75rem 1rem; font-size: 1.1rem; border: 2px solid var(--vp-c-divider); border-radius: 8px; background: var(--vp-c-bg-alt); color: var(--vp-c-text-1); }
.search-input:focus { outline: none; border-color: var(--vp-c-brand-1); }
.search-input::placeholder { color: var(--vp-c-text-3); }
.result-count { font-size: 0.9rem; color: var(--vp-c-text-2); white-space: nowrap; }
.browser-layout { display: grid; grid-template-columns: 220px 1fr; gap: 2rem; }
.filters-sidebar { position: sticky; top: 1rem; height: fit-content; padding: 1rem; background: var(--vp-c-bg-alt); border-radius: 8px; border: 1px solid var(--vp-c-divider); }
.filter-section { margin-bottom: 1.5rem; }
.filter-section:last-child { margin-bottom: 0; }
.filter-section h4 { margin: 0 0 0.75rem 0; font-size: 0.85rem; font-weight: 600; color: var(--vp-c-text-2); text-transform: uppercase; letter-spacing: 0.05em; }
.filter-checkbox { display: flex; align-items: flex-start; gap: 0.5rem; margin-bottom: 0.5rem; cursor: pointer; }
.filter-checkbox input { margin-top: 0.2rem; cursor: pointer; }
.filter-label { font-size: 0.9rem; color: var(--vp-c-text-1); }
.filter-icon { margin-right: 0.25rem; }
.filter-count { font-size: 0.8rem; color: var(--vp-c-text-3); }
.results-main { min-width: 0; }
.alpha-nav { display: flex; flex-wrap: wrap; gap: 0.25rem; margin-bottom: 1.5rem; padding-bottom: 1rem; border-bottom: 1px solid var(--vp-c-divider); }
.alpha-nav button { width: 32px; height: 32px; padding: 0; border: 1px solid var(--vp-c-divider); border-radius: 4px; background: var(--vp-c-bg-alt); color: var(--vp-c-text-3); font-size: 0.85rem; font-weight: 500; cursor: pointer; }
.alpha-nav button:hover:not(:disabled) { background: var(--vp-c-brand-soft); border-color: var(--vp-c-brand-1); color: var(--vp-c-brand-1); }
.alpha-nav button.has-content { color: var(--vp-c-text-1); background: var(--vp-c-bg); }
.alpha-nav button:disabled { opacity: 0.4; cursor: default; }
.letter-group { margin-bottom: 2rem; }
.letter-heading { font-size: 1.5rem; font-weight: 700; color: var(--vp-c-brand-1); margin: 0 0 1rem 0; padding-bottom: 0.5rem; border-bottom: 2px solid var(--vp-c-brand-1); }
.formula-items { display: grid; gap: 0.5rem; }
.formula-item { display: flex; justify-content: space-between; align-items: center; padding: 0.75rem 1rem; border: 1px solid var(--vp-c-divider); border-radius: 6px; background: var(--vp-c-bg); text-decoration: none; transition: all 0.2s; }
.formula-item:hover { border-color: var(--vp-c-brand-1); background: var(--vp-c-bg-alt); transform: translateX(4px); }
.formula-main { display: flex; flex-direction: column; gap: 0.25rem; }
.formula-name { font-weight: 600; color: var(--vp-c-text-1); }
.formula-key { font-family: var(--vp-font-family-mono); font-size: 0.85rem; color: var(--vp-c-text-2); }
.formula-meta { display: flex; flex-direction: column; align-items: flex-end; gap: 0.25rem; }
.formula-badges { font-size: 1rem; }
.formula-counts { font-size: 0.8rem; color: var(--vp-c-text-3); }
@media (max-width: 768px) {
  .browser-layout { grid-template-columns: 1fr; }
  .filters-sidebar { position: static; order: 2; }
  .results-main { order: 1; }
  .formula-item { flex-direction: column; align-items: flex-start; gap: 0.5rem; }
  .formula-meta { flex-direction: row; align-items: center; width: 100%; justify-content: space-between; }
}
</style>
