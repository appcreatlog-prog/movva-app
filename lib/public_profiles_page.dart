import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend_config.dart';
import 'main.dart' show Cores, fmtKm, fmtTime;

class PublicProfilesPage extends StatefulWidget {
  const PublicProfilesPage({super.key});
  @override State<PublicProfilesPage> createState()=>_PublicProfilesPageState();
}
class _PublicProfilesPageState extends State<PublicProfilesPage> {
  late Future<List<Map<String,dynamic>>> future;
  @override void initState(){super.initState();future=_load();}
  Future<List<Map<String,dynamic>>> _load() async {
    final client=BackendConfig.client;
    if(client==null)return [];
    final rows=await client.from('profiles').select('id,display_name,bio,avatar_url').eq('is_public',true).order('display_name');
    return (rows as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
  }
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:Cores.fundo,appBar:AppBar(title:const Text('Comunidade MOVVA'),backgroundColor:Cores.fundo),body:FutureBuilder<List<Map<String,dynamic>>>(future:future,builder:(context,snap){
    if(snap.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
    if(snap.hasError)return const Center(child:Padding(padding:EdgeInsets.all(24),child:Text('Não foi possível carregar os perfis. Confira o SQL e as políticas do Supabase.',textAlign:TextAlign.center,style:TextStyle(color:Cores.mudo))));
    final profiles=snap.data??[];
    if(profiles.isEmpty)return const Center(child:Text('Ainda não há perfis públicos.',style:TextStyle(color:Cores.mudo)));
    return ListView.builder(itemCount:profiles.length,itemBuilder:(context,i){final p=profiles[i];return Card(color:Cores.card,margin:const EdgeInsets.symmetric(horizontal:12,vertical:5),child:ListTile(leading:const CircleAvatar(backgroundColor:Cores.laranja,child:Icon(Icons.person,color:Colors.white)),title:Text((p['display_name']??'Atleta MOVVA').toString()),subtitle:Text((p['bio']??'').toString().isEmpty?'Perfil público':p['bio'].toString(),maxLines:2,overflow:TextOverflow.ellipsis),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>PublicProfileDetail(profile:p)))));});
  }));
}

class PublicProfileDetail extends StatelessWidget {
  final Map<String,dynamic> profile;
  const PublicProfileDetail({super.key,required this.profile});
  Future<List<Map<String,dynamic>>> _activities() async {
    final client=BackendConfig.client!;
    final rows=await client.from('activities').select('mode,date,seconds,meters,calories').eq('user_id',profile['id']).order('date',ascending:false).limit(100);
    return (rows as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
  }
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:Cores.fundo,appBar:AppBar(title:const Text('Perfil público'),backgroundColor:Cores.fundo),body:FutureBuilder<List<Map<String,dynamic>>>(future:_activities(),builder:(context,snap){
    final list=snap.data??[];final km=list.fold<double>(0,(s,a)=>s+((a['meters'] as num?)?.toDouble()??0)/1000);
    return ListView(padding:const EdgeInsets.all(16),children:[
      const CircleAvatar(radius:40,backgroundColor:Cores.laranja,child:Icon(Icons.person,size:42,color:Colors.white)),const SizedBox(height:12),
      Center(child:Text((profile['display_name']??'Atleta MOVVA').toString(),style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold))),
      Center(child:Text((profile['bio']??'').toString(),style:const TextStyle(color:Cores.mudo))),const SizedBox(height:18),
      Row(children:[Expanded(child:_metric('ATIVIDADES','${list.length}')),Expanded(child:_metric('DISTÂNCIA','${fmtKm(km)} km'))]),
      const SizedBox(height:20),const Text('ATIVIDADES PÚBLICAS',style:TextStyle(fontWeight:FontWeight.bold,letterSpacing:1)),const SizedBox(height:8),
      if(snap.connectionState==ConnectionState.waiting)const Center(child:CircularProgressIndicator()),
      if(snap.hasError)const Text('Não foi possível carregar atividades deste perfil.',style:TextStyle(color:Cores.mudo)),
      if(!snap.hasError&&snap.connectionState!=ConnectionState.waiting&&list.isEmpty)const Text('Nenhuma atividade publicada ainda.',style:TextStyle(color:Cores.mudo)),
      ...list.map((a){final d=DateTime.tryParse((a['date']??'').toString())?.toLocal();final sec=(a['seconds'] as num?)?.toInt()??0;final meters=(a['meters'] as num?)?.toDouble()??0;return Card(color:Cores.card,child:ListTile(leading:Icon(a['mode']=='Pedal'?Icons.directions_bike:Icons.directions_run,color:Cores.laranja),title:Text('${fmtKm(meters/1000)} km • ${a['mode']??'Atividade'}'),subtitle:Text('${d==null?'': '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}'} • ${fmtTime(sec)}')));}),
    ]);
  }));
}
Widget _metric(String title,String value)=>Container(margin:const EdgeInsets.all(4),padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Cores.card,borderRadius:BorderRadius.circular(12)),child:Column(children:[Text(value,style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),Text(title,style:const TextStyle(color:Cores.mudo,fontSize:10))]));
