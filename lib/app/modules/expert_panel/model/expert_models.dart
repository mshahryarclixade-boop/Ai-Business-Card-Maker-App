import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../clixa/widgets/clixa_avatars.dart';

/// One of the five panel characters (the same cast as the prompts: Dave, Olivia,
/// John, Marcus and Sara) or Clixa, the host.
class Expert {
  const Expert({
    required this.id,
    required this.name,
    required this.shortRoleKey,
    required this.longRoleKey,
    required this.color,
    required this.asset,
  });

  /// What the AI backend knows the character by.
  final String id;
  final String name;

  /// "Finance": next to the name in the chat and feedback.
  final String shortRoleKey;

  /// "Finance and numbers": under the avatar on the start screen.
  final String longRoleKey;
  final Color color;
  final String asset;
}

/// The five selectable characters, in the order of the start screen.
const kExperts = [
  Expert(
    id: 'olivia',
    name: 'Olivia',
    shortRoleKey: 'panel_role_retail',
    longRoleKey: 'panel_role_retail_long',
    color: Color(0xFFB45F06),
    asset: 'assets/images/expert_panel_5.png',
  ),
  Expert(
    id: 'marcus',
    name: 'Marcus',
    shortRoleKey: 'panel_role_growth',
    longRoleKey: 'panel_role_growth_long',
    color: Color(0xFF6A3FC4),
    asset: 'assets/images/expert_panel_4.png',
  ),
  Expert(
    id: 'dave',
    name: 'Dave',
    shortRoleKey: 'panel_role_finance',
    longRoleKey: 'panel_role_finance_long',
    color: Color(0xFF3B8A45),
    asset: 'assets/images/expert_panel_3.png',
  ),
  Expert(
    id: 'sara',
    name: 'Sara',
    shortRoleKey: 'panel_role_customer',
    longRoleKey: 'panel_role_customer_long',
    color: Color(0xFF2A7F66),
    asset: 'assets/images/expert_panel_2.png',
  ),
  Expert(
    id: 'john',
    name: 'John',
    shortRoleKey: 'panel_role_operations',
    longRoleKey: 'panel_role_operations_long',
    color: Color(0xFFB4481C),
    asset: 'assets/images/expert_panel_1.png',
  ),
];

/// Clixa hosts both modes (welcome, transitions, safety, close). Not selectable.
const kClixaHost = Expert(
  id: 'clixa',
  name: 'Clixa',
  shortRoleKey: 'panel_role_clixa',
  longRoleKey: 'panel_role_clixa',
  color: AppColors.onboardingBtnEnd,
  asset: kClixaAvatarAsset,
);

Expert expertById(String id) => id == 'clixa'
    ? kClixaHost
    : kExperts.firstWhere((e) => e.id == id, orElse: () => kExperts.first);

enum PanelMode {
  consult('consult'),
  pitch('pitch');

  const PanelMode(this.id);
  final String id;

  String get labelKey => 'panel_mode_${id}_label';
}

/// One line of the session: a character's or Clixa's (speaker = their id), or
/// the user's (speaker null).
class PanelMessage {
  const PanelMessage({this.speaker, required this.text, required this.round});

  final String? speaker;
  final String text;
  final int round;

  bool get fromUser => speaker == null;

  Map<String, dynamic> toJson() => {'speaker': speaker, 'text': text};
}

/// The session: who is on the panel, the mode, everything said so far and the
/// workflow state the server keeps between calls (stage, strikes, notebooks or
/// case file...). The server holds nothing: this object is sent with each call.
class PanelSession {
  PanelSession({
    String? id,
    required this.experts,
    required this.mode,
    required this.title,
    this.round = 1,
    Map<String, dynamic>? engine,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       engine = engine ?? <String, dynamic>{};

  final String id;

  /// Indexes into [kExperts].
  final List<int> experts;
  final PanelMode mode;
  String title;
  int round;

  /// The server's session state (opaque to the app apart from the fields below).
  Map<String, dynamic> engine;

  final messages = <PanelMessage>[].obs;

  bool get wholePanel => experts.length == kExperts.length;
  List<String> get expertIds => [for (final i in experts) kExperts[i].id];
  bool get hasUserMessage => messages.any((m) => m.fromUser);

  /// Why the session is over (completed, founder_ended, conduct...), or null.
  String? get ended => engine['ended'] as String?;
  bool get isOver => ended != null;
  bool get paused => engine['paused'] == true;

  Map<String, dynamic> toRequest({String? userName}) => {
    'mode': mode.id,
    'experts': expertIds,
    'messages': [for (final m in messages) m.toJson()],
    'state': engine,
    'userName': ?userName,
  };
}

/// A face with an optional small badge (a tick / cross).
class ExpertFace extends StatelessWidget {
  const ExpertFace({
    super.key,
    required this.expert,
    required this.size,
    this.ringColor,
    this.badge,
  });

  final Expert expert;
  final double size;
  final Color? ringColor;

  /// true = green tick, false = red cross, null = none.
  final bool? badge;

  @override
  Widget build(BuildContext context) {
    Widget face = RoundAsset(asset: expert.asset, size: size);
    if (ringColor != null) {
      // A thicker ring with a small gap, so the edge stays smooth and clear.
      face = Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ringColor!, width: 2.5),
        ),
        child: face,
      );
    }
    if (badge == null) return face;
    final b = size * 0.36;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        face,
        PositionedDirectional(
          end: -2,
          bottom: -2,
          child: Container(
            width: b,
            height: b,
            decoration: BoxDecoration(
              color: badge! ? const Color(0xFF3B8A45) : const Color(0xFFD64545),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Icon(
              badge! ? Icons.check_rounded : Icons.close_rounded,
              size: b * 0.7,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
