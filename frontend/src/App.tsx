/**
 * AC7 Ride — route table and role guards
 *
 * Roles come from the JWT (`rider | driver | admin`) and are enforced
 * server-side by middleware.RequireRole on every protected endpoint. The
 * guards here are purely for navigation quality — they are not a security
 * boundary and must never be treated as one.
 *
 * Rider routes are eagerly loaded (the common case); driver and admin are
 * lazy so a rider never downloads them.
 */

import { lazy, Suspense } from 'react';
import { Navigate, Route, Routes, useLocation } from 'react-router-dom';

import type { UserRole } from '@/api/types';
import { FullPageSpinner } from '@/components/ui/Spinner';
import { useAuth } from '@/providers/AuthProvider';

import { LoginPage } from '@/routes/auth/LoginPage';

/* -------------------------------------------------------------------------- */
/* Guards                                                                      */
/* -------------------------------------------------------------------------- */

/** Where each role lands after signing in. */
const HOME_FOR_ROLE: Record<UserRole, string> = {
  rider: '/app',
  driver: '/driver',
  admin: '/admin',
};

function RequireAuth({ allow, children }: { allow: UserRole[]; children: React.ReactNode }) {
  const { isAuthenticated, isLoading, role } = useAuth();
  const location = useLocation();

  if (isLoading) return <FullPageSpinner label="Signing you in" />;

  if (!isAuthenticated) {
    // Remember where they were headed so login can bounce them back.
    return <Navigate to="/login" state={{ from: location.pathname }} replace />;
  }

  if (role && !allow.includes(role)) {
    return <Navigate to={HOME_FOR_ROLE[role]} replace />;
  }

  return <>{children}</>;
}

/** Sends an already-signed-in user away from login/register. */
function RedirectIfAuthed({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, isLoading, role } = useAuth();

  if (isLoading) return <FullPageSpinner label="Loading" />;
  if (isAuthenticated && role) return <Navigate to={HOME_FOR_ROLE[role]} replace />;

  return <>{children}</>;
}

/* -------------------------------------------------------------------------- */
/* Lazy route groups                                                           */
/* -------------------------------------------------------------------------- */

const RegisterPage = lazy(() =>
  import('@/routes/auth/RegisterPage').then((m) => ({ default: m.RegisterPage })),
);
const ForgotPasswordPage = lazy(() =>
  import('@/routes/auth/ForgotPasswordPage').then((m) => ({ default: m.ForgotPasswordPage })),
);
const TwoFactorPage = lazy(() =>
  import('@/routes/auth/TwoFactorPage').then((m) => ({ default: m.TwoFactorPage })),
);

const RiderLayout = lazy(() =>
  import('@/routes/rider/RiderLayout').then((m) => ({ default: m.RiderLayout })),
);
const DriverLayout = lazy(() =>
  import('@/routes/driver/DriverLayout').then((m) => ({ default: m.DriverLayout })),
);
const AdminLayout = lazy(() =>
  import('@/routes/admin/AdminLayout').then((m) => ({ default: m.AdminLayout })),
);

const LandingPage = lazy(() =>
  import('@/routes/LandingPage').then((m) => ({ default: m.LandingPage })),
);
const NotFoundPage = lazy(() =>
  import('@/routes/NotFoundPage').then((m) => ({ default: m.NotFoundPage })),
);
const DriverLookupPage = lazy(() =>
  import('@/routes/DriverLookupPage').then((m) => ({ default: m.DriverLookupPage })),
);

/* -------------------------------------------------------------------------- */

export function App() {
  return (
    <Suspense fallback={<FullPageSpinner />}>
      <Routes>
        {/* Public */}
        <Route path="/" element={<LandingPage />} />

        <Route
          path="/login"
          element={
            <RedirectIfAuthed>
              <LoginPage />
            </RedirectIfAuthed>
          }
        />
        <Route
          path="/register"
          element={
            <RedirectIfAuthed>
              <RegisterPage />
            </RedirectIfAuthed>
          }
        />
        <Route path="/forgot-password" element={<ForgotPasswordPage />} />
        <Route path="/two-factor" element={<TwoFactorPage />} />

        {/* Driver code lookup — public on purpose.
            /d      is the scanner and manual entry
            /d/:code is what a driver's QR encodes, so a phone's built-in camera
                     app resolves straight to the answer with no typing.
            Someone deciding whether to get into a car cannot be asked to
            register first; that would defeat the point of the check. */}
        <Route path="/d" element={<DriverLookupPage />} />
        <Route path="/d/:code" element={<DriverLookupPage />} />

        {/* Rider */}
        <Route
          path="/app/*"
          element={
            <RequireAuth allow={['rider', 'driver', 'admin']}>
              <RiderLayout />
            </RequireAuth>
          }
        />

        {/* Driver — admins are allowed in so they can inspect the surface.
            Note the backend still enforces RequireRole(driver) on every
            /api/v1/driver/* endpoint, so an admin sees the screens but the
            data calls return 403. That is correct: this guard is for
            navigation, not authorisation. */}
        <Route
          path="/driver/*"
          element={
            <RequireAuth allow={['driver', 'admin']}>
              <DriverLayout />
            </RequireAuth>
          }
        />

        {/* Admin */}
        <Route
          path="/admin/*"
          element={
            <RequireAuth allow={['admin']}>
              <AdminLayout />
            </RequireAuth>
          }
        />

        <Route path="*" element={<NotFoundPage />} />
      </Routes>
    </Suspense>
  );
}
