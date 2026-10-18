import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'activity_model.dart';
import 'activity_repository.dart';
import 'backend_config.dart';
import 'registrar_page.dart';
import 'auth_pages.dart';
import 'public_profiles_page.dart';
import 'movva_home_page.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try { await BackendConfig.initialize(); } catch (e) {
    debugPrint('Supabase indisponível; o app seguirá no modo local: $e');
  }
  runApp(const MovvaApp());
}

class Cores {
  static const fundo = Color(0xFF0B0B0D);
  static const card = Color(0xFF16161A);
  static const linha = Color(0xFF2A2A30);
  static const texto = Color(0xFFF4F4F5);
  static const mudo = Color(0xFF9A9AA3);
  static const laranja = Color(0xFFFF4D1A);
  static const laranja2 = Color(0xFFFF7A3D);
  static const brilho = Color(0x59FF4D1A);
}

class MovvaApp extends StatelessWidget {
  const MovvaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MOVVA', debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark, scaffoldBackgroundColor: Cores.fundo,
      colorScheme: const ColorScheme.dark(primary: Cores.laranja, surface: Cores.card),
      fontFamily: 'Roboto', useMaterial3: true,
    ),
    home: const AuthGate(child: Shell()),
  );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override State<Shell> createState() => _ShellState();
}
class _ShellState extends State<Shell> {
  int aba = 0;
  final repo = ActivityRepository();
  int refreshKey = 0;

  Future<void> _registrar([String modo = 'Corrida']) async {
    final resumo = await Navigator.of(context).push<Resumo>(
      MaterialPageRoute(builder: (_) => RegistrarPage(modo: modo)),
    );
    if (resumo == null || !mounted) return;
    final record = ActivityRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      mode: resumo.modo, date: DateTime.now(), seconds: resumo.segundos,
      meters: resumo.metros, calories: resumo.calorias,
      points: resumo.pontos.map((p) => [p.latitude, p.longitude]).toList(),
    );
    await repo.save(record);
    if (!mounted) return;
    setState(() => refreshKey++);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Atividade salva neste aparelho.')),
    );
  }

  @override Widget build(BuildContext context) {
    final pages = [
      HomePage(repo: repo, onStart: _registrar, refreshKey: refreshKey, onNavigate: (i) => setState(() => aba = i)),
      ExplorePage(repo: repo, refreshKey: refreshKey),
      const SizedBox.shrink(),
      ChallengesPage(repo: repo, refreshKey: refreshKey),
      ProfilePage(repo: repo, refreshKey: refreshKey),
    ];
    const items = [
      (Icons.home_rounded, 'Início'), (Icons.explore_outlined, 'Histórico'),
      (Icons.play_circle_fill_rounded, 'Registrar'),
      (Icons.emoji_events_outlined, 'Desafios'), (Icons.person_outline, 'Perfil'),
    ];
    return Scaffold(
      body: SafeArea(bottom: false, child: pages[aba]),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: Cores.card, border: Border(top: BorderSide(color: Cores.linha))),
        child: SafeArea(top: false, child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            for (var i=0; i<items.length; i++)
              InkWell(
                onTap: () { if (i == 2) { _registrar(); } else { setState(() => aba=i); } },
                borderRadius: BorderRadius.circular(12),
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(items[i].$1, color: (aba==i || i==2) ? Cores.laranja : Cores.mudo, size: i==2 ? 34 : 23),
                    Text(items[i].$2, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: (aba==i || i==2) ? Cores.laranja : Cores.mudo)),
                  ]),
                ),
              ),
          ]),
        )),
      ),
    );
  }
}

String fmtTime(int s) {
  final h=s~/3600, m=(s%3600)~/60, sec=s%60;
  String p(int n)=>n.toString().padLeft(2,'0');
  return h>0 ? '${p(h)}:${p(m)}:${p(sec)}' : '${p(m)}:${p(sec)}';
}
String fmtKm(double km) => km.toStringAsFixed(2).replaceAll('.', ',');
String fmtPace(ActivityRecord r) => r.km > 0.02 ? fmtTime((r.seconds/r.km).round()) : '--:--';

