import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../controllers/library_controller.dart';
import '../theme/app_theme.dart';
import '../components/common.dart';
import 'explore_page.dart';
import 'favorites_page.dart';
import 'diary_page.dart';
import 'calendar_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.user});
  final User user;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final LibraryController controller;
  int _index = 0;
  String? _startupError;
  @override
  void initState() {
    super.initState();
    controller = LibraryController(widget.user);
    unawaited(
      controller.initialize().catchError((Object e) {
        if (mounted) {
          setState(
            () => _startupError = 'Não foi possível abrir os dados locais. Reinicie o aplicativo.',
          );
        }
      }),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      if (_startupError != null) {
        return Scaffold(body: EmptyState('Falha ao abrir', _startupError!));
      }
      if (!controller.ready) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              if (!controller.networkAvailable ||
                  controller.pendingCount > 0 ||
                  controller.syncError != null)
                Container(
                  width: double.infinity,
                  color: AppTheme.surface,
                  padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
                  child: Row(
                    children: [
                      Icon(
                        controller.syncing
                            ? Icons.sync
                            : Icons.cloud_off_outlined,
                        size: 17,
                        color: AppTheme.gold,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.syncError ??
                              (controller.pendingCount > 0
                                  ? '${controller.pendingCount} alteração(ões) pendente(s) de envio.'
                                  : 'Sem rede. Exibindo dados desta sessão e pendências locais.'),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sincronizar agora',
                        onPressed: controller.syncing
                            ? null
                            : controller.synchronize,
                        icon: const Icon(Icons.refresh, size: 18),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: IndexedStack(
                  index: _index,
                  children: [
                    ExplorePage(controller: controller),
                    FavoritesPage(controller: controller),
                    DiaryPage(controller: controller),
                    CalendarPage(controller: controller),
                    ProfilePage(controller: controller),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Explorar',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_outline),
              selectedIcon: Icon(Icons.favorite),
              label: 'Favoritos',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Diário',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Calendário',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      );
    },
  );
}
