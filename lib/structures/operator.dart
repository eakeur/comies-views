import 'package:comies_entities/comies_entities.dart';

class Operator {
  int id;
  String name;
  String identification;
  String password;
  DateTime lastLogin;
  Profile profile;
  Store store;
  Partner partner;
  List<Order> orders;
  bool active;
}
