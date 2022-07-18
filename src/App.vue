<template>
  <router-view />
</template>

<script setup>
import { onMounted } from 'vue'

onMounted(() => {
  document.body.style.setProperty('--el-color-primary', '#EAA4A4');
  document.body.style.setProperty('--el-color-primary-light-3', '#FBB8AC');
  document.body.style.setProperty('--el-color-primary-light-5', '#FEDBD0');
  document.body.style.setProperty('--el-color-primary-light-8', '#FEDBD0');
  document.body.style.setProperty('--el-color-primary-light-9', '#FEEAE6');
})
</script>
