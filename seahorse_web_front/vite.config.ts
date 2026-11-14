import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import path from 'path'

export default defineConfig(({ mode }) => {
  const isDesktop = mode === 'desktop' || process.env.VITE_DESKTOP === 'true'
  return {
    base: isDesktop ? './' : '/seahorse/',
    plugins: [vue()],
    resolve: {
      alias: {
        '@': path.resolve(__dirname, './src')
      }
    },
    build: {
      outDir: isDesktop ? 'dist-desktop' : 'dist',
      chunkSizeWarningLimit: 1000,
      rollupOptions: {
        output: {
          manualChunks(id) {
            if (!id.includes('node_modules')) return undefined
            if (id.includes('@element-plus/icons-vue')) return 'element-icons'
            if (id.includes('element-plus')) return 'element-plus'
            if (id.includes('/vue/') || id.includes('vue-router') || id.includes('pinia') || id.includes('axios') || id.includes('@vue/')) {
              return 'vue-vendor'
            }
            return undefined
          }
        }
      }
    },
    server: {
      port: 3000,
      host: '0.0.0.0',
      proxy: {
        '/api': {
          target: 'http://localhost:8082',
          changeOrigin: true
        }
      }
    }
  }
})
