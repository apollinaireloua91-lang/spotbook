"use client";

import { useState, useRef, useEffect, useCallback, type CSSProperties } from "react";
import { toPng } from "html-to-image";

/* ─── Canvas & Mockup Constants ─── */
const W = 1290;
const H = 2796;

const MK_W = 1022;
const MK_H = 2082;
const SC_L = (52 / MK_W) * 100;
const SC_T = (46 / MK_H) * 100;
const SC_W = (918 / MK_W) * 100;
const SC_H = (1990 / MK_H) * 100;
const SC_RX = (126 / 918) * 100;
const SC_RY = (126 / 1990) * 100;

/* ─── Spotbook Design Tokens ─── */
const C = {
  bg: "#0D0D14",
  surface: "#1E1E2E",
  surfaceAlt: "#16161F",
  border: "#2A2A3A",
  white: "#FFFFFF",
  grey: "#9090AA",
  greyInactive: "#555555",
  violet: "#6C3EF4",
  violetLight: "#8B63FF",
  rose: "#F43E8F",
  roseLight: "#FF6BAA",
  success: "#22C55E",
  error: "#FF4444",
  warning: "#FFBB33",
};

const SIZES = [
  { label: '6.7"', w: 1290, h: 2796 },
  { label: '6.9"', w: 1320, h: 2868 },
  { label: '6.5"', w: 1284, h: 2778 },
  { label: '6.3"', w: 1206, h: 2622 },
  { label: '6.1"', w: 1125, h: 2436 },
] as const;

/* ─── Image Preload ─── */
const IMAGE_PATHS = ["/mockup.png"];
const imageCache: Record<string, string> = {};

async function preloadAllImages() {
  await Promise.all(
    IMAGE_PATHS.map(async (path) => {
      const resp = await fetch(path);
      const blob = await resp.blob();
      const dataUrl = await new Promise<string>((resolve) => {
        const reader = new FileReader();
        reader.onloadend = () => resolve(reader.result as string);
        reader.readAsDataURL(blob);
      });
      imageCache[path] = dataUrl;
    })
  );
}

function img(path: string): string {
  return imageCache[path] || path;
}

/* ─── Phone Mockup Component ─── */
function Phone({
  children,
  style,
  className = "",
}: {
  children: React.ReactNode;
  style?: CSSProperties;
  className?: string;
}) {
  return (
    <div
      className={`relative ${className}`}
      style={{ aspectRatio: `${MK_W}/${MK_H}`, ...style }}
    >
      <img
        src={img("/mockup.png")}
        alt=""
        style={{ display: "block", width: "100%", height: "100%" }}
        draggable={false}
      />
      <div
        style={{
          position: "absolute",
          zIndex: 10,
          overflow: "hidden",
          left: `${SC_L}%`,
          top: `${SC_T}%`,
          width: `${SC_W}%`,
          height: `${SC_H}%`,
          borderRadius: `${SC_RX}% / ${SC_RY}%`,
        }}
      >
        {children}
      </div>
    </div>
  );
}

/* ─── Caption Component ─── */
function Caption({
  headline,
  subtitle,
  label,
}: {
  headline: React.ReactNode;
  subtitle?: string;
  label?: string;
}) {
  return (
    <div
      style={{
        textAlign: "center",
        padding: `0 ${W * 0.06}px`,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        gap: W * 0.015,
      }}
    >
      {label && (
        <span
          style={{
            fontSize: W * 0.028,
            fontWeight: 600,
            color: C.violet,
            letterSpacing: "0.06em",
            textTransform: "uppercase",
          }}
        >
          {label}
        </span>
      )}
      <h1
        style={{
          fontSize: W * 0.088,
          fontWeight: 800,
          color: C.white,
          lineHeight: 1.0,
          margin: 0,
          maxWidth: "95%",
        }}
      >
        {headline}
      </h1>
      {subtitle && (
        <p
          style={{
            fontSize: W * 0.034,
            fontWeight: 500,
            color: "rgba(255,255,255,0.55)",
            margin: 0,
            lineHeight: 1.4,
          }}
        >
          {subtitle}
        </p>
      )}
    </div>
  );
}

/* ─── Mock UI Helpers ─── */
function MockAvatar({
  size,
  color,
  initials,
}: {
  size: number;
  color: string;
  initials: string;
}) {
  return (
    <div
      style={{
        width: size,
        height: size,
        borderRadius: "50%",
        background: `linear-gradient(135deg, ${color}, ${color}88)`,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        fontSize: size * 0.4,
        fontWeight: 700,
        color: "#fff",
        flexShrink: 0,
      }}
    >
      {initials}
    </div>
  );
}

/* ═══════════════════════════════════════════════
   SLIDE 1 — FEED (HERO SHOT)
   ═══════════════════════════════════════════════ */
