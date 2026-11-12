# Remote Config reference (final, proposed - not yet published)

Project `ai-business-card-e1cde`. Live template today: **version 20** (2026-11-10). The JSON below is the **proposed final state** (`docs/remote_config/template_proposed.json`; per-key paste files `docs/remote_config/<key>.android.json` / `.ios.json`). Backup of the live template: `docs/remote_config/backups/rc_backup_2026-11-11.json`. Nothing has been published.

Conditions (already in the console, reused): `Android.` = `device.os == 'android'`, `iOS.` = `device.os == 'ios'`. Every new/changed JSON key carries an Android and an iOS value (identical today). Every key has a description.

The app reads Remote Config in `lib/app/core/services/remote_config_service.dart` (8 s fetch at start; every key has an in-app default, so a missing/empty/malformed value never breaks the app). "Released build" = the version in the stores; "new build" = this repo.

## 1. Summary of the changes

| Key | Change |
|---|---|
| `cro_messages` | **Modified**: `counter_bg` removed (background remover is free, no limit). |
| `cro_offers` | **Removed** (key deleted). All offer code removed from the app (see section 8). |
| `onboarding_config` | **Modified**: no `image` (the picture is bundled in the app; it never was read). |
| `paywall_offers` | **Modified**: only `products` (yearly, monthly) and `trial` are left; `first_year_offer`, `returning_offer`, `max_dialogs_per_day`, `weekly` removed. **Now actually read by the app.** |
| `plan_limits` | **Modified**: `templates` and `background_remover` removed from every plan; Pro Clixa chats = **5 per week** on `trial`, `monthly`, `yearly`. |
| `paywall_config` | Modified: no `trial.enabled/days` (now in `paywall_offers.trial`), no `pro_bg` headline. |
| `cro_triggers` | Modified: `pro_bg` removed (the trigger no longer exists). |
| `cro_limits`, `onboarding_enabled` | Kept (restored in the template) for the released build only. |
| `credit_pools` | Stays deleted. |
| `android_version_config`, `ios_version_config`, `cro_experiment` | Unchanged. |

## 2. Keys at a glance

| Key | Read by | Status |
|---|---|---|
| `android_version_config` / `ios_version_config` | `app_update_service.dart` | Used (not touched) |
| `plan_limits` | `RemoteConfigService.croLimits` -> `UsageService`, `FreeLimits`, scan screen, Clixa | Used (new build) |
| `cro_limits` | same getter, fallback | Deprecated, kept for the released build |
| `cro_triggers` | `PaywallTriggers.enabled` | Used |
| `cro_messages` | `croText()`, counters, watermark | Used |
| `cro_experiment` | `onboarding_experiment.dart` | Used |
| `paywall_config` | splash, both paywall screens, `paywall_actions.dart`, `career_hub_sheets.dart`, headlines | Used |
| `paywall_offers` | `RevenueCatHelper` (product ids), `PaywallConfig` (trial) | Used (new build) |
| `onboarding_config` | onboarding screen, splash | Used (new build) |
| `onboarding_enabled` | splash (released build) + fallback | Deprecated, kept for the released build |
| `scan_orientation_toggle` | `scan_card_view.dart` | Used, never in console (default `false`) |
| `credits_enabled`, `credit_costs`, `credit_pools` | `credits_gate.dart`, `user_credits_manager.dart`, 4 controllers | Dead system (gate off); `credit_pools` deleted |

## 3. Limits

### `plan_limits`
```json
{
  "show_counters": true,
  "plans": {
    "free": {
      "card_scans": {
        "limit": 5,
        "period": "lifetime",
        "warn_at_remaining": 1
      },
      "ai_card": {
        "limit": 3,
        "period": "lifetime"
      },
      "qr_styles": {
        "allowed": [
          "classic"
        ]
      },
      "clixa_chats": {
        "limit": 3,
        "period": "weekly",
        "messages_per_chat": 3
      },
      "career_build": {
        "limit": 1,
        "period": "lifetime"
      },
      "career_optimize": {
        "limit": 1,
        "period": "lifetime"
      },
      "contacts": {
        "limit": -1
      },
      "export_watermark": true
    },
    "trial": {
      "card_scans": {
        "limit": -1
      },
      "ai_card": {
        "limit": -1
      },
      "qr_styles": {
        "allowed": "all"
      },
      "clixa_chats": {
        "limit": 5,
        "period": "weekly",
        "messages_per_chat": -1
      },
      "career_build": {
        "limit": -1
      },
      "career_optimize": {
        "limit": -1
      },
      "contacts": {
        "limit": -1
      },
      "export_watermark": false
    },
    "monthly": {
      "card_scans": {
        "limit": -1
      },
      "ai_card": {
        "limit": -1
      },
      "qr_styles": {
        "allowed": "all"
      },
      "clixa_chats": {
        "limit": 5,
        "period": "weekly",
        "messages_per_chat": -1
      },
      "career_build": {
        "limit": -1
      },
      "career_optimize": {
        "limit": -1
      },
      "contacts": {
        "limit": -1
      },
      "export_watermark": false
    },
    "yearly": {
      "card_scans": {
        "limit": -1
      },
      "ai_card": {
        "limit": -1
      },
      "qr_styles": {
        "allowed": "all"
      },
      "clixa_chats": {
        "limit": 5,
        "period": "weekly",
        "messages_per_chat": -1
      },
      "career_build": {
        "limit": -1
      },
      "career_optimize": {
        "limit": -1
      },
      "contacts": {
        "limit": -1
      },
      "export_watermark": false
    }
  }
}
```

