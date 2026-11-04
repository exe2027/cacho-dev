import 'package:flutter/material.dart';
import 'package:cacho_engine/cacho_engine.dart';
import '../../models/room_config.dart';
import 'player_slot_widget.dart';
import 'premium_table_widget.dart';

export 'premium_table_widget.dart';

/// Adaptador compatible para [Table2DLayoutWidget], delegando al nuevo [PremiumTableWidget].
class Table2DLayoutWidget extends StatelessWidget {
  final RoomConfig roomConfig;
  final List<PlayerSlotData> slots;
  final int pot;
  final Bid? currentBid;
  final String? lastBidderName;
  final Widget? overlayChild;

  const Table2DLayoutWidget({
    super.key,
    required this.roomConfig,
    required this.slots,
    this.pot = 0,
    this.currentBid,
    this.lastBidderName,
    this.overlayChild,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumTableWidget(
      roomConfig: roomConfig,
      slots: slots,
      pot: pot,
      currentBid: currentBid,
      lastBidderName: lastBidderName,
      overlayChild: overlayChild,
    );
  }
}