function Slide1() {
  return (
    <div
      style={{
        width: W,
        height: H,
        position: "relative",
        overflow: "hidden",
        background: "linear-gradient(180deg, #1a0a3e 0%, #0D0D14 60%)",
        fontFamily: "var(--font-dm-sans), sans-serif",
      }}
    >
      {/* Subtle glow */}
      <div
        style={{
          position: "absolute",
          top: -200,
          left: "50%",
          transform: "translateX(-50%)",
          width: 900,
          height: 900,
          borderRadius: "50%",
          background: `radial-gradient(circle, ${C.violet}30 0%, transparent 70%)`,
        }}
      />

      {/* Logo */}
      <div
        style={{
          position: "absolute",
          top: W * 0.07,
          left: "50%",
          transform: "translateX(-50%)",
          fontSize: 20,
          fontWeight: 700,
          color: C.white,
          letterSpacing: "0.02em",
          zIndex: 20,
          opacity: 0.7,
        }}
      >
        Spotbook
      </div>

      {/* Caption */}
      <div style={{ position: "absolute", top: W * 0.2, width: "100%", zIndex: 20 }}>
        <Caption
          headline={<>Discover talented<br />pros near you</>}
          subtitle="Watch, like & book in one tap"
        />
      </div>

      {/* Phone — centered, lower */}
      <Phone
        style={{
          position: "absolute",
          bottom: 0,
          left: "50%",
          transform: "translateX(-50%) translateY(14%)",
          width: "84%",
          zIndex: 10,
        }}
      >
        {/* Mock Feed Screen */}
        <div
          style={{
            width: "100%",
            height: "100%",
            background: "linear-gradient(180deg, #1a0830 0%, #0D0D14 50%, #0a0518 100%)",
            position: "relative",
            overflow: "hidden",
          }}
        >
          {/* Video background simulation */}
          <div
            style={{
              position: "absolute",
              inset: 0,
              background: `linear-gradient(135deg, #2a1555 0%, #0D0D14 40%, #1a0a30 80%)`,
            }}
          />
          {/* Decorative blur */}
          <div
            style={{
              position: "absolute",
              top: "15%",
              left: "10%",
              width: "60%",
              height: "40%",
              borderRadius: 20,
              background: `linear-gradient(135deg, ${C.violet}40, ${C.rose}20, ${C.violet}15)`,
              filter: "blur(30px)",
            }}
          />

          {/* Top bar */}
          <div
            style={{
              position: "absolute",
              top: 55,
              left: 0,
              right: 0,
              display: "flex",
              justifyContent: "center",
              gap: 24,
              zIndex: 30,
            }}
          >
            <span style={{ color: "rgba(255,255,255,0.5)", fontSize: 15, fontWeight: 600 }}>
              Discover
            </span>
            <span
              style={{
                color: "#fff",
                fontSize: 15,
                fontWeight: 700,
                borderBottom: `2px solid ${C.violet}`,
                paddingBottom: 4,
              }}
            >
              Following
            </span>
          </div>

          {/* Right side icons */}
          <div
            style={{
              position: "absolute",
              right: 16,
              bottom: "22%",
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              gap: 22,
              zIndex: 30,
            }}
          >
            <MockAvatar size={38} color={C.violet} initials="AS" />
            <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}>
              <svg width="26" height="26" viewBox="0 0 24 24" fill={C.rose} stroke="none">
                <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
              </svg>
              <span style={{ fontSize: 12, color: "#fff", fontWeight: 600 }}>2.4k</span>
            </div>
            <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}>
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
              </svg>
              <span style={{ fontSize: 12, color: "#fff", fontWeight: 600 }}>89</span>
            </div>
            <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}>
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"/>
              </svg>
              <span style={{ fontSize: 12, color: "#fff", fontWeight: 600 }}>Save</span>
            </div>
            <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}>
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/>
                <line x1="8.59" y1="13.51" x2="15.42" y2="17.49"/><line x1="15.41" y1="6.51" x2="8.59" y2="10.49"/>
              </svg>
              <span style={{ fontSize: 12, color: "#fff", fontWeight: 600 }}>Share</span>
            </div>
          </div>

          {/* Bottom info */}
          <div style={{ position: "absolute", left: 16, bottom: "12%", zIndex: 30, maxWidth: "70%" }}>
            <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 8 }}>
              <span style={{ fontSize: 16, fontWeight: 700, color: "#fff" }}>@apollo.studio</span>
              <span
                style={{
                  fontSize: 11,
                  fontWeight: 600,
                  color: C.violet,
                  background: `${C.violet}22`,
                  padding: "2px 8px",
                  borderRadius: 6,
                }}
              >
                Barber
              </span>
            </div>
            <p style={{ fontSize: 13, color: "rgba(255,255,255,0.8)", margin: 0, lineHeight: 1.4 }}>
              Fresh fade for the weekend
            </p>
            {/* Music ticker */}
            <div
              style={{
                display: "flex",
                alignItems: "center",
                gap: 6,
                marginTop: 10,
                color: "rgba(255,255,255,0.6)",
                fontSize: 12,
              }}
            >
              <span>{"\u266B"}</span>
              <span>Drake {"\u2014"} Rich Flex</span>
            </div>
          </div>

          {/* Book CTA strip */}
          <div
            style={{
              position: "absolute",
              bottom: 52,
              left: 0,
              right: 0,
              height: 52,
              background: C.violet,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: 8,
              zIndex: 30,
            }}
          >
            <span style={{ fontSize: 15, fontWeight: 700, color: "#fff" }}>Book Now</span>
            <span style={{ fontSize: 13, color: "rgba(255,255,255,0.7)" }}>{"\u2014"} from $45</span>
          </div>

          {/* Bottom nav */}
          <div
            style={{
              position: "absolute",
              bottom: 0,
              left: 0,
              right: 0,
              height: 52,
              background: "rgba(13,13,20,0.97)",
              display: "flex",
              alignItems: "center",
              justifyContent: "space-around",
              zIndex: 30,
              borderTop: `1px solid ${C.border}`,
            }}
          >
            {["Feed", "Search", "Bookings", "Profile"].map((t, i) => (
              <span
                key={t}
                style={{
                  fontSize: 10,
                  fontWeight: i === 0 ? 700 : 500,
                  color: i === 0 ? C.violet : "rgba(255,255,255,0.4)",
                }}
              >
                {t}
              </span>
            ))}
          </div>
        </div>
      </Phone>

      {/* Bottom gradient fade */}
      <div
        style={{
          position: "absolute",
          bottom: 0,
          left: 0,
          right: 0,
          height: 200,
          background: "linear-gradient(0deg, #0D0D14 0%, transparent 100%)",
          zIndex: 15,
        }}
      />
    </div>
  );
}

/* ═══════════════════════════════════════════════
   SLIDE 2 — SEARCH & MAP
   ═══════════════════════════════════════════════ */
