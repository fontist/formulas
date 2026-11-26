<script setup>
import { onMounted } from 'vue'

onMounted(() => {
  document.querySelectorAll('.sha-copy-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.preventDefault()
      const sha = btn.dataset.sha
      navigator.clipboard.writeText(sha).then(() => {
        const originalText = btn.textContent
        btn.textContent = 'Copied!'
        btn.classList.add('copied')
        setTimeout(() => {
          btn.textContent = originalText
          btn.classList.remove('copied')
        }, 2000)
      })
    })
  })
})
</script>
