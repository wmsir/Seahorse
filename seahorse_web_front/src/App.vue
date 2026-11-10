<template>
  <router-view />
</template>

<script setup lang="ts">
</script>

<style>
html, body, #app {
  margin: 0;
  padding: 0;
  width: 100%;
  height: 100%;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
  background-color: #f8fafc;
  color: #0f172a;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
* {
  box-sizing: border-box;
}

@media print {
  /* 隐藏管理后台导航、侧栏、卡片头部与操作按钮，确保小票打印纯净无泄露 */
  .layout-aside,
  .layout-header,
  .el-card__header,
  .post-sub-nav-bar,
  .form-actions-bar,
  .printer-form-col,
  .preview-header-bar,
  .el-tabs__header {
    display: none !important;
  }
}
</style>
