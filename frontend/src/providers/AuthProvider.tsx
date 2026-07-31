/**
 * AC7 Ride — authentication context
 *
 * Wraps the session store in React state, owns login/register/logout, and
 * keeps the WebSocket lifecycle tied to the session (connect on login, drop on
 * logout, reconnect with a fresh token when the token changes).
 */

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';

import { authApi } from '@/api';
import type { LoginRequest, RegisterRequest, User, UserRole } from '@/api/types';
// DEMO_MODE — delete this import with src/dev/ and src/preview/.
import { DEMO_ENABLED, ensurePreviewSession, isDemoSession } from '@/dev/demoSession';
import { setUnauthorizedHandler } from '@/lib/http';
import {
  clearSession,
  getSession,
  onSessionChange,
  setSession,
  updateUser as persistUser,
} from '@/lib/session';
import { realtime } from '@/lib/ws';

interface AuthContextValue {
  user: User | null;
  role: UserRole | null;
  isAuthenticated: boolean;
  /** True until the initial session check completes. Guards flash-of-login. */
  isLoading: boolean;

  login: (payload: LoginRequest) => Promise<User>;
  register: (payload: RegisterRequest) => Promise<User>;
  logout: () => void;
  refreshProfile: () => Promise<void>;
  updateUser: (user: User) => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(() => getSession()?.user ?? null);
  const [isLoading, setIsLoading] = useState(true);

  /* -- Initial boot: validate the stored token against the backend -------- */
  useEffect(() => {
    // DEMO_MODE — delete with src/dev/ and src/preview/. A design-preview build
    // has no backend to sign in to, so it bootstraps a session rather than
    // bouncing to a login form that cannot succeed.
    const previewUser = ensurePreviewSession();
    if (previewUser) {
      setUser(previewUser);
      setIsLoading(false);
      return;
    }

    const session = getSession();

    if (!session) {
      clearSession();
      setUser(null);
      setIsLoading(false);
      return;
    }

    // DEMO_MODE — delete this block with src/dev/. A fabricated session has no
    // server-side counterpart, so validating it would immediately log us out.
    if (DEMO_ENABLED && isDemoSession()) {
      setUser(session.user);
      setIsLoading(false);
      return;
    }

    let cancelled = false;

    // The token may be revoked or the user deactivated since last visit, so we
    // confirm with the server rather than trusting localStorage.
    authApi
      .profile()
      .then((profile) => {
        if (cancelled) return;
        setUser(profile);
        persistUser(profile);
        realtime.connect();
      })
      .catch(() => {
        if (cancelled) return;
        clearSession();
        setUser(null);
      })
      .finally(() => {
        if (!cancelled) setIsLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, []);

  /* -- Keep React state in sync with the store (other tabs, 401 handler) -- */
  useEffect(() => {
    return onSessionChange((session) => {
      setUser(session?.user ?? null);
      if (!session) realtime.disconnect();
    });
  }, []);

  /* -- Global 401 handling ------------------------------------------------ */
  useEffect(() => {
    setUnauthorizedHandler(() => {
      // DEMO_MODE — delete this block with src/dev/. Every request made with a
      // fabricated token comes back 401; bouncing on each one would make the
      // app unusable for a design review. Stay put and let screens show their
      // own error states.
      if (DEMO_ENABLED && isDemoSession()) return;

      setUser(null);
      realtime.disconnect();
      // Full navigation rather than router push: a 401 means we want a clean
      // slate, including any stale React Query cache.
      if (!window.location.pathname.startsWith('/login')) {
        window.location.assign('/login?expired=1');
      }
    });

    return () => setUnauthorizedHandler(null);
  }, []);

  /* -- Actions ------------------------------------------------------------ */

  const login = useCallback(async (payload: LoginRequest): Promise<User> => {
    const result = await authApi.login(payload);
    setSession(result.token, result.user);
    setUser(result.user);
    realtime.reconnectWithFreshToken();
    return result.user;
  }, []);

  const register = useCallback(
    async (payload: RegisterRequest): Promise<User> => {
      // The backend's register returns the User but not a token, so we log in
      // immediately afterwards to obtain one.
      await authApi.register(payload);
      return login({ email: payload.email, password: payload.password });
    },
    [login],
  );

  const logout = useCallback(() => {
    clearSession();
    setUser(null);
    realtime.disconnect();
  }, []);

  const refreshProfile = useCallback(async () => {
    const profile = await authApi.profile();
    setUser(profile);
    persistUser(profile);
  }, []);

  const updateUser = useCallback((next: User) => {
    setUser(next);
    persistUser(next);
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      role: user?.role ?? null,
      isAuthenticated: user !== null,
      isLoading,
      login,
      register,
      logout,
      refreshProfile,
      updateUser,
    }),
    [user, isLoading, login, register, logout, refreshProfile, updateUser],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used inside <AuthProvider>');
  return context;
}
