import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/what3words_models.dart';

void main() {
  group('What3wordsAddress', () {
    group('tryParse', () {
      test('parses valid three-word format', () {
        final result = What3wordsAddress.tryParse('slurs.this.name');
        expect(result, isNotNull);
        expect(result!.words, equals('slurs.this.name'));
      });

      test('parses format with single slash prefix', () {
        final result = What3wordsAddress.tryParse('/slurs.this.name');
        expect(result, isNotNull);
        expect(result!.words, equals('slurs.this.name'));
      });

      test('parses format with triple slash prefix', () {
        final result = What3wordsAddress.tryParse('///slurs.this.name');
        expect(result, isNotNull);
        expect(result!.words, equals('slurs.this.name'));
      });

      test('normalizes uppercase to lowercase', () {
        final result = What3wordsAddress.tryParse('CAPS.ARE.OK');
        expect(result, isNotNull);
        expect(result!.words, equals('caps.are.ok'));
      });

      test('normalizes mixed case to lowercase', () {
        final result = What3wordsAddress.tryParse('Mixed.Case.Words');
        expect(result, isNotNull);
        expect(result!.words, equals('mixed.case.words'));
      });

      test('trims whitespace', () {
        final result = What3wordsAddress.tryParse('  slurs.this.name  ');
        expect(result, isNotNull);
        expect(result!.words, equals('slurs.this.name'));
      });

      test('rejects single word', () {
        final result = What3wordsAddress.tryParse('invalid');
        expect(result, isNull);
      });

      test('rejects two words', () {
        final result = What3wordsAddress.tryParse('two.words');
        expect(result, isNull);
      });

      test('rejects four words', () {
        final result = What3wordsAddress.tryParse('too.many.words.here');
        expect(result, isNull);
      });

      test('rejects empty string', () {
        final result = What3wordsAddress.tryParse('');
        expect(result, isNull);
      });

      test('rejects words with numbers', () {
        final result = What3wordsAddress.tryParse('word1.word2.word3');
        expect(result, isNull);
      });

      test('rejects words with hyphens', () {
        final result = What3wordsAddress.tryParse(
          'word-one.word-two.word-three',
        );
        expect(result, isNull);
      });

      test('rejects words with special characters', () {
        final result = What3wordsAddress.tryParse('word@.word#.word!');
        expect(result, isNull);
      });

      test('rejects empty word parts', () {
        final result = What3wordsAddress.tryParse('.word.word');
        expect(result, isNull);
      });

      test('accepts Scottish-relevant words', () {
        // These are actual what3words addresses in Scotland
        final result = What3wordsAddress.tryParse('index.home.raft');
        expect(result, isNotNull);
        expect(result!.words, equals('index.home.raft'));
      });
    });

    group('parse (throwing)', () {
      test('returns What3wordsAddress for valid input', () {
        final result = What3wordsAddress.parse('word.word.word');
        expect(result.words, equals('word.word.word'));
      });

      test('throws ArgumentError for invalid input', () {
        expect(
          () => What3wordsAddress.parse('invalid'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError with descriptive message', () {
        expect(
          () => What3wordsAddress.parse('bad'),
          throwsA(
            predicate<ArgumentError>(
              (e) => e.message.toString().contains('Invalid what3words format'),
            ),
          ),
        );
      });
    });

    group('looksLikeWhat3words', () {
      test('returns true for valid format', () {
        expect(What3wordsAddress.looksLikeWhat3words('word.word.word'), isTrue);
      });

      test('returns true with slash prefix', () {
        expect(
          What3wordsAddress.looksLikeWhat3words('/word.word.word'),
          isTrue,
        );
        expect(
          What3wordsAddress.looksLikeWhat3words('///word.word.word'),
          isTrue,
        );
      });

      test('returns false for invalid format', () {
        expect(What3wordsAddress.looksLikeWhat3words('invalid'), isFalse);
        expect(What3wordsAddress.looksLikeWhat3words('two.words'), isFalse);
      });

      test('returns false for empty string', () {
        expect(What3wordsAddress.looksLikeWhat3words(''), isFalse);
      });
    });

    group('displayFormat', () {
      test('returns triple-slash prefix format', () {
        final address = What3wordsAddress.tryParse('slurs.this.name')!;
        expect(address.displayFormat, equals('///slurs.this.name'));
      });

      test('returns triple-slash even when parsed with single slash', () {
        final address = What3wordsAddress.tryParse('/slurs.this.name')!;
        expect(address.displayFormat, equals('///slurs.this.name'));
      });
    });

    group('copyFormat', () {
      test('returns raw words without prefix', () {
        final address = What3wordsAddress.tryParse('///slurs.this.name')!;
        expect(address.copyFormat, equals('slurs.this.name'));
      });
    });

    group('equality', () {
      test('equal addresses have same hashCode', () {
        final address1 = What3wordsAddress.tryParse('word.word.word')!;
        final address2 = What3wordsAddress.tryParse('word.word.word')!;
        expect(address1.hashCode, equals(address2.hashCode));
      });

      test('equal addresses are equal', () {
        final address1 = What3wordsAddress.tryParse('word.word.word')!;
        final address2 = What3wordsAddress.tryParse('word.word.word')!;
        expect(address1, equals(address2));
      });

      test('different addresses are not equal', () {
        final address1 = What3wordsAddress.tryParse('word.word.word')!;
        final address2 = What3wordsAddress.tryParse('other.word.word')!;
        expect(address1, isNot(equals(address2)));
      });

      test('normalized addresses are equal', () {
        final lowercase = What3wordsAddress.tryParse('word.word.word')!;
        final uppercase = What3wordsAddress.tryParse('WORD.WORD.WORD')!;
        expect(lowercase, equals(uppercase));
      });
    });

    group('toString', () {
      test('returns displayFormat', () {
        final address = What3wordsAddress.tryParse('word.word.word')!;
        expect(address.toString(), equals('///word.word.word'));
      });
    });
  });

  group('What3wordsError hierarchy', () {
    group('What3wordsApiError', () {
      test('provides user message for InvalidKey', () {
        const error = What3wordsApiError(
          code: 'InvalidKey',
          message: 'Key invalid',
        );
        expect(error.userMessage, equals('what3words service unavailable'));
      });

      test('provides user message for InvalidInput', () {
        const error = What3wordsApiError(
          code: 'InvalidInput',
          message: 'Bad input',
        );
        expect(error.userMessage, equals('Invalid what3words address'));
      });

      test('provides user message for QuotaExceeded', () {
        const error = What3wordsApiError(
          code: 'QuotaExceeded',
          message: 'Limit',
        );
        expect(
          error.userMessage,
          equals('what3words limit reached, try again later'),
        );
      });

      test('provides user message for BadWords', () {
        const error = What3wordsApiError(
          code: 'BadWords',
          message: 'Not found',
        );
        expect(error.userMessage, equals('what3words address not found'));
      });

      test('provides fallback user message for unknown codes', () {
        const error = What3wordsApiError(
          code: 'Unknown',
          message: 'Something happened',
        );
        expect(
          error.userMessage,
          equals('what3words error: Something happened'),
        );
      });

      test('includes status code in toString', () {
        const error = What3wordsApiError(
          code: 'InvalidKey',
          message: 'Bad key',
          statusCode: 401,
        );
        expect(error.toString(), contains('statusCode: 401'));
      });
    });

    group('What3wordsNetworkError', () {
      test('provides user-friendly message', () {
        const error = What3wordsNetworkError();
        expect(error.userMessage, equals('Unable to reach what3words service'));
      });

      test('accepts optional details', () {
        const error = What3wordsNetworkError('Connection timed out');
        expect(error.details, equals('Connection timed out'));
        expect(error.userMessage, equals('Unable to reach what3words service'));
      });

      test('toString includes details', () {
        const error = What3wordsNetworkError('Timeout');
        expect(error.toString(), contains('Timeout'));
      });
    });

    group('What3wordsInvalidAddressError', () {
      test('provides user-friendly message', () {
        const error = What3wordsInvalidAddressError('bad input');
        expect(error.userMessage, equals('Invalid what3words format'));
      });

      test('stores the invalid input', () {
        const error = What3wordsInvalidAddressError('bad.input');
        expect(error.input, equals('bad.input'));
      });

      test('toString includes the invalid input', () {
        const error = What3wordsInvalidAddressError('bad');
        expect(error.toString(), contains('bad'));
      });
    });

    group('sealed class pattern matching', () {
      test('can pattern match on error types', () {
        What3wordsError error = const What3wordsApiError(
          code: 'InvalidKey',
          message: 'Bad key',
        );

        final message = switch (error) {
          What3wordsApiError(:final code) => 'API error: $code',
          What3wordsNetworkError() => 'Network error',
          What3wordsInvalidAddressError(:final input) => 'Invalid: $input',
        };

        expect(message, equals('API error: InvalidKey'));
      });
    });
  });
}
