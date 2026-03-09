## 2.0.1

### New features
- **Multiple orbiters** – pass any number of `OrbiterConfig` objects; each can have a different color, size, shape, and phase offset
- **Orbiter shapes** – `circle` (default), `square`, `diamond`, `star` via `OrbiterShape` enum
- **Custom orbiter widget** – set `OrbiterConfig.child` to replace the built-in dot with any Flutter widget
- **Orbit track** – optional faint guide circle via `showOrbitTrack`, `orbitTrackColor`, `orbitTrackWidth`
- **Image pulse** – `pulseImage` + `pulseScale` add a subtle breathing animation to the central image
- **Rotation direction** – `clockwise` flag
- **Orbit curve** – `OrbitCurve` enum: `linear`, `easeInOut`, `elastic`, `bounce`
- **Pause/resume** – toggle animation without rebuilding via `paused`
- **Cycle callback** – `onCycleComplete` fires once per full orbit
- **Image decoration** – `imageRadius`, `imageDecoration`, `imagePadding`, `imageFit` for full image control
- **Drop-shadows** – per-orbiter `BoxShadow` list

### Breaking changes from 0.0.1
- `loaderColor` removed → use `OrbiterConfig(color: …)` instead
- `duration` semantics unchanged

## 0.0.1
- Initial release: single rotating dot, `size`, `loaderColor`, `duration`