function Slide2() {
  const markers = [
    { x: 30, y: 28, label: "$45", active: false },
    { x: 55, y: 35, label: "$60", active: false },
    { x: 42, y: 50, label: "$35", active: false },
    { x: 70, y: 42, label: "$55", active: false },
    { x: 25, y: 60, label: "$40", active: false },
    { x: 60, y: 65, label: "$50", active: false },
    { x: 45, y: 38, label: "$75", active: true },
  ];

  return (
    <div
      style={{
        width: W,
        height: H,
        position: "relative",
        overflow: "hidden",
        background: "linear-gradient(180deg, #0a1a3e 0%, #0D0D14 60%)",
        fontFamily: "var(--font-dm-sans), sans-serif",
      }}
    >
      {/* Glow */}
      <div
        style={{
          position: "absolute",
          top: -100,
          right: -200,
          width: 700,
          height: 700,
          borderRadius: "50%",
          background: `radial-gradient(circle, ${C.violet}20 0%, transparent 70%)`,
        }}
      />

      {/* Caption */}
      <div style={{ position: "absolute", top: W * 0.12, width: "100%", zIndex: 20 }}>
        <Caption
          label="Explore"
          headline={<>Find pros<br />on the map</>}
          subtitle="37 professionals across Montreal"
        />
      </div>

      {/* Phone — offset right */}
      <Phone
        style={{
          position: "absolute",
          bottom: 0,
          right: "-6%",
          transform: "translateY(10%)",
          width: "86%",
          zIndex: 10,
        }}
      >
        {/* Mock Map Screen */}
        <div
          style={{
            width: "100%",
            height: "100%",
            background: "#0e1a2e",
            position: "relative",
            overflow: "hidden",
          }}
        >
          {/* Dark map background */}
          <div
            style={{
              position: "absolute",
              inset: 0,
              background: `
                radial-gradient(circle at 30% 40%, #1a2540 0%, transparent 50%),
                radial-gradient(circle at 70% 60%, #152035 0%, transparent 50%),
                linear-gradient(180deg, #0c1525 0%, #0a1220 100%)
              `,
            }}
          />
          {/* Map grid lines */}
          {[20, 35, 50, 65, 80].map((top) => (
            <div
              key={`h${top}`}
              style={{
                position: "absolute",
                top: `${top}%`,
                left: 0,
                right: 0,
                height: 1,
                background: "rgba(255,255,255,0.04)",
              }}
            />
          ))}
          {[20, 40, 60, 80].map((left) => (
            <div
              key={`v${left}`}
              style={{
                position: "absolute",
                left: `${left}%`,
                top: 0,
                bottom: 0,
                width: 1,
                background: "rgba(255,255,255,0.04)",
              }}
            />
          ))}

          {/* Map markers */}
          {markers.map((m, i) => (
            <div
              key={i}
              style={{
                position: "absolute",
                left: `${m.x}%`,
                top: `${m.y}%`,
                transform: "translate(-50%,-50%)",
                background: m.active ? C.violet : `${C.violet}cc`,
                padding: "6px 10px",
                borderRadius: 20,
                fontSize: 12,
                fontWeight: 700,
                color: "#fff",
                boxShadow: m.active ? `0 0 20px ${C.violet}80` : "0 2px 8px rgba(0,0,0,0.3)",
                zIndex: m.active ? 5 : 1,
                border: m.active ? "2px solid rgba(255,255,255,0.3)" : "none",
              }}
            >
              {m.label}
            </div>
          ))}

          {/* Search bar */}
          <div
            style={{
              position: "absolute",
              top: 54,
              left: 14,
              right: 14,
              height: 44,
              background: "rgba(30,30,46,0.95)",
              borderRadius: 12,
              display: "flex",
              alignItems: "center",
              padding: "0 14px",
              gap: 8,
              border: "1px solid rgba(255,255,255,0.08)",
              zIndex: 20,
            }}
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={C.grey} strokeWidth="2" strokeLinecap="round">
              <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
            </svg>
            <span style={{ fontSize: 13, color: C.grey }}>Search Montreal...</span>
          </div>

          {/* Category pills */}
          <div
            style={{
              position: "absolute",
              top: 108,
              left: 0,
              right: 0,
              display: "flex",
              gap: 8,
              padding: "0 14px",
              zIndex: 20,
            }}
          >
            {[
              { label: "Barber", active: true },
              { label: "Nails", active: false },
              { label: "Coach", active: false },
              { label: "Photo", active: false },
              { label: "Tattoo", active: false },
            ].map((c) => (
              <div
                key={c.label}
                style={{
                  padding: "6px 14px",
                  borderRadius: 20,
                  fontSize: 12,
                  fontWeight: 600,
                  color: c.active ? "#fff" : "rgba(255,255,255,0.6)",
                  background: c.active ? C.violet : "rgba(30,30,46,0.9)",
                  border: c.active ? "none" : "1px solid rgba(255,255,255,0.08)",
                  whiteSpace: "nowrap",
                }}
              >
                {c.label}
              </div>
            ))}
          </div>

          {/* Bottom pro card */}
          <div
            style={{
              position: "absolute",
              bottom: 80,
              left: 14,
              right: 14,
              background: "rgba(30,30,46,0.95)",
              borderRadius: 16,
              padding: 14,
              display: "flex",
              alignItems: "center",
              gap: 12,
              border: "1px solid rgba(255,255,255,0.08)",
              zIndex: 20,
            }}
          >
            <MockAvatar size={48} color={C.violet} initials="AS" />
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14, fontWeight: 700, color: "#fff" }}>Apollo Studio</div>
              <div style={{ fontSize: 12, color: C.grey, marginTop: 2 }}>Barber {"\u2022"} 0.8 km</div>
              <div style={{ display: "flex", alignItems: "center", gap: 4, marginTop: 4 }}>
                <span style={{ fontSize: 12, color: C.warning }}>{"\u2605\u2605\u2605\u2605\u2605"}</span>
                <span style={{ fontSize: 11, color: C.grey }}>4.9 (127)</span>
              </div>
            </div>
            <div
              style={{
                background: C.violet,
                padding: "8px 16px",
                borderRadius: 10,
                fontSize: 13,
                fontWeight: 700,
                color: "#fff",
              }}
            >
              Book
            </div>
          </div>

          {/* Bottom nav */}
          <div
            style={{
              position: "absolute",
              bottom: 0,
              left: 0,
              right: 0,
              height: 55,
              background: "rgba(13,13,20,0.97)",
              display: "flex",
              alignItems: "center",
              justifyContent: "space-around",
              zIndex: 30,
              borderTop: `1px solid ${C.border}`,
            }}
          >
            {["Feed", "Search", "Bookings", "Profile"].map((t, i) => (
              <span
                key={t}
                style={{
                  fontSize: 10,
                  fontWeight: i === 1 ? 700 : 500,
                  color: i === 1 ? C.violet : "rgba(255,255,255,0.4)",
                }}
              >
                {t}
              </span>
            ))}
          </div>
        </div>
      </Phone>

      {/* Floating category decorations — left side */}
      <div
        style={{
          position: "absolute",
          left: W * 0.04,
          top: H * 0.52,
          transform: "rotate(-6deg)",
          background: `${C.violet}18`,
          border: `1px solid ${C.violet}40`,
          padding: "10px 20px",
          borderRadius: 24,
          fontSize: W * 0.026,
          fontWeight: 600,
          color: C.violetLight,
          zIndex: 5,
        }}
      >
        Barber
      </div>
      <div
        style={{
          position: "absolute",
          left: W * 0.02,
          top: H * 0.58,
          transform: "rotate(3deg)",
          background: `${C.rose}15`,
          border: `1px solid ${C.rose}35`,
          padding: "10px 20px",
          borderRadius: 24,
          fontSize: W * 0.026,
          fontWeight: 600,
          color: C.roseLight,
          zIndex: 5,
        }}
      >
        Nails
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════
   SLIDE 3 — BOOK A SERVICE
   ═══════════════════════════════════════════════ */
