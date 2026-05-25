# Privacy Policy — Not To-Do List

**Last updated: 2026-05-24**

---

## What we collect

**Nothing.** Not To-Do List collects zero data about you.

Every piece of information you enter — your not-to-do list entries, streak history,
daily check-ins, pause events, and screen-time summaries — is stored exclusively in a
SQLite database on your device. It never leaves your device. It is never transmitted,
never backed up to a cloud service, and never shared with anyone, including the developer.

---

## What we do not do

- **No telemetry.** The app contains no analytics SDK, no crash-reporting library,
  no event tracking, and no usage metrics pipeline. There is no Crashlytics, no Firebase,
  no Google Analytics, no Amplitude, no Mixpanel, no Segment, no Sentry, and no equivalent.
- **No FCM / remote config / backend.** The app has no backend server. There is no
  Firebase project, no FCM integration, and no remote configuration. Daily reminders are
  scheduled entirely on-device using Android's AlarmManager.
- **No advertising IDs or device identifiers.** The app does not read the Android
  Advertising ID, IMEI, serial number, or any other device or user identifier.
- **No network requests.** The `INTERNET` permission is not declared in the app's
  Android manifest. The app cannot make any network call beyond what the Android OS
  itself initiates at app launch (e.g., license validation by the Play Store).
- **No account or sign-up.** There is no account system. The app works entirely
  without registration, login, or any server-side component.

---

## Local data storage

All app data is stored in a Drift/SQLite database located in your app's private storage
on your Android device. The database holds five tables: your not-to-do list entries,
daily check-ins, streak days, pause events, and daily usage summaries.

You can export a full copy of your data at any time from **Settings → Export data**.
The export produces a ZIP archive containing one CSV file per table plus a JSON envelope,
saved to a location you choose on your device.

---

## Deleting your data

You can delete all app data at any time from **Settings → Reset all data**. This
permanently removes every entry, streak day, check-in, pause event, and usage summary
from the local database, and clears all app preferences (including reminder time and
theme choice). After reset, the app returns to the onboarding screen.

Uninstalling the app also deletes all data from your device.

---

## Permissions

Not To-Do List requests four Android permissions. Each is used only for the feature
it names:

1. **Usage Access (PACKAGE_USAGE_STATS).** Reads per-app foreground time from Android's
   `UsageStatsManager` to power the screen-time dashboard and streak detection. Usage
   data is read, aggregated on-device, and never transmitted anywhere.

2. **Accessibility Service (AccessibilityService API).** Detects when you open an app on
   your Not-To-Do List so the app can show the reflection screen. The service reads only
   `AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED` events; it reads only the
   `event.getPackageName()` field; it never reads on-screen content, never performs
   gestures, never automates UI actions, and never stores or transmits the package name.
   The flag `isAccessibilityTool="false"` is set — this app is not assistive technology.

3. **Battery Optimization Exemption (REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).** Allows the
   AccessibilityService to remain active in the background even when the device enters
   Doze mode, so the pause screen can appear reliably throughout the day.

4. **Post Notifications (POST_NOTIFICATIONS — Android 13+).** Sends the single daily
   reminder notification at the time you choose in Settings. No other notifications are
   sent.

All four permissions are optional in the sense that you can revoke any of them from
Android system Settings at any time. The app degrades gracefully: revoking Usage Access
disables the dashboard; revoking the Accessibility Service disables launch interception
(the rest of the app continues to work); revoking notifications cancels the daily reminder.

---

## Contact

This app is open-source. If you have questions about privacy, please open an issue in
the project repository or contact the developer directly.

---

*Not To-Do List is 100% on-device. zero data is collected, stored off-device,
or shared. This policy applies to all versions of the app.*
