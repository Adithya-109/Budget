import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/database/ledger_models.dart';
import '../../core/providers/database_providers.dart';
import '../../domain/expense_draft.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'nudge_cards.dart';
import 'nudge_composer.dart';
import 'shared_ledger.dart';

Future<void> showNudgeStudio(
  BuildContext context, {
  required FriendRef friend,
  required List<OpenSplit> openSplits,
  NudgeTone initialTone = NudgeTone.polite,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => NudgeStudio(
      friend: friend,
      openSplits: openSplits,
      initialTone: initialTone,
    ),
  );
}

/// The Nudge Bot: pick a tone, preview the card, share via WhatsApp /
/// iMessage (system share sheet) with a zero-install settle link.
class NudgeStudio extends ConsumerStatefulWidget {
  const NudgeStudio({
    super.key,
    required this.friend,
    required this.openSplits,
    this.initialTone = NudgeTone.polite,
  });

  final FriendRef friend;
  final List<OpenSplit> openSplits;
  final NudgeTone initialTone;

  @override
  ConsumerState<NudgeStudio> createState() => _NudgeStudioState();
}

class _NudgeStudioState extends ConsumerState<NudgeStudio> {
  final _cardKey = GlobalKey();
  late NudgeTone _tone = widget.initialTone;
  bool _sharing = false;

  Future<Uint8List> _renderCard() async {
    final boundary =
        _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  }

  Future<void> _share(Nudge nudge, {required bool withCard}) async {
    setState(() => _sharing = true);
    try {
      final box = context.findRenderObject() as RenderBox?;
      final origin = box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size;
      if (withCard) {
        final png = await _renderCard();
        await SharePlus.instance.share(
          ShareParams(
            text: nudge.text,
            files: [
              XFile.fromData(
                png,
                mimeType: 'image/png',
                name: 'splitburn-tab.png',
              ),
            ],
            fileNameOverrides: const ['splitburn-tab.png'],
            sharePositionOrigin: origin,
          ),
        );
      } else {
        await SharePlus.instance.share(
          ShareParams(text: nudge.text, sharePositionOrigin: origin),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _whatsApp(Nudge nudge) async {
    final uri = Uri.https('wa.me', '/', {'text': nudge.text});
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      showSnack(context, 'WhatsApp isn\'t installed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(budgetSettingsProvider).value;
    final symbol = ref.watch(currencySymbolProvider);
    final ownerName = settings?.ownerName;
    final ownerHandle = settings?.ownerPaymentHandle;
    final lines = NudgeComposer.linesFor(widget.openSplits);
    final link = SharedLedger(
      title: "${widget.friend.name.split(' ').first}'s tab",
      payeeName: ownerName ?? 'your friend',
      payeeHandle: ownerHandle,
      currencySymbol: symbol,
      lines: lines,
    ).toUri();
    final nudge = NudgeComposer.compose(
      tone: _tone,
      friendName: widget.friend.name,
      openSplits: widget.openSplits,
      currencySymbol: symbol,
      ownerName: ownerName,
      settleLink: link,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'NUDGE ${widget.friend.name.toUpperCase()}',
            style: Theme.of(context).appBarTheme.titleTextStyle,
          ),
          const SizedBox(height: 14),
          SegmentedButton<NudgeTone>(
            key: const Key('nudge-tone'),
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: NudgeTone.polite, label: Text('Polite')),
              ButtonSegment(value: NudgeTone.meme, label: Text('Meme card')),
              ButtonSegment(value: NudgeTone.digest, label: Text('Monthly')),
            ],
            selected: {_tone},
            onSelectionChanged: (s) => setState(() => _tone = s.single),
          ),
          const SizedBox(height: 18),
          Center(
            child: FittedBox(
              child: RepaintBoundary(
                key: _cardKey,
                child: Padding(
                  // Room for the hard shadow inside the exported image.
                  padding: const EdgeInsets.fromLTRB(4, 4, 10, 10),
                  child: NudgeCard(
                    nudge: nudge,
                    friendName: widget.friend.name,
                    symbol: symbol,
                    payeeName: ownerName,
                    settleLink: link,
                  ),
                ),
              ),
            ),
          ),
          if (ownerHandle == null) ...[
            const SizedBox(height: 14),
            const Text(
              'Add your UPI ID or Venmo handle in Settings so the link gets a one-tap Settle Now button.',
              style: TextStyle(
                color: SbColors.magma,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SbLabel('Message'),
          const SizedBox(height: 6),
          Text(nudge.text, key: const Key('nudge-text')),
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const Key('nudge-share'),
            onPressed: _sharing
                ? null
                : () => _share(nudge, withCard: _tone != NudgeTone.polite),
            icon: const Icon(Icons.ios_share),
            label: Text(
              _tone == NudgeTone.polite
                  ? 'SHARE MESSAGE'
                  : 'SHARE CARD + MESSAGE',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _whatsApp(nudge),
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('WHATSAPP'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: link.toString()),
                    );
                    if (context.mounted) {
                      showSnack(context, 'Settle link copied');
                    }
                  },
                  icon: const Icon(Icons.link),
                  label: const Text('COPY LINK'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
