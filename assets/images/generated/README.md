# Generated Image Assets

This folder stores non-critical bitmap UI assets generated for Petji.

## empty_timeline.png

- Tool path: Codex built-in image generation tool
- Intended model path: OpenAI `gpt-image-2` image generation workflow
- Use: empty-state / onboarding illustration for timeline and pet care record screens
- Prompt:

```text
Use case: ui-mockup
Asset type: mobile app empty-state illustration for a pet care app
Primary request: warm practical illustration of a cat and dog sitting beside a simple timeline card and small health record notebook, no text
Style/medium: polished flat 2D illustration, app-friendly, rounded shapes, warm orange #F97316 and trust blue #2563EB accents, light cream background #FFF7ED
Composition/framing: centered square composition with generous padding, suitable for a Flutter empty state
Lighting/mood: friendly, calm, practical, not childish
Constraints: no words, no letters, no numbers, no logos, no watermark, no emoji style, consistent clean shapes
```

## app_icon_petji.png

- Tool path: Codex built-in image generation tool
- Intended model path: OpenAI `gpt-image-2` image generation workflow
- Use: source artwork for Android launcher icons
- Post-processing: resized to 1024px and Android mipmap densities with transparent rounded corners
- Prompt:

```text
Use case: logo-brand
Asset type: mobile app launcher icon for a Flutter Android app named Petji / 宠物记
Primary request: Create a polished square app icon with rounded-square safe composition, no text, no letters, no watermark.
Reference intent: friendly pet record/calendar app, cat and dog together with a calendar/checklist motif, inspired by warm practical pet tech UI.
Style: modern vector-like 3D sticker illustration, crisp edges, high contrast, premium mobile app icon, simple enough to be recognizable at small size.
Palette: warm orange #F97316 as the main accent, trust blue #2563EB, soft cream highlights, teal/cyan used sparingly for freshness, deep navy outlines.
Composition: a smiling cat and dog face in the foreground, partially overlapping a rounded calendar card with a small checkmark and paw-print detail; centered, balanced, generous padding for launcher mask cropping.
Background: smooth rounded-square background with subtle warm orange-to-blue depth, not a flat single hue, no bokeh or decorative orbs.
Avoid: text, Chinese characters, English letters, numbers, watermark, signature, brand marks, busy tiny details, photorealism, harsh shadows.
```

Iconography inside the Flutter UI still uses Material Icons. Generated images should remain decorative or illustrative so app controls stay consistent and accessible.
