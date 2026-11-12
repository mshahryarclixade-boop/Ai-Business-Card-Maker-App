> **Outdated.** The current reference is `docs/remote_config_reference.md` (offers, `cro_offers` and the background-remover limit were removed).

# UPDATE 2026-11-11 (supersedes the proposal below where they differ)

* The app now reads `plan_limits` (falls back to `cro_limits`), `onboarding_config` (falls back to `onboarding_enabled`) and `paywall_config.headlines`.
* No `paywall_offers`, no first-year/discount offer in the new config; `cro_offers` is untouched. No weekly entry and no image key in the new keys. Weekly product/tier stay in code; any active subscriber (weekly included) is Pro.
* `plan_limits`: `ai_card` kept (free 3, lifetime); Pro (trial/monthly/yearly) Clixa chats = 5 per week.
* Existing console conditions are reused (named `Android.` and `iOS.`).
* Backup of the live template before publishing: `docs/remote_config/backups/rc_backup_2026-11-11.json`.

---

# Remote Config rebuild (proposal, nothing deployed)

Live console was read (read-only) on 2026-11-10: project `ai-business-card-e1cde`, **no conditions and no conditional values exist yet**. Nothing was published.

Files in `docs/remote_config/`:
* `<key>.android.json` / `<key>.ios.json`: ready-to-paste value per platform (console: parameter -> add value for condition `Android` / `iOS`).
* `template_proposed.json`: the whole template (live parameters kept as they are + the new ones + the two conditions `device.os == 'android'` / `'ios'`). Deploy only after you review it: `firebase remoteconfig:get` first, then `firebase deploy --only remoteconfig`.

## 1. Every key the app reads today

| Key | Read in | In console | Used? |
|---|---|---|---|
| `android_version_config` / `ios_version_config` | `app_update_service.dart` (via `RemoteConfigService.versionConfigRaw`) | yes | Yes - not touched |
| `onboarding_enabled` | `splash_view.dart` | yes | Yes |
| `paywall_config` | `splash_view.dart` (`enabled`, `show_on_launch`), `paywall_view.dart`, `paywall_view_2.dart`, `paywall_actions.dart`, `career_hub_sheets.dart` | no (in-app default applies) | Yes |
| `cro_limits` | `usage_service.dart`, `free_limits.dart` (show_counters), `scan_card_view.dart` (warning), `template_controller.dart` | yes | Yes |
| `cro_triggers` | `paywall_triggers.dart` | yes | Yes (11 sources) |
| `cro_messages` | `paywall_triggers.dart` (`croText`), watermark, counters | yes (`{}`) | Yes |
| `cro_experiment` | `onboarding_experiment.dart` | yes | Yes |
| `cro_offers` | `offer_service.dart`, `subscription_controller.dart` | yes | Yes |
| `credit_pools` | `user_credits_manager.dart` | yes | Read, but only feeds the credit gate, which is off |
| `credits_enabled` | `credits_gate.dart` | no (default `false`) | Gate is OFF, so it does nothing |
| `credit_costs` | `home_controller`, `ai_card_controller`, `profile_controller`, `career_ai_service` | no (defaults: ai_card 1, rest 0) | Only matters if `credits_enabled` were true |
| `scan_orientation_toggle` | `scan_card_view.dart` | no (default `false`) | Yes (hides Landscape/Portrait switch) |

In `paywall_config`, `show_close_button` and `show_plans_screen` are parsed but **no screen reads them** (dead). `trial.enabled/days`: days only until the store answers.

## 2. Plain-words description of each new/changed parameter

| Parameter | What it does |
|---|---|
| `onboarding_config` | The single onboarding screen: `enabled`, `title`, `subtitle`, `button_text`, `image` (bundled asset path). |
| `plan_limits` | What each plan can do. `-1` = unlimited. `period`: `lifetime` / `weekly` / `none` (static). |
| `paywall_config` | Paywall words only (headline per source, five feature points, Continue, fine print, per-month label). |
| `paywall_offers` | Store product IDs, the one-time first-year offer, the day 2-3 Home bottom-sheet offer, max one offer dialog a day. |
| `cro_experiment` | Onboarding paywall 50/50 test. |
| `cro_triggers` | On/off per paywall source. |
| `cro_messages` | Counter texts and watermark texts. |

