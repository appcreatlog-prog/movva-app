# MOVVA — Android + Supabase + OpenStreetMap

Esta versão inclui o código de login/cadastro, recuperação de senha, banco remoto, sincronização de atividades e publicação de perfis públicos. O aplicativo ainda precisa ser conectado ao seu próprio projeto Supabase usando as instruções abaixo. Não há credenciais de projeto incluídas no ZIP e eu não consigo executar a configuração dentro da sua conta Supabase por você.

## Recursos implementados
- Cadastro com e-mail e senha, login, sair e pedido de redefinição de senha.
- Perfil público com nome e biografia editáveis.
- Página Comunidade para listar perfis públicos e abrir as atividades publicadas.
- Tabela remota de atividades, incluindo distância, duração, calorias estimadas e pontos GPS da rota.
- Salvamento local e tentativa de sincronização com o Supabase quando há sessão e internet; falhas de rede não apagam o registro local.
- Isolamento por usuário no cache local e políticas RLS no banco.
- Mapa OpenStreetMap e localização GPS do celular durante o registro.

## 1. Criar o projeto Supabase
1. Acesse https://supabase.com e crie um projeto.
2. No projeto, abra **Project Settings > API** (ou **Connect**, dependendo da interface).
3. Copie o **Project URL** e a chave pública **anon / publishable**.
4. **Nunca use a chave `service_role` no aplicativo.** A chave pública é protegida pelas políticas RLS incluídas no SQL.

## 2. Criar tabelas e políticas de segurança
1. Abra **SQL Editor** no painel Supabase.
2. Abra o arquivo `supabase/movva_schema.sql` que vem neste pacote.
3. Copie todo o conteúdo, cole no SQL Editor e pressione **Run**.
4. Confirme que as tabelas `profiles` e `activities` aparecem em **Table Editor**.

O SQL cria os perfis automaticamente quando uma conta é criada, ativa RLS e permite leitura pública dos perfis e atividades dos usuários cujo perfil está público. Cada usuário só pode inserir, alterar ou excluir as próprias atividades.

## 3. Configurar confirmação de e-mail
No Supabase, abra **Authentication > URL Configuration** e configure as URLs do seu ambiente. Em **Authentication > Providers > Email**, você pode exigir confirmação por e-mail. Se a confirmação estiver ligada, a pessoa precisa confirmar o endereço antes de entrar. Para teste rápido, a confirmação pode ser desativada nas configurações do provedor, se isso fizer sentido para seu ambiente.

## 4. Preparar no Windows
Requisitos: Flutter SDK, Android Studio e Android SDK. Extraia o ZIP para uma pasta simples, por exemplo `C:\Projetos\MOVVA`.

Na pasta que contém `pubspec.yaml`, execute:
```bat
flutter create --platforms=android --org com.movva .
flutter pub get
```
Se solicitado, preserve `lib/`, `pubspec.yaml` e `supabase/`.

Adicione ao arquivo `android/app/src/main/AndroidManifest.xml`, dentro de `<manifest>` e antes de `<application>`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>
```

## 5. Executar com seu Supabase
Abra o Prompt de Comando na pasta do projeto e substitua os valores abaixo pelos do seu projeto:
```bat
flutter run --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co --dart-define=SUPABASE_ANON_KEY=SUA_CHAVE_PUBLICA
```
Para rodar no Android, ative Opções do desenvolvedor e Depuração USB, conecte o celular e aceite a autorização.

Para gerar um APK de teste:
```bat
flutter build apk --release --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co --dart-define=SUPABASE_ANON_KEY=SUA_CHAVE_PUBLICA
```
O APK deverá aparecer em `build\app\outputs\flutter-apk\app-release.apk`. Não gere nem compartilhe o APK com a URL/chave de outro projeto.

## Como testar a integração
1. Abra o app e crie uma conta.
2. Entre com e-mail e senha (confirme o e-mail caso o projeto exija confirmação).
3. No Supabase > Table Editor, confirme que existe uma linha em `profiles`.
4. Edite o nome/biografia na página Perfil e salve; confirme a atualização em `profiles`.
5. Registre uma atividade com GPS. Com internet, ela deve aparecer em `activities`.
6. Abra **Perfil > Explorar perfis públicos** e confira o perfil publicado.
7. Teste offline e online. O salvamento local não garante que toda operação remota tenha sido concluída; reconecte à internet e abra Histórico para disparar nova tentativa de sincronização.

## Privacidade importante
Você escolheu perfil público. O nome, a biografia e as atividades de um perfil público ficam visíveis para outras pessoas que usam o app e podem ser consultados via API pública do Supabase. O código atual também salva pontos GPS da rota na atividade pública; isso pode revelar locais de início/fim e deslocamentos. Evite rotas que exponham endereço residencial ou outros locais privados. A chave anon/publicável não é senha: a segurança depende das políticas RLS do SQL.

## Limitações e testes necessários
- Não foi possível compilar/testar em aparelho físico neste ambiente. Execute `flutter analyze` e teste o app no Android antes de distribuir.
- A sincronização é uma estratégia simples: guarda localmente e tenta enviar quando o histórico é aberto ou uma atividade é salva; não é um serviço de sincronização em segundo plano garantido.
- Rastreamento GPS com a tela apagada depende de permissões e configuração adicionais do Android e deve ser testado no dispositivo.
- A tela de comunidade lista perfis públicos, mas não há ainda sistema de seguidores, curtidas, comentários, feed social ou upload de foto de perfil.
- Calorias são estimativas genéricas.

## Estrutura
- `lib/auth_pages.dart`: login, cadastro, redefinição de senha e tela de configuração.
- `lib/activity_repository.dart`: cache local e sincronização remota.
- `lib/public_profiles_page.dart`: lista de perfis e detalhe público.
- `lib/main.dart`: dashboard, histórico, desafios e perfil.
- `lib/registrar_page.dart`: GPS e mapa OpenStreetMap.
- `supabase/movva_schema.sql`: tabelas, trigger de criação de perfil, índices e políticas RLS.