class HomePageAntiga extends StatelessWidget {
  final ActivityRepository repo; final VoidCallback onStart; final int refreshKey;
  const HomePageAntiga({super.key, required this.repo, required this.onStart, required this.refreshKey});
  @override Widget build(BuildContext context) => FutureBuilder<List<ActivityRecord>>(
    key: ValueKey(refreshKey), future: repo.getAll(),
    builder: (context, snap) {
      final list=snap.data ?? [];
      final km=list.fold<double>(0,(s,a)=>s+a.km);
      final secs=list.fold<int>(0,(s,a)=>s+a.seconds);
      return ListView(padding: EdgeInsets.zero, children: [
        Container(padding: const EdgeInsets.fromLTRB(20,22,20,28),
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter,end: Alignment.bottomRight,
              colors:[Color(0xFF1C3A63),Color(0xFF7A3B4A),Cores.laranja]),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(26))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children:[Icon(Icons.bolt_rounded,size:30),SizedBox(width:8),
              Text('MOVVA',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900,letterSpacing:5)),
              Spacer(),CircleAvatar(backgroundColor:Cores.laranja,child:Text('A'))]),
            const SizedBox(height:30),
            const Text('Olá, atleta! Pronto para hoje?',style:TextStyle(fontSize:14)),
            const SizedBox(height:8),
            const Text('MOVIMENTO\\nÉ EVOLUÇÃO.',style:TextStyle(fontSize:32,fontWeight:FontWeight.w900,height:1.05)),
            const SizedBox(height:10),
            const Text('Cada atividade conta. Registre seu próximo desafio.',style:TextStyle(color:Color(0xDDFFFFFF))),
            const SizedBox(height:18),
            FilledButton.icon(onPressed:onStart, icon:const Icon(Icons.play_arrow_rounded),
              label:const Text('Iniciar atividade'), style:FilledButton.styleFrom(backgroundColor:Cores.laranja,foregroundColor:Colors.white)),
          ]),
        ),
        Padding(padding:const EdgeInsets.fromLTRB(16,18,16,8),child:Text('SEU RESUMO',style:TextStyle(color:Cores.mudo,fontWeight:FontWeight.bold,letterSpacing:1.2))),
        Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:Row(children:[
          _stat('DISTÂNCIA', '${fmtKm(km)} km', Icons.route),
          _stat('ATIVIDADES', '${list.length}', Icons.fitness_center),
          _stat('TEMPO', fmtTime(secs), Icons.timer_outlined),
        ])),
        const Padding(padding:EdgeInsets.fromLTRB(16,24,16,8),child:Text('DESAFIO DA SEMANA',style:TextStyle(fontWeight:FontWeight.bold,letterSpacing:1))),
        Container(margin:const EdgeInsets.symmetric(horizontal:14),padding:const EdgeInsets.all(16),
          decoration:BoxDecoration(color:Cores.card,border:Border.all(color:Cores.linha),borderRadius:BorderRadius.circular(18)),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Row(children:[Icon(Icons.emoji_events,color:Cores.laranja,size:30),SizedBox(width:10),
              Expanded(child:Text('Meta pessoal: 20 km',style:TextStyle(fontWeight:FontWeight.bold,fontSize:16)))]),
            const SizedBox(height:10),LinearProgressIndicator(value:(km/20).clamp(0,1),color:Cores.laranja,backgroundColor:Cores.linha,minHeight:7),
            const SizedBox(height:6),Text('${fmtKm(km)} de 20,00 km registrados',style:const TextStyle(color:Cores.mudo,fontSize:12)),
          ])),
        const Padding(padding:EdgeInsets.fromLTRB(16,24,16,8),child:Text('ATIVIDADES RECENTES',style:TextStyle(fontWeight:FontWeight.bold,letterSpacing:1))),
        if(list.isEmpty) const Padding(padding:EdgeInsets.all(20),child:Text('Suas atividades salvas aparecerão aqui.',style:TextStyle(color:Cores.mudo))),
        ...list.take(3).map((a)=>ActivityTile(record:a)),
        const SizedBox(height:20),
      ]);
    });
}

