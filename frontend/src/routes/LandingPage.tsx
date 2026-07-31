import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import {
  Apple,
  ArrowRight,
  Clock,
  Globe,
  Phone,
  PlayCircle,
  ScanLine,
  ShieldCheck,
  Star,
} from 'lucide-react';

import { isDriverCode, normaliseDriverCode } from '@/api/drivers';
import { Button } from '@/components/ui/Button';
import { QrCode } from '@/components/ui/QrCode';
import { env } from '@/config/env';

/**
 * AC7 Ride — public landing page.
 *
 * Three ways in, because the people arriving here are not the same person:
 *
 *   1. Download the app        — the rider who will use us repeatedly
 *   2. Call the control centre — the person who does not want another app on
 *                                their phone, which in this market is a large
 *                                share of customers and not an edge case
 *   3. Check a driver's code   — someone standing next to a car right now,
 *                                deciding whether it is safe to get in
 *
 * The third is the one nobody else offers, so it gets equal billing rather
 * than being buried in a footer.
 */
export function LandingPage() {
  const navigate = useNavigate();
  const [code, setCode] = useState('');

  const storesLive = Boolean(env.appStores.ios || env.appStores.android);
  const canCheck = isDriverCode(normaliseDriverCode(code));

  return (
    <div className="min-h-screen bg-bg">
      <header className="glass sticky top-0 z-50 border-b border-line">
        <nav className="mx-auto flex h-16 max-w-6xl items-center justify-between px-6">
          <Link to="/" className="flex items-center gap-2 font-bold tracking-tight text-brand-ink">
            <span
              aria-hidden
              className="grid h-8 w-8 place-items-center rounded-lg bg-brand text-sm text-white"
            >
              A7
            </span>
            AC7 Ride
          </Link>

          <div className="flex items-center gap-2">
            <a
              href={`tel:${env.controlCentre.tel}`}
              className="hidden items-center gap-1.5 rounded-control px-3 py-2 text-body-sm font-medium text-ink hover:bg-surface sm:inline-flex"
            >
              <Phone size={15} aria-hidden />
              {env.controlCentre.display}
            </a>
            <Link to="/login">
              <Button variant="ghost" size="sm">
                Sign in
              </Button>
            </Link>
            <Link to="/register">
              <Button size="sm">Get started</Button>
            </Link>
          </div>
        </nav>
      </header>

      {/* ---- Hero ------------------------------------------------------ */}
      <section className="mx-auto max-w-6xl px-6 pb-6 pt-16 text-center sm:pt-24">
        <p className="mb-4 inline-flex items-center gap-1.5 rounded-pill bg-brand-soft px-3 py-1 text-caption font-medium text-brand-ink">
          <Globe size={12} aria-hidden />
          Private hire across London
        </p>

        <h1 className="mx-auto max-w-3xl text-display text-ink">
          Your car is already
          <span className="text-brand-ink"> on its way</span>
        </h1>

        <p className="mx-auto mt-5 max-w-xl text-body-lg leading-relaxed text-ink-muted">
          Transparent fares, checked drivers, live tracking door to door. Book in the app, or ring
          our control centre and we will book it for you.
        </p>
      </section>

      {/* ---- The three doors ------------------------------------------- */}
      <section className="mx-auto grid max-w-6xl gap-4 px-6 pb-16 md:grid-cols-3">
        {/* 1 — Download */}
        <article className="flex flex-col rounded-card border border-line bg-card p-6 shadow-card">
          <h2 className="text-h4 text-ink">Get the app</h2>
          <p className="mt-1.5 flex-1 text-body-sm leading-relaxed text-ink-muted">
            Book, track and pay from your phone. The fare is shown before you confirm.
          </p>

          <div className="mt-5 space-y-2">
            {storesLive ? (
              <>
                {env.appStores.ios && (
                  <a href={env.appStores.ios} className="block">
                    <Button fullWidth variant="secondary" leadingIcon={<Apple size={17} />}>
                      Download on the App Store
                    </Button>
                  </a>
                )}
                {env.appStores.android && (
                  <a href={env.appStores.android} className="block">
                    <Button fullWidth variant="secondary" leadingIcon={<PlayCircle size={17} />}>
                      Get it on Google Play
                    </Button>
                  </a>
                )}
              </>
            ) : (
              /* The store listings do not exist yet. A button that opens a 404
                 costs more trust than an honest "coming soon", so we send
                 people to the web app, which works on the same phone today. */
              <>
                <Link to="/register" className="block">
                  <Button fullWidth trailingIcon={<ArrowRight size={16} />}>
                    Use the web app
                  </Button>
                </Link>
                <p className="pt-1 text-center text-caption text-ink-subtle">
                  iPhone and Android apps are on the way. The web app works on both today — add
                  it to your home screen.
                </p>
              </>
            )}
          </div>
        </article>

        {/* 2 — Control centre */}
        <article className="flex flex-col rounded-card border border-line bg-card p-6 shadow-card">
          <h2 className="text-h4 text-ink">Rather just call?</h2>
          <p className="mt-1.5 flex-1 text-body-sm leading-relaxed text-ink-muted">
            Our control centre will take your details and book the taxi for you. No app, no
            account.
          </p>

          <a href={`tel:${env.controlCentre.tel}`} className="mt-5 block">
            <Button fullWidth leadingIcon={<Phone size={17} />}>
              {env.controlCentre.display}
            </Button>
          </a>
          <p className="mt-2 flex items-center justify-center gap-1.5 text-caption text-ink-subtle">
            <Clock size={12} aria-hidden />
            {env.controlCentre.hours}
          </p>
        </article>

        {/* 3 — Check a driver */}
        <article className="flex flex-col rounded-card border border-line bg-card p-6 shadow-card">
          <h2 className="text-h4 text-ink">Check a driver</h2>
          <p className="mt-1.5 text-body-sm leading-relaxed text-ink-muted">
            Scan the QR on the windscreen card, or type the driver&rsquo;s code, to confirm who
            they are and whether they are working right now.
          </p>

          <form
            className="mt-5 flex-1"
            onSubmit={(event) => {
              event.preventDefault();
              if (canCheck) navigate(`/d/${normaliseDriverCode(code)}`);
            }}
          >
            <label htmlFor="landing-driver-code" className="sr-only">
              Driver code
            </label>
            <div className="flex gap-2">
              <input
                id="landing-driver-code"
                value={code}
                onChange={(event) => setCode(event.target.value.toUpperCase())}
                placeholder="AC700042"
                autoCapitalize="characters"
                autoCorrect="off"
                spellCheck={false}
                className="tabular h-11 min-w-0 flex-1 rounded-control border border-line bg-bg px-3.5 text-body text-ink placeholder:text-ink-subtle focus:border-brand focus:outline-none focus:ring-2 focus:ring-brand/25"
              />
              <Button type="submit" disabled={!canCheck} aria-label="Check this code">
                <ArrowRight size={17} aria-hidden />
              </Button>
            </div>
          </form>

          <Link
            to="/d"
            className="mt-3 inline-flex items-center gap-1.5 text-body-sm font-medium text-brand-ink underline underline-offset-4"
          >
            <ScanLine size={15} aria-hidden />
            Scan a QR code instead
          </Link>
        </article>
      </section>

      {/* ---- QR to the app --------------------------------------------- */}
      <section className="border-y border-line bg-surface">
        <div className="mx-auto flex max-w-6xl flex-col items-center gap-8 px-6 py-14 sm:flex-row sm:justify-center">
          <div className="rounded-card border border-line bg-white p-3 shadow-card">
            <QrCode
              value={typeof window === 'undefined' ? 'https://ac7ride.com' : window.location.origin}
              size={148}
              label="QR code linking to the AC7 Ride web app"
            />
          </div>
          <div className="max-w-sm text-center sm:text-left">
            <h2 className="text-h3 text-ink">Open AC7 on your phone</h2>
            <p className="mt-2 text-body-sm leading-relaxed text-ink-muted">
              Point your camera at this code to open AC7 on your phone, then add it to your home
              screen. It behaves like a native app from there.
            </p>
          </div>
        </div>
      </section>

      {/* ---- Why ------------------------------------------------------- */}
      <section className="mx-auto max-w-6xl px-6 py-16">
        <div className="grid gap-4 sm:grid-cols-3">
          {[
            {
              icon: ShieldCheck,
              title: 'Every driver is checked',
              body: 'Licensed, insured, and identifiable by a code you can verify before you get in.',
            },
            {
              icon: Star,
              title: 'The price you were quoted',
              body: 'The fare is agreed before you confirm, so there is no surprise at the end of the trip.',
            },
            {
              icon: Clock,
              title: 'Book ahead',
              body: 'Airport runs and early starts can be booked in advance and assigned to a named driver.',
            },
          ].map(({ icon: Icon, title, body }) => (
            <article key={title} className="rounded-card border border-line bg-card p-5 shadow-card">
              <span
                aria-hidden
                className="grid h-10 w-10 place-items-center rounded-tile bg-brand-soft text-brand-ink"
              >
                <Icon size={19} />
              </span>
              <h3 className="mt-3.5 text-body font-semibold text-ink">{title}</h3>
              <p className="mt-1.5 text-body-sm leading-relaxed text-ink-muted">{body}</p>
            </article>
          ))}
        </div>
      </section>

      {/* ---- Drive with us --------------------------------------------- */}
      <section className="mx-auto max-w-6xl px-6 pb-20">
        <div className="rounded-panel border border-line bg-card p-8 text-center shadow-card sm:p-12">
          <h2 className="text-h2 text-ink">Drive with AC7</h2>
          <p className="mx-auto mt-3 max-w-md text-body leading-relaxed text-ink-muted">
            Keep more of every fare as you move up the ranks, claim booked jobs in advance, and
            earn £200 for every driver you bring with you.
          </p>
          <Link to="/register" className="mt-6 inline-block">
            <Button size="lg" trailingIcon={<ArrowRight size={17} />}>
              Apply to drive
            </Button>
          </Link>
        </div>
      </section>

      <footer className="border-t border-line">
        <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-3 px-6 py-8 text-caption text-ink-subtle sm:flex-row">
          <p>© {new Date().getFullYear()} AC7 Ride · London</p>
          <a href={`tel:${env.controlCentre.tel}`} className="hover:text-ink">
            Control centre {env.controlCentre.display}
          </a>
        </div>
      </footer>
    </div>
  );
}
