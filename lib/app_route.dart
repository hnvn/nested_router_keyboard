import 'package:flutter/widgets.dart';

import 'views.dart';

typedef AppRoute AppRouteCreator(Map<String, String> parameters);

final routeCreatorByName = <String, AppRouteCreator>{
  '/': FirstRoute.creator,
  'second': SecondRoute.creator,
};

abstract class AppRoute {
  String get name;

  String get identifier;

  Map<String, String> toMap() => null;

  Widget createWidget();
}

class FirstRoute extends AppRoute {
  String get name => '/';

  String get identifier => '/';

  static AppRouteCreator get creator => (_) => FirstRoute();

  @override
  Widget createWidget() => FirstView();

  @override
  bool operator ==(other) =>
      identical(this, other) ||
      other.runtimeType == this.runtimeType && other is FirstRoute;

  @override
  int get hashCode => super.hashCode;
}

class SecondRoute extends AppRoute {
  String get name => 'second';

  String get identifier => 'second';

  static AppRouteCreator get creator => (_) => SecondRoute();

  @override
  Widget createWidget() => SecondView();
}
