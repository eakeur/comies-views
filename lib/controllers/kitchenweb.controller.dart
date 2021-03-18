import 'dart:collection';
import 'dart:convert';
import 'package:comies/main.dart';
import 'package:comies/utils/converters.dart';
import 'package:comies/structures/structures.dart';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as HTML show WebSocket, document;
import 'package:flutter/widgets.dart';

class KitchenController extends ChangeNotifier {

  List<Order> _pending = [];
  List<Order> _preparing = [];
  List<Order> _orders = [];
  Order _order;
  String _code = "";

  UnmodifiableListView<Order> get pending =>  UnmodifiableListView<Order>(_pending);
  UnmodifiableListView<Order> get preparing =>  UnmodifiableListView<Order>(_preparing);
  Order get selectedOrder => _order;
  bool get hasSelectedOrder => _order != null;
  String get code => _code;

  HTML.WebSocket _pan;
  HTML.WebSocket _spoon;


  String get kitchenRoute => "${session.server.replaceFirst("http://", "ws://").replaceFirst("https://", "wss://")}/kitchen/${session.partner.id}/${session.store.id}";

  KitchenController(String type, {ScrollController controller, String panID}){
    switch (type){
      case "spoon": connectToKitchenAsSpoon(panID); break;
      case "pan": connectToKitchenAsPan(controller); break;
      default: throw Exception();
    }
  }

  void connectToKitchenAsPan(ScrollController controller) async {
    HTML.document.cookie = "authorization = ${session.token};";
      _pan = new HTML.WebSocket(kitchenRoute+"/TV");
      _pan.onMessage.listen((data) => listenToPanUpdates(data.data, controller));
  }



  void listenToPanUpdates(dynamic data, ScrollController controller){
    try {
      if (data != null){
        var decoded = jsonDecode(data);

        if (decoded['sender'] == 'server'){
          if (decoded['type'] == 'pan-initial'){
            decoded['data'].map((e) => deserializeOrderMap(e)).toList().forEach((ord) {
              if (!_orders.any((order) => order.id == ord.id)) _orders.add(ord);
              _pending = _orders.where((ord) => ord.status == Status.pending).toList();
              _preparing = _orders.where((ord) => ord.status == Status.preparing).toList();
            });
             _code = decoded['code'].toString();
          }
        }

        if (decoded['sender'] == 'spoon'){
          switch (decoded['type']){
            case 'scroll': controller.position.jumpTo(controller.position.pixels + decoded['value']); break;
            case 'display-order': _order = _orders.firstWhere((order) => order.id == decoded['value'], orElse: () => null); break;
          }
        }
 
        notifyListeners();
      } else throw Exception("Nothing received from server");
    } catch (e) {
      print(e);
    }
  }

  void listenToSpoonUpdates(dynamic data){
    try {
      if (data != null){
        var decoded = jsonDecode(data);

        if (decoded['sender'] == 'server'){
          if (decoded['type'] == 'spoon-initial'){
            decoded['data'].map((e) => deserializeOrderMap(e)).toList().forEach((ord) {
              if (!_orders.any((order) => order.id == ord.id)) _orders.add(ord);
              _pending = _orders.where((ord) => ord.status == Status.pending).toList();
              _preparing = _orders.where((ord) => ord.status == Status.preparing).toList();
            });
          }
        }
 
        notifyListeners();
      } else throw Exception("Nothing received from server");
    } catch (e) {
      print(e);
    }
  }

  void connectToKitchenAsSpoon(String panID) async {
    _code = panID;
     HTML.document.cookie = "authorization = ${session.token}";
      _spoon = new HTML.WebSocket(kitchenRoute+"/$panID");
      _spoon.onMessage.listen((data) => listenToSpoonUpdates(data));
  }

  void sendToPan(String event, dynamic value){
   _spoon.send(jsonEncode({'sender': 'spoon', 'type':event, 'code':_code, 'value':value}));
  }


  @override
  void dispose(){
    if (_pan != null) _pan.close();
      if (_spoon != null) _spoon.close();
    super.dispose();
  }
}