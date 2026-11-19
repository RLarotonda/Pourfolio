import 'package:flutter/material.dart';

import '../service/auth_service.dart';
import '../theme/app_theme.dart';
import '../components/common.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _email = TextEditingController();
  final _password = TextEditingController(),
      _confirmation = TextEditingController();
  bool _register = false, _busy = false, _hide = true;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  String? _emailError(String? value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value?.trim() ?? '')
      ? null
      : 'Informe um e-mail válido.';
  Future<void> _submit() async {
    if (!_form.currentState!.validate()) {
      return;
    }
    setState(() => _busy = true);
    try {
      final auth = AuthService();
      if (_register) {
        await auth.register(_name.text, _email.text, _password.text);
      } else {
        await auth.login(_email.text, _password.text);
      }
    } catch (e) {
      if (mounted) {
        notice(context, AuthService.message(e));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _reset() async {
    if (_emailError(_email.text) != null) {
      notice(context, 'Preencha um e-mail válido para recuperar a senha.');
      return;
    }
    setState(() => _busy = true);
    try {
      await AuthService().reset(_email.text);
      if (mounted) {
        notice(
          context,
          'Solicitação enviada. Confira seu e-mail e a pasta de spam.',
        );
      }
    } catch (e) {
      if (mounted) {
        notice(context, AuthService.message(e));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: AutofillGroup(
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.local_bar_outlined,
                      size: 56,
                      color: AppTheme.gold,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'POURFOLIO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34,
                        fontFamily: 'PlayfairDisplay',
                        letterSpacing: 5,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'BOAS RECEITAS. NOVAS HISTÓRIAS.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2,
                        color: AppTheme.gold,
                      ),
                    ),
                    const SizedBox(height: 42),
                    Text(
                      _register
                          ? 'Crie sua conta'
                          : 'Seu próximo favorito\ncomeça aqui.',
                      style: const TextStyle(
                        fontSize: 29,
                        fontFamily: 'PlayfairDisplay',
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _register
                          ? 'Organize receitas e guarde suas experiências.'
                          : 'Entre para descobrir, avaliar e lembrar.',
                      style: const TextStyle(color: Colors.white60),
                    ),
                    const SizedBox(height: 28),
                    if (_register) ...[
                      TextFormField(
                        controller: _name,
                        enabled: !_busy,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        decoration: const InputDecoration(
                          labelText: 'Nome completo',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            (v?.trim().split(RegExp(r'\s+')).length ?? 0) < 2
                            ? 'Informe nome e sobrenome.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _email,
                      enabled: !_busy,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: _emailError,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      enabled: !_busy,
                      obscureText: _hide,
                      autofillHints: [
                        _register
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _hide ? 'Mostrar senha' : 'Ocultar senha',
                          onPressed: () => setState(() => _hide = !_hide),
                          icon: Icon(
                            _hide
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (v) => (v?.length ?? 0) < 6
                          ? 'Use pelo menos 6 caracteres.'
                          : null,
                    ),
                    if (_register) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmation,
                        enabled: !_busy,
                        obscureText: _hide,
                        decoration: const InputDecoration(
                          labelText: 'Confirme a senha',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (v) => v != _password.text
                            ? 'As senhas não conferem.'
                            : null,
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (!_register)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _busy ? null : _reset,
                          child: const Text('Esqueci minha senha'),
                        ),
                      ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_register ? 'Criar conta' : 'Entrar'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _register = !_register;
                              _form.currentState?.reset();
                            }),
                      child: Text(
                        _register
                            ? 'Já tenho uma conta'
                            : 'Ainda não tem conta? Cadastre-se',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
