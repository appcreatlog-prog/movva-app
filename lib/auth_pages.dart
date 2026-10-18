import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend_config.dart';
import 'main.dart' show Cores;

class AuthGate extends StatelessWidget {
  final Widget child;
  const AuthGate({super.key, required this.child});
  @override Widget build(BuildContext context) {
    if (!BackendConfig.configured || BackendConfig.client == null) return const SupabaseSetupPage();
    final client = BackendConfig.client!;
    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (client.auth.currentSession != null) return child;
        return const LoginPage();
      },
    );
  }
}

class SupabaseSetupPage extends StatelessWidget {
  const SupabaseSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.fundo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, color: Cores.laranja, size: 56),
                const Text(
                  'MOVVA',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 5,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Conecte seu projeto Supabase para ativar login, banco remoto e perfis públicos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Cores.mudo),
                ),
                const SizedBox(height: 18),
                const Text(
                  'No Windows, execute o app com --dart-define=SUPABASE_URL=... '
                  'e --dart-define=SUPABASE_ANON_KEY=...\n'
                  'Depois execute o arquivo supabase/movva_schema.sql '
                  'no SQL Editor do Supabase.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _signup = false, _busy = false, _hide = true;
  String? _error, _message;
  @override void dispose() { _email.dispose(); _password.dispose(); _name.dispose(); super.dispose(); }

  Future<void> _submit() async {
    setState(() { _busy = true; _error = null; _message = null; });
    try {
      final auth = BackendConfig.client!.auth;
      if (_signup) {
        final response = await auth.signUp(email: _email.text.trim(), password: _password.text, data: {'display_name': _name.text.trim().isEmpty ? _email.text.trim().split('@').first : _name.text.trim(), 'is_public': true});
        if (response.session == null) {
          _message = 'Conta criada. Confira seu e-mail para confirmar o cadastro e depois entre no MOVVA.';
        } else {
          _message = 'Conta criada com sucesso!';
        }
      } else {
        await auth.signInWithPassword(email: _email.text.trim(), password: _password.text);
      }
    } on AuthException catch (e) { _error = e.message; }
      catch (e) { _error = 'Não foi possível conectar. Verifique internet e configuração do Supabase.'; }
    if (mounted) setState(() { _busy = false; });
  }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: Cores.fundo,
    body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Icon(Icons.bolt_rounded, color: Cores.laranja, size: 54),
      const Center(child: Text('MOVVA', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 5))),
      const SizedBox(height: 8), Center(child: Text(_signup ? 'Crie sua conta de atleta' : 'Entre para continuar', style: const TextStyle(color: Cores.mudo))),
      const SizedBox(height: 28),
      if (_signup) ...[
        TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nome público', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder())),
        const SizedBox(height: 12),
      ],
      TextField(controller: _email, keyboardType: TextInputType.emailAddress, autocorrect: false, decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: _password, obscureText: _hide, decoration: InputDecoration(labelText: 'Senha (mínimo 6 caracteres)', prefixIcon: const Icon(Icons.lock_outline), border: const OutlineInputBorder(), suffixIcon: IconButton(onPressed: ()=>setState(()=>_hide=!_hide), icon: Icon(_hide?Icons.visibility:Icons.visibility_off)))),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: Colors.redAccent))),
      if (_message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_message!, style: const TextStyle(color: Colors.lightGreenAccent))),
      const SizedBox(height: 18),
      FilledButton(onPressed: _busy ? null : _submit, style: FilledButton.styleFrom(backgroundColor: Cores.laranja, padding: const EdgeInsets.symmetric(vertical: 15)), child: _busy ? const SizedBox(width: 20,height:20,child:CircularProgressIndicator(strokeWidth:2)) : Text(_signup ? 'Criar conta' : 'Entrar')),
      TextButton(onPressed: _busy ? null : ()=>setState(()=>_signup=!_signup), child: Text(_signup ? 'Já tenho uma conta — entrar' : 'Não tenho conta — cadastrar')),
      if (!_signup) TextButton(onPressed: _busy ? null : _resetPassword, child: const Text('Esqueci minha senha')),
      const SizedBox(height: 10), const Text('Ao criar a conta, seu perfil fica público por padrão. Não publique informações pessoais sensíveis.', textAlign: TextAlign.center, style: TextStyle(color: Cores.mudo, fontSize: 11)),
    ]))))),
  );

  Future<void> _resetPassword() async {
    if (_email.text.trim().isEmpty) { setState(()=>_error='Informe seu e-mail primeiro.'); return; }
    try {
      await BackendConfig.client!.auth.resetPasswordForEmail(_email.text.trim());
      setState(()=>_message='Se o e-mail estiver cadastrado, você receberá instruções para redefinir a senha.');
    } catch (_) { setState(()=>_error='Não foi possível solicitar a redefinição agora.'); }
  }
}
