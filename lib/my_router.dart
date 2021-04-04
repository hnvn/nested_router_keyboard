import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'app_route.dart';

abstract class MyRouterDelegate extends RouterDelegate<List<AppRoute>>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin {
  final List<AppRoute> _stack;

  MyRouterDelegate(List<AppRoute> initialRoutes) : _stack = initialRoutes;

  static MyRouterDelegate of(BuildContext context) {
    final delegate = Router.of(context).routerDelegate;
    assert(delegate is MyRouterDelegate, 'Delegate type must match');
    return delegate as MyRouterDelegate;
  }

  @override
  List<AppRoute> get currentConfiguration => _stack;

  @override
  Future<void> setNewRoutePath(List<AppRoute> configuration) {
    _stack
      ..clear()
      ..addAll(configuration);
    return SynchronousFuture<void>(null);
  }

  List<AppRoute> get stack => List.unmodifiable(_stack);

  void push(AppRoute newRoute, {bool clearStack = false}) {
    if (clearStack) {
      _stack.clear();
    }
    _stack.add(newRoute);
    notifyListeners();
  }

  void pop() {
    if (_stack.isNotEmpty) {
      _stack.removeLast();
      notifyListeners();
    }
  }

  void remove(String routeName) {
    for (int i = _stack.length - 1; i >= 0; i--) {
      if (_stack[i].name == routeName) {
        _stack.remove(i);
        break;
      }
    }
    notifyListeners();
  }

  void loadUri(Uri uri) {
    final routes = _parseUri(uri);
    loadConfiguration(routes);
  }

  void loadConfiguration(List<AppRoute> configuration) {
    _stack
      ..clear()
      ..addAll(configuration);
    notifyListeners();
  }

  Route _routeFactory(RouteSettings settings, AppRoute route,
      [bool useCupertinoPage = true]) {
    final widgetBuilder = (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
        child: route.createWidget());

    if (useCupertinoPage) {
      return CupertinoPageRoute(settings: settings, builder: widgetBuilder);
    } else {
      return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, _, __) => widgetBuilder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          });
    }
  }
}

class TestRouterDelegate extends MyRouterDelegate {
  final Widget _home;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  TestRouterDelegate(Widget home)
      : _home = home,
        super(<AppRoute>[]);

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navigatorKey,
      onPopPage: _onPopPage,
      pages: [
        MyPage(
          routeFactory: (settings) => MaterialPageRoute(
            settings: settings,
            builder: (_) => _home,
          ),
        )
      ],
    );
  }

  @override
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  bool _onPopPage(Route<dynamic> route, dynamic result) {
    if (_stack.isNotEmpty) {
      if (_stack.last.name == route.settings.name) {
        _stack.removeLast();
        notifyListeners();
      }
    }
    return route.didPop(result);
  }
}

class RootRouterDelegate extends MyRouterDelegate {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  RootRouterDelegate() : super(<AppRoute>[]);

  @override
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navigatorKey,
      onPopPage: _onPopPage,
      pages: _stack
          .map((route) => MyPage(
              key: ValueKey(route.identifier),
              name: route.name,
              routeFactory: (settings) => _routeFactory(settings, route)))
          .toList(growable: false),
    );
  }

  @override
  Future<void> setInitialRoutePath(List<AppRoute> configuration) {
    return setNewRoutePath([FirstRoute()]);
  }

  bool _onPopPage(Route<dynamic> route, dynamic result) {
    if (_stack.isNotEmpty) {
      if (_stack.last.name == route.settings.name) {
        _stack.removeLast();
        notifyListeners();
      }
    }
    return route.didPop(result);
  }
}

typedef Widget NestedRouterBuilder(Navigator navigator);

class NestedRouterDelegate extends MyRouterDelegate {
  final Widget root;
  final NestedRouterBuilder builder;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final Function(dynamic result) onFinish;

