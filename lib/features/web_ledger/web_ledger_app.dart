import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/money.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../ledger/settle_links.dart';
import '../ledger/shared_ledger.dart';

/// The Flutter Web build: a zero-install viewer for shared tabs. Friends open
/// the link, see what they owe, and tap Settle Now. No database, no login.
///
/// Flutter Web turns the `#/l/<payload>` fragment into the route name, both
/// on first load and when another link is opened in the same tab, so every
/// route name is treated as a (possibly empty) tab payload.
class WebLedgerApp extends StatelessWidget {
  const WebLedgerApp({super.key});

  static Route<void> _route(String? name) => MaterialPageRoute<void>(
    settings: RouteSettings(name: name),
    builder: (_) =>
        WebLedgerScreen(payload: SharedLedger.payloadFromFragment(name ?? '')),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SplitBurn',
      debugShowCheckedModeBanner: false,
      theme: buildSplitBurnTheme(),
      // One route per link: don't stack "/" and "/l" under a deep link.
      onGenerateInitialRoutes: (name) => [_route(name)],
      onGenerateRoute: (settings) => _route(settings.name),
    );
  }
}

class WebLedgerScreen extends StatelessWidget {
  const WebLedgerScreen({super.key, required this.payload});

  final String? payload;

  @override
  Widget build(BuildContext context) {
    final body = switch (payload) {
      null => const _Message(
        'SplitBurn tabs open here.',
        'Ask your friend to share their SplitBurn link again.',
      ),
      final p => _decode(p),
    };
    return Scaffold(
      appBar: AppBar(title: const Text('SPLITBURN')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: body,
        ),
      ),
    );
  }

  Widget _decode(String p) {
    try {
      return _Ledger(ledger: SharedLedger.decode(p));
    } on SharedLedgerFormatException catch (e) {
      return _Message('Can\'t open this tab', e.message);
    }
  }
}

class _Message extends StatelessWidget {
  const _Message(this.title, this.body);

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: BrutalCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: SbColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ledger extends StatelessWidget {
  const _Ledger({required this.ledger});

  final SharedLedger ledger;

  String _fmt(int minor) => Money.format(minor, symbol: ledger.currencySymbol);

  Future<void> _open(BuildContext context, Uri link) async {
    final opened = await launchUrl(link, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      showSnack(
        context,
        'No payment app picked it up. Copy the ID below instead.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final handle = ledger.payeeHandle;
    final rail = SettleLinks.railOf(handle);
    final total = ledger.totalMinor;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        BrutalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SbLabel(ledger.title, color: SbColors.lime),
              const SizedBox(height: 8),
              Text(
                _fmt(total),
                key: const Key('web-total'),
                style: SbType.hero,
              ),
              const SizedBox(height: 4),
              Text(
                'to ${ledger.payeeName}',
                style: const TextStyle(color: SbColors.muted),
              ),
              const SizedBox(height: 14),
              for (final l in ledger.lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${l.date.day}/${l.date.month}',
                          style: const TextStyle(color: SbColors.muted),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          l.label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        _fmt(l.amountMinor),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (rail == PaymentRail.upi)
          FilledButton.icon(
            key: const Key('settle-now'),
            onPressed: () => _open(
              context,
              SettleLinks.upi(
                payeeVpa: handle!,
                payeeName: ledger.payeeName,
                amountMinor: total,
              ),
            ),
            icon: const Icon(Icons.bolt),
            label: Text('SETTLE NOW · ${_fmt(total)} VIA UPI'),
          )
        else if (rail == PaymentRail.venmo)
          FilledButton.icon(
            key: const Key('settle-now'),
            onPressed: () => _open(
              context,
              SettleLinks.venmo(handle: handle!, amountMinor: total),
            ),
            icon: const Icon(Icons.bolt),
            label: Text('SETTLE NOW · ${_fmt(total)} ON VENMO'),
          )
        else
          Text(
            'Ask ${ledger.payeeName} for their UPI ID or Venmo to settle.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: SbColors.muted),
          ),
        if (handle != null) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: handle));
              if (context.mounted) showSnack(context, 'Copied $handle');
            },
            icon: const Icon(Icons.copy),
            label: Text(handle),
          ),
        ],
        const SizedBox(height: 24),
        const Text(
          'Shared with SplitBurn · nothing to install',
          textAlign: TextAlign.center,
          style: TextStyle(color: SbColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}
