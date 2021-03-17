import 'dart:collection';
import 'dart:convert';
import 'dart:io' as IO;
import 'package:comies/main.dart';
import 'package:comies/utils/converters.dart';
import 'package:comies_entities/comies_entities.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class KitchenController extends ChangeNotifier {

  List<Order> _pending = [];
  List<Order> _preparing = [];
  List<Order> _orders = [];
  String _code = "";

  UnmodifiableListView get pending =>  UnmodifiableListView(_pending);
  UnmodifiableListView get preparing =>  UnmodifiableListView(_preparing);
  String get code => _code;

  IO.WebSocket _pan;
  IO.WebSocket _tv;
  IO.WebSocket _spoon;


  String get kitchenRoute => "${session.server.replaceFirst("http://", "ws://").replaceFirst("https://", "wss://")}/kitchen/${session.partner.id}/${session.store.id}";
  String get screenRoute => "${session.server.replaceFirst("http://", "ws://").replaceFirst("https://", "wss://")}/screen/${session.partner.id}/${session.store.id}/";
  String get screenTVRoute => "${session.server.replaceFirst("http://", "ws://").replaceFirst("https://", "wss://")}/screen/${session.partner.id}/${session.store.id}/TV";

  KitchenController(String type, {ScrollController controller, String panID}){
    switch (type){
      case "spoon": connectToKitchenAsSpoon(panID); break;
      case "pan": connectToKitchenAsPan(controller); break;
      default: throw Exception();
    }
  }





  void connectToKitchenAsPan(ScrollController controller) async {
    _pan = await IO.WebSocket.connect(kitchenRoute, headers: {"authorization": session.token});
      _pan.listen(listenToPanUpdates);
      _tv = await IO.WebSocket.connect(screenTVRoute, headers: {"authorization": session.token});
      _tv.listen((data) => listenToTVUpdates(data, controller));
    
  }



  void listenToPanUpdates(dynamic data){
    try {
      if (data != null){
        var decoded = jsonDecode(data);
        if (decoded is List){
          decoded.map((e) => deserializeOrderMap(e)).toList().forEach((ord) {
            if (!_orders.any((order) => order.id == ord.id)) _orders.add(ord);
            _pending = _orders.where((ord) => ord.status == Status.pending).toList();
            _preparing = _orders.where((ord) => ord.status == Status.preparing).toList();
          });
          notifyListeners();
        } else throw Exception("Usuportted data type for this endpoint");
      } else throw Exception("Nothing receive from server");
    } catch (e) {
      print(e);
    }
  }

  void listenToTVUpdates(dynamic data, ScrollController controller){
    try {
      if (data != null && double.tryParse(data) != null){
        var scroll = double.parse(data);
        controller.position.jumpTo(controller.position.pixels + scroll);
      } else if (data is String && data.length > 0 && data.length <= 8){
        _code = data.toString();
        notifyListeners();
      } else throw Exception("Usuportted data type for this endpoint");
    } catch (e) {
      print(e);
    }
  }

  void connectToKitchenAsSpoon(String panID) async {
    _code = panID;
    _spoon = await IO.WebSocket.connect(screenRoute+"$panID", headers: {"authorization": session.token});
  }

  void sendScrollToPan(double scroll){
   _spoon.add(scroll.toString());
  }


  @override
  void dispose(){
    if (_pan != null) _pan.close();
    if (_tv != null) _tv.close();
    if (_spoon != null) _spoon.close();
    super.dispose();
  }
}