  NestedRouterDelegate(
      {@required this.root,
      @required this.builder,
      @required List<AppRoute> initialRoutes,
      this.onFinish})
      : super(initialRoutes);

  @override
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  @override
  List<AppRoute> get currentConfiguration => null;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator(
      key: _navigatorKey,
      observers: [
        HeroController(),
      ],
      onPopPage: _onPopPage,
      pages: [
        MyPage(
            key: ValueKey('RootOfNestedNavigator'),
            name: 'RootOfNestedNavigator',
            routeFactory: (settings) => PageRouteBuilder(
                settings: settings, pageBuilder: (_, __, ___) => root)),
      ]..addAll(_stack.map<Page>((route) => MyPage(
          key: ValueKey(route.identifier),
          name: route.name,
          routeFactory: (settings) => _routeFactory(
                settings,
                route,
                false,
              )))),
    );
    return builder(navigator);
  }

  bool _onPopPage(Route<dynamic> route, dynamic result) {
    if (_stack.isNotEmpty) {
      if (_stack.last.name == route.settings.name) {
        _stack.removeLast();
        notifyListeners();
      }
    }
    return route.didPop(result);
  }

  void finish([dynamic result]) {
    if (onFinish != null) {
      onFinish(result);
    }
  }
}

class MyRouterParser extends RouteInformationParser<List<AppRoute>> {
  @override
  Future<List<AppRoute>> parseRouteInformation(
      RouteInformation routeInformation) {
    final uri = Uri.parse(routeInformation.location);
    return SynchronousFuture(_parseUri(uri));
  }

  @override
  RouteInformation restoreRouteInformation(List<AppRoute> configuration) {
    final pathBuffer = StringBuffer();
    final parameters = <String, List<String>>{};
    for (int i = 0; i < configuration.length; i++) {
      final route = configuration[i];
      pathBuffer.write(route.name);
      if (route.name != '/' && i < configuration.length - 1) {
        pathBuffer.write('/');
      }
      if (route.toMap() != null) {
        final routeParameters = route.toMap();
        routeParameters.forEach((key, value) {
          final values = parameters[key] ?? <String>[];
          values.add(value);
          parameters[key] = values;
        });
      }
    }

    return RouteInformation(
        location: Uri(
                path: pathBuffer.toString(),
                queryParameters: parameters.isNotEmpty ? parameters : null)
            .toString());
  }
}

List<AppRoute> _parseUri(Uri uri) {
  final result = <AppRoute>[];
  if (uri.path?.startsWith('/') ?? false) {
    result.add(FirstRoute());
  }
  final routeCounterByName = <String, int>{};
  for (final segment in uri.pathSegments) {
    /// a route name can appeare more than one time on the url
    /// in that case the same parameter will be encoded more than one on the url too
    /// those parameters will be decoded to an array
    /// eg, given this url: '/content_collection/news_detail/news_detail?content_id=123&content_id=456'
    /// then we have parameters looks like {'content_id': ['123', '456']}
    final routeCounter = routeCounterByName[segment] ?? 0;
    final routeCreator = routeCreatorByName[segment];
    if (routeCreator != null) {
      final parameters = <String, String>{};
      uri.queryParametersAll.forEach((key, value) {
        if (value.isNotEmpty) {
          if (routeCounter < value.length) {
            parameters[key] = value[routeCounter];
          } else {
            parameters[key] = value.last;
          }
        } else {
          parameters[key] = '';
        }
      });
      final route = routeCreator(parameters);
      if (route != null) {
        result.add(route);
      }
    }
    routeCounterByName[segment] = routeCounter + 1;
  }

  if (result.isEmpty) {
    result.add(FirstRoute());
  }

  return result;
}

class MyPage extends Page {
  const MyPage({
    LocalKey key,
    String name,
    Object arguments,
    @required this.routeFactory,
  }) : super(key: key, name: name, arguments: arguments);

  final RouteFactory routeFactory;

  @override
  Route createRoute(BuildContext context) => routeFactory(this);
}
