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
      theme: buildSplitBurnTheme(Brightness.light),
      darkTheme: buildSplitBurnTheme(Brightness.dark),
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
      appBar: AppBar(
        title: const Text('SplitBurn'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SbTag('Guest · zero-install', color: context.sb.nudgeViolet),
          ),
        ],
      ),
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
      child: BentoCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: SbType.title.copyWith(
                fontSize: 20,
                color: context.sb.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.sb.textSecondary),
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
    final sb = context.sb;
    final handle = ledger.payeeHandle;
    final rail = SettleLinks.railOf(handle);
    final total = ledger.totalMinor;
    final settle = switch (rail) {
      PaymentRail.upi => (
        SettleLinks.upi(
          payeeVpa: handle!,
          payeeName: ledger.payeeName,
          amountMinor: total,
        ),
        'UPI',
      ),
      PaymentRail.venmo => (
        SettleLinks.venmo(handle: handle!, amountMinor: total),
        'Venmo',
      ),
      null => null,
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Web ledger',
          style: SbType.title.copyWith(fontSize: 28, color: sb.textPrimary),
        ),
        Text(
          'Nothing to install · nothing to sign up for',
          style: TextStyle(color: sb.textSecondary),
        ),
        const SizedBox(height: 16),
        BentoCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FriendAvatar(ledger.payeeName, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ledger.title,
                      style: SbType.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: sb.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const SbLabel('Your share'),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _fmt(total),
                  key: const Key('web-total'),
                  style: SbType.hero.copyWith(color: sb.textPrimary),
                ),
              ),
              Text(
                'to ${ledger.payeeName}',
                style: TextStyle(color: sb.textSecondary),
              ),
              const SizedBox(height: 14),
              Divider(color: sb.hairlineBorder),
              for (final l in ledger.lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: sb.info,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          l.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: sb.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${l.date.day}/${l.date.month}',
                        style: SbType.receipt.copyWith(color: sb.textMuted),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _fmt(l.amountMinor),
                        style: SbType.amount.copyWith(color: sb.textPrimary),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (settle case (final link, final railName))
          _PayButton(
            key: const Key('settle-now'),
            label: 'Pay ${_fmt(total)} via $railName',
            onPressed: () => _open(context, link),
          )
        else
          Text(
            'Ask ${ledger.payeeName} for their UPI ID or Venmo to settle.',
            textAlign: TextAlign.center,
            style: TextStyle(color: sb.textSecondary),
          ),
        if (handle != null) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: handle));
              if (context.mounted) showSnack(context, 'Copied $handle');
            },
            icon: const Icon(Icons.copy_rounded),
            label: Text(handle),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'Shared with SplitBurn',
          textAlign: TextAlign.center,
          style: TextStyle(color: sb.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}

/// Dark pill with a gradient rim: the one action on the page.
class _PayButton extends StatelessWidget {
  const _PayButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SbRadius.pill),
        gradient: LinearGradient(
          colors: [sb.safeMint, sb.info, sb.nudgeViolet, sb.survivalMagma],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: const Color(0xFF15161A),
          borderRadius: BorderRadius.circular(SbRadius.pill),
          child: InkWell(
            borderRadius: BorderRadius.circular(SbRadius.pill),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bolt_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: SbType.body.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
