package com.nottodo.not_to_do_list

import io.flutter.embedding.android.FlutterActivity

/**
 * Phase-1 stub for the Pause / reflection screen activity.
 *
 * This class exists in Phase 1 only so that the manifest entry
 * (`<activity android:name=".PauseActivity">`) points to a real compilable class.
 * The body is intentionally empty.
 *
 * Phase 4 will implement:
 *   - setShowWhenLocked(true) and setTurnScreenOn(true) (PAUS-08)
 *   - reading the blocked-package Intent extra
 *   - routing the Flutter engine to the /pause route with the package name
 *   - cooldown-timer state handoff between the AccessibilityService and Flutter
 */
class PauseActivity : FlutterActivity()