function Slide3() {
  return (
    <div
      style={{
        width: W,
        height: H,
        position: "relative",
        overflow: "hidden",
        background: "linear-gradient(180deg, #1a0a2e 0%, #0D0D14 60%)",
        fontFamily: "var(--font-dm-sans), sans-serif",
      }}
    >
      {/* Rose glow */}
      <div
        style={{
          position: "absolute",
          top: H * 0.3,
          left: "50%",
          transform: "translateX(-50%)",
          width: 600,
          height: 600,
          borderRadius: "50%",
          background: `radial-gradient(circle, ${C.rose}15 0%, transparent 70%)`,
        }}
      />

      {/* Caption */}
      <div style={{ position: "absolute", top: W * 0.12, width: "100%", zIndex: 20 }}>
        <Caption
          label="Booking"
          headline="Book instantly"
          subtitle="Pick a date, choose a time, confirm"
        />
      </div>

      {/* Phone — centered */}
      <Phone
        style={{
          position: "absolute",
          bottom: 0,
          left: "50%",
          transform: "translateX(-50%) translateY(12%)",
          width: "82%",
          zIndex: 10,
        }}
      >
        {/* Mock Booking Screen */}
        <div
          style={{
            width: "100%",
            height: "100%",
            background: C.bg,
            position: "relative",
            overflow: "hidden",
          }}
        >
          {/* Header */}
          <div
            style={{
              padding: "54px 16px 12px",
              display: "flex",
              alignItems: "center",
              gap: 12,
            }}
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2" strokeLinecap="round">
              <polyline points="15 18 9 12 15 6"/>
            </svg>
            <span style={{ fontSize: 17, fontWeight: 700, color: "#fff" }}>Book a Service</span>
          </div>

          {/* Pro card */}
          <div
            style={{
              margin: "8px 16px",
              background: C.surface,
              borderRadius: 14,
              padding: 14,
              display: "flex",
              alignItems: "center",
              gap: 12,
              border: `1px solid ${C.border}`,
            }}
          >
            <MockAvatar size={44} color={C.violet} initials="AS" />
            <div>
              <div style={{ fontSize: 14, fontWeight: 700, color: "#fff" }}>Apollo Studio</div>
              <div style={{ fontSize: 12, color: C.grey }}>Barber {"\u2022"} Mile End</div>
            </div>
          </div>

          {/* Service selection */}
          <div style={{ padding: "12px 16px 0" }}>
            <div style={{ fontSize: 14, fontWeight: 700, color: "#fff", marginBottom: 10 }}>
              Select Service
            </div>
            {[
              { name: "Classic Haircut", price: "$45", time: "45 min", selected: true },
              { name: "Beard Trim", price: "$25", time: "20 min", selected: false },
              { name: "Haircut + Beard", price: "$65", time: "60 min", selected: false },
            ].map((s) => (
              <div
                key={s.name}
                style={{
                  background: s.selected ? `${C.violet}15` : C.surfaceAlt,
                  borderRadius: 12,
                  padding: "12px 14px",
                  marginBottom: 8,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "space-between",
                  border: s.selected ? `1.5px solid ${C.violet}` : `1px solid ${C.border}`,
                }}
              >
                <div>
                  <div
                    style={{
                      fontSize: 13,
                      fontWeight: 600,
                      color: s.selected ? "#fff" : "rgba(255,255,255,0.8)",
                    }}
                  >
                    {s.name}
                  </div>
                  <div style={{ fontSize: 11, color: C.grey, marginTop: 2 }}>{s.time}</div>
                </div>
                <div style={{ fontSize: 14, fontWeight: 700, color: C.violet }}>{s.price}</div>
              </div>
            ))}
          </div>

          {/* Calendar */}
          <div style={{ padding: "10px 16px 0" }}>
            <div style={{ fontSize: 14, fontWeight: 700, color: "#fff", marginBottom: 10 }}>
              Select Date
            </div>
            <div style={{ display: "flex", gap: 8 }}>
              {[
                { day: "Mon", date: "14", active: false },
                { day: "Tue", date: "15", active: true },
                { day: "Wed", date: "16", active: false },
                { day: "Thu", date: "17", active: false },
                { day: "Fri", date: "18", active: false },
              ].map((d) => (
                <div
                  key={d.date}
                  style={{
                    flex: 1,
                    textAlign: "center",
                    padding: "10px 0",
                    borderRadius: 12,
                    background: d.active ? C.violet : C.surfaceAlt,
                    border: d.active ? "none" : `1px solid ${C.border}`,
                  }}
                >
                  <div
                    style={{
                      fontSize: 10,
                      color: d.active ? "rgba(255,255,255,0.8)" : C.grey,
                      fontWeight: 500,
                    }}
                  >
                    {d.day}
                  </div>
                  <div
                    style={{
                      fontSize: 16,
                      fontWeight: 700,
                      color: d.active ? "#fff" : "rgba(255,255,255,0.7)",
                      marginTop: 2,
                    }}
                  >
                    {d.date}
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Time slots */}
          <div style={{ padding: "14px 16px 0" }}>
            <div style={{ fontSize: 14, fontWeight: 700, color: "#fff", marginBottom: 10 }}>
              Available Times
            </div>
            <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
              {["9:00", "9:45", "10:30", "11:15", "14:00", "14:45", "15:30", "16:15"].map(
                (t, i) => (
                  <div
                    key={t}
                    style={{
                      padding: "8px 0",
                      width: "calc(25% - 6px)",
                      textAlign: "center",
                      borderRadius: 10,
                      fontSize: 12,
                      fontWeight: 600,
                      background: i === 2 ? C.violet : C.surfaceAlt,
                      color: i === 2 ? "#fff" : "rgba(255,255,255,0.7)",
                      border: i === 2 ? "none" : `1px solid ${C.border}`,
                    }}
                  >
                    {t}
                  </div>
                )
              )}
            </div>
          </div>

          {/* CTA */}
          <div style={{ position: "absolute", bottom: 70, left: 16, right: 16 }}>
            <div
              style={{
                background: C.violet,
                borderRadius: 14,
                padding: "16px 0",
                textAlign: "center",
                fontSize: 15,
                fontWeight: 700,
                color: "#fff",
              }}
            >
              Confirm Booking {"\u2014"} $45
            </div>
          </div>
        </div>
      </Phone>
    </div>
  );
}

/* ═══════════════════════════════════════════════
   SLIDE 4 — PRO DASHBOARD
   ═══════════════════════════════════════════════ */
function Slide4() {
  return (
    <div
      style={{
        width: W,
        height: H,
        position: "relative",
        overflow: "hidden",
        background: "linear-gradient(180deg, #0D0D14 0%, #1a1030 100%)",
        fontFamily: "var(--font-dm-sans), sans-serif",
      }}
    >
      {/* Violet glow top right */}
      <div
        style={{
          position: "absolute",
          top: H * 0.35,
          right: -200,
          width: 600,
          height: 600,
          borderRadius: "50%",
          background: `radial-gradient(circle, ${C.violet}18 0%, transparent 70%)`,
        }}
      />

      {/* Caption */}
      <div style={{ position: "absolute", top: W * 0.12, width: "100%", zIndex: 20 }}>
        <Caption
          label="For Pros"
          headline={<>Manage your<br />business</>}
          subtitle="Revenue, bookings & calendar in one place"
        />
      </div>

      {/* Phone — slightly left */}
      <Phone
        style={{
          position: "absolute",
          bottom: 0,
          left: "-4%",
          transform: "translateY(8%)",
          width: "88%",
          zIndex: 10,
        }}
      >
        {/* Mock Dashboard Screen */}
        <div
          style={{
            width: "100%",
            height: "100%",
            background: C.bg,
            position: "relative",
            overflow: "hidden",
          }}
        >
          {/* Header */}
          <div style={{ padding: "54px 16px 0" }}>
            <div style={{ fontSize: 13, color: C.grey }}>Good morning,</div>
            <div style={{ fontSize: 22, fontWeight: 800, color: "#fff", marginTop: 2 }}>
              Apollo
            </div>
          </div>

          {/* Revenue card */}
          <div
            style={{
              margin: "16px 16px 0",
              background: `linear-gradient(135deg, ${C.violet}, ${C.violetLight})`,
              borderRadius: 18,
              padding: 18,
              position: "relative",
              overflow: "hidden",
            }}
          >
            <div
              style={{
                position: "absolute",
                top: -30,
                right: -30,
                width: 100,
                height: 100,
                borderRadius: "50%",
                background: "rgba(255,255,255,0.1)",
              }}
            />
            <div style={{ fontSize: 13, color: "rgba(255,255,255,0.8)", fontWeight: 500 }}>
              This Month
            </div>
            <div style={{ fontSize: 32, fontWeight: 800, color: "#fff", marginTop: 4 }}>
              $1,845
            </div>
            <div
              style={{
                display: "flex",
                alignItems: "center",
                gap: 4,
                marginTop: 6,
                fontSize: 12,
                color: "rgba(255,255,255,0.9)",
              }}
            >
              <span style={{ color: "#4ade80", fontWeight: 700 }}>{"\u2191"} 23%</span>
              <span>vs last month</span>
            </div>
          </div>

          {/* Stats row */}
          <div style={{ display: "flex", gap: 10, margin: "12px 16px 0" }}>
            {[
              { label: "Bookings", value: "28", icon: "\uD83D\uDCC5" },
              { label: "Rating", value: "4.9", icon: "\u2B50" },
              { label: "Clients", value: "156", icon: "\uD83D\uDC65" },
            ].map((s) => (
              <div
                key={s.label}
                style={{
                  flex: 1,
                  background: C.surface,
                  borderRadius: 14,
                  padding: "12px 10px",
                  textAlign: "center",
                  border: `1px solid ${C.border}`,
                }}
              >
                <div style={{ fontSize: 18 }}>{s.icon}</div>
                <div style={{ fontSize: 18, fontWeight: 800, color: "#fff", marginTop: 4 }}>
                  {s.value}
                </div>
                <div style={{ fontSize: 10, color: C.grey, marginTop: 2 }}>{s.label}</div>
              </div>
            ))}
          </div>

          {/* Quick actions */}
          <div style={{ padding: "14px 16px 0" }}>
            <div style={{ fontSize: 14, fontWeight: 700, color: "#fff", marginBottom: 10 }}>
              Quick Actions
            </div>
            <div style={{ display: "flex", flexWrap: "wrap", gap: 10 }}>
              {[
                { label: "Create Event", icon: "\uD83C\uDF89" },
                { label: "Scan Ticket", icon: "\u2B21" },
                { label: "Calendar", icon: "\uD83D\uDCC5" },
                { label: "Services", icon: "\u2702\uFE0F" },
                { label: "Revenue", icon: "\uD83D\uDCC8" },
                { label: "Events", icon: "\uD83C\uDFAB" },
              ].map((a) => (
                <div
                  key={a.label}
                  style={{
                    width: "calc(33.33% - 7px)",
                    background: C.surfaceAlt,
                    borderRadius: 14,
                    padding: "14px 8px",
                    textAlign: "center",
                    border: `1px solid ${C.border}`,
                  }}
                >
                  <div style={{ fontSize: 22 }}>{a.icon}</div>
                  <div style={{ fontSize: 10, color: "rgba(255,255,255,0.7)", marginTop: 6, fontWeight: 500 }}>
                    {a.label}
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Upcoming */}
          <div style={{ padding: "14px 16px 0" }}>
            <div style={{ fontSize: 14, fontWeight: 700, color: "#fff", marginBottom: 10 }}>
              Upcoming
            </div>
            {[
              { name: "Marie L.", time: "10:30 AM", service: "Classic Haircut" },
              { name: "Thomas R.", time: "11:15 AM", service: "Beard Trim" },
            ].map((a) => (
              <div
                key={a.name}
                style={{
                  background: C.surface,
                  borderRadius: 12,
                  padding: "12px 14px",
                  marginBottom: 8,
                  display: "flex",
                  alignItems: "center",
                  gap: 10,
                  border: `1px solid ${C.border}`,
                }}
              >
                <MockAvatar
                  size={36}
                  color={a.name.includes("M") ? C.rose : "#3b82f6"}
                  initials={a.name.slice(0, 2)}
                />
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, fontWeight: 600, color: "#fff" }}>{a.name}</div>
                  <div style={{ fontSize: 11, color: C.grey }}>{a.service}</div>
                </div>
                <div style={{ fontSize: 12, fontWeight: 600, color: C.violet }}>{a.time}</div>
              </div>
            ))}
          </div>
        </div>
      </Phone>

      {/* Floating stats decoration — right side */}
      <div
        style={{
          position: "absolute",
          right: W * 0.04,
          top: H * 0.55,
          background: `${C.surface}ee`,
          borderRadius: 16,
          padding: "14px 20px",
          border: `1px solid ${C.border}`,
          zIndex: 5,
          transform: "rotate(3deg)",
        }}
      >
        <div style={{ fontSize: W * 0.022, color: C.grey, fontWeight: 500 }}>Revenue</div>
        <div style={{ fontSize: W * 0.038, fontWeight: 800, color: "#fff" }}>+23%</div>
        <div style={{ fontSize: W * 0.02, color: C.success, fontWeight: 600 }}>{"\u2191"} trending</div>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════
   SLIDE 5 — PRO PROFILE
   ═══════════════════════════════════════════════ */
function Slide5() {
  return (
    <div
      style={{
        width: W,
        height: H,
        position: "relative",
        overflow: "hidden",
        background: "linear-gradient(180deg, #0D0D14 0%, #0a1a2e 100%)",
        fontFamily: "var(--font-dm-sans), sans-serif",
      }}
    >
      {/* Glow */}
      <div
        style={{
          position: "absolute",
          bottom: H * 0.2,
          left: "50%",
          transform: "translateX(-50%)",
          width: 800,
          height: 800,
          borderRadius: "50%",
          background: `radial-gradient(circle, ${C.violet}12 0%, transparent 60%)`,
        }}
      />

      {/* Caption */}
      <div style={{ position: "absolute", top: W * 0.12, width: "100%", zIndex: 20 }}>
        <Caption
          label="Profile"
          headline={<>Build your<br />online presence</>}
          subtitle="Showcase your work, grow your clients"
        />
      </div>

      {/* Phone — centered */}
      <Phone
        style={{
          position: "absolute",
          bottom: 0,
          left: "50%",
          transform: "translateX(-50%) translateY(14%)",
          width: "84%",
          zIndex: 10,
        }}
      >
        {/* Mock Pro Profile Screen */}
        <div
          style={{
            width: "100%",
            height: "100%",
            background: C.bg,
            position: "relative",
            overflow: "hidden",
          }}
        >
          {/* Cover gradient */}
          <div
            style={{
              height: "18%",
              background: `linear-gradient(135deg, ${C.violet}60, ${C.rose}40, ${C.violet}30)`,
              position: "relative",
            }}
          >
            <div
              style={{
                position: "absolute",
                bottom: -32,
                left: "50%",
                transform: "translateX(-50%)",
                zIndex: 10,
              }}
            >
              <div
                style={{
                  width: 72,
                  height: 72,
                  borderRadius: "50%",
                  background: `linear-gradient(135deg, ${C.violet}, ${C.violetLight})`,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  fontSize: 28,
                  fontWeight: 800,
                  color: "#fff",
                  border: `3px solid ${C.bg}`,
                }}
              >
                A
              </div>
            </div>
          </div>

          {/* Profile info */}
          <div style={{ textAlign: "center", paddingTop: 40 }}>
            <div style={{ fontSize: 18, fontWeight: 800, color: "#fff" }}>Apollo Studio</div>
            <div style={{ fontSize: 12, color: C.grey, marginTop: 2 }}>@apollo.studio</div>
            <div
              style={{
                display: "inline-block",
                marginTop: 6,
                fontSize: 11,
                fontWeight: 600,
                color: C.violet,
                background: `${C.violet}18`,
                padding: "3px 12px",
                borderRadius: 20,
              }}
            >
              Barber
            </div>
          </div>

          {/* Social icons */}
          <div
            style={{
              display: "flex",
              justifyContent: "center",
              gap: 16,
              marginTop: 12,
            }}
          >
            {[
              { label: "IG", color: "#E1306C" },
              { label: "TT", color: "#fff" },
              { label: "SC", color: "#FFFC00" },
              { label: "\uD835\uDD4F", color: "#fff" },
            ].map((s, idx) => (
              <div
                key={idx}
                style={{
                  width: 32,
                  height: 32,
                  borderRadius: "50%",
                  background: C.surfaceAlt,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  fontSize: 12,
                  fontWeight: 700,
                  color: s.color,
                  border: `1px solid ${C.border}`,
                }}
              >
                {s.label}
              </div>
            ))}
          </div>

          {/* Stats */}
          <div
            style={{
              display: "flex",
              justifyContent: "center",
              gap: 30,
              marginTop: 16,
              paddingBottom: 14,
              borderBottom: `1px solid ${C.border}`,
              marginLeft: 16,
              marginRight: 16,
            }}
          >
            {[
              { value: "127", label: "Reviews" },
              { value: "4.9", label: "Rating" },
              { value: "2.4k", label: "Followers" },
            ].map((s) => (
              <div key={s.label} style={{ textAlign: "center" }}>
                <div style={{ fontSize: 16, fontWeight: 800, color: "#fff" }}>{s.value}</div>
                <div style={{ fontSize: 10, color: C.grey }}>{s.label}</div>
              </div>
            ))}
          </div>

          {/* Action buttons */}
          <div style={{ display: "flex", gap: 8, margin: "12px 16px 0" }}>
            <div
              style={{
                flex: 1,
                background: C.violet,
                borderRadius: 12,
                padding: "10px 0",
                textAlign: "center",
                fontSize: 13,
                fontWeight: 700,
                color: "#fff",
              }}
            >
              Book
            </div>
            <div
              style={{
                flex: 1,
                background: C.surface,
                borderRadius: 12,
                padding: "10px 0",
                textAlign: "center",
                fontSize: 13,
                fontWeight: 600,
                color: "#fff",
                border: `1px solid ${C.border}`,
              }}
            >
              Message
            </div>
          </div>

          {/* Video grid */}
          <div style={{ padding: "14px 16px 0" }}>
            <div style={{ fontSize: 13, fontWeight: 700, color: "#fff", marginBottom: 10 }}>
              Work
            </div>
            <div style={{ display: "flex", flexWrap: "wrap", gap: 6 }}>
              {[
                "linear-gradient(135deg, #2a1555, #1a0a30)",
                "linear-gradient(135deg, #1a2555, #0a1530)",
                "linear-gradient(135deg, #2a0a35, #150520)",
                "linear-gradient(135deg, #1a1555, #0a0a30)",
                "linear-gradient(135deg, #2a2055, #1a1530)",
                "linear-gradient(135deg, #251535, #150a20)",
              ].map((bg, i) => (
                <div
                  key={i}
                  style={{
                    width: "calc(33.33% - 4px)",
                    aspectRatio: "3/4",
                    borderRadius: 10,
                    background: bg,
                    position: "relative",
                    overflow: "hidden",
                  }}
                >
                  {/* Play icon */}
                  <div
                    style={{
                      position: "absolute",
                      top: "50%",
                      left: "50%",
                      transform: "translate(-50%,-50%)",
                      width: 24,
                      height: 24,
                      borderRadius: "50%",
                      background: "rgba(255,255,255,0.15)",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                    }}
                  >
                    <span style={{ fontSize: 10, color: "rgba(255,255,255,0.6)", marginLeft: 2 }}>{"\u25B6"}</span>
                  </div>
                  <div
                    style={{
                      position: "absolute",
                      bottom: 6,
                      left: 6,
                      fontSize: 8,
                      color: "rgba(255,255,255,0.5)",
                      display: "flex",
                      alignItems: "center",
                      gap: 3,
                    }}
                  >
                    <span>{"\u25B6"}</span>
                    <span>{`${(i + 1) * 234}`}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Services preview */}
          <div style={{ padding: "14px 16px 0" }}>
            <div style={{ fontSize: 13, fontWeight: 700, color: "#fff", marginBottom: 8 }}>
              Services
            </div>
            <div
              style={{
                background: C.surface,
                borderRadius: 12,
                padding: "10px 14px",
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                border: `1px solid ${C.border}`,
              }}
            >
              <div>
                <div style={{ fontSize: 12, fontWeight: 600, color: "#fff" }}>Classic Haircut</div>
                <div style={{ fontSize: 10, color: C.grey }}>45 min</div>
              </div>
              <div style={{ fontSize: 13, fontWeight: 700, color: C.violet }}>$45</div>
            </div>
          </div>
        </div>
      </Phone>
    </div>
  );
}

/* ═══════════════════════════════════════════════
   SLIDE REGISTRY
   ═══════════════════════════════════════════════ */
const SLIDES = [
  { id: "feed-hero", label: "Feed", component: Slide1 },
  { id: "search-map", label: "Search & Map", component: Slide2 },
  { id: "book-service", label: "Booking", component: Slide3 },
  { id: "pro-dashboard", label: "Dashboard", component: Slide4 },
  { id: "pro-profile", label: "Profile", component: Slide5 },
];

/* ─── Preview Component ─── */
function ScreenshotPreview({
  index,
  slide,
  onExport,
}: {
  index: number;
  slide: (typeof SLIDES)[number];
  onExport: (el: HTMLDivElement, name: string) => void;
}) {
  const previewRef = useRef<HTMLDivElement>(null);
  const fullRef = useRef<HTMLDivElement>(null);
  const [scale, setScale] = useState(0.2);

  useEffect(() => {
    if (!previewRef.current) return;
    const observer = new ResizeObserver((entries) => {
      const { width } = entries[0].contentRect;
      setScale(width / W);
    });
    observer.observe(previewRef.current);
    return () => observer.disconnect();
  }, []);

  const SlideComponent = slide.component;
  const padIndex = String(index + 1).padStart(2, "0");

  return (
    <div style={{ position: "relative" }}>
      {/* Preview card */}
      <div
        ref={previewRef}
        style={{
          width: "100%",
          aspectRatio: `${W}/${H}`,
          overflow: "hidden",
          borderRadius: 12,
          border: "1px solid rgba(255,255,255,0.1)",
          cursor: "pointer",
          position: "relative",
        }}
        onClick={() =>
          fullRef.current && onExport(fullRef.current, `${padIndex}-${slide.id}`)
        }
      >
        <div
          style={{
            transform: `scale(${scale})`,
            transformOrigin: "top left",
            width: W,
            height: H,
          }}
        >
          <SlideComponent />
        </div>

        {/* Hover overlay */}
        <div
          style={{
            position: "absolute",
            inset: 0,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            background: "rgba(0,0,0,0)",
            transition: "background 0.2s",
          }}
          onMouseEnter={(e) => {
            e.currentTarget.style.background = "rgba(0,0,0,0.4)";
            const hint = e.currentTarget.querySelector("span");
            if (hint) (hint as HTMLElement).style.opacity = "1";
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.background = "rgba(0,0,0,0)";
            const hint = e.currentTarget.querySelector("span");
            if (hint) (hint as HTMLElement).style.opacity = "0";
          }}
        >
          <span
            style={{
              color: "#fff",
              fontSize: 14,
              fontWeight: 600,
              opacity: 0,
              transition: "opacity 0.2s",
              pointerEvents: "none",
              background: "rgba(108,62,244,0.8)",
              padding: "8px 16px",
              borderRadius: 8,
            }}
          >
            Click to export
          </span>
        </div>
      </div>

      {/* Label */}
      <p
        style={{
          marginTop: 8,
          textAlign: "center",
          fontSize: 13,
          color: "rgba(255,255,255,0.5)",
          fontWeight: 500,
        }}
      >
        {padIndex}. {slide.label}
      </p>

      {/* Offscreen full-size for individual export */}
      <div
        ref={fullRef}
        style={{
          position: "absolute",
          left: -9999,
          top: 0,
          width: W,
          height: H,
          fontFamily: "var(--font-dm-sans), sans-serif",
        }}
      >
        <SlideComponent />
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════
   MAIN PAGE
   ═══════════════════════════════════════════════ */
export default function ScreenshotsPage() {
  const [ready, setReady] = useState(false);
  const [sizeIdx, setSizeIdx] = useState(0);
  const [exporting, setExporting] = useState<string | null>(null);
  const [exportingAll, setExportingAll] = useState(false);

  useEffect(() => {
    preloadAllImages().then(() => setReady(true));
  }, []);

  const selectedSize = SIZES[sizeIdx];

  const resizeAndDownload = useCallback(
    async (dataUrl: string, name: string) => {
      if (selectedSize.w !== W || selectedSize.h !== H) {
        const imgEl = new Image();
        imgEl.src = dataUrl;
        await new Promise((res) => {
          imgEl.onload = res;
        });
        const canvas = document.createElement("canvas");
        canvas.width = selectedSize.w;
        canvas.height = selectedSize.h;
        const ctx = canvas.getContext("2d")!;
        ctx.drawImage(imgEl, 0, 0, selectedSize.w, selectedSize.h);
        const resized = canvas.toDataURL("image/png");
        downloadPng(resized, `${name}-${selectedSize.w}x${selectedSize.h}.png`);
      } else {
        downloadPng(dataUrl, `${name}-${selectedSize.w}x${selectedSize.h}.png`);
      }
    },
    [selectedSize]
  );

  const captureElement = useCallback(async (el: HTMLDivElement) => {
    el.style.left = "0px";
    el.style.opacity = "1";
    el.style.zIndex = "-1";

    const opts = { width: W, height: H, pixelRatio: 1, cacheBust: true };
    await toPng(el, opts); // warm-up call
    const dataUrl = await toPng(el, opts);

    el.style.left = "-9999px";
    el.style.opacity = "";
    el.style.zIndex = "";

    return dataUrl;
  }, []);

  const exportSlide = useCallback(
    async (el: HTMLDivElement, name: string) => {
      setExporting(name);
      try {
        const dataUrl = await captureElement(el);
        await resizeAndDownload(dataUrl, name);
      } finally {
        setExporting(null);
      }
    },
    [captureElement, resizeAndDownload]
  );

  const exportAll = useCallback(async () => {
    setExportingAll(true);
    const offscreenEls = document.querySelectorAll<HTMLDivElement>(
      "[data-offscreen-slide]"
    );
    for (let i = 0; i < offscreenEls.length; i++) {
      const el = offscreenEls[i];
      const name = `${String(i + 1).padStart(2, "0")}-${SLIDES[i].id}`;
      setExporting(name);

      const dataUrl = await captureElement(el);
      await resizeAndDownload(dataUrl, name);

      if (i < offscreenEls.length - 1) {
        await new Promise((r) => setTimeout(r, 300));
      }
    }
    setExporting(null);
    setExportingAll(false);
  }, [captureElement, resizeAndDownload]);

  if (!ready) {
    return (
      <div
        style={{
          minHeight: "100vh",
          background: "#0a0a0a",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          color: "#fff",
          fontSize: 18,
          fontFamily: "var(--font-dm-sans), sans-serif",
        }}
      >
        Loading images...
      </div>
    );
  }

  return (
    <div style={{ minHeight: "100vh", background: "#0a0a0a", color: "#fff" }}>
      {/* Toolbar */}
      <div
        style={{
          position: "sticky",
          top: 0,
          zIndex: 50,
          background: "rgba(10,10,10,0.95)",
          backdropFilter: "blur(12px)",
          borderBottom: "1px solid rgba(255,255,255,0.08)",
          padding: "12px 24px",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          gap: 16,
          flexWrap: "wrap",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
          <h1 style={{ fontSize: 16, fontWeight: 700, margin: 0 }}>
            Spotbook Screenshots
          </h1>
          <select
            value={sizeIdx}
            onChange={(e) => setSizeIdx(Number(e.target.value))}
            style={{
              background: "#1a1a1a",
              color: "#fff",
              border: "1px solid rgba(255,255,255,0.1)",
              borderRadius: 8,
              padding: "6px 12px",
              fontSize: 13,
              cursor: "pointer",
            }}
          >
            {SIZES.map((s, i) => (
              <option key={i} value={i}>
                {s.label} {"\u2014"} {s.w}{"\u00D7"}{s.h}
              </option>
            ))}
          </select>
        </div>

        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          {exporting && (
            <span style={{ fontSize: 13, color: C.violet }}>
              Exporting {exporting}...
            </span>
          )}
          <button
            onClick={exportAll}
            disabled={exportingAll}
            style={{
              background: C.violet,
              color: "#fff",
              border: "none",
              borderRadius: 10,
              padding: "8px 20px",
              fontSize: 13,
              fontWeight: 700,
              cursor: exportingAll ? "wait" : "pointer",
              opacity: exportingAll ? 0.6 : 1,
            }}
          >
            {exportingAll ? "Exporting..." : "Export All"}
          </button>
        </div>
      </div>

      {/* Grid */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fill, minmax(240px, 1fr))",
          gap: 24,
          padding: 24,
          position: "relative",
        }}
      >
        {SLIDES.map((slide, i) => (
          <ScreenshotPreview
            key={slide.id}
            index={i}
            slide={slide}
            onExport={exportSlide}
          />
        ))}
      </div>

      {/* Offscreen full-size containers for export-all */}
      {SLIDES.map((slide) => {
        const SlideComponent = slide.component;
        return (
          <div
            key={`offscreen-${slide.id}`}
            data-offscreen-slide={slide.id}
            style={{
              position: "absolute",
              left: -9999,
              top: 0,
              width: W,
              height: H,
              fontFamily: "var(--font-dm-sans), sans-serif",
            }}
          >
            <SlideComponent />
          </div>
        );
      })}
    </div>
  );
}

/* ─── Download Helper ─── */
function downloadPng(dataUrl: string, filename: string) {
  const a = document.createElement("a");
  a.href = dataUrl;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
}
