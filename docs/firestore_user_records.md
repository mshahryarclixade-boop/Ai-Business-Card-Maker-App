# Firestore: devices/{deviceId}

The app reads and writes this document itself (no Cloud Functions, no login). `deviceId` = the real device id (Android `ANDROID_ID`; iOS Keychain UUID), so a reinstall opens the same document.

```
deviceId, platform, appVersion, createdAt, lastSeenAt, updatedAt
plan: { tier: free|monthly|yearly, isPro, expiresAt, productId }   (a record; Pro itself comes from RevenueCat)
counters.<feature>: { used, windowStart? }
   scan, ai_card, clixa_chat (weekly), career_build, career_optimize, email_signature (created), template, qr, contacts, bg_remover, expert_panel
```
App start: read; missing -> create as free, counters 0. Before a limited action: read (3 s, offline = last known count). After: `FieldValue.increment(1)`. `firestore.rules`: only `devices/{id}`; counters +1 per write; no delete; everything else denied. Enable App Check enforcement for Firestore in the console. Debug log: filter `[DeviceUsage]`.
