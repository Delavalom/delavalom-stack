---
name: delavalom-distribute
description: Content distribution pipeline — repurpose one piece into platform-specific formats (blog, LinkedIn, X, YouTube, newsletter)
version: 1.0.0
author: Luis Arvelo (Delavalom)
triggers:
  - distribute
  - repurpose
  - cross-post
  - content pipeline
  - platform versions
---

# Content Distribution Skill

## Purpose
Take a single piece of content (article, video transcript, talk, idea) and generate platform-optimized versions for maximum distribution with minimum rework.

## Distribution Matrix

| Platform | Format | Length | Tone | CTA Style |
|----------|--------|--------|------|-----------|
| Blog | Long-form markdown | 1200-2500 words | Technical + accessible | Read more / subscribe |
| LinkedIn | Professional post | 150-300 words | Insight-driven, first-person | Comment / share |
| X (Twitter) | Thread or single | 1 tweet or 5-12 thread | Punchy, opinionated, hooks | Repost / follow |
| YouTube | Script + description | 5-15 min script | Conversational, visual cues | Subscribe / comment |
| Newsletter | Email format | 500-800 words | Personal, curated | Reply / forward |
| Dev.to / Hashnode | Technical article | 1000-2000 words | Tutorial-style, code-heavy | Star repo / follow |

## Workflow

### Step 1: Extract Core Message
From the source content, identify:
- **One-line thesis** — the single most important takeaway
- **3 supporting points** — the evidence/examples that prove the thesis
- **Target audience** — who specifically needs to hear this

### Step 2: Generate Platform Versions
For each target platform, adapt:
- Hook/opening (platform-specific attention pattern)
- Body (length and depth appropriate to platform)
- CTA (aligned with platform engagement patterns)
- Formatting (markdown, plain text, script format)

### Step 3: Optimize Per Platform
- **LinkedIn:** Start with a bold statement or counterintuitive insight. Use line breaks. End with a question.
- **X:** Lead with the most surprising claim. Thread format: hook → context → insight → proof → CTA.
- **YouTube:** Script with timestamps. Include B-roll suggestions. Write both title and description.
- **Newsletter:** Personal angle first, then the insight, then the ask.
- **Blog:** SEO-optimized title, meta description, headers with keywords, internal links.

### Step 4: Schedule Recommendations
- Blog publishes first (canonical URL)
- LinkedIn same day or next morning (peak: Tue-Thu 8-10am)
- X thread same day (peak: weekdays 9am-12pm)
- Newsletter next day or same week
- YouTube within the week (allows production time)

## Anti-Patterns to Avoid
- DO NOT copy-paste the same text to all platforms
- DO NOT use LinkedIn's corporate jargon on X
- DO NOT write X threads that read like blog paragraphs
- DO NOT skip the platform-specific hook — each platform has different scroll patterns
- DO NOT publish without a clear CTA on every piece

## Content Recycling
Every 30-60 days, review top-performing content and:
- Update with new data or examples
- Redistribute to platforms that missed it
- Create derivative content (infographic, video, podcast mention)
- Use last30days-skill to check if the topic is trending again
