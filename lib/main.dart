import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';

import 'theme/app_theme.dart';
import 'view/auth_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  String? error;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // O SQLite é a fila explícita. Não manter um segundo cache persistente
    // de registros já sincronizados, conforme a limpeza exigida no trabalho.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  } catch (e) {
    error = 'Configure o projeto Firebase para habilitar a autenticação e os dados.';
  }
  runApp(PourfolioApp(configurationError: error));
}

class PourfolioApp extends StatelessWidget {
  const PourfolioApp({super.key, this.configurationError});
  final String? configurationError;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Pourfolio',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    locale: const Locale('pt', 'BR'),
    supportedLocales: const [Locale('pt', 'BR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: configurationError == null
        ? const AuthPage()
        : ConfigurationPage(message: configurationError!),
  );
}

class ConfigurationPage extends StatelessWidget {
  const ConfigurationPage({super.key, required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.local_bar_outlined,
                  color: AppTheme.gold,
                  size: 56,
                ),
                const SizedBox(height: 24),
                const Text('Pourfolio', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(fontSize: 19, height: 1.5),
                ),
                const SizedBox(height: 18),
                const Text(
                  'A conexão com o Firebase ainda não foi configurada neste Android. Siga o passo a passo em docs/CONFIGURACAO_FIREBASE.md e execute novamente.',
                  style: TextStyle(color: Colors.white60, height: 1.6),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