Widget _stat(String title,String value,IconData icon)=>Expanded(child:Container(
  margin:const EdgeInsets.all(4),padding:const EdgeInsets.all(12),
  decoration:BoxDecoration(color:Cores.card,border:Border.all(color:Cores.linha),borderRadius:BorderRadius.circular(15)),
  child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Icon(icon,color:Cores.laranja,size:20),const SizedBox(height:8),
    Text(value,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:16)),
    Text(title,style:const TextStyle(color:Cores.mudo,fontSize:9)),
  ])));

class ActivityTile extends StatelessWidget {
  final ActivityRecord record; const ActivityTile({super.key,required this.record});
  @override Widget build(BuildContext context)=>Container(
    margin:const EdgeInsets.symmetric(horizontal:14,vertical:4),padding:const EdgeInsets.all(13),
    decoration:BoxDecoration(color:Cores.card,borderRadius:BorderRadius.circular(14),border:Border.all(color:Cores.linha)),
    child:Row(children:[
      CircleAvatar(backgroundColor:Cores.brilho,child:Icon(record.mode=='Pedal'?Icons.directions_bike:Icons.directions_run,color:Cores.laranja)),
      const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(record.mode,style:const TextStyle(fontWeight:FontWeight.bold)),
        Text('${record.date.day.toString().padLeft(2,'0')}/${record.date.month.toString().padLeft(2,'0')}/${record.date.year} • ${fmtTime(record.seconds)}',style:const TextStyle(color:Cores.mudo,fontSize:11)),
      ])),
      Text('${fmtKm(record.km)} km',style:const TextStyle(fontWeight:FontWeight.bold,color:Cores.laranja2)),
    ]));
}

class ExplorePage extends StatefulWidget {
  final ActivityRepository repo; final int refreshKey;
  const ExplorePage({super.key,required this.repo,required this.refreshKey});
  @override State<ExplorePage> createState()=>_ExplorePageState();
}
class _ExplorePageState extends State<ExplorePage> {
  String filter='Todas';
  @override Widget build(BuildContext context)=>FutureBuilder<List<ActivityRecord>>(
    key:ValueKey(widget.refreshKey),future:widget.repo.getAll(),
    builder:(context,snap){
      final all=snap.data??[];
      final list=filter=='Todas'?all:all.where((a)=>a.mode==filter).toList();
      return Scaffold(backgroundColor:Cores.fundo,appBar:AppBar(title:const Text('Histórico'),backgroundColor:Cores.fundo),
        body:Column(children:[
          Padding(padding:const EdgeInsets.all(12),child:Wrap(spacing:8,children:[
            for(final f in ['Todas','Corrida','Pedal']) ChoiceChip(label:Text(f),selected:filter==f,onSelected:(_)=>setState(()=>filter=f),selectedColor:Cores.brilho),
          ])),
          Expanded(child:list.isEmpty?const Center(child:Text('Nenhuma atividade salva ainda.',style:TextStyle(color:Cores.mudo))):
            ListView(children:list.map((a)=>ActivityTile(record:a)).toList())),
        ]));
    });
}

class ChallengesPage extends StatelessWidget {
  final ActivityRepository repo; final int refreshKey;
  const ChallengesPage({super.key,required this.repo,required this.refreshKey});
  @override Widget build(BuildContext context)=>FutureBuilder<List<ActivityRecord>>(
    key:ValueKey(refreshKey),future:repo.getAll(),
    builder:(context,snap){
      final all=snap.data??[];
      final now=DateTime.now();
      final weekStart=now.subtract(Duration(days:now.weekday-1));
      final km=all.where((a)=>a.date.isAfter(DateTime(weekStart.year,weekStart.month,weekStart.day))).fold<double>(0,(s,a)=>s+a.km);
      final progress=(km/20).clamp(0.0,1.0);
      return Scaffold(backgroundColor:Cores.fundo,appBar:AppBar(title:const Text('Desafios'),backgroundColor:Cores.fundo),
        body:ListView(padding:const EdgeInsets.all(16),children:[
          const Text('SUPERE SEU LIMITE',style:TextStyle(color:Cores.mudo,letterSpacing:1.3)),
          const SizedBox(height:12),
          Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Cores.card,borderRadius:BorderRadius.circular(18),border:Border.all(color:Cores.linha)),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              const Icon(Icons.emoji_events,color:Cores.laranja,size:38),
              const SizedBox(height:12),const Text('20 km na semana',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),
              const Text('Meta pessoal • segunda a domingo',style:TextStyle(color:Cores.mudo)),
              const SizedBox(height:18),LinearProgressIndicator(value:progress,color:Cores.laranja,backgroundColor:Cores.linha,minHeight:8),
              const SizedBox(height:8),Text('${fmtKm(km)} / 20,00 km',style:const TextStyle(fontWeight:FontWeight.bold)),
              const SizedBox(height:6),const Text('Etapa 1: progresso calculado a partir das atividades salvas neste aparelho.',style:TextStyle(color:Cores.mudo,fontSize:11)),
            ])),
        ]));
    });
}

