<template>
  <img :src="svgData" :alt="`${label}: ${text}`" />
</template>

<script setup>
const props = defineProps({
  label: { type: String, required: true },
  text: { type: String, required: true },
  color: { type: String, default: '#28a745' }
})

const encodedLabel = encodeURIComponent(props.label)
const encodedText = encodeURIComponent(props.text)
const encodedColor = encodeURIComponent(props.color)

const svgData = `data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' width='auto' height='20' role='img' aria-label='${props.label}: ${props.text}'%3E%3Ctitle%3E${props.label}: ${props.text}%3C/title%3E%3ClinearGradient id='b' x2='0' y2='100%25'%3E%3Cstop offset='0' stop-color='%23bbb' stop-opacity='.1'/%3E%3Cstop offset='1' stop-opacity='.1'/%3C/linearGradient%3E%3Cmask id='a'%3E%3Crect width='100%25' height='100%25' fill='%23fff' rx='3'/%3E%3C/mask%3E%3Cg mask='url(%23a)'%3E%3Cpath fill='%23555' d='M0 0h50v20H0z'/%3E%3Cpath fill='${encodedColor}' d='M50 0h80v20H50z'/%3E%3Cpath fill='url(%23b)' d='M0 0h130v20H0z'/%3E%3C/g%3E%3Cg fill='%23fff' text-anchor='middle' font-family='Verdana,Geneva,DejaVu Sans,sans-serif' font-size='11'%3E%3Ctext x='25' y='15'%3E${props.label}%3C/text%3E%3Ctext x='90' y='15'%3E${props.text}%3C/text%3E%3C/g%3E%3C/svg%3E`
</script>
