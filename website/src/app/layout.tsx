import type { Metadata } from "next";
import "./globals.css";
import { SITE } from "@/lib/site";

export const metadata: Metadata = {
  metadataBase: new URL(SITE.url),
  title: "Cuprim — AI quota in your Mac menu bar",
  description: SITE.description,
  applicationName: "Cuprim",
  openGraph: {
    title: "Cuprim",
    description: "Menu-bar AI quota for Claude, Codex, Cursor, and Grok. Local only.",
    url: SITE.url,
    siteName: "Cuprim",
    images: [{ url: "/og.png", width: 1200, height: 630, alt: "Cuprim" }],
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Cuprim",
    description: SITE.description,
    images: ["/og.png"],
  },
  icons: {
    icon: [{ url: "/favicon.png", type: "image/png" }],
    apple: [{ url: "/icon-192.png" }],
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="font-sans">{children}</body>
    </html>
  );
}
