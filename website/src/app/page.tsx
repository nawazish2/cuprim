import { SiteNav } from "@/components/SiteNav";
import { Hero } from "@/components/Hero";
import { FeatureScroll } from "@/components/FeatureScroll";
import { TrustSection } from "@/components/TrustSection";
import { FAQ } from "@/components/FAQ";
import { SiteFooter } from "@/components/SiteFooter";

export default function HomePage() {
  return (
    <>
      <SiteNav />
      <main>
        <Hero />
        <FeatureScroll />
        <TrustSection />
        <FAQ />
      </main>
      <SiteFooter />
    </>
  );
}
