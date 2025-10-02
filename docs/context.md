# WildFire Prototype — Context Pack

## What We’re Building
WildFire MVP prototype for Scotland. **Phase-0 goal**: display current wildfire risk on the Home screen.
- Primary data: EFFIS Fire Weather Index (FWI)
- Fallbacks: SEPA (Scotland only) → Cache → Mock
- Focus: proving data feeds + hooks, not emergency-grade reliability yet.

## Scope for Phase-0
- Risk data service + simple Home screen banner
- No notifications, authentication, or advanced map features
- Map overlays and reporting deferred to later phases

## Guardrails (from Constitution)
- No secrets in repo; env/runtime config only
- All data must show **Last updated** timestamp + source label
- Use official wildfire risk color scale only
- A11y: semantic labels + ≥44dp targets
- Clear offline/error/cached states (no silent fails)

## Data Chain (for Phase-0)
1. **EFFIS** — Fire Weather Index via WMS GetFeatureInfo
2. **SEPA** — Scotland fallback if EFFIS fails
3. **Cache** — TTL 6h for resilience
4. **Mock** — clearly tagged as fallback when no data available

## Non-Goals
- Emergency compliance or alert certification
- Push notifications
- Fire polygon rendering
- Multi-user accounts

## References
- Constitution v1.0 (root)
- `docs/DATA-SOURCES.md`
- `scripts/allowed_colors.txt` (palette)
- `lib/theme/risk_palette.dart` (when added)

