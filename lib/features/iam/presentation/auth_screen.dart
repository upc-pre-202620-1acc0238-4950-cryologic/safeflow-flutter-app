import 'package:flutter/material.dart';

import '../../../core/theme/safeflow_theme.dart';
import '../../../core/widgets/safe_flow_widgets.dart';
import '../../workspace/application/workspace_controller.dart';

enum _AuthMode { login, register, recover, verification }

class SafeFlowAuthScreen extends StatefulWidget {
  const SafeFlowAuthScreen({super.key, required this.controller});
  final WorkspaceController controller;

  @override
  State<SafeFlowAuthScreen> createState() => _SafeFlowAuthScreenState();
}

class _SafeFlowAuthScreenState extends State<SafeFlowAuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _terms = false;
  _AuthMode _mode = _AuthMode.login;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _validEmail =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_email.text.trim());
  bool get _validPassword =>
      _password.text.length >= 8 &&
      RegExp(r'[A-Za-z]').hasMatch(_password.text) &&
      RegExp(r'\d').hasMatch(_password.text) &&
      RegExp(r'[^A-Za-z0-9\s]').hasMatch(_password.text);

  Future<void> _submit() async {
    final controller = widget.controller;
    if (_mode == _AuthMode.login) {
      await controller.signIn(_email.text, _password.text);
    } else if (_mode == _AuthMode.register) {
      await controller.signUp(_email.text, _password.text);
      if (mounted && controller.error == null) {
        setState(() => _mode = _AuthMode.verification);
      }
    } else if (_mode == _AuthMode.recover) {
      await controller.requestRecovery(_email.text);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SafeFlowBrand(subtitle: 'Control de cadena de frío'),
                  const SizedBox(height: 38),
                  if (_mode == _AuthMode.verification)
                    _verification()
                  else
                    _form(),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _form() {
    final register = _mode == _AuthMode.register;
    final recovery = _mode == _AuthMode.recover;
    final controller = widget.controller;
    final title = register
        ? 'Crear cuenta'
        : recovery
        ? 'Recuperar acceso'
        : 'Iniciar sesión';
    final subtitle = register
        ? 'Crea tu identidad para acceder a SafeFlow.'
        : recovery
        ? 'Ingresa el correo de tu cuenta.'
        : 'Supervisa la cadena de frío de tus productos.';
    final passwordValid = _validPassword;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: SafeFlowColors.textSecondary),
        ),
        const SizedBox(height: 28),
        SafeFlowInput(
          label: 'Correo electrónico',
          controller: _email,
          hint: 'nombre@organizacion.com',
          helper: register ? 'Será tu identificador de acceso.' : null,
          onChanged: (_) => setState(() {}),
          error: _email.text.isNotEmpty && !_validEmail
              ? 'Ingresa un correo electrónico válido.'
              : null,
        ),
        if (!recovery) ...[
          const SizedBox(height: 18),
          SafeFlowInput(
            label: 'Contraseña',
            controller: _password,
            password: true,
            hint: '••••••••••',
            onChanged: (_) => setState(() {}),
            helper: register
                ? 'Mínimo 8 caracteres, una letra, un número y un símbolo.'
                : 'Tu contraseña se mantiene oculta.',
            error: register && _password.text.isNotEmpty && !passwordValid
                ? 'La contraseña no cumple las reglas de seguridad.'
                : null,
          ),
        ],
        if (register) ...[
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _terms,
            onChanged: (value) => setState(() => _terms = value ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Acepto los términos y condiciones.'),
          ),
        ],
        if (controller.error != null) ...[
          const SizedBox(height: 16),
          SafeFlowCallout(
            title: 'No se pudo completar',
            message: controller.error!,
            tone: SafeFlowTone.critical,
          ),
        ],
        if (recovery && controller.notice != null) ...[
          const SizedBox(height: 16),
          SafeFlowCallout(
            title: 'Solicitud registrada',
            message: controller.notice!,
          ),
        ],
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed:
                controller.busy ||
                    !_validEmail ||
                    (!recovery && _password.text.isEmpty) ||
                    (register && (!passwordValid || !_terms))
                ? null
                : _submit,
            child: controller.busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    register
                        ? 'Crear cuenta'
                        : recovery
                        ? 'Solicitar recuperación'
                        : 'Iniciar sesión',
                  ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: controller.busy
                ? null
                : () => setState(() {
                    controller.error = null;
                    controller.notice = null;
                    _mode = register || recovery
                        ? _AuthMode.login
                        : _AuthMode.register;
                  }),
            child: Text(
              register || recovery ? 'Volver a iniciar sesión' : 'Crear cuenta',
            ),
          ),
        ),
        if (!register && !recovery) ...[
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: controller.busy
                  ? null
                  : () => setState(() {
                      controller.error = null;
                      controller.notice = null;
                      _mode = _AuthMode.recover;
                    }),
              child: const Text('Recuperar acceso'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _verification() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Cuenta creada', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 18),
      SafeFlowCallout(
        title: 'Revisa la siguiente etapa',
        message:
            'Tu cuenta de OPERADOR quedó registrada. El envío de correos está pendiente. No has iniciado sesión.',
        tone: SafeFlowTone.success,
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => setState(() {
            _mode = _AuthMode.login;
            widget.controller.notice = null;
            widget.controller.error = null;
          }),
          child: const Text('Volver a iniciar sesión'),
        ),
      ),
    ],
  );
}
