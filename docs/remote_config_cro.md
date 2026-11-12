> **Outdated.** The current reference is `docs/remote_config_reference.md` (offers, `cro_offers` and the background-remover limit were removed).

# Remote Config - CRO Part 1

All five parameters are JSON. Every key is optional: a missing / invalid key uses the default below (the plan's Option A), so the app works with none of them published. They were published to project `ai-business-card-e1cde` with exactly these defaults.

| Parameter | Type | Default |
|---|---|---|
| `cro_limits` | JSON | scan_free 5, scan_warning_remaining 1, ai_card_free 3, templates_free 10, bg_remover_free 1, clixa_chats_per_week 3, career_build_lifetime 1, career_optimize_lifetime 1, show_counters true |
| `cro_triggers` | JSON | one `{"enabled": true}` per source: onboarding, scan_warning, scan_limit, ai_limit, pro_template, pro_qr, pro_bg, watermark, clixa_limit, crown, settings |
| `cro_messages` | JSON | `{}` - empty = the translated in-app text. Keys: default_headline, scan_limit_headline, ai_limit_headline, counter_scans/ai/bg/clixa/career_build/career_optimize, watermark_link, watermark_text. A value set here is shown as written (not translated). |
| `cro_experiment` | JSON | `{"onboarding_paywall": {"enabled": true, "paywall_percent": 50}}` (enabled false = everybody sees the onboarding paywall) |
| `cro_offers` | JSON | enabled true, first_year_product_id "" (empty = no offer), returning_enabled true, returning_day_min 2, returning_day_max 3, max_per_day 1 |

## Per-platform values (Android / iOS)

The `cro_*` parameters keep ONE key each. Values can differ by platform: set them as Remote Config **conditional values** in the Firebase console (a condition on the app's platform), not as separate keys per platform. The app just reads the key and gets the value for its platform.

* **Do not overwrite them from this repo.** Conditions live in the console only; the defaults below are the in-app fallbacks and the unconditional default value.
* If you ever deploy a template from the CLI, fetch the live one first (`firebase remoteconfig:get`) and edit that, so the existing conditions and conditional values are kept. Deploying a template built from this file alone would drop them.
* `cro_offers.first_year_product_id` is the **App Store product ID on iOS** and the **Play product ID on Android** (use a platform condition to set each). It must be a product RevenueCat returns for that platform; otherwise no offer shows.

## Setup notes

* Discounted offer: create the discounted yearly subscription (for example $19.99) as a SEPARATE product in App Store Connect and Google Play, add it to RevenueCat, then set `cro_offers.first_year_product_id` to that store product id. While it is empty - or the store does not return it - no offer is shown and no price is invented.
* Existing products are reused: `business_card_weekly`, `business_card_monthly`, `business_card_yearly` (entitlement `premium`). Prices come from the store. The 3-day trial label shows only if the yearly product has a real introductory offer and the user is eligible.
* Switch a paywall source off with `cro_triggers.<source>.enabled = false`; the limit itself still holds.
* Usage counters (scans, AI cards, bg remover, Clixa weekly window, Career lifetime) live on the device.
* Analytics events: paywall_shown / paywall_dismissed (source), plan_selected, trial_eligibility, purchase tapped / purchased / cancelled / failed, restore tapped / restored / failed, usage_consumed, limit_reached, experiment_assigned, offer_displayed / offer_accepted / offer_dismissed. Every event also carries `subscription_status`.

## Part 2 additions

* `scan_orientation_toggle` (boolean, default `false`, set in the app only - not published): `true` brings back the scan screen's Auto / Landscape / Portrait switch. It is hidden by default; Auto-detect is the default mode.
* The plans paywall text still comes from `paywall_config` (not published, so the in-app defaults apply): headline "Create and scan without limits", four highlights, "Try {days} days free" (only for an eligible yearly plan, the length comes from the store), saving label computed from the real prices (64% at $29.99 vs 12 x $6.99).