Read by `CroLimits.fromPlanLimitsString`; wins over `cro_limits`.

| Field | Meaning / used by |
|---|---|
| `show_counters` | "3 of 5 scans used" lines on/off. |
| `plans.free.card_scans.limit` | Free scans in total (5). Scan screen. |
| `plans.free.card_scans.warn_at_remaining` | Scans left when the "1 free scan left" dialog + `scan_warning` paywall shows. |
| `plans.free.ai_card.limit` | Free AI cards (3, lifetime). Kept on purpose: Home template fallback, AI card generator, My Cards entry. |
| `plans.free.clixa_chats.limit` | Free Clixa chats per rolling week (3). |
| `plans.free.clixa_chats.messages_per_chat` | Documentation only (3 is fixed in code). |
| `plans.free.career_build / career_optimize` | Career Studio free uses (1 each, lifetime). |
| `plans.<trial|monthly|yearly>.clixa_chats.limit` | **Pro Clixa chats per week: 5** (`-1` would be unlimited). Paid tiers are read together (the highest value wins); a weekly subscriber has no tier entry and gets the same 5. Pro users are counted only for Clixa; every other feature stays unlimited for Pro. |
| `period`, `qr_styles`, `contacts`, `export_watermark`, `-1` entries for other features | Documentation only: Classic-only QR, free contacts, the watermark and "Pro = unlimited" are driven by Pro status in code. |

**Removed on purpose:**
* `templates`: free vs Pro templates are fixed in the app (`CroLimits.freeTemplates = 10`, the first 10, half per orientation; the rest show the Pro crown and open `pro_template`). No Remote Config value.
* `background_remover`: free for everyone, no limit. The usage counter, the paywall gate (`pro_bg`) and the `counter_bg` text were removed from the app.

### `cro_limits` (legacy, released build only)
Flat form of the same numbers (`scan_free`, `scan_warning_remaining`, `ai_card_free`, `templates_free`, `bg_remover_free`, `clixa_chats_per_week`, `career_build_lifetime`, `career_optimize_lifetime`, `show_counters`). The new build uses it only when `plan_limits` is empty and ignores `templates_free` / `bg_remover_free`. Delete it after the new build is out.

## 4. Paywall

### `paywall_offers`
```json
{
  "products": {
    "yearly": "business_card_yearly",
    "monthly": "business_card_monthly"
  },
  "trial": {
    "enabled": true,
    "days": 3
  }
}
```

| Field | Meaning |
|---|---|
| `products.yearly` / `products.monthly` | Store product ids of the two plans sold (`business_card_yearly` $29.99, `business_card_monthly` $6.99). `RevenueCatHelper` uses them; if a field is missing it falls back to the built-in id. Use the platform conditions if the ids ever differ. Prices always come from the store. |
| `trial.enabled` | Free-trial wording on/off (a trial is also shown only when the store offers it to this user). |
| `trial.days` | Trial length shown until the store reports the real one. |

There is no weekly entry (the paywall sells yearly and monthly only). The weekly product id and tier stay in the code, so existing weekly subscribers still get Pro.

