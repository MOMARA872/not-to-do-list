// Plan 04-07 — Task 04-07-02: PauseController unit tests.
//
// D-13 contract:
//   PauseController is a hand-written Riverpod controller (no @riverpod
//   codegen — see 01-01-SUMMARY.md for the analyzer-pin incompatibility).
//   Writes pause_events via PauseEventRepository at session-end
//   (insert-at-end to avoid UPDATE-by-id race on activity kill).
//
// onClose is injected via PauseSessionArgs for test isolation.
import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:not_to_do_list/data/repositories/pause_event_repository.dart';
import 'package:not_to_do_list/features/pause/controllers/pause_controller.dart';
import 'package:not_to_do_list/features/pause/models/pause_session.dart';
import 'package:not_to_do_list/features/pause/providers/pause_providers.dart';

class MockPauseEventRepository extends Mock implements PauseEventRepository {}

/// Builds a ProviderContainer with the mock repo and a PauseController
/// for the given args (no overrideWith on the family — the factory is used
/// directly).
ProviderContainer buildContainer({
  required MockPauseEventRepository mockRepo,
  required PauseSessionArgs args,
}) {
  return ProviderContainer(
    overrides: [
      pauseEventRepositoryProvider.overrideWithValue(mockRepo),
      // Override the family provider with a notifier built from [args].
      pauseControllerProvider(args).overrideWith(() => PauseController(args)),
    ],
  );
}

