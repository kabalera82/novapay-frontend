// lib/presentation/pages/admin/admin.shell.page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/theme.dart';
import '../../../data/models/user.dart';
import '../../controllers/admin.shell.controller.dart';
import '../login.page.dart';
import 'sections/personal.area.section.dart';
import 'sections/users.list.section.dart';
import 'sections/sala.section.dart';
import 'sections/inventario.section.dart';
import 'sections/tickets.section.dart';
import 'sections/caja.section.dart';
import 'sections/verifactu.section.dart';

class AdminShellPage extends StatefulWidget {
  static const String routename = '/admin';

  const AdminShellPage({super.key});

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  late User _user;
  late List<Widget> _sections;
  bool _initialized = false;

  static const _navItems = [
    _NavItem(Icons.person_outline,          'Mi perfil'),
    _NavItem(Icons.group,                   'Usuarios'),
    _NavItem(Icons.table_chart_outlined,    'Sala'),
    _NavItem(Icons.inventory_2,             'Inventario'),
    _NavItem(Icons.receipt_long,            'Tickets'),
    _NavItem(Icons.account_balance_wallet,  'Caja'),
    _NavItem(Icons.verified_user,           'Verifactu'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    _user = args is User ? args : User();

    _sections = [
      PersonalAreaSection(user: _user),
      const UsersListSection(),
      const SalaSection(),
      const InventarioSection(),
      const TicketsSection(),
      const CajaSection(),
      const VerifactuSection(),
    ];

    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AdminShellController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide     = constraints.maxWidth >= 600;
        final isExtended = constraints.maxWidth >= 900;

        return Scaffold(
          appBar: _buildAppBar(context, ctrl),
          drawer: isWide ? null : _buildDrawer(context, ctrl),
          body: isWide
              ? Row(
                  children: [
                    _buildRail(ctrl, isExtended),
                    const VerticalDivider(width: 1, thickness: 1),
                    Expanded(child: _buildBody(ctrl)),
                  ],
                )
              : _buildBody(ctrl),
        );
      },
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AdminShellController ctrl,
  ) {
    return AppBar(
      title: Obx(
        () => Text(_navItems[ctrl.selectedIndex.value].label),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Cerrar sesión',
          onPressed: () =>
              Navigator.pushReplacementNamed(context, LoginPage.routename),
        ),
      ],
    );
  }

  // ── NavigationRail (wide) ───────────────────────────────────────────────

  Widget _buildRail(AdminShellController ctrl, bool extended) {
    return Obx(
      () => NavigationRail(
        extended: extended,
        selectedIndex: ctrl.selectedIndex.value,
        onDestinationSelected: ctrl.navigateTo,
        destinations: _navItems
            .map(
              (item) => NavigationRailDestination(
                icon: Icon(item.icon),
                label: Text(item.label),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── Drawer (narrow) ─────────────────────────────────────────────────────

  Widget _buildDrawer(BuildContext context, AdminShellController ctrl) {
    final displayName = _user.username ?? _user.email ?? 'Admin';

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.textPrimary),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.secondary,
                  child: Text(
                    displayName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Administrador',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(
              () {
                final currentIndex = ctrl.selectedIndex.value;
                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _navItems.length,
                  itemBuilder: (_, i) {
                    final selected = currentIndex == i;
                    return ListTile(
                    leading: Icon(
                      _navItems[i].icon,
                      color: selected ? Theme.of(context).colorScheme.primary : null,
                    ),
                    title: Text(
                      _navItems[i].label,
                      style: TextStyle(
                        color: selected ? Theme.of(context).colorScheme.primary : null,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    selected: selected,
                    selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
                    onTap: () {
                      ctrl.navigateTo(i);
                      Navigator.pop(context);
                    },
                  );
                },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────────

  Widget _buildBody(AdminShellController ctrl) {
    return Obx(
      () => IndexedStack(
        index: ctrl.selectedIndex.value,
        children: _sections,
      ),
    );
  }
}

// ── Modelo de ítem de navegación ─────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem(this.icon, this.label);
}
