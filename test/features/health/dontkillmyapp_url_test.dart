import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/core/utils/dontkillmyapp_url.dart';

void main() {
  group('dontkillmyappUrl (REL-03)', () {
    for (final entry in {
      'xiaomi': 'https://dontkillmyapp.com/xiaomi',
      'huawei': 'https://dontkillmyapp.com/huawei',
      'samsung': 'https://dontkillmyapp.com/samsung',
      'oppo': 'https://dontkillmyapp.com/oppo',
      'vivo': 'https://dontkillmyapp.com/vivo',
      'oneplus': 'https://dontkillmyapp.com/oneplus',
    }.entries) {
      test('${entry.key} -> ${entry.value}', () {
        expect(dontkillmyappUrl(entry.key), entry.value);
      });
    }

    test('unknown manufacturer returns null', () {
      expect(dontkillmyappUrl('pixel'), isNull);
      expect(dontkillmyappUrl('google'), isNull);
      expect(dontkillmyappUrl(''), isNull);
    });

    test('case-sensitive: caller must lowercase', () {
      expect(dontkillmyappUrl('Xiaomi'), isNull);
    });

    test('every URL is https (no http leaks)', () {
      for (final mfr in const [
        'xiaomi',
        'huawei',
        'samsung',
        'oppo',
        'vivo',
        'oneplus',
      ]) {
        final url = dontkillmyappUrl(mfr);
        expect(url, isNotNull);
        expect(url!.startsWith('https://'), isTrue);
      }
    });
  });
}