class ProfilePage extends StatefulWidget {
  final ActivityRepository repo; final int refreshKey;
  const ProfilePage({super.key,required this.repo,required this.refreshKey});
  @override State<ProfilePage> createState()=>_ProfilePageState();
}
class _ProfilePageState extends State<ProfilePage> {
  Map<String,dynamic>? profile;
  bool loading=true;
  String? error;
  @override void initState(){super.initState();_loadProfile();}
  Future<void> _loadProfile() async {
    final client=BackendConfig.client; final user=client?.auth.currentUser;
    if(client==null||user==null){if(mounted)setState(()=>loading=false);return;}
    try {
      final row=await client.from('profiles').select().eq('id',user.id).maybeSingle();
      if(mounted)setState(()=>profile=row==null?{'id':user.id,'display_name':user.userMetadata?['display_name']??'Atleta MOVVA','bio':'','is_public':true}:Map<String,dynamic>.from(row));
    } catch(e){if(mounted)setState(()=>error='Não foi possível carregar o perfil. Verifique se executou o SQL do MOVVA no Supabase.');}
    if(mounted)setState(()=>loading=false);
  }
  Future<void> _editProfile() async {
    final name=TextEditingController(text:(profile?['display_name']??'Atleta MOVVA').toString());
    final bio=TextEditingController(text:(profile?['bio']??'').toString());
    final result=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      backgroundColor:Cores.card,title:const Text('Editar perfil público'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:name,decoration:const InputDecoration(labelText:'Nome público')),
        const SizedBox(height:10),TextField(controller:bio,maxLines:3,maxLength:160,decoration:const InputDecoration(labelText:'Sobre você (opcional)')),
        const SizedBox(height:8),const Text('Seu perfil e suas atividades ficam públicos.',style:TextStyle(color:Cores.mudo,fontSize:12)),
      ]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Salvar'))]));
    if(result!=true)return;
    final client=BackendConfig.client; final user=client?.auth.currentUser;
    if(client==null||user==null)return;
    try {
      final updated={'id':user.id,'display_name':name.text.trim().isEmpty?'Atleta MOVVA':name.text.trim(),'bio':bio.text.trim(),'is_public':true,'updated_at':DateTime.now().toUtc().toIso8601String()};
      await client.from('profiles').upsert(updated);
      await client.auth.updateUser(UserAttributes(data:{'display_name':updated['display_name']}));
      if(mounted){setState(()=>profile=updated);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Perfil publicado e atualizado no Supabase.')));}
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Falha ao salvar. Confirme as tabelas e políticas RLS do Supabase.')));}
  }
  Future<void> _logout() async {
    try { await BackendConfig.client?.auth.signOut(); } catch (_) {}
  }
  @override Widget build(BuildContext context)=>FutureBuilder<List<ActivityRecord>>(
    key:ValueKey(widget.refreshKey),future:widget.repo.getAll(),builder:(context,snap){
      final list=snap.data??[];final km=list.fold<double>(0,(s,a)=>s+a.km);final user=BackendConfig.client?.auth.currentUser;
      final name=(profile?['display_name']??user?.email?.split('@').first??'Atleta MOVVA').toString();
      return Scaffold(backgroundColor:Cores.fundo,appBar:AppBar(title:const Text('Perfil'),backgroundColor:Cores.fundo,actions:[
        IconButton(tooltip:'Editar perfil',onPressed:_editProfile,icon:const Icon(Icons.edit_outlined)),
        IconButton(tooltip:'Sair da conta',onPressed:_logout,icon:const Icon(Icons.logout)),
      ]),body:loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(18),children:[
        const CircleAvatar(radius:42,backgroundColor:Cores.laranja,child:Icon(Icons.person,size:46,color:Colors.white)),
        const SizedBox(height:12),Center(child:Text(name,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800))),
        Center(child:Text(user?.email??'',style:const TextStyle(color:Cores.mudo))),
        Center(child:Text((profile?['bio']??'').toString().isEmpty?'Perfil público MOVVA':(profile?['bio']).toString(),style:const TextStyle(color:Cores.mudo))),
        const SizedBox(height:16),Center(child:Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:7),decoration:BoxDecoration(color:Cores.brilho,borderRadius:BorderRadius.circular(20)),child:const Text('● PERFIL PÚBLICO',style:TextStyle(color:Cores.laranja2,fontWeight:FontWeight.bold,fontSize:11)))),
        if(error!=null)Padding(padding:const EdgeInsets.all(8),child:Text(error!,style:const TextStyle(color:Colors.redAccent))),
        const SizedBox(height:22),Row(children:[_stat('ATIVIDADES','${list.length}',Icons.fitness_center),_stat('DISTÂNCIA','${fmtKm(km)} km',Icons.route),_stat('SEGUIDORES','0',Icons.people_outline)]),
        const SizedBox(height:18),FilledButton.icon(onPressed:_editProfile,icon:const Icon(Icons.edit),label:const Text('Editar e publicar perfil'),style:FilledButton.styleFrom(backgroundColor:Cores.laranja)),
        const SizedBox(height:8),OutlinedButton.icon(onPressed:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>const PublicProfilesPage())),icon:const Icon(Icons.people_outline),label:const Text('Explorar perfis públicos')),
        const SizedBox(height:16),const Text('Suas atividades sincronizam com a nuvem quando há internet e sessão ativa. Se estiver offline, ficam guardadas neste aparelho para tentar sincronizar depois.',style:TextStyle(color:Cores.mudo,fontSize:12)),
      ]));
    });
}
class HomePage extends StatelessWidget {
  final ActivityRepository repo;
  final void Function(String modo) onStart;
  final int refreshKey;
  final ValueChanged<int>? onNavigate;
  const HomePage({
    super.key,
    required this.repo,
    required this.onStart,
    required this.refreshKey,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<List<ActivityRecord>>(
    key: ValueKey(refreshKey),
    future: repo.getAll(),
    builder: (context, snap) {
      final list = [...(snap.data ?? <ActivityRecord>[])]
        ..sort((a, b) => b.date.compareTo(a.date));
      final ultima = list.isEmpty ? null : list.first;

      final agora = DateTime.now();
      final inicioSemana =
          DateTime(agora.year, agora.month, agora.day - (agora.weekday - 1));
      final kmSemana = list
          .where((a) => !a.date.isBefore(inicioSemana))
          .fold<double>(0, (s, a) => s + a.km);

            Duration? ritmo;
      if (ultima != null && ultima.km >= 0.1 && ultima.seconds > 0) {
        final seg = (ultima.seconds / ultima.km).round();
        // Acima de 30 min/km indica pouco movimento ou GPS impreciso.
        if (seg <= 30 * 60) ritmo = Duration(seconds: seg);
      }

      final meta = BackendConfig.client?.auth.currentUser?.userMetadata?['display_name'];
      final nome = (meta is String && meta.isNotEmpty) ? meta : null;

      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: MovvaHomeContent(
            userName: nome,
            distanceKm: ultima?.km,
            duration: ultima == null ? null : Duration(seconds: ultima.seconds),
            pacePerKm: ritmo,
            calories: ultima?.calories.round(),
            weeklyKm: kmSemana,
            weeklyGoalKm: 20,
            onStartRun: () => onStart('Corrida'),
            onStartRide: () => onStart('Pedal'),
            onOpenChallenges: onNavigate == null ? null : () => onNavigate!(3),
            onProfile: onNavigate == null ? null : () => onNavigate!(4),
          ),
        ),
      );
    },
  );
}
