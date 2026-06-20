<script setup>
import { ref, computed, onMounted } from 'vue'

const props = defineProps({
  slug: { type: String, required: true },
  redistributable: { type: Boolean, default: false }
})

const coverage = ref(null)
const loading = ref(true)
const error = ref(null)
const expandedGroups = ref(new Set(['Latin & European']))

const basePath = import.meta.env.BASE_URL || '/'

const groupedBlocks = computed(() => {
  if (!coverage.value?.blocks) return []
  const groups = {}
  for (const block of coverage.value.blocks) {
    const cat = categorize(block.name)
    if (!groups[cat]) groups[cat] = { name: cat, blocks: [], supported: 0 }
    groups[cat].blocks.push(block)
    groups[cat].supported++
  }
  return Object.values(groups).sort((a, b) => a.name.localeCompare(b.name))
})

const unsupportedGroups = computed(() => {
  if (!coverage.value) return []
  const supported = new Set(coverage.value.blocks?.map(b => b.name))
  return ALL_BLOCKS.value.filter(b => !supported.has(b.name))
})

const ALL_BLOCKS = ref([])

function categorize(name) {
  if (/Latin|Latin Extended|IPA|Spacing Modifier|Combining Diacritic/i.test(name))
    return 'Latin & European'
  if (/Cyrillic|Greek|Coptic/i.test(name)) return 'Cyrillic & Greek'
  if (/Arabic|Hebrew|Syriac|Thaana|Samaritan|Mandaic/i.test(name)) return 'Middle Eastern'
  if (/Devanagari|Bengali|Gurmukhi|Gujarati|Oriya|Tamil|Telugu|Kannada|Malayalam|Sinhala|Thai|Lao|Tibetan|Myanmar/i.test(name))
    return 'South & Southeast Asian'
  if (/CJK|Unified Ideographs|Hiragana|Katakana|Hangul|Bopomofo|Kangxi|Yi|CJK|Phags-pa/i.test(name))
    return 'CJK'
  if (/Mathematical|Arrows|Supplemental|Miscellaneous|Dingbats|Geometric|Box Drawing|Block Elements/i.test(name))
    return 'Symbols'
  if (/Emoji|Emoticons|Pictographs|Transport|Alchemy/i.test(name)) return 'Emoji & Pictographs'
  if (/Private Use/i.test(name)) return 'Private Use'
  return 'Other'
}

function toggleGroup(name) {
  if (expandedGroups.value.has(name)) expandedGroups.value.delete(name)
  else expandedGroups.value.add(name)
}

onMounted(async () => {
  try {
    const res = await fetch(`${basePath}coverage/${props.slug}.json`)
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    coverage.value = await res.json()

    const blocksRes = await fetch(`${basePath}unicode-blocks.json`)
    if (blocksRes.ok) ALL_BLOCKS.value = await blocksRes.json()
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div class="unicode-coverage">
    <div v-if="loading" class="uc-loading">Loading Unicode coverage…</div>

    <div v-else-if="error" class="uc-error">
      Coverage data not available for this font.
    </div>

    <div v-else-if="coverage" class="uc-summary">
      <div class="uc-stats">
        <span class="uc-stat">
          <strong>{{ coverage.total_codepoints }}</strong> codepoints
        </span>
        <span class="uc-stat">
          <strong>{{ coverage.supported_blocks }}</strong> / {{ ALL_BLOCKS.length || '?' }} blocks
        </span>
        <span class="uc-stat">
          Planes:
          <strong>{{ Object.entries(coverage.planes).filter(([, v]) => v).map(([k]) => k.toUpperCase()).join(', ') || 'None' }}</strong>
        </span>
      </div>

      <div v-if="!redistributable" class="uc-note">
        ⚠ This font's license does not permit redistribution. Glyph previews are not shown.
        Install via <code>fontist</code> to see the full character set.
      </div>

      <div class="uc-groups">
        <div v-for="group in groupedBlocks" :key="group.name" class="uc-group">
          <button class="uc-group-header" @click="toggleGroup(group.name)">
            <span class="uc-group-name">{{ group.name }}</span>
            <span class="uc-group-count">{{ group.supported }} supported</span>
            <span class="uc-toggle">{{ expandedGroups.has(group.name) ? '−' : '+' }}</span>
          </button>
          <div v-if="expandedGroups.has(group.name)" class="uc-block-list">
            <div v-for="block in group.blocks" :key="block.name" class="uc-block uc-block--supported">
              <span class="uc-check">✓</span>
              <span class="uc-block-name">{{ block.name }}</span>
              <span class="uc-block-range">{{ block.range }}</span>
              <span class="uc-block-count">{{ block.count }}/{{ block.total }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.unicode-coverage {
  margin: 2rem 0;
}

.uc-loading, .uc-error {
  color: var(--vp-c-text-3);
  font-style: italic;
  padding: 1rem 0;
}

.uc-summary {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.uc-stats {
  display: flex;
  gap: 1.5rem;
  flex-wrap: wrap;
  font-size: 0.9rem;
  color: var(--vp-c-text-2);
}

.uc-stat strong {
  color: var(--vp-c-text-1);
  font-variant-numeric: tabular-nums;
}

.uc-note {
  padding: 0.75rem 1rem;
  background: var(--vp-c-bg-soft);
  border-left: 3px solid var(--fontist-rose, #bf4e6a);
  font-size: 0.875rem;
  color: var(--vp-c-text-2);
}

.uc-note code {
  font-family: var(--vp-font-family-mono);
  font-size: 0.8rem;
  background: var(--vp-c-bg-alt);
  padding: 0.1em 0.3em;
  border-radius: 3px;
}

.uc-groups {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.uc-group {
  border: 1px solid var(--vp-c-divider);
  border-radius: 6px;
  overflow: hidden;
}

.uc-group-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  width: 100%;
  padding: 0.5rem 0.75rem;
  background: var(--vp-c-bg-soft);
  border: none;
  cursor: pointer;
  text-align: left;
  font-size: 0.875rem;
  transition: background 0.15s;
}

.uc-group-header:hover {
  background: var(--vp-c-bg-alt);
}

.uc-group-name {
  font-weight: 600;
  color: var(--vp-c-text-1);
}

.uc-group-count {
  color: var(--vp-c-text-3);
  font-size: 0.8rem;
}

.uc-toggle {
  margin-left: auto;
  color: var(--vp-c-text-3);
  font-size: 1rem;
  width: 1.2rem;
  text-align: center;
}

.uc-block-list {
  padding: 0.25rem 0;
}

.uc-block {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.35rem 0.75rem;
  font-size: 0.8rem;
  border-bottom: 1px solid var(--vp-c-divider);
}

.uc-block:last-child {
  border-bottom: none;
}

.uc-check {
  width: 1rem;
  text-align: center;
  font-weight: 600;
}

.uc-block--supported .uc-check {
  color: #5b8c5a;
}

.uc-block-name {
  color: var(--vp-c-text-1);
  flex: 1;
}

.uc-block-range {
  font-family: var(--vp-font-family-mono);
  font-size: 0.75rem;
  color: var(--vp-c-text-3);
}

.uc-block-count {
  font-variant-numeric: tabular-nums;
  color: var(--vp-c-text-2);
  font-size: 0.75rem;
  min-width: 4rem;
  text-align: right;
}

@media (max-width: 640px) {
  .uc-stats {
    flex-direction: column;
    gap: 0.5rem;
  }
  .uc-block-range {
    display: none;
  }
}
</style>
