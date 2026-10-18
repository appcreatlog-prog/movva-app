import 'dart:async';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'main.dart' show Cores, fmtTime, fmtKm;

class Resumo {
  final String modo; final int segundos; final double metros; final double calorias; final List<LatLng> pontos;
  const Resumo({required this.modo,required this.segundos,required this.metros,required this.calorias,required this.pontos});
  double get km=>metros/1000;
}
class RegistrarPage extends StatefulWidget {
  final String modo; const RegistrarPage({super.key,required this.modo});
  @override State<RegistrarPage> createState()=>_RegistrarPageState();
}
class _RegistrarPageState extends State<RegistrarPage> {
  final _mapa=MapController(); final List<LatLng> _pontos=[];
  StreamSubscription<Position>? _gps; Timer? _timer;
  int _seg=0; double _metros=0; bool _pausado=false; bool _semSinal=true;
  String? _erro; LatLng? _atual; LatLng? _ultimoPonto;
  bool get _corrida=>widget.modo=='Corrida';
  double get _km=>_metros/1000;
  double get _calorias=>_km*(_corrida?62:30);

  @override void initState(){super.initState();_iniciar();}
  Future<void> _iniciar() async {
    try {
      if(!await Geolocator.isLocationServiceEnabled()){_setErro('Ative a localização do aparelho.');return;}
      var perm=await Geolocator.checkPermission();
      if(perm==LocationPermission.denied) perm=await Geolocator.requestPermission();
      if(perm==LocationPermission.denied||perm==LocationPermission.deniedForever){_setErro('Permita o acesso à localização nas configurações.');return;}
      _timer=Timer.periodic(const Duration(seconds:1),(_){if(!_pausado&&mounted)setState(()=>_seg++);});
      final LocationSettings cfg=defaultTargetPlatform==TargetPlatform.android
        ? AndroidSettings(accuracy:LocationAccuracy.best,distanceFilter:5,
          foregroundNotificationConfig:const ForegroundNotificationConfig(notificationTitle:'MOVVA',notificationText:'Registrando sua atividade',enableWakeLock:true))
        : const LocationSettings(accuracy:LocationAccuracy.best,distanceFilter:5);
      _gps=Geolocator.getPositionStream(locationSettings:cfg).listen(_novaPosicao,onError:(_){_setErro('Não foi possível ler o GPS.');});
    } catch(e){_setErro('Falha ao iniciar GPS: $e');}
  }
  void _setErro(String s){if(mounted)setState(()=>_erro=s);}
  void _novaPosicao(Position p){
    if(!mounted)return;
    final point=LatLng(p.latitude,p.longitude);
    setState((){
      _semSinal=false;_atual=point;
      if(!_pausado&&p.accuracy<=30){
        final prev=_ultimoPonto;
        if(prev!=null){
          final delta=Geolocator.distanceBetween(prev.latitude,prev.longitude,point.latitude,point.longitude);
          // Filtra saltos de GPS anormais; pode ser revisto após testes reais.
          if(delta>=0.5&&delta<=100) _metros+=delta;
        }
        _pontos.add(point);_ultimoPonto=point;
      }
    });
    try{_mapa.move(point,_pontos.length<2?17:_mapa.camera.zoom);}catch(_){}
  }
  Future<void> _finalizar() async {
    final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(backgroundColor:Cores.card,title:const Text('Finalizar atividade?'),
      content:Text('${fmtKm(_km)} km registrados. A atividade será salva localmente ao confirmar.'),
      actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Continuar')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Finalizar'))]));
    if(ok!=true||!mounted)return;
    Navigator.pop(context,Resumo(modo:widget.modo,segundos:_seg,metros:_metros,calorias:_calorias,pontos:List.of(_pontos)));
  }
  Future<void> _centralizarLocalizacao() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _setErro('Ative a localização do aparelho.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setErro('Permita o acesso à localização nas configurações.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
      );
      if (!mounted) return;
      final point = LatLng(position.latitude, position.longitude);
      setState(() {
        _atual = point;
        _semSinal = false;
      });
      _mapa.move(point, 17);
    } catch (_) {
      _setErro('Não foi possível obter a localização atual.');
    }
  }

  void _alternarPausa(){setState(()=>_pausado=!_pausado);if(_pausado){_ultimoPonto=null;}else{_ultimoPonto=null;}}
  @override void dispose(){_gps?.cancel();_timer?.cancel();_mapa.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>PopScope(canPop:false,onPopInvokedWithResult:(didPop,_) {if(!didPop)_finalizar();},
    child:Scaffold(body:Column(children:[Expanded(flex:5,child:_mapaView()),_painel()])));
  Widget _mapaView()=>Stack(children:[
    FlutterMap(mapController:_mapa,options:const MapOptions(initialCenter:LatLng(-5.79,-35.21),initialZoom:5),
      children:[
        TileLayer(urlTemplate:'https://tile.openstreetmap.org/{z}/{x}/{y}.png',userAgentPackageName:'com.movva.app'),
        PolylineLayer(polylines:[Polyline(points:_pontos,strokeWidth:5,color:Cores.laranja)]),
        if(_atual!=null)MarkerLayer(markers:[Marker(point:_atual!,width:22,height:22,child:Container(decoration:BoxDecoration(color:Cores.laranja2,shape:BoxShape.circle,border:Border.all(color:Colors.white,width:3))))]),
        const RichAttributionWidget(attributions:[TextSourceAttribution('© OpenStreetMap')]),
      ]),
    SafeArea(child:Align(alignment:Alignment.topCenter,child:_erro!=null||_semSinal?Container(margin:const EdgeInsets.all(12),padding:const EdgeInsets.symmetric(horizontal:14,vertical:8),decoration:BoxDecoration(color:Cores.card,borderRadius:BorderRadius.circular(999)),child:Text(_erro??'Procurando sinal de GPS…',style:const TextStyle(fontSize:12))):const SizedBox.shrink())),
    SafeArea(child:Align(alignment:Alignment.topLeft,child:Padding(padding:const EdgeInsets.all(12),child:IconButton.filledTonal(onPressed:()=>_finalizar(),icon:const Icon(Icons.close))))),
    SafeArea(child:Align(alignment:Alignment.bottomRight,child:Padding(
      padding:const EdgeInsets.all(14),
      child:FloatingActionButton.small(
        heroTag:'movva_recenter_gps',
        backgroundColor:Cores.card,
        foregroundColor:Cores.laranja,
        tooltip:'Centralizar na minha localização',
        onPressed:_centralizarLocalizacao,
        child:const Icon(Icons.my_location),
      ),
    ))),
  ]);
  Widget _painel(){
    Widget metric(String value,String label)=>Expanded(child:Column(children:[Text(value,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800)),Text(label,style:const TextStyle(fontSize:11,color:Cores.mudo))]));
    return Container(width:double.infinity,padding:const EdgeInsets.fromLTRB(20,16,20,12),decoration:const BoxDecoration(color:Cores.fundo,border:Border(top:BorderSide(color:Cores.linha))),
      child:SafeArea(top:false,child:Column(mainAxisSize:MainAxisSize.min,children:[
        Text(widget.modo,style:const TextStyle(color:Cores.laranja2,fontWeight:FontWeight.w700)),
        Text(fmtTime(_seg),style:const TextStyle(fontSize:54,fontWeight:FontWeight.w900)),
        Row(children:[metric(fmtKm(_km),'km'),metric(_km>0.02?fmtTime((_seg/_km).round()):'--:--','ritmo /km'),metric('${_calorias.round()}','calorias')]),
        const SizedBox(height:18),
        Row(children:[
          Expanded(child:OutlinedButton(onPressed:_alternarPausa,style:OutlinedButton.styleFrom(foregroundColor:Cores.texto,side:const BorderSide(color:Cores.linha),shape:const StadiumBorder(),padding:const EdgeInsets.symmetric(vertical:14)),child:Text(_pausado?'Retomar':'Pausar'))),
          const SizedBox(width:12),
          Expanded(child:FilledButton(onPressed:_finalizar,style:FilledButton.styleFrom(backgroundColor:Cores.laranja,shape:const StadiumBorder(),padding:const EdgeInsets.symmetric(vertical:14)),child:const Text('Finalizar'))),
        ]),
      ])));
  }
}
