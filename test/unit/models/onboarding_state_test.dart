import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/features/onboarding/models/onboarding_state.dart';
import 'package:wildfire_mvp_v3/models/consent_record.dart';

void main() {
  group('OnboardingLoading', () {
    test('is equal to another instance', () {
      const state1 = OnboardingLoading();
      const state2 = OnboardingLoading();

      expect(state1, equals(state2));
    });

    test('has empty props', () {
      const state = OnboardingLoading();
      expect(state.props, isEmpty);
    });
  });

  group('OnboardingActive', () {
    group('default values', () {
      test('has correct defaults', () {
        const state = OnboardingActive();

        expect(state.currentPage, equals(0));
        expect(state.totalPages, equals(4));
        expect(state.disclaimerChecked, isFalse);
        expect(state.termsChecked, isFalse);
        expect(
            state.selectedRadiusKm, equals(OnboardingConfig.defaultRadiusKm));
        expect(state.locationPermissionGranted, isFalse);
        expect(state.isRequestingLocation, isFalse);
      });
    });

    group('canProceed', () {
      test('returns true for page 0 without checkboxes', () {
        const state = OnboardingActive(currentPage: 0);
        expect(state.canProceed, isTrue);
      });

      test('returns true for page 1 without checkboxes', () {
        const state = OnboardingActive(currentPage: 1);
        expect(state.canProceed, isTrue);
      });

      test('returns true for page 2 without checkboxes', () {
        const state = OnboardingActive(currentPage: 2);
        expect(state.canProceed, isTrue);
      });

      test('returns false for page 3 without checkboxes', () {
        const state = OnboardingActive(currentPage: 3);
        expect(state.canProceed, isFalse);
      });

      test('returns false for page 3 with only disclaimer checked', () {
        const state = OnboardingActive(
          currentPage: 3,
          disclaimerChecked: true,
          termsChecked: false,
        );
        expect(state.canProceed, isFalse);
      });

      test('returns false for page 3 with only terms checked', () {
        const state = OnboardingActive(
          currentPage: 3,
          disclaimerChecked: false,
          termsChecked: true,
        );
        expect(state.canProceed, isFalse);
      });

      test('returns true for page 3 with both checkboxes checked', () {
        const state = OnboardingActive(
          currentPage: 3,
          disclaimerChecked: true,
          termsChecked: true,
        );
        expect(state.canProceed, isTrue);
      });
    });

    group('canFinish', () {
      test('returns false when not on last page', () {
        const state = OnboardingActive(
          currentPage: 2,
          disclaimerChecked: true,
          termsChecked: true,
        );
        expect(state.canFinish, isFalse);
      });

      test('returns false on last page without checkboxes', () {
        const state = OnboardingActive(currentPage: 3);
        expect(state.canFinish, isFalse);
      });

      test('returns true on last page with both checkboxes', () {
        const state = OnboardingActive(
          currentPage: 3,
          disclaimerChecked: true,
          termsChecked: true,
        );
        expect(state.canFinish, isTrue);
      });
    });

    group('hasNextPage', () {
      test('returns true for page 0', () {
        const state = OnboardingActive(currentPage: 0);
        expect(state.hasNextPage, isTrue);
      });

      test('returns true for page 2', () {
        const state = OnboardingActive(currentPage: 2);
        expect(state.hasNextPage, isTrue);
      });

      test('returns false for page 3 (last page)', () {
        const state = OnboardingActive(currentPage: 3);
        expect(state.hasNextPage, isFalse);
      });
    });

    group('isLastPage', () {
      test('returns false for page 0', () {
        const state = OnboardingActive(currentPage: 0);
        expect(state.isLastPage, isFalse);
      });

      test('returns true for page 3', () {
        const state = OnboardingActive(currentPage: 3);
        expect(state.isLastPage, isTrue);
      });
    });

    group('copyWith', () {
      test('copies all values when none provided', () {
        const original = OnboardingActive(
          currentPage: 2,
          disclaimerChecked: true,
          termsChecked: true,
          selectedRadiusKm: 25,
          locationPermissionGranted: true,
          isRequestingLocation: true,
        );

        final copy = original.copyWith();

        expect(copy.currentPage, equals(2));
        expect(copy.disclaimerChecked, isTrue);
        expect(copy.termsChecked, isTrue);
        expect(copy.selectedRadiusKm, equals(25));
        expect(copy.locationPermissionGranted, isTrue);
        expect(copy.isRequestingLocation, isTrue);
        expect(copy.totalPages, equals(4)); // Always preserved
      });

      test('updates currentPage', () {
        const original = OnboardingActive(currentPage: 0);
        final copy = original.copyWith(currentPage: 2);

        expect(copy.currentPage, equals(2));
      });

      test('updates disclaimerChecked', () {
        const original = OnboardingActive(disclaimerChecked: false);
        final copy = original.copyWith(disclaimerChecked: true);

        expect(copy.disclaimerChecked, isTrue);
      });

      test('updates termsChecked', () {
        const original = OnboardingActive(termsChecked: false);
        final copy = original.copyWith(termsChecked: true);

        expect(copy.termsChecked, isTrue);
      });

      test('updates selectedRadiusKm', () {
        const original = OnboardingActive(selectedRadiusKm: 10);
        final copy = original.copyWith(selectedRadiusKm: 50);

        expect(copy.selectedRadiusKm, equals(50));
      });

      test('updates locationPermissionGranted', () {
        const original = OnboardingActive(locationPermissionGranted: false);
        final copy = original.copyWith(locationPermissionGranted: true);

        expect(copy.locationPermissionGranted, isTrue);
      });

      test('updates isRequestingLocation', () {
        const original = OnboardingActive(isRequestingLocation: false);
        final copy = original.copyWith(isRequestingLocation: true);

        expect(copy.isRequestingLocation, isTrue);
      });

      test('preserves totalPages', () {
        const original = OnboardingActive();
        final copy = original.copyWith(currentPage: 3);

        expect(copy.totalPages, equals(4));
      });
    });

    group('equality', () {
      test('two states with same values are equal', () {
        const state1 = OnboardingActive(
          currentPage: 1,
          disclaimerChecked: true,
          selectedRadiusKm: 25,
        );
        const state2 = OnboardingActive(
          currentPage: 1,
          disclaimerChecked: true,
          selectedRadiusKm: 25,
        );

        expect(state1, equals(state2));
      });

      test('states with different pages are not equal', () {
        const state1 = OnboardingActive(currentPage: 1);
        const state2 = OnboardingActive(currentPage: 2);

        expect(state1, isNot(equals(state2)));
      });
    });

    group('props', () {
      test('contains all tracked fields', () {
        const state = OnboardingActive(
          currentPage: 2,
          disclaimerChecked: true,
          termsChecked: false,
          selectedRadiusKm: 25,
          locationPermissionGranted: true,
          isRequestingLocation: false,
        );

        expect(state.props, contains(2)); // currentPage
        expect(state.props, contains(4)); // totalPages
        expect(state.props,
            contains(true)); // disclaimerChecked or locationPermissionGranted
        expect(state.props,
            contains(false)); // termsChecked or isRequestingLocation
        expect(state.props, contains(25)); // selectedRadiusKm
        expect(state.props.length, equals(7));
      });
    });

    group('toString', () {
      test('includes key fields', () {
        const state = OnboardingActive(
          currentPage: 2,
          disclaimerChecked: true,
          termsChecked: false,
          selectedRadiusKm: 25,
        );

        final str = state.toString();
        expect(str, contains('OnboardingActive'));
        expect(str, contains('page: 2/4'));
        expect(str, contains('disclaimer: true'));
        expect(str, contains('terms: false'));
        expect(str, contains('radius: 25km'));
      });
    });
  });

  group('OnboardingComplete', () {
    test('is equal to another instance', () {
      const state1 = OnboardingComplete();
      const state2 = OnboardingComplete();

      expect(state1, equals(state2));
    });

    test('has empty props', () {
      const state = OnboardingComplete();
      expect(state.props, isEmpty);
    });
  });

  group('OnboardingMigration', () {
    test('stores version information', () {
      const state = OnboardingMigration(
        previousVersion: 1,
        currentVersion: 2,
      );

      expect(state.previousVersion, equals(1));
      expect(state.currentVersion, equals(2));
    });

    test('equality based on versions', () {
      const state1 = OnboardingMigration(
        previousVersion: 1,
        currentVersion: 2,
      );
      const state2 = OnboardingMigration(
        previousVersion: 1,
        currentVersion: 2,
      );
      const state3 = OnboardingMigration(
        previousVersion: 1,
        currentVersion: 3,
      );

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });

    test('props contains both versions', () {
      const state = OnboardingMigration(
        previousVersion: 1,
        currentVersion: 2,
      );

      expect(state.props, contains(1));
      expect(state.props, contains(2));
      expect(state.props.length, equals(2));
    });

    test('toString includes version info', () {
      const state = OnboardingMigration(
        previousVersion: 1,
        currentVersion: 2,
      );

      final str = state.toString();
      expect(str, contains('OnboardingMigration'));
      expect(str, contains('from: 1'));
      expect(str, contains('to: 2'));
    });
  });

  group('Sealed class hierarchy', () {
    test('all states extend OnboardingState', () {
      const loading = OnboardingLoading();
      const active = OnboardingActive();
      const complete = OnboardingComplete();
      const migration = OnboardingMigration(
        previousVersion: 1,
        currentVersion: 2,
      );

      expect(loading, isA<OnboardingState>());
      expect(active, isA<OnboardingState>());
      expect(complete, isA<OnboardingState>());
      expect(migration, isA<OnboardingState>());
    });

    test('switch statement is exhaustive', () {
      const OnboardingState state = OnboardingLoading();

      // This test verifies the sealed class works with switch
      final result = switch (state) {
        OnboardingLoading() => 'loading',
        OnboardingActive() => 'active',
        OnboardingComplete() => 'complete',
        OnboardingMigration() => 'migration',
      };

      expect(result, equals('loading'));
    });
  });
}
