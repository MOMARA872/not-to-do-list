package com.nottodo.not_to_do_list.service

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent

/**
 * Phase-1 stub for the Not-To-Do AccessibilityService.
 *
 * This class exists in Phase 1 only so that the manifest entry points to a
 * real compilable class. The body is intentionally empty.
 *
 * Phase 4 will implement:
 *   - the TYPE_WINDOW_STATE_CHANGED filter
 *   - the 800ms debounce window (per ARCHITECTURE.md)
 *   - the in-memory match against the user's Not-To-Do list
 *   - launching the pause activity for matched packages
 *
 * PLAY-02 contract: this service MUST NEVER call any autonomous-action API on
 * AccessibilityService (see docs/play-declaration.md section 2 for the canonical
 * forbidden-call list). The forbidden API names are deliberately kept out of
 * this file so that the V12/PLAY-02 absence-greps stay exact.
 *
 * RESEARCH section-13 anti-pattern lockdown: this service MUST NEVER access an
 * on-device database from the event thread. Database technology names are kept
 * out of this file so that the no-DB-imports absence-grep stays exact.
 */
class NotToDoAccessibilityService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Phase-1 stub. Phase 4 fills in the filter/debounce/match/launch flow.
    }

    override fun onInterrupt() {
        // Phase-1 stub. No interruptible feedback to cancel.
    }
}