### `paywall_config`
```json
{
  "enabled": true,
  "show_on_launch": true,
  "trial": {
    "button_label": "Start {days}-Day Free Trial",
    "no_trial_button_label": "Continue",
    "benefit_text": "{days} days completely free, no charge today",
    "info_line_1": "No payment today, {yearly_price}/year after trial",
    "info_line_2": "Cancel anytime before trial ends",
    "fine_print": "{days} days free, then {yearly_price}/year. Cancel anytime."
  },
  "screen1": {
    "title_line1": "Start creating",
    "title_line2": "for free",
    "subtitle": "Unlock everything with Pro",
    "features": [
      {
        "icon": "scan",
        "text": "Unlimited card scans"
      },
      {
        "icon": "ai",
        "text": "Design with AI, no limits"
      },
      {
        "icon": "watermark",
        "text": "No watermark on exports"
      },
      {
        "icon": "templates",
        "text": "All templates and QR styles"
      },
      {
        "icon": "coach",
        "text": "AI Business Coach"
      }
    ],
    "plan_title": "Yearly Pro"
  },
  "screen2": {
    "title": "Create and scan without limits",
    "subtitle": "Get unlimited access to every feature",
    "features": [
      "Unlimited card scans",
      "Design with AI, no limits",
      "No watermark on exports",
      "All templates and QR styles",
      "AI Business Coach"
    ],
    "button_label": "Continue",
    "trial_button_label": "Start Free Trial",
    "commitment_text": "No commitment, cancel anytime"
  },
  "headlines": {
    "default": "Create and scan without limits",
    "onboarding": "Create and scan without limits",
    "scan_warning": "Keep scanning with Pro",
    "scan_limit": "Keep scanning with Pro",
    "ai_limit": "Keep creating with AI",
    "pro_template": "Unlock every template",
    "pro_qr": "Unlock every QR style",
    "watermark": "Export without the watermark",
    "clixa_limit": "Keep talking to your AI coach",
    "crown": "Create and scan without limits",
    "settings": "Create and scan without limits",
    "career": "Get found by the right people"
  },
  "plans": {
    "monthly": {
      "visible": true,
      "title": "Monthly",
      "period": "/month",
      "description": "Full access to all Pro features"
    },
    "yearly": {
      "visible": true,
      "title": "Yearly",
      "badge": "Most Popular",
      "period": "/year",
      "per_month_note": "{price}/month, billed yearly"
    }
  },
  "footer": {
    "restore": "Restore Purchase",
    "terms": "Terms of Use",
    "privacy": "Privacy Policy"
  }
}
```

| Field | Meaning |
|---|---|
| `enabled`, `show_on_launch` | Paywall on/off; show at app start (splash). |
| `trial.button_label`, `no_trial_button_label`, `benefit_text`, `info_line_1`, `info_line_2` | Yearly-pitch screen texts. |
| `trial.fine_print` | Under the plans button: "{days} days free, then {yearly_price}/year. Cancel anytime." |
| `screen1.*` | Yearly-pitch screen (titles, `features[]` with icon+text, plan title). |
| `screen2.title` / `subtitle` / `features[]` | Plans screen headline, subtitle, the five feature points. |
| `screen2.button_label` | Button when monthly is selected (the default): "Continue". |
| `screen2.trial_button_label` | Button whenever the yearly plan is selected: "Start Free Trial" (monthly is selected by default). |
| `screen2.commitment_text` | Fine print without a trial. |
| `headlines.<source>` | Headline per paywall source. A text equal to the English default is shown translated; a changed text is shown as written. |
| `plans.monthly.*`, `plans.yearly.*` | Titles, period, description, "Most Popular" badge, `per_month_note` ("{price}/month, billed yearly"). Prices and the saving % are computed from the store. |
| `footer.*` | Restore / Terms / Privacy labels. |

`show_close_button` and `show_plans_screen` are parsed but read by no screen (not in the proposed value).

### `cro_triggers`
```json
{
  "onboarding": {
    "enabled": true
  },
  "scan_warning": {
    "enabled": true
  },
  "scan_limit": {
    "enabled": true
  },
  "ai_limit": {
    "enabled": true
  },
  "pro_template": {
    "enabled": true
  },
  "pro_qr": {
    "enabled": true
  },
  "watermark": {
    "enabled": true
  },
  "clixa_limit": {
    "enabled": true
  },
  "crown": {
    "enabled": true
  },
  "settings": {
    "enabled": true
  }
}
```

`{"enabled": false}` hides that paywall (the limit still holds). Sources: `onboarding` (first card ready, A/B test), `scan_warning`, `scan_limit`, `ai_limit`, `pro_template`, `pro_qr`, `watermark`, `clixa_limit`, `crown` (every crown/Pro button), `settings`. Always on, not switchable: `launch`, `subscription_lapsed`, `career_*`, `email_signature`, `logo_bg`.

