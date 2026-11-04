import 'avatar_frame_model.dart';
import 'cup_skin_model.dart';

/// Modelo de perfil para contrincantes bots en el sistema de matchmaking estilo 8 Ball Pool.
class BotProfile {
  final String id;
  final String username;
  final int level;
  final AvatarFrameModel frame;
  final CupSkinModel cupSkin;
  final int winRatePercent;
  final int coins;

  const BotProfile({
    required this.id,
    required this.username,
    required this.level,
    this.frame = AvatarFrameModel.none,
    this.cupSkin = CupSkinModel.standard,
    this.winRatePercent = 55,
    this.coins = 1000,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'level': level,
        'frameId': frame.id,
        'cupSkinId': cupSkin.id,
        'winRatePercent': winRatePercent,
        'coins': coins,
      };

  factory BotProfile.fromJson(Map<String, dynamic> json) {
    return BotProfile(
      id: json['id'] as String? ?? 'bot',
      username: json['username'] as String? ?? 'Player',
      level: (json['level'] as num?)?.toInt() ?? 1,
      frame: AvatarFrameModel.getById(json['frameId'] as String? ?? 'none'),
      cupSkin: CupSkinModel.getById(json['cupSkinId'] as String? ?? 'clasico'),
      winRatePercent: (json['winRatePercent'] as num?)?.toInt() ?? 55,
      coins: (json['coins'] as num?)?.toInt() ?? 1000,
    );
  }
}
