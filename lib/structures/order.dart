import 'package:comies_entities/comies_entities.dart';

class Order {
  int id;
  DateTime placed;
  Status status;
  DeliverType deliverType;
  PaymentMethod payment;
  Store store;
  Costumer costumer;
  Operator operator;
  List<Item> items;
  Address address;
  double price;
  bool active;
}