Texts: a value equal to the English default is shown translated in the user's language; a changed value is shown as written in every language.

## 3. Answers to the specific questions

* **onboarding_enabled**: merge into `onboarding_config.enabled`. Keep the old key until the new build reads the new one.
* **Weekly plan**: the code defines `business_card_weekly` (both stores) and the `weekly` credit tier, but the paywall does not sell it (only monthly + yearly). It stays in `plan_limits` and `paywall_offers.products` so it is ready.
* **Clixa for other plans (code-derived, not in the CRO plan)**: the code has one rule: Pro (trial, weekly, monthly or yearly) = unlimited chats and unlimited messages per chat; free = 3 chats a week, 3 messages per chat. So trial/weekly/monthly/yearly are `-1`. This is derived from the code, not a number someone chose. `messages_per_chat: 3` for free is a code constant (`ClixaController.freeMessagesPerChat`), shown here so it can be controlled later.
* **AI card limit**: not added to `plan_limits`. But `ai_card_free` (in `cro_limits`, default 3) and the `ai_limit` source **are still reachable in code**: `AiCardGeneratorView` opens from Settings -> My Cards (empty state button) and from editing an AI-generated card; Home's `applyTemplate` falls back to AI when a template has no live version (`home_controller._applyWithAi`). All three call `FreeLimits.ensure(UsageFeature.aiCard)` and `promptAiLimit` (`ai_limit` paywall). If AI generation must be only onboarding, these entry points need a code change. Until then keep `ai_card_free` working: do not retire `cro_limits` yet.
* **Retiring `cro_limits` / `credit_pools`**: both can be retired once the new app build reads `plan_limits` (the app does not read it yet). `credit_pools` can already be deleted with no visible change: the in-app defaults are identical (5/50/50/200/2000) and the credit gate is off. `credits_enabled`, `credit_costs` are also dead while the gate is off.
* **Where the paywall CTA text differs from your brief**: you asked for "Try 3 days free" with a trial. The code (after your later instruction "Keep 'Continue' as the CTA text") always shows **Continue** on the plans paywall; the trial is explained in the fine print "3 days free, then $X/year. Cancel anytime." The string "Try 3 days free" does not exist in the app. I followed the code. The yearly-pitch screen's button label is `Start {days}-Day Free Trial` (only inside `paywall_config.trial`, unchanged, not in this rebuild).
* **Headlines per source** (in `paywall_config.headlines`): all 11 CRO sources plus the other sources the code actually opens: `ai_limit`, `launch`, `subscription_lapsed`, `email_signature`, `logo_bg`, `expert_panel`, `career` (all `career_*` sources). `scan_warning` = "Keep scanning with Pro" (my earlier assumption, not in your screenshots). The "Grow your business with Pro" headline is not connected to any source (no Tools-led trigger exists).
* **`cro_triggers`**: only the 11 sources the code can switch off. `launch`, `subscription_lapsed`, `career_*`, `email_signature`, `logo_bg` are always on; adding them to the JSON would be a switch that does nothing.
* **Offers**: `first_year_offer.product_id` is `""` on purpose (empty = no offer shown, no price invented). Put the discounted product's store id per platform in the matching value. `products.*` are informational: the app still has the three IDs compiled in (`revenue_cat_service.dart`) until it reads this key. Prices (including $19.99) always come from the store.
* **Display switches** (`enabled`, `show_on_launch`) stay top-level in `paywall_config` because the splash screen reads them; they are settings, not content.

## 4. What needs an app change before it takes effect

The current build reads `cro_limits`, `cro_offers`, `onboarding_enabled` and headlines in `cro_messages`. Pasting the new keys is harmless but **does nothing** until the app reads: `plan_limits`, `paywall_offers`, `onboarding_config`, `paywall_config.headlines`/`cta`. Until then, do not delete the old keys (the template keeps them, marked OLD).
