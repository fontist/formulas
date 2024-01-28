<script setup>
import { useData } from 'vitepress'
import { marked } from 'marked'

// params is a Vue ref
const { params } = useData()

// console.log(params.value)

const licenseAgreementHTML = marked(params.value.requires_license_agreement || "", { breaks: true })

const fonts = []
for (const font of params.value.fonts || []) {
    for (const style of font.styles || []) {
        let fontName = style.family_name || "<unknown>"
        if (style.type) {
            fontName = `${fontName} (${style.type})`
        }
        fonts.push(fontName)
    }
}
</script>

# {{ $params.name }}

{{ $params.description }}

<a :href="$params.yaml_url">📜 View the source recipe</a>

{{ $params.name }} provides these fonts:

<ul>
  <template v-for="font in fonts">
    <li>{{ font }}</li>
  </template>
</ul>

{{ $params.copyright }}

<a :href="$params.license_url">{{ $params.license_url }}</a>

<details v-if="$params.requires_license_agreement">
<summary>License agreement</summary>
<div v-html="licenseAgreementHTML"></div>
</details>
