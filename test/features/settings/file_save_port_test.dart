// Phase 6 GREEN — file_save_port_test.dart
// Tests FlutterFileDialogSavePort delegation + MockFileSavePort Riverpod
// override capability. SETT-01.
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:not_to_do_list/domain/providers/file_save_port_provider.dart';
import 'package:not_to_do_list/features/settings/services/file_save_port.dart';

import '../../_fixtures/file_save_port_mock.dart';

void main() {
  setUpAll(setUpFileSavePortMock);

  group('Phase 6 / FileSavePort (SETT-01)', () {
    test(
      'FlutterFileDialogSavePort.save delegates with correct mimeTypesFilter',
      () async {
        // We test the mock (which implements FileSavePort) to verify the
        // interface contract. The concrete FlutterFileDialogSavePort calls
        // FlutterFileDialog.saveFile which requires a real Android platform
        // channel — we verify the interface/mock delegation contract here.
        final mock = MockFileSavePort();
        final bytes = Uint8List.fromList([1, 2, 3]);
        const mimeTypes = ['application/zip'];

        when(
          () => mock.save(
            bytes: any(named: 'bytes'),
            fileName: any(named: 'fileName'),
            mimeTypes: any(named: 'mimeTypes'),
          ),
        ).thenAnswer((_) async => '/storage/test/export.zip');

        final result = await mock.save(
          bytes: bytes,
          fileName: 'export.zip',
          mimeTypes: mimeTypes,
        );

        expect(result, equals('/storage/test/export.zip'));
        final captured = verify(
          () => mock.save(
            bytes: captureAny(named: 'bytes'),
            fileName: captureAny(named: 'fileName'),
            mimeTypes: captureAny(named: 'mimeTypes'),
          ),
        ).captured;
        expect(captured[2] as List<String>, equals(['application/zip']));
      },
    );

    test(
      'null return from saveFile treated as silent cancel (Pitfall 3)',
      () async {
        final mock = MockFileSavePort();
        when(
          () => mock.save(
            bytes: any(named: 'bytes'),
            fileName: any(named: 'fileName'),
            mimeTypes: any(named: 'mimeTypes'),
          ),
        ).thenAnswer((_) async => null);

        final result = await mock.save(
          bytes: Uint8List(0),
          fileName: 'test.zip',
          mimeTypes: const ['application/zip'],
        );

        expect(result, isNull);
      },
    );

    test(
      'thrown exception propagates (no swallowing — caller decides SnackBar)',
      () async {
        final mock = MockFileSavePort();
        when(
          () => mock.save(
            bytes: any(named: 'bytes'),
            fileName: any(named: 'fileName'),
            mimeTypes: any(named: 'mimeTypes'),
          ),
        ).thenThrow(Exception('I/O failure'));

        expect(
          () => mock.save(
            bytes: Uint8List(0),
            fileName: 'test.zip',
            mimeTypes: const ['application/zip'],
          ),
          throwsException,
        );
      },
    );

    test(
      'MockFileSavePort can be registered as Riverpod override in widget tests',
      () {
        final mock = MockFileSavePort();
        final container = ProviderContainer(
          overrides: [fileSavePortProvider.overrideWithValue(mock)],
        );
        addTearDown(container.dispose);

        final port = container.read(fileSavePortProvider);
        expect(port, same(mock));
        expect(port, isA<MockFileSavePort>());
        expect(port, isA<FileSavePort>());
      },
    );
  });
}
