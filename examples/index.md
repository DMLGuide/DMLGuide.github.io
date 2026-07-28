---
layout: default
title: Examples
nav_order: 3
math: true
has_toc: false
has_children: true
description: "A collection of double/debiased machine learning examples."
permalink: /examples
---

# Examples

Here you find a collection of DML illustrations. 

<style>
  /* Belt-and-suspenders: inline the tile styles here so they apply even if
     _sass/custom/custom.scss is not picked up in some build environments
     (e.g. some GitHub Pages configurations). */
  .example-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
    grid-auto-rows: 1fr;
    gap: 1.25rem;
    margin: 2rem 0 1rem;
  }
  .example-tile {
    position: relative;
    display: flex;
    flex-direction: column;
    background: #fff;
    border: 1px solid #e5e5e5;
    border-radius: 8px;
    overflow: hidden;
    text-decoration: none !important;
    color: inherit !important;
    transition: transform 0.18s ease, box-shadow 0.18s ease, border-color 0.18s ease;
    background-image: none !important;
  }
  .example-tile:hover,
  .example-tile:focus-visible {
    transform: translateY(-3px);
    box-shadow: 0 10px 28px rgba(128, 0, 0, 0.14);
    border-color: #800000;
    background-image: none !important;
    outline: none;
  }
  .example-tile-icon {
    flex: 0 0 auto;
    height: 140px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #800000;
    background: linear-gradient(135deg, rgba(128, 0, 0, 0.05) 0%, rgba(128, 0, 0, 0.11) 100%);
    border-bottom: 1px solid rgba(128, 0, 0, 0.08);
  }
  .example-tile-icon svg {
    width: 120px;
    height: 90px;
  }
  .example-tile-body {
    flex: 1 1 auto;
    padding: 0.85rem 1rem 0.9rem;
    display: flex;
    flex-direction: column;
    min-height: 0;
  }
  .example-tile-title {
    font-size: 0.98rem;
    font-weight: 600;
    color: #800000 !important;
    margin: 0 0 0.35rem !important;
    line-height: 1.2;
  }
  .example-tile-blurb {
    flex: 1 1 auto;
    font-size: 0.8rem;
    color: #4a4a4a;
    margin: 0 !important;
    line-height: 1.4;
  }
  .example-tile-footer {
    display: flex;
    flex-direction: column;
    gap: 0.45rem;
    margin-top: 0.6rem;
  }
  .example-tile-tags {
    font-size: 0.66rem;
    color: #767676;
    margin: 0 !important;
    text-transform: uppercase;
    letter-spacing: 0.04em;
    font-weight: 600;
    line-height: 1.3;
    word-spacing: 0.1em;
  }
  .example-tile-langs {
    display: flex;
    flex-wrap: wrap;
    gap: 0.3rem;
  }
  .lang-chip {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    font-size: 0.62rem;
    font-weight: 700;
    padding: 0.15rem 0.45rem;
    border-radius: 3px;
    color: #fff;
    letter-spacing: 0.05em;
    text-transform: uppercase;
    line-height: 1;
  }
  .lang-stata  { background: #1a5276; }
  .lang-r      { background: #1f76d3; }
  .lang-python {
    background: linear-gradient(135deg,
                #3776ab 0%,  #3776ab 50%,
                #ffd43b 50%, #ffd43b 100%);
    color: #1a1a1a;
  }
</style>

<div class="example-grid">

  <a class="example-tile" href="{{ '/examples/401k' | relative_url }}">
    <div class="example-tile-icon">
      <svg viewBox="0 0 80 64" width="100" height="80" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        <line x1="8"  y1="56" x2="78" y2="56" opacity="0.4"/>
        <rect x="12" y="40" width="10" height="16" rx="1"/>
        <rect x="26" y="32" width="10" height="24" rx="1"/>
        <rect x="40" y="22" width="10" height="34" rx="1"/>
        <rect x="54" y="12" width="10" height="44" rx="1"/>
        <text x="72" y="20" font-size="14" font-weight="700" stroke="none" fill="currentColor" text-anchor="middle">$</text>
      </svg>
    </div>
    <div class="example-tile-body">
      <div class="example-tile-title">401(k) Eligibility</div>
      <p class="example-tile-blurb">A toy starter: estimating PLR coefficients, ATEs, and LATEs with DML.</p>
      <div class="example-tile-footer">
        <p class="example-tile-tags">PLR · ATE · LATE</p>
        <div class="example-tile-langs">
          <span class="lang-chip lang-stata"  title="Stata code included">Stata</span>
          <span class="lang-chip lang-r"      title="R code included">R</span>
          <span class="lang-chip lang-python" title="Python code included">Python</span>
        </div>
      </div>
    </div>
  </a>

  <a class="example-tile" href="{{ '/examples/AngristEvans' | relative_url }}">
    <div class="example-tile-icon">
      <svg viewBox="0 0 80 64" width="100" height="80" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        <circle cx="10" cy="32" r="9"/>
        <circle cx="40" cy="32" r="9"/>
        <circle cx="70" cy="32" r="9"/>
        <line x1="20" y1="32" x2="30" y2="32"/>
        <path d="M 30 32 L 26 28 M 30 32 L 26 36"/>
        <line x1="50" y1="32" x2="60" y2="32"/>
        <path d="M 60 32 L 56 28 M 60 32 L 56 36"/>
        <text x="10" y="36" font-size="11" font-weight="600" stroke="none" fill="currentColor" text-anchor="middle">Z</text>
        <text x="40" y="36" font-size="11" font-weight="600" stroke="none" fill="currentColor" text-anchor="middle">D</text>
        <text x="70" y="36" font-size="11" font-weight="600" stroke="none" fill="currentColor" text-anchor="middle">Y</text>
      </svg>
    </div>
    <div class="example-tile-body">
      <div class="example-tile-title">Angrist &amp; Evans IV</div>
      <p class="example-tile-blurb">Revisiting the <em>Machine Labor</em> critique: DML lands essentially on 2SLS where naive ML fails.</p>
      <div class="example-tile-footer">
        <p class="example-tile-tags">IV · PLIV</p>
        <div class="example-tile-langs">
          <span class="lang-chip lang-r" title="R code included">R</span>
        </div>
      </div>
    </div>
  </a>


  <a class="example-tile" href="{{ '/examples/GN' | relative_url }}">
    <div class="example-tile-icon">
      <svg viewBox="0 0 80 64" width="100" height="80" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        <path d="M 6 40 Q 16 28 26 40 T 46 40 T 66 40 T 86 40" opacity="0.35"/>
        <circle cx="16" cy="14" r="4" fill="currentColor"/>
        <circle cx="32" cy="22" r="4" fill="currentColor"/>
        <circle cx="48" cy="34" r="4" fill="currentColor"/>
        <circle cx="62" cy="48" r="4" fill="currentColor"/>
        <line x1="19" y1="16" x2="29" y2="20"/>
        <line x1="35" y1="24" x2="45" y2="32"/>
        <line x1="51" y1="36" x2="59" y2="46"/>
      </svg>
    </div>
    <div class="example-tile-body">
      <div class="example-tile-title">Cultural Persistence</div>
      <p class="example-tile-blurb">PLM in a small cross-section: climate volatility and tradition (Giuliano &amp; Nunn).</p>
      <div class="example-tile-footer">
        <p class="example-tile-tags">PLM · small N</p>
        <div class="example-tile-langs">
          <span class="lang-chip lang-stata"  title="Stata code included">Stata</span>
          <span class="lang-chip lang-r"      title="R code included">R</span>
          <span class="lang-chip lang-python" title="Python code included">Python</span>
        </div>
      </div>
    </div>
  </a>

  <a class="example-tile" href="{{ '/examples/HRS' | relative_url }}">
    <div class="example-tile-icon">
      <svg viewBox="0 0 80 64" width="100" height="80" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        <line x1="8"  y1="56" x2="74" y2="56" opacity="0.4"/>
        <line x1="8"  y1="56" x2="8"  y2="8"  opacity="0.4"/>
        <line x1="42" y1="10" x2="42" y2="56" stroke-dasharray="3,3" opacity="0.45"/>
        <path d="M 12 46 L 42 42 L 72 38"/>
        <path d="M 12 36 L 42 32 L 42 18 L 72 12" stroke-width="2.5"/>
      </svg>
    </div>
    <div class="example-tile-body">
      <div class="example-tile-title">Hospitalization Effects</div>
      <p class="example-tile-blurb">DML for difference-in-differences under conditional parallel trends.</p>
      <div class="example-tile-footer">
        <p class="example-tile-tags">DiD · panel</p>
        <div class="example-tile-langs">
          <span class="lang-chip lang-r" title="R code included">R</span>
        </div>
      </div>
    </div>
  </a>

  <a class="example-tile" href="{{ '/examples/Monopsony_DML' | relative_url }}">
    <div class="example-tile-icon">
      <svg viewBox="0 0 80 64" width="100" height="80" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        <rect x="6" y="8" width="68" height="48" rx="3"/>
        <line x1="6" y1="20" x2="74" y2="20"/>
        <circle cx="11" cy="14" r="1.4" fill="currentColor" stroke="none"/>
        <circle cx="16" cy="14" r="1.4" fill="currentColor" stroke="none"/>
        <circle cx="21" cy="14" r="1.4" fill="currentColor" stroke="none"/>
        <line x1="12" y1="30" x2="50" y2="30" stroke-width="2"/>
        <line x1="12" y1="38" x2="58" y2="38" stroke-width="1.4" opacity="0.55"/>
        <line x1="12" y1="44" x2="50" y2="44" stroke-width="1.4" opacity="0.55"/>
        <text x="68" y="53" font-size="8" font-weight="700" stroke="none" fill="currentColor" text-anchor="end">$10</text>
      </svg>
    </div>
    <div class="example-tile-body">
      <div class="example-tile-title">Monopsony on MTurk</div>
      <p class="example-tile-blurb">Estimating the labor supply elasticity with fine-tuned DeBERTa embeddings.</p>
      <div class="example-tile-footer">
        <p class="example-tile-tags">Text · embeddings · 3 parts</p>
        <div class="example-tile-langs">
          <span class="lang-chip lang-r"      title="R code included">R</span>
          <span class="lang-chip lang-python" title="Python code included">Python</span>
        </div>
      </div>
    </div>
  </a>


</div>
