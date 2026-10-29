import 'package:flutter/material.dart';

import '../features/bills/bills_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/ledger/ledger_screen.dart';
import '../features/settings/settings_screen.dart';

/// Bottom navigation between the four tabs. Tabs keep their state.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          DashboardScreen(onOpenFriends: () => setState(() => _tab = 1)),
          const LedgerScreen(),
          const BillsScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFF7F5EC), width: 2)),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.local_fire_department_outlined),
              label: 'TODAY',
            ),
            NavigationDestination(
              icon: Icon(Icons.group_outlined),
              label: 'FRIENDS',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_repeat_outlined),
              label: 'BILLS',
            ),
            NavigationDestination(icon: Icon(Icons.tune), label: 'SETTINGS'),
          ],
        ),
      ),
    );
  }
}
