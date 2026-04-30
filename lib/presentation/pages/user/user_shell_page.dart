// lib/presentation/pages/user/user_shell_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/app_routes.dart';
import '../../../config/theme.dart';
import '../../../data/models/user.dart';
import '../../controllers/admin_shell_controller.dart';
import '../admin/sections/personal_area_section.dart';
import '../admin/sections/sala_section.dart';
import '../admin/sections/tickets_section.dart';
import '../admin/sections/inventario_section.dart';

class UserShellPage extends StatefulWidget {
  const UserShellPage({super.key});

  @override
  State<UserShellPage> createState() => _UserShellPageState();
}

class _UserShellPageState extends State<UserShellPage> {
  late User _user;
  late List<Widget> _sections;
  bool _initialized = false;

  static const _navItems = [
    _NavItem(Icons.person_outline,       'Mi perfil'),
    _NavItem(Icons.table_chart_outlined, 'Sala'),
    _NavItem(Icons.receipt_long,         'Tickets'),
    _NavItem(Icons.inventory_2,          'Inventario'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final args = Get.arguments;
    _user = args is User ? args : User();

    _sections = [
      PersonalAreaSection(user: _user),
      const SalaSection(),
      const TicketsSection(),
      const InventarioSection(),
    ];

    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AdminShellController>();
    // Reset to first section when entering user shell
    ctrl.selectedIndex.value = ctrl.selectedIndex.value.clamp(0, _navItems.length - 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide     = constraints.maxWidth >= 600;
        final isExtended = constraints.maxWidth >= 900;

        return Scaffold(
          primary: false,
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

  PreferredSizeWidget _buildAppBar(BuildContext context, AdminShellController ctrl) {
    return AppBar(
      primary: false,
      title: Obx(() {
        final idx = ctrl.selectedIndex.value.clamp(0, _navItems.length - 1);
        return Text(_navItems[idx].label);
      }),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Cerrar sesión',
          onPressed: () => Get.offNamed(AppRoutes.login),
        ),
      ],
    );
  }

  Widget _buildRail(AdminShellController ctrl, bool extended) {
    return Obx(
      () => NavigationRail(
        extended: extended,
        selectedIndex: ctrl.selectedIndex.value.clamp(0, _navItems.length - 1),
        onDestinationSelected: (i) => ctrl.selectedIndex.value = i,
        destinations: _navItems
            .map((item) => NavigationRailDestination(
                  icon:  Icon(item.icon),
                  label: Text(item.label),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AdminShellController ctrl) {
    final displayName = _user.username ?? _user.email ?? 'Usuario';
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: AppTheme.primary),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  radius: 28,
                  child: Text(
                    displayName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
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
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Empleado',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.70), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(
              () => ListView.builder(
                itemCount: _navItems.length,
                itemBuilder: (_, i) {
                  final item     = _navItems[i];
                  final selected = ctrl.selectedIndex.value == i;
                  return ListTile(
                    leading:  Icon(item.icon, color: selected ? AppTheme.primary : null),
                    title:    Text(item.label),
                    selected: selected,
                    onTap: () {
                      ctrl.selectedIndex.value = i;
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title:   const Text('Cerrar sesión'),
            onTap:   () => Get.offNamed(AppRoutes.login),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBody(AdminShellController ctrl) {
    return Obx(() {
      final idx = ctrl.selectedIndex.value.clamp(0, _sections.length - 1);
      return _sections[idx];
    });
  }
}

class _NavItem {
  final IconData icon;
  final String   label;
  const _NavItem(this.icon, this.label);
}
