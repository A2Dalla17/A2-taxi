import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

import { App } from './App';
import { OfflineBanner } from '@/components/ui/EmptyState';
// DEMO_MODE — delete this import and <DemoBanner /> below with src/dev/.
import { DemoBanner } from '@/dev/DemoBanner';
import { AuthProvider } from '@/providers/AuthProvider';
import { ThemeProvider } from '@/providers/ThemeProvider';
import { ApiError } from '@/lib/http';

import './styles/index.css';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30_000,
      gcTime: 5 * 60_000,
      refetchOnWindowFocus: false,
      retry: (failureCount, error) => {
        // Never retry auth failures or client errors — only transient ones.
        if (error instanceof ApiError) {
          if (!error.isRetryable) return false;
        }
        return failureCount < 2;
      },
    },
    mutations: {
      retry: false,
    },
  },
});

const container = document.getElementById('root');
if (!container) throw new Error('#root not found');

createRoot(container).render(
  <StrictMode>
    <ThemeProvider>
      <QueryClientProvider client={queryClient}>
        <BrowserRouter>
          <AuthProvider>
            <OfflineBanner />
            <App />
            {/* DEMO_MODE — delete with src/dev/. */}
            <DemoBanner />
          </AuthProvider>
        </BrowserRouter>
      </QueryClientProvider>
    </ThemeProvider>
  </StrictMode>,
);

// Remove the pre-hydration splash now that React owns the page.
document.getElementById('boot')?.remove();
