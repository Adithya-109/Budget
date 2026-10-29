// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trial_reminders.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(trialReminderScheduler)
final trialReminderSchedulerProvider = TrialReminderSchedulerProvider._();

final class TrialReminderSchedulerProvider
    extends
        $FunctionalProvider<
          TrialReminderScheduler,
          TrialReminderScheduler,
          TrialReminderScheduler
        >
    with $Provider<TrialReminderScheduler> {
  TrialReminderSchedulerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trialReminderSchedulerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trialReminderSchedulerHash();

  @$internal
  @override
  $ProviderElement<TrialReminderScheduler> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TrialReminderScheduler create(Ref ref) {
    return trialReminderScheduler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TrialReminderScheduler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrialReminderScheduler>(value),
    );
  }
}

String _$trialReminderSchedulerHash() =>
    r'1d227122cade81953bbe81b0392e49cdce3dd8b1';