### `cro_messages`
```json
{
  "counter_scans": "{used} of {limit} scans used",
  "counter_ai": "{used} of {limit} AI cards used",
  "counter_clixa": "{used} of {limit} chats this week",
  "counter_career_build": "{used} of {limit} profile build used",
  "counter_career_optimize": "{used} of {limit} profile optimize used",
  "watermark_link": "Remove watermark",
  "watermark_text": "Made with AI Business Card Maker"
}
```

Counter lines (`{used}`/`{limit}` are filled in), `watermark_link`, `watermark_text`. Empty = translated built-in text; a changed text is shown as written (not translated).

### `cro_experiment`
```json
{
  "onboarding_paywall": {
    "enabled": true,
    "paywall_percent": 50
  }
}
```

`onboarding_paywall.enabled` (false = everyone sees the onboarding paywall), `paywall_percent` (share who see it).

## 5. Onboarding

### `onboarding_config`
```json
{
  "enabled": true,
  "title": "Create Stunning\nCards in Seconds.",
  "subtitle": "",
  "button_text": "Create my Profile"
}
```

`enabled` (wins over `onboarding_enabled`), `title`, `subtitle` (empty = not shown), `button_text`. The picture is bundled in the app and is not controlled by Remote Config.

## 6. Update check
`android_version_config` / `ios_version_config`: `min_build_number` (below = forced update), `min_version_label`, `latest_version_label`. Untouched.

## 7. Not in the console
`scan_orientation_toggle` (bool, `false`): brings back the scan screen's Auto/Landscape/Portrait switch. `credits_enabled` (`false`), `credit_costs`, `credit_pools`: the old credit gate (AI card, exports), off and replaced by the plan limits; can be removed in a later cleanup.

## 8. Offer code removed from the app (nothing else depended on it)
* Deleted `OfferService` and the offer bottom sheet; removed the first-year offer on the paywall close button (`PaywallActions.close` now just leaves), the returning-user sheet on Home, the discounted product fetch (`getProducts(extraIds)`), `croOffers`/`CroOffers`/`cro_offers`, the `offer_displayed/accepted/dismissed` analytics and the `cro_offer_*` strings (all 71 languages), and the offer tests.
* Kept: normal purchase, restore, trial detection from the store, the trial/welcome/restored dialogs, `paywall_*` analytics.

## 9. Unused / deprecated / redundant after this change
* Deprecated until the new build is out: `cro_limits`, `onboarding_enabled`.
* Dead system: `credits_enabled`, `credit_costs`, `credit_pools`.
* Not read: `plan_limits` documentation-only fields (above), `cro_messages.tools_headline` (no Tools-led trigger).
* AI card generation is still reachable outside onboarding (Settings -> My Cards, editing an AI card, Home template fallback), so `plan_limits.free.ai_card` and `ai_limit` stay live (as you decided).

## 10. Languages and Remote Config text

A Remote Config text can be written in two ways:

* **Plain string** (`"title": "Monthly"`): shown **exactly as written, in every language**. The only exception: a string equal to the app's built-in English text (e.g. `Monthly`) is shown in the user's language from the app's own translations (71 languages).
* **Map of texts per language** (`"title": {"default": "MONTHLYYY", "fr": "MENSUEL", "ar": "شهري"}`): the app shows the entry for the current language tag (`pt-BR`/`zh-TW` style tags first, then the language code such as `fr`), then `default`, then `en`. A full example with all 71 languages: `docs/remote_config/examples/monthly_title_all_languages.json`.

There is **no automatic translation** of arbitrary text: to change a text in every language you supply the translations in the map. A plain changed string will stay in that one language.

Supported everywhere text is Remote Config-controlled: `paywall_config` (titles, subtitles, buttons, fine print, plan titles/badges/descriptions, footer labels, feature lists, `headlines.*`), `cro_messages` (counters, watermark texts, headline overrides) and `onboarding_config` (`title`, `subtitle`, `button_text`). The map form needs the new app build (the released build reads strings only).

The language is resolved each time a text is shown, so a change of the in-app language **or** of the phone's language (while "System default" is selected) switches the Remote Config texts too, without restarting the app.

**Missing language:** if a map has no entry for the current language, `default` is used, then `en`; if none of those exist, the app's own built-in (translated) text for that field is shown, never a blank or a raw key. Lists (`features`) fall back to the built-in item at the same position.

**Audit (all Remote Config text):** `paywall_config` (every text field of trial, screen1, screen2, plans, footer, both feature lists and all `headlines.*`), `cro_messages` (every key: headlines, counters, watermark texts, link), `onboarding_config` (`title`, `subtitle`, `button_text`). The version configs only carry version numbers. A headline shown on an open paywall also follows a language change.
