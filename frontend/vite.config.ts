import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'node:path';

/**
 * AC7 Ride — Vite configuration
 *
 * In development the dev server proxies `/api` and `/ws` to the Go backend
 * (Kong gateway by default) so the browser sees a same-origin app. This avoids
 * CORS entirely during development and means `VITE_API_BASE_URL` can stay empty
 * locally. In production the app is served as static files and talks to the
 * gateway origin configured via `VITE_API_BASE_URL`.
 */
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');

  // Kong proxy listens on :8000 and fronts every microservice.
  const gateway = env.DEV_API_PROXY_TARGET || 'http://localhost:8000';

  /**
   * Preview builds are a design showcase with no backend — see src/preview/.
   *
   * This goes through `define` rather than being read from import.meta.env in
   * application code, and that distinction matters. Vite replaces
   * `import.meta.env` with a plain object, so `env.VITE_PREVIEW_MODE` stays a
   * runtime property access that the minifier will not fold — which means the
   * `if (preview)` branches survive and drag the whole fixture set into a
   * production bundle. A build check caught exactly that.
   *
   * `define` substitutes a bare `true` / `false` literal at every use site, so
   * the branches become statically dead and the fixture chunk is never
   * referenced. Verified by grepping the built assets.
   */
  const previewMode = env.VITE_PREVIEW_MODE === 'true';

  return {
    plugins: [react()],

    define: {
      __PREVIEW_BUILD__: JSON.stringify(previewMode),
    },

    resolve: {
      alias: {
        '@': path.resolve(__dirname, './src'),
      },
    },

    server: {
      host: true,
      port: 3000,
      proxy: {
        '/api': {
          target: gateway,
          changeOrigin: true,
        },
        '/ws': {
          target: gateway,
          changeOrigin: true,
          ws: true,
        },
        // The maps service is mounted at /maps (not under /api/v1).
        '/maps': {
          target: gateway,
          changeOrigin: true,
        },
      },
    },

    preview: {
      host: true,
      port: 3000,
    },

    build: {
      target: 'es2020',
      sourcemap: mode !== 'production',
      rollupOptions: {
        output: {
          // Split the three role bundles so a rider never downloads admin code.
          manualChunks(id) {
            if (id.includes('node_modules')) {
              if (id.includes('react') || id.includes('scheduler')) return 'vendor-react';
              if (id.includes('@tanstack')) return 'vendor-query';
              return 'vendor';
            }
            if (id.includes('/src/routes/admin/')) return 'app-admin';
            if (id.includes('/src/routes/driver/')) return 'app-driver';
            return undefined;
          },
        },
      },
    },
  };
});
