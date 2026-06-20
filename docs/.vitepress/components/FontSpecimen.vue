<script setup>
import { ref, computed, onMounted, watch } from 'vue'

const props = defineProps({
  slug: { type: String, required: true },
  familyName: { type: String, default: '' },
  woff2Path: { type: String, default: null },
  redistributable: { type: Boolean, default: false }
})

const basePath = import.meta.env.BASE_URL || '/'
const loaded = ref(false)
const error = ref(null)

const fontUrl = computed(() => {
  if (!props.woff2Path) return null
  return `${basePath}${props.woff2Path}`
})

const fontId = computed(() => `fontist-${props.slug.replace(/[^a-z0-9]/gi, '-')}`)

const sampleText = ref('The quick brown fox jumps over the lazy dog')
const showCharmap = ref(false)

const charmapChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*(){}[]<>?'

const styleId = `fontist-specimen-style-${fontId.value}`

function injectFontFace() {
  if (!fontUrl.value) return
  if (document.getElementById(styleId)) return

  const style = document.createElement('style')
  style.id = styleId
  style.textContent = `
    @font-face {
      font-family: '${fontId.value}';
      src: url('${fontUrl.value}') format('woff2');
      font-weight: 100 900;
      font-display: swap;
    }
  `
  document.head.appendChild(style)
  loaded.value = true
}

onMounted(() => {
  if (props.redistributable && props.woff2Path) {
    injectFontFace()
  }
})

watch(() => props.woff2Path, () => {
  if (props.redistributable && props.woff2Path) {
    injectFontFace()
  }
})
</script>

<template>
  <div class="font-specimen">
    <!-- Redistributable: live @font-face specimen -->
    <div v-if="redistributable && woff2Path" class="fs-live">
      <div class="fs-hero" :style="{ fontFamily: `'${fontId}', serif` }">
        {{ familyName || slug }}
      </div>

      <div class="fs-sample">
        <input
          v-model="sampleText"
          class="fs-input"
          :style="{ fontFamily: `'${fontId}', sans-serif` }"
          placeholder="Type to preview in this font…"
        >
      </div>

      <div class="fs-alphabet" :style="{ fontFamily: `'${fontId}', sans-serif` }">
        ABCDEFGHIJKLMNOPQRSTUVWXYZ
      </div>
      <div class="fs-alphabet" :style="{ fontFamily: `'${fontId}', sans-serif` }">
        abcdefghijklmnopqrstuvwxyz
      </div>
      <div class="fs-numbers" :style="{ fontFamily: `'${fontId}', sans-serif` }">
        0123456789 !&amp;?"#$%&amp;'()*+,-./:;&lt;&gt;=
      </div>

      <button class="fs-charmap-toggle" @click="showCharmap = !showCharmap">
        {{ showCharmap ? 'Hide' : 'Show' }} character map
      </button>

      <div v-if="showCharmap" class="fs-charmap">
        <div
          v-for="char in charmapChars"
          :key="char"
          class="fs-charmap-cell"
          :style="{ fontFamily: `'${fontId}', sans-serif` }"
          :title="`U+${char.codePointAt(0).toString(16).toUpperCase().padStart(4, '0')}`"
        >
          {{ char }}
        </div>
      </div>
    </div>

    <!-- Proprietary: no specimen, show metadata only -->
    <div v-else class="fs-unavailable">
      <div class="fs-unavailable-icon">Aa</div>
      <p class="fs-unavailable-text">
        Specimen unavailable — this font's license does not permit web preview.
      </p>
      <p class="fs-unavailable-hint">
        Install via <code>fontist install --formula "{{ slug }}"</code> to see the full character set locally.
      </p>
    </div>
  </div>
</template>

<style scoped>
.font-specimen {
  margin: 1.5rem 0;
}

.fs-live {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.fs-hero {
  font-size: clamp(2.5rem, 6vw, 4rem);
  font-weight: 700;
  line-height: 1.1;
  letter-spacing: -0.02em;
  color: var(--vp-c-text-1);
}

.fs-sample {
  position: relative;
}

.fs-input {
  width: 100%;
  padding: 0.75rem 1rem;
  font-size: clamp(1.25rem, 2.5vw, 1.75rem);
  line-height: 1.4;
  border: 1px solid var(--vp-c-divider);
  border-radius: 8px;
  background: var(--vp-c-bg);
  color: var(--vp-c-text-1);
  outline: none;
  transition: border-color 0.15s;
}

.fs-input:focus {
  border-color: var(--fontist-rose, #bf4e6a);
}

.fs-input::placeholder {
  color: var(--vp-c-text-3);
}

.fs-alphabet,
.fs-numbers {
  font-size: clamp(1rem, 2vw, 1.5rem);
  line-height: 1.6;
  letter-spacing: 0.01em;
  color: var(--vp-c-text-2);
}

.fs-charmap-toggle {
  align-self: flex-start;
  padding: 0.4rem 0.8rem;
  font-size: 0.8rem;
  font-weight: 500;
  border: 1px solid var(--vp-c-divider);
  border-radius: 6px;
  background: var(--vp-c-bg);
  color: var(--vp-c-text-2);
  cursor: pointer;
  transition: all 0.15s;
}

.fs-charmap-toggle:hover {
  border-color: var(--fontist-rose, #bf4e6a);
  color: var(--fontist-rose, #bf4e6a);
}

.fs-charmap {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(48px, 1fr));
  gap: 2px;
  padding: 0.5rem;
  border: 1px solid var(--vp-c-divider);
  border-radius: 8px;
  background: var(--vp-c-bg-soft);
}

.fs-charmap-cell {
  aspect-ratio: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.5rem;
  color: var(--vp-c-text-1);
  border-radius: 4px;
  transition: background 0.1s;
}

.fs-charmap-cell:hover {
  background: var(--fontist-rose-soft, rgba(191, 78, 106, 0.14));
}

/* Proprietary fallback */
.fs-unavailable {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  padding: 2rem 1.5rem;
  border: 1px dashed var(--vp-c-divider);
  border-radius: 8px;
  background: var(--vp-c-bg-soft);
}

.fs-unavailable-icon {
  font-size: 3rem;
  font-weight: 300;
  color: var(--vp-c-text-3);
  margin-bottom: 0.5rem;
  font-family: Georgia, 'Times New Roman', serif;
}

.fs-unavailable-text {
  font-size: 0.9rem;
  color: var(--vp-c-text-2);
  margin: 0 0 0.5rem 0;
}

.fs-unavailable-hint {
  font-size: 0.8rem;
  color: var(--vp-c-text-3);
  margin: 0;
}

.fs-unavailable-hint code {
  font-family: var(--vp-font-family-mono);
  font-size: 0.75rem;
  background: var(--vp-c-bg);
  padding: 0.1em 0.3em;
  border-radius: 3px;
}

@media (max-width: 640px) {
  .fs-charmap {
    grid-template-columns: repeat(auto-fill, minmax(36px, 1fr));
  }

  .fs-charmap-cell {
    font-size: 1.2rem;
  }
}
</style>
