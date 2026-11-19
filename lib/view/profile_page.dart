import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../controllers/library_controller.dart';
import '../service/auth_service.dart';
import '../theme/app_theme.dart';
import '../components/common.dart';
import 'collections_page.dart';
import 'favorites_page.dart';
import 'diary_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.controller});
  final LibraryController controller;
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser ?? controller.user;
    final diary = controller.diary;
    final average = diary.isEmpty
        ? null
        : diary.fold<int>(0, (sum, e) => sum + e.rating) / diary.length;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 14),
        const Align(
          alignment: Alignment.centerLeft,
          child: CircleAvatar(
            radius: 38,
            backgroundColor: Color(0xFF351B32),
            child: Icon(Icons.person_outline, size: 36, color: AppTheme.gold),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          user.displayName ?? 'Seu perfil',
          style: const TextStyle(
            fontSize: 30,
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Text(user.email ?? '', style: const TextStyle(color: Colors.white60)),
        const SizedBox(height: 28),
        Wrap(
          spacing: 24,
          runSpacing: 14,
          children: [
            _stat('${controller.favorites.length}', 'Favoritos'),
            _stat('${diary.length}', 'Experiências'),
            _stat(average?.toStringAsFixed(1) ?? '—', 'Nota média'),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Estatísticas dos dados disponíveis nesta sessão.',
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
        const SizedBox(height: 30),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.favorite_outline),
          title: const Text('Favoritos'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar: AppBar(),
                body: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) =>
                      FavoritesPage(controller: controller),
                ),
              ),
            ),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.collections_bookmark_outlined),
          title: const Text('Coleções'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => CollectionsPage(controller: controller),
            ),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.menu_book_outlined),
          title: const Text('Histórico pessoal'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => DiarioProfile(controller: controller),
            ),
          ),
        ),
        const Divider(height: 32),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            controller.syncing ? Icons.sync : Icons.cloud_upload_outlined,
          ),
          title: Text('${controller.pendingCount} alteração(ões) pendente(s)'),
          subtitle: const Text('Após confirmação, a fila local é limpa.'),
          onTap: controller.syncing ? null : controller.synchronize,
        ),
        if (controller.syncError != null)
          Text(
            controller.syncError!,
            style: const TextStyle(color: AppTheme.gold),
          ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () async {
            final message = controller.pendingCount > 0
                ? 'Há alterações salvas neste aparelho aguardando envio. Elas pertencem a esta conta e serão reenviadas quando você entrar nela novamente.'
                : 'Deseja encerrar a sessão?';
            if (!await confirm(context, 'Sair da conta?', message)) {
              return;
            }
            try {
              await AuthService().logout();
            } catch (e) {
              if (context.mounted) {
                notice(context, AuthService.message(e));
              }
            }
          },
          icon: const Icon(Icons.logout),
          label: const Text('Sair da conta'),
        ),
        const SizedBox(height: 30),
        const Text(
          'POURFOLIO\nRafael Larotonda & Luana Cosmo',
          style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.8),
        ),
      ],
    );
  }

  Widget _stat(String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 29,
          fontFamily: 'PlayfairDisplay',
          color: AppTheme.gold,
        ),
      ),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.white60)),
    ],
  );
}

class DiarioProfile extends StatelessWidget {
  const DiarioProfile({super.key, required this.controller});
  final LibraryController controller;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => DiaryPage(controller: controller),
  );
}
