import 'package:flutter/material.dart';
import 'package:nested_router_keyboard/app_route.dart';
import 'package:nested_router_keyboard/my_router.dart';

class FirstView extends StatefulWidget {
  @override
  _FirstViewState createState() => _FirstViewState();
}

class _FirstViewState extends State<FirstView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This is Root',
                style: TextStyle(fontSize: 30.0),
              ),
              SizedBox(
                height: 48.0,
              ),
              SizedBox(
                width: 300.0,
                child: TextField(
                  decoration: InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              SizedBox(
                height: 48.0,
              ),
              TextButton(
                  onPressed: () {
                    MyRouterDelegate.of(context).push(SecondRoute());
                  },
                  child: Text('NEXT'))
            ],
          ),
        ),
      ),
    );
  }
}

class SecondView extends StatefulWidget {
  @override
  _SecondViewState createState() => _SecondViewState();
}

class _SecondViewState extends State<SecondView> {
  final _nestedRoutes = <AppRoute>[];

  int _currentIndex;
  Widget _rootView;

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;
    _rootView = HomeView();
  }

  @override
  Widget build(BuildContext context) {
    return Router(
      routerDelegate: NestedRouterDelegate(
        root: _rootView,
        builder: (navigator) {
          return Scaffold(
            appBar: AppBar(),
            body: SizedBox.expand(
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  _navigationRail(),
                  Expanded(child: navigator),
                ],
              ),
            ),
          );
        },
        initialRoutes: _nestedRoutes,
      ),
    );
  }

  Widget _navigationRail() {
    return NavigationRail(
      backgroundColor: Theme.of(context).primaryColor,
      destinations: [
        NavigationRailDestination(
          icon: Icon(
            Icons.home,
            color: Colors.white,
          ),
          label: Text(
            'Home',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        NavigationRailDestination(
          icon: Icon(
            Icons.calendar_today,
            color: Colors.white,
          ),
          label: Text(
            'Calendar',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ],
      onDestinationSelected: _onNavigationChanged,
      selectedIndex: _currentIndex,
    );
  }

  _onNavigationChanged(int index) {
    switch (index) {
      case 0:
        _rootView = HomeView();
        break;
      case 1:
        _rootView = CalendarView();
        break;
      default:
        _rootView = Container();
    }
    setState(() {
      _currentIndex = index;
    });
  }
}

class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This is Home',
              style: TextStyle(
                fontSize: 30.0,
              ),
            ),
            SizedBox(
              height: 48.0,
            ),
            SizedBox(
              width: 300.0,
              child: TextField(
                  decoration: InputDecoration(border: OutlineInputBorder())),
            ),
            SizedBox(
              height: 8.0,
            )
          ],
        ),
      ),
    );
  }
}

class CalendarView extends StatefulWidget {
  @override
  _CalendarViewtate createState() => _CalendarViewtate();
}

class _CalendarViewtate extends State<CalendarView> {
  DateTimeRange _currentTimeRange;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This is Calendar',
              style: TextStyle(fontSize: 30.0),
            ),
            SizedBox(
              height: 48.0,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pick Time Range: ${_currentTimeRange != null ? _currentTimeRange.toString() : ''}',
                  style: TextStyle(fontSize: 20.0),
                ),
                SizedBox(
                  width: 30.0,
                ),
                IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () {
                      _showDateTimeRangePicker();
                    })
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _showDateTimeRangePicker() async {
    final now = DateTime.now();
    final tomorrow =
        DateTime(now.year, now.month, now.day).add(Duration(days: 1));
    final today = tomorrow.subtract(Duration(milliseconds: 1));
    final aYearAgo = DateTime(now.year - 1, now.month, now.day);
    final dateRange = await showDateRangePicker(
      context: context,
      initialDateRange: _currentTimeRange,
      initialEntryMode: DatePickerEntryMode.input,
      firstDate: aYearAgo,
      lastDate: tomorrow,
      currentDate: today,
    );
    if (dateRange != null) {
      setState(() {
        _currentTimeRange = dateRange;
      });
    }
  }
}
