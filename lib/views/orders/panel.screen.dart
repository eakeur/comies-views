import 'package:comies/components/screen.comp.dart';
import 'package:comies/components/titlebox.comp.dart';
import 'package:comies/controllers/kitchen.controller.dart' if(dart.library.html) 'package:comies/controllers/kitchenweb.controller.dart' if(dart.library.io) 'package:comies/controllers/kitchen.controller.dart';
import 'package:comies_entities/comies_entities.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrdersPanelScreen extends StatefulWidget {
  @override
  OrdersPanel createState() => OrdersPanel();
}

class OrdersPanel extends State<OrdersPanelScreen> {
  TextEditingController c = new TextEditingController();
  String type;

  @override
  Widget build(BuildContext context) {
    Widget child;
    switch (type){
      case "spoon": child = SpoonScreen(code: c.text); break;
      case "pan": child = PanScreen(); break;
      default: child = Scaffold(
        appBar: AppBar(title: Text("Selecione sua função")),
        body: Builder(
          builder: (context){
            return Wrap(
              children: [
                ElevatedButton(child: Text("SOU COLHER"), onPressed: (){
                  Scaffold.of(context).showBottomSheet((context) => Container(
                    child: TextFormField(
                      controller: c,
                      onFieldSubmitted: (s) => setState((){type = "spoon";}),
                      onEditingComplete: () => setState((){type = "spoon";}),
                      onSaved: (s) => setState((){type = "spoon";}),
                      decoration: InputDecoration(
                        labelText: "Código da panela",
                        hintMaxLines: 3,
                        hintText: "Este código aparecerá na tela em que você que se conectar",
                        suffix: IconButton(icon: Icon(Icons.add), onPressed: (){
                          Navigator.pop(context);
                          setState((){type = "spoon";});
                        })
                      ),
                    )
                  ));
                }),
                ElevatedButton(child: Text("SOU PANELA"), onPressed: (){setState((){type = "pan";});})
              ],
            );
          },
        )
      ); break;
    }

    return child;

  }
}


class OrderCard extends StatefulWidget {
  final Order order;
  OrderCard({this.order});
  @override
  _OrderCardState createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: 300,
        child: Column(
          children: [
            TitleBox("PEDIDO Nº "+widget.order.id.toString()),
            for (var it in widget.order.items) ListTile(title: Text("PRODUTO: ${it.product.name} - QUANTIDADE: ${it.quantity}")),
            Container(
              alignment: Alignment.bottomRight,
              child: Row(children: [TextButton(child: Text("PREPARAR"), onPressed: (){})]),
            )
        ])
      )
    );
  }
}


class PanScreen extends StatefulWidget {
  final ScrollController scroll = new ScrollController();
  @override
  _PanScreenState createState() => _PanScreenState();
}

class _PanScreenState extends State<PanScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => KitchenController("pan", controller: widget.scroll),
      child: Consumer<KitchenController>(
        builder: (context, ctx, child){
          return Scaffold(
            appBar: AppBar(title: Text("Cozinha" + (ctx.code == "" ? "" : " - ID: ${ctx.code}"))),
            floatingActionButtonLocation: FloatingActionButtonLocation.miniStartTop,
            body: Screen(
              onRefresh: () => new Future(() => setState(() {})),
              children: [
                Row(
                  children: [
                    Expanded(flex: 35,
                    child: ListView(controller: widget.scroll, children: [
                        for (var order in ctx.pending) OrderCard(order: order)
                      ]),
                    ),
                    Expanded(flex: 65,
                      child: ListView(children: [
                        for (var order in ctx.preparing) OrderCard(order: order)
                      ]),
                    )
                  ],
                )
              ]
            )
          );
        }
      )
    );
  }
}

class SpoonScreen extends StatefulWidget {
  final String code;
  SpoonScreen({this.code});
  @override
  _SpoonScreenState createState() => _SpoonScreenState();
}

class _SpoonScreenState extends State<SpoonScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => KitchenController("spoon", panID: widget.code),
      child: Consumer<KitchenController>(
        builder: (context, ctx, child){
          return Scaffold(
            appBar: AppBar(title: Text("Cozinha" + (ctx.code == "" ? "" : " - ID: ${ctx.code}"))),
            floatingActionButtonLocation: FloatingActionButtonLocation.miniStartTop,
            body: Column(
              children: [
                Expanded(flex: 90,
                  child: GestureDetector(
                    onVerticalDragUpdate: (details){
                      details.delta.dy > 0 
                      ? ctx.sendScrollToPan(details.delta.distanceSquared * -1)
                      : ctx.sendScrollToPan(details.delta.distanceSquared);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red, width: 2)
                      ),
                      child: Center(child:Text("Deslize para mexer na panela"))
                    ),
                  ),
                )
              ]
            ),
            
          );
        }
      )
    );
  }
}