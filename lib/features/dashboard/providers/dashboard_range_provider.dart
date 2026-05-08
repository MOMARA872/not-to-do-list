import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:not_to_do_list/domain/dashboard/dashboard_range.dart';

/// Session-only D/W/M selection for the dashboard (CONTEXT.md D-05).
/// Default = Day on cold start. NO `shared_preferences` write — open-on-Day
/// each cold start matches user expectation.
///
/// Hand-written `StateProvider` (from flutter_riverpod/legacy.dart — the
/// legacy StateProvider is still the idiomatic simple-value holder in
/// Riverpod 3.x for session-only state that doesn't need full Notifier
/// boilerplate). Mirrors no Phase 1+2 analog.
final StateProvider<DashboardRange> dashboardRangeProvider =
    StateProvider<DashboardRange>((_) => DashboardRange.day);
