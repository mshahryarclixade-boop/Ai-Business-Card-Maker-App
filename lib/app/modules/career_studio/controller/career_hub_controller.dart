import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/translations/app_strings.dart';

import '../../paywall/controller/subscription_controller.dart';

/// What the Career Studio hub shows. Plain data: there is no backend yet, so
/// the values below are placeholders until real usage is wired in.
class CareerHubState {
  const CareerHubState({
    this.isPro = false,
    this.buildsLeft = 1,
    this.scansLeft = 1,
    this.hasDraft = false,
    this.score,
    this.fixesDone = 0,
    this.fixesTotal = 7,
    this.resetDate = 'Nov 1',
  });

  /// New free user: 1 build and 1 scan left.
  const CareerHubState.free() : this();

  /// Pro user: unlimited everything.
  const CareerHubState.pro() : this(isPro: true);

  final bool isPro;
  final int buildsLeft;
  final int scansLeft;

  /// A generated profile that hasn't been published yet.
  final bool hasDraft;

  /// Last profile score (0-100); null until the first scan.
  final int? score;
  final int fixesDone;
  final int fixesTotal;

  /// When the free allowance renews, already formatted ("Nov 1").
  final String resetDate;

  bool get hasReport => score != null;
  bool get buildUsed => !isPro && buildsLeft <= 0;
  bool get scanUsed => !isPro && scansLeft <= 0;

  CareerHubState copyWith({
    bool? isPro,
    int? buildsLeft,
    int? scansLeft,
    bool? hasDraft,
    int? score,
    int? fixesDone,
  }) => CareerHubState(
    isPro: isPro ?? this.isPro,
    buildsLeft: buildsLeft ?? this.buildsLeft,
    scansLeft: scansLeft ?? this.scansLeft,
    hasDraft: hasDraft ?? this.hasDraft,
    score: score ?? this.score,
    fixesDone: fixesDone ?? this.fixesDone,
    fixesTotal: fixesTotal,
    resetDate: resetDate,
  );

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// First day of next month in the app language, e.g. "Nov 1" (falls back
  /// to English if the language's date data isn't loaded).
  static String nextResetDate([DateTime? now]) {
    final n = now ?? DateTime.now();
    final first = DateTime(n.year, n.month + 1, 1);
    try {
      return DateFormat.MMMd(AppStrings.language).format(first);
    } catch (_) {
      return '${_months[first.month - 1]} ${first.day}';
    }
  }
}

class CareerHubController extends GetxController {
  CareerHubController([CareerHubState? initial])
    : state =
          (initial ?? CareerHubState(resetDate: CareerHubState.nextResetDate()))
              .obs;

  final Rx<CareerHubState> state;

  /// Follows the real subscription for Free/Pro; usage is placeholder data.
  void syncSubscription() {
    if (!Get.isRegistered<SubscriptionController>()) return;
    final pro = Get.find<SubscriptionController>().isPro;
    if (pro != state.value.isPro) {
      state.value = state.value.copyWith(isPro: pro);
    }
  }
}