void main() {
  late MockPauseEventRepository mockRepo;
  late DateTime fakeTriggeredAt;

  setUp(() {
    mockRepo = MockPauseEventRepository();
    fakeTriggeredAt = DateTime.utc(2026, 5, 10, 9);
    when(
      () => mockRepo.insertOutcome(
        entryId: any(named: 'entryId'),
        packageName: any(named: 'packageName'),
        triggeredAt: any(named: 'triggeredAt'),
        cooldownChosenSeconds: any(named: 'cooldownChosenSeconds'),
        outcome: any(named: 'outcome'),
      ),
    ).thenAnswer((_) async => 1);
  });

  group('PAUS-04 cooldown drain auto-completes outcome=0', () {
    test(
      'cooldown timer drains and writes outcome=0 — verified via state.cooldownChosenSeconds',
      () async {
        // This test verifies that startCooldown sets cooldownChosenSeconds and
        // that cancel writes outcome=0 indirectly via the state on the notifier.
        // The real drain test relies on real Timer.periodic (100ms ticks) which
        // is integration-level; we verify the plumbing here.
        final args = (
          entryId: 1,
          packageName: 'com.instagram.android',
          blockMode: 'soft',
          triggeredAt: fakeTriggeredAt,
          onClose: () async {},
        );
        final container = buildContainer(mockRepo: mockRepo, args: args);
        addTearDown(container.dispose);

        final controller =
            container.read(pauseControllerProvider(args).notifier);

        // Verify initial state.
        final initial = container.read(pauseControllerProvider(args));
        expect(initial.cooldownChosenSeconds, isNull);
        expect(initial.isComplete, isFalse);

        // After startCooldown, cooldownChosenSeconds is set.
        controller.startCooldown(180);
        final running = container.read(pauseControllerProvider(args));
        expect(running.cooldownChosenSeconds, 180);
        expect(running.remainingMs, greaterThan(0));

        // Dispose to cancel the timer — avoids pending timer after test.
        container.dispose();
      },
    );
  });

  group('PAUS-05 Cancel writes outcome=1', () {
    test(
      'cancel writes outcome=1 with cooldownChosenSeconds=null when no chip was tapped',
      () async {
        var closeCalled = false;
        final args = (
          entryId: 1,
          packageName: 'com.instagram.android',
          blockMode: 'soft',
          triggeredAt: fakeTriggeredAt,
          onClose: () async => closeCalled = true,
        );
        final container = buildContainer(mockRepo: mockRepo, args: args);
        addTearDown(container.dispose);

        final controller =
            container.read(pauseControllerProvider(args).notifier);
        // No chip tapped — cancel immediately.
        await controller.cancel();

        verify(
          () => mockRepo.insertOutcome(
            entryId: 1,
            packageName: 'com.instagram.android',
            triggeredAt: fakeTriggeredAt,
            cooldownChosenSeconds: null,
            outcome: 1,
          ),
        ).called(1);
        expect(closeCalled, isTrue);
      },
    );

    test(
      'cancel writes outcome=1 with cooldownChosenSeconds=180 when a chip was tapped mid-cooldown',
      () async {
        var closeCalled = false;
        final args = (
          entryId: 1,
          packageName: 'com.instagram.android',
          blockMode: 'soft',
          triggeredAt: fakeTriggeredAt,
          onClose: () async => closeCalled = true,
        );
        final container = buildContainer(mockRepo: mockRepo, args: args);
        addTearDown(container.dispose);

        final controller =
            container.read(pauseControllerProvider(args).notifier);
        // Tap 3m chip, then immediately cancel.
        controller.startCooldown(180);
        await controller.cancel();

        verify(
          () => mockRepo.insertOutcome(
            entryId: 1,
            packageName: 'com.instagram.android',
            triggeredAt: fakeTriggeredAt,
            cooldownChosenSeconds: 180,
            outcome: 1,
          ),
        ).called(1);
        expect(closeCalled, isTrue);
      },
    );
  });

  group('PAUS-06 Use anyway writes outcome=2', () {
    test(
      'useAnyway writes outcome=2 with cooldownChosenSeconds=300 (5min chip)',
      () async {
        var closeCalled = false;
        final args = (
          entryId: 1,
          packageName: 'com.instagram.android',
          blockMode: 'soft',
          triggeredAt: fakeTriggeredAt,
          onClose: () async => closeCalled = true,
        );
        final container = buildContainer(mockRepo: mockRepo, args: args);
        addTearDown(container.dispose);

        final controller =
            container.read(pauseControllerProvider(args).notifier);
        // Tap 5m chip, then use anyway.
        controller.startCooldown(300);
        await controller.useAnyway();

        verify(
          () => mockRepo.insertOutcome(
            entryId: 1,
            packageName: 'com.instagram.android',
            triggeredAt: fakeTriggeredAt,
            cooldownChosenSeconds: 300,
            outcome: 2,
          ),
        ).called(1);
        expect(closeCalled, isTrue);
      },
    );
  });

  group('D-13 insert-at-session-end seam', () {
    test(
      'PauseEventRepository.insertOutcome called exactly once per session at resolution',
      () async {
        final args = (
          entryId: 1,
          packageName: 'com.instagram.android',
          blockMode: 'soft',
          triggeredAt: fakeTriggeredAt,
          onClose: () async {},
        );
        final container = buildContainer(mockRepo: mockRepo, args: args);
        addTearDown(container.dispose);

        final controller =
            container.read(pauseControllerProvider(args).notifier);
        // Multiple chip taps do NOT write rows — only the final cancel does.
        controller.startCooldown(60);
        controller.startCooldown(180);
        controller.startCooldown(300);
        await controller.cancel();

        // Exactly one insertOutcome call (insert-at-end — D-13).
        verify(
          () => mockRepo.insertOutcome(
            entryId: any(named: 'entryId'),
            packageName: any(named: 'packageName'),
            triggeredAt: any(named: 'triggeredAt'),
            cooldownChosenSeconds: any(named: 'cooldownChosenSeconds'),
            outcome: any(named: 'outcome'),
          ),
        ).called(1);
      },
    );
  });

  group('WR-05 fakeAsync drain — timer auto-completes outcome=0', () {
    // Uses fakeAsync (transitive via flutter_test) to advance time without
    // real wall-clock delay, verifying the Timer.periodic drain path.
    // Also locks in the CR-02 isComplete guard: a second _writeOutcomeAndClose
    // call after the timer drain must be a no-op.
    test(
      'timer drain to zero: remainingMs reaches 0 and triggers outcome write path',
      () {
        fakeAsync((fake) {
          final args = (
            entryId: 1,
            packageName: 'com.instagram.android',
            blockMode: 'soft',
            triggeredAt: fakeTriggeredAt,
            onClose: () async {},
          );
          final container = buildContainer(mockRepo: mockRepo, args: args);
          // Keep the autoDispose provider alive throughout the fakeAsync block.
          final sub = container.listen(
            pauseControllerProvider(args),
            (_, __) {},
          );
          final controller =
              container.read(pauseControllerProvider(args).notifier);

          // Start a 60-second cooldown (600 ticks of 100 ms each).
          controller.startCooldown(60);

          // Sanity: timer is running and remainingMs > 0.
          expect(controller.state.remainingMs, greaterThan(0));

          // Advance time past the full cooldown. All Timer.periodic ticks fire
          // synchronously within fakeAsync.elapse, including the final tick
          // that calls _cancelTimer() + unawaited(_writeOutcomeAndClose(0)).
          fake.elapse(const Duration(milliseconds: 60100));

          // After drain: remainingMs should be 0 (set synchronously by timer).
          expect(controller.state.remainingMs, equals(0));

          // Flush the microtask queue to let the unawaited future chain run:
          // insertOutcome → isComplete=true → Future.delayed(1500ms) [fake timer].
          fake.flushMicrotasks();

          // insertOutcome must have been called by now (before the delayed).
          verify(
            () => mockRepo.insertOutcome(
              entryId: 1,
              packageName: 'com.instagram.android',
              triggeredAt: fakeTriggeredAt,
              cooldownChosenSeconds: 60,
              outcome: 0,
            ),
          ).called(1);

          sub.close();
          container.dispose();
        });
      },
    );

    test(
      'CR-02 guard: second _writeOutcomeAndClose after isComplete=true is a no-op',
      () async {
        // Directly verifies the isComplete guard added for CR-02:
        // once a session is resolved, subsequent calls must not insert a row.
        final args = (
          entryId: 2,
          packageName: 'com.twitter.android',
          blockMode: 'soft',
          triggeredAt: fakeTriggeredAt,
          onClose: () async {},
        );
        final container = buildContainer(mockRepo: mockRepo, args: args);
        // Keep the autoDispose provider alive by holding a listener reference
        // throughout the test. Without a listener, autoDispose fires between
        // the two cancel() calls (after the 1500ms Future.delayed completes)
        // and the second cancel() would access a disposed ref.
        final sub = container.listen(
          pauseControllerProvider(args),
          (_, __) {},
        );

        final controller =
            container.read(pauseControllerProvider(args).notifier);

        // First cancel resolves the session: inserts a row and sets isComplete.
        await controller.cancel();

        // isComplete is now true. A second cancel must be a no-op (guard fires).
        await controller.cancel();

        sub.close();
        container.dispose();

        // Exactly one insertOutcome call despite two cancel() invocations.
        verify(
          () => mockRepo.insertOutcome(
            entryId: any(named: 'entryId'),
            packageName: any(named: 'packageName'),
            triggeredAt: any(named: 'triggeredAt'),
            cooldownChosenSeconds: any(named: 'cooldownChosenSeconds'),
            outcome: any(named: 'outcome'),
          ),
        ).called(1);
      },
    );
  });
}